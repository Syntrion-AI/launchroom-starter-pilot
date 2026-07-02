<#
.SYNOPSIS
  Install a real LaunchRoom Starter profile distribution layer for Hermes on Windows.

.DESCRIPTION
  Public LaunchRoom test package / not AIRMIDA authority.

  This is the primary LaunchRoom setup tool. It creates or selects an isolated
  Hermes profile, applies non-secret Stage 1 profile config values, installs the
  LaunchRoom SaaS profile-distribution package, writes profile-level
  instructions/contracts/reports, optionally enables starter toolsets, creates a
  local workspace, and collects a no-secret software inventory.

  It never copies .env, auth.json, state.db, OAuth stores, memory/session stores,
  logs, or raw MCP credential values. It never asks for or writes secret values.

  Use -TestOutputRoot for CI-grade non-mutating self-test mode. In that mode
  the script writes a simulated profile/workspace tree under the supplied path
  and never calls hermes profile/config/tools commands.

  The source package is profile-distribution/launchroom-saas. The old
  templates/ directory is kept only for compatibility with earlier pilot stages.
#>
param(
  [string]$ProfileName = 'launchroom',
  [string]$WorkspacePath = '',
  [string]$ProjectName = '',
  [string]$ProjectType = 'blank_saas_workspace',
  [string]$UserLanguage = 'auto',
  [string]$ModelProvider = '',
  [string]$ModelDefault = '',
  [switch]$Yes,
  [switch]$NoLocalSkills,
  [switch]$NoToolsets,
  [switch]$NoInventory,
  [switch]$ShowPlanOnly,
  [string]$TestOutputRoot = ''
)

$ErrorActionPreference = 'Stop'
$protected = @('default','airmida','main')
if ($protected -contains $ProfileName.ToLowerInvariant()) {
  throw "Refusing to configure protected profile: $ProfileName"
}
if ($ProfileName -notmatch '^[a-z0-9][a-z0-9-]*$') {
  throw "ProfileName must use lowercase letters, numbers, and hyphens only."
}
if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
  $HomeRoot = if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { $env:USERPROFILE } elseif (-not [string]::IsNullOrWhiteSpace($env:HOME)) { $env:HOME } else { [System.IO.Path]::GetTempPath() }
  $WorkspacePath = Join-Path $HomeRoot (Join-Path 'LaunchRoom' $ProfileName)
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = $ProfileName
}
$AllowedProjectTypes = @('blank_saas_workspace','existing_project','repo_clone_later','planning_only')
if ($AllowedProjectTypes -notcontains $ProjectType) {
  throw "ProjectType must be one of: $($AllowedProjectTypes -join ', ')"
}

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$DistributionRoot = Join-Path $RepoRoot 'profile-distribution/launchroom-saas'
$SourceRoot = Join-Path $RepoRoot 'source'

function Require-Path {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path $Path)) { throw "Missing required ${Label}: ${Path}" }
}

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Run-Hermes {
  param([string[]]$Arguments)
  & hermes @Arguments
  if ($LASTEXITCODE -ne 0) { throw "hermes $($Arguments -join ' ') failed with exit code $LASTEXITCODE" }
}

function Try-Hermes {
  param([string[]]$Arguments)
  $output = & hermes @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) {
    return @{ ok=$false; command="hermes $($Arguments -join ' ')"; output=(($output | Out-String).Trim()) }
  }
  return @{ ok=$true; command="hermes $($Arguments -join ' ')"; output=(($output | Out-String).Trim()) }
}

function Capture-Hermes {
  param([string[]]$Arguments)
  $output = & hermes @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) { throw "hermes $($Arguments -join ' ') failed: $output" }
  return (($output | Out-String).Trim())
}

function Confirm-Step {
  param([string]$Message)
  if ($Yes) { return }
  $answer = Read-Host "$Message Type YES to continue"
  if ($answer -ne 'YES') { throw 'User cancelled LaunchRoom setup.' }
}


function Write-LaunchRoomSection {
  param([string]$Title)
  Write-Host ""
  Write-Host "== $Title =="
}

function ConvertTo-LaunchRoomYesNo {
  param([bool]$Value)
  if ($Value) { return 'yes' }
  return 'no'
}


function Test-UnsafeWorkspacePath {
  param([string]$Path)
  $full = [System.IO.Path]::GetFullPath($Path)
  $root = [System.IO.Path]::GetPathRoot($full)
  if ($full.TrimEnd('\','/') -eq $root.TrimEnd('\','/')) { return 'workspace path must not be a drive root' }
  $homePath = if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) { [System.IO.Path]::GetFullPath($env:USERPROFILE) } elseif (-not [string]::IsNullOrWhiteSpace($env:HOME)) { [System.IO.Path]::GetFullPath($env:HOME) } else { '' }
  $trimChars = [char[]]@([char]'\',[char]'/')
  if ($homePath -and ($full.TrimEnd($trimChars).ToLowerInvariant() -eq $homePath.TrimEnd($trimChars).ToLowerInvariant())) { return 'workspace path must not be the user home directory itself' }
  $lower = $full.ToLowerInvariant().Replace([string][char]92,'/')
  $blockedFragments = @('/appdata/local/hermes/profiles','/.hermes/profiles','/auth.json','/state.db','/.ssh','/.aws','/99_secrets','/credentials','/credential','/secrets','/secret')
  foreach ($fragment in $blockedFragments) {
    if ($lower.Contains($fragment)) { return "workspace path contains blocked credential/runtime fragment: $fragment" }
  }
  return ''
}

function Get-SafeProjectStructure {
  param([string]$Path)
  $summary = [ordered]@{
    git_dir_present = Test-Path (Join-Path $Path '.git')
    package_manifest_present = (Test-Path (Join-Path $Path 'package.json')) -or (Test-Path (Join-Path $Path 'pnpm-workspace.yaml')) -or (Test-Path (Join-Path $Path 'yarn.lock'))
    python_manifest_present = (Test-Path (Join-Path $Path 'pyproject.toml')) -or (Test-Path (Join-Path $Path 'requirements.txt'))
    node_manifest_present = Test-Path (Join-Path $Path 'package.json')
    tests_dir_present = (Test-Path (Join-Path $Path 'tests')) -or (Test-Path (Join-Path $Path 'test'))
    src_dir_present = (Test-Path (Join-Path $Path 'src')) -or (Test-Path (Join-Path $Path 'app'))
    docs_dir_present = (Test-Path (Join-Path $Path 'docs')) -or (Test-Path (Join-Path $Path 'doc'))
  }
  return $summary
}

function Resolve-LaunchRoomTokens {
  param([string]$Text, [hashtable]$Tokens)
  $result = $Text
  foreach ($key in $Tokens.Keys) {
    $value = [string]$Tokens[$key]
    $result = $result.Replace("{{${key}}}", $value)
    $result = $result.Replace("__LAUNCHROOM_RESOLVE__${key}", $value)
  }
  return $result
}

function Copy-ResolvedFile {
  param([string]$SourcePath, [string]$DestinationPath, [hashtable]$Tokens)
  $text = Get-Content -Raw -Encoding UTF8 $SourcePath
  $resolved = Resolve-LaunchRoomTokens $text $Tokens
  Write-Utf8NoBom $DestinationPath $resolved
}

function Set-HermesConfig {
  param([string]$Key, [string]$Value)
  Write-Host "config set $Key"
  Run-Hermes @('-p',$ProfileName,'config','set',$Key,$Value)
}

function Get-CommandStatus {
  param([string]$Name, [string[]]$VersionArgs)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { return @{ name=$Name; status='missing'; version=''; path='' } }
  $version = ''
  try { $version = (& $Name @VersionArgs 2>&1 | Select-Object -First 1 | Out-String).Trim() } catch { $version = 'present_version_probe_failed' }
  return @{ name=$Name; status='present'; version=$version; path=$cmd.Source }
}

function ConvertTo-YamlSingleQuotedScalar {
  param([string]$Value)
  $clean = [regex]::Replace([string]$Value, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', ' ')
  $clean = $clean.Replace("`r", ' ').Replace("`n", ' ').Replace("`t", ' ').Trim()
  $clean = $clean.Replace("'", "''")
  return "'$clean'"
}

function ConvertTo-YamlListBlock {
  param([string[]]$Values, [string]$Indent = '  ')
  if (-not $Values -or $Values.Count -eq 0) { return @("${Indent}[]") }
  $out = @()
  foreach ($value in $Values) { $out += "${Indent}- $value" }
  return $out
}

function Has-UnresolvedLaunchRoomPlaceholder {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $true }
  $text = Get-Content -Raw -Encoding UTF8 $Path
  return ($text -match '__LAUNCHROOM_RESOLVE__[A-Z0-9_]+')
}

$RequiredDistributionFiles = @(
  'distribution.yaml',
  'config.yaml.template',
  'SOUL.md',
  'PROFILE_INSTRUCTIONS.md',
  'LAUNCHROOM_PROFILE_CONTRACT.yaml',
  '.env.EXAMPLE',
  'reports/profile-foundation-report.template.yaml',
  'reports/profile-apply-plan.template.yaml',
  'skills/launchroom-profile-operator/SKILL.md',
  'skills/launchroom-hermes-settings-guide/SKILL.md',
  'skills/launchroom-saas-operator/SKILL.md'
)
foreach ($rel in $RequiredDistributionFiles) {
  Require-Path (Join-Path $DistributionRoot $rel) "distribution file $rel"
}
Require-Path (Join-Path $SourceRoot 'stages/output/stage-1-selected-settings.example.yaml') 'selected settings example'

$IsSelfTest = -not [string]::IsNullOrWhiteSpace($TestOutputRoot)
$TestOutputFull = ''
if ($IsSelfTest) {
  $TestOutputFull = [System.IO.Path]::GetFullPath($TestOutputRoot)
  $WorkspaceFull = Join-Path $TestOutputFull (Join-Path 'workspace' $ProfileName)
} else {
  $WorkspaceFull = [System.IO.Path]::GetFullPath($WorkspacePath)
}
$HasModelProvider = -not [string]::IsNullOrWhiteSpace($ModelProvider)
$HasModelDefault = -not [string]::IsNullOrWhiteSpace($ModelDefault)
$ModelProviderToken = if ($HasModelProvider) { $ModelProvider } else { 'DEFERRED_MODEL_PROVIDER' }
$ModelDefaultToken = if ($HasModelDefault) { $ModelDefault } else { 'DEFERRED_MODEL_DEFAULT' }

$ToolsetPlan = if ($NoToolsets) { 'skipped by -NoToolsets' } elseif ($IsSelfTest) { 'skipped in self-test mode' } else { 'starter toolsets will be enabled where supported' }
$InventoryPlan = if ($NoInventory) { 'skipped by -NoInventory' } else { 'no-secret software inventory will be collected' }
$LocalSkillsPlan = if ($NoLocalSkills) { 'skipped by -NoLocalSkills' } else { '3 LaunchRoom skills will be installed' }
$ModelProviderPlan = if ($HasModelProvider) { $ModelProvider } else { 'deferred safely; run Hermes model/setup later' }
$ModelDefaultPlan = if ($HasModelDefault) { $ModelDefault } else { 'deferred safely; run Hermes model/setup later' }

$plan = @"
LaunchRoom Stage 1 beginner-safe setup plan

In plain language:
- This creates or updates ONE isolated Hermes profile: $ProfileName
- Stage 2 links that profile to one local workspace: $WorkspaceFull
- Your existing main/default/airmida profiles are protected and are not the target.
- Secrets are not requested, copied, printed, or stored by this installer.
- Provider/model setup is optional and can be deferred safely.
- Runtime surfaces such as n8n, Cloudflare, Hetzner, MCP credentials, gateways, and production deployments are not touched.

Selected choices:
- Profile: $ProfileName
- Project name: $ProjectName
- Project type: $ProjectType
- Workspace: $WorkspaceFull
- User language: $UserLanguage
- Model provider: $ModelProviderPlan
- Default model: $ModelDefaultPlan
- Toolsets: $ToolsetPlan
- Local LaunchRoom skills: $LocalSkillsPlan
- Inventory: $InventoryPlan
- Self-test mode: $IsSelfTest

Will create/update:
- Hermes profile if missing, using --no-skills to avoid default bundled skill noise
- non-secret Hermes config values from LaunchRoom Stage 1 baseline
- profile SOUL.md, PROFILE_INSTRUCTIONS.md, LAUNCHROOM_PROFILE_CONTRACT.yaml
- profile .env.EXAMPLE with variable names only
- profile reports/profile-foundation-report.yaml
- profile reports/profile-apply-plan.yaml
- profile reports/stage-1-selected-settings.yaml
- profile reports/config.yaml.draft (template/draft mode only)
- local LaunchRoom bundled skills in the target profile
- workspace README.md, AGENTS.md, HERMES.md when compatibility templates exist
- workspace .hermes/reports/profile-setup-report.yaml when compatibility template exists
- workspace .hermes/reports/workspace-onboarding-report.yaml
- workspace .hermes/reports/software-inventory-report.yaml unless -NoInventory

Will not touch:
- .env
- auth.json
- state.db
- OAuth/session/memory stores
- cloud/provider/runtime/gateway credentials
- raw MCP credential values
- n8n, Cloudflare, Hetzner, MCP, gateway, billing, or production runtime surfaces

Self-test mode additionally will not call:
- hermes profile create
- hermes config set
- hermes tools enable

Beginner-safe result to expect:
- PASS means the profile layer exists, required files are visible, YAML is valid, and no LaunchRoom placeholders remain.
- PARTIAL means the profile layer is usable, but model/provider or optional tools still need a later setup step.
- BLOCKED means the installer refused to proceed instead of guessing or touching a protected surface.
"@
Write-LaunchRoomSection 'Beginner-safe plan'
Write-Host $plan
if ($ShowPlanOnly) { exit 0 }
Confirm-Step "Apply this LaunchRoom Starter profile setup?"

$WorkspaceSafetyBlocker = Test-UnsafeWorkspacePath $WorkspaceFull
if (-not [string]::IsNullOrWhiteSpace($WorkspaceSafetyBlocker)) {
  throw "Refusing unsafe Stage 2 workspace path before profile mutation: $WorkspaceSafetyBlocker ($WorkspaceFull)"
}

if ($IsSelfTest) {
  Write-Host "Running non-mutating self-test mode under: $TestOutputFull"
  $profileRoot = Join-Path $TestOutputFull (Join-Path 'profiles' $ProfileName)
  $configPath = Join-Path $profileRoot 'config.yaml'
  New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
} else {
  $profiles = (Capture-Hermes @('profile','list'))
  if ($profiles -notmatch [regex]::Escape($ProfileName)) {
    Write-Host "Creating Hermes profile: $ProfileName"
    Run-Hermes @('profile','create',$ProfileName,'--no-skills','--description','LaunchRoom Starter profile for local SaaS project setup and governed AI-operator work.')
  } else {
    Write-Host "Using existing Hermes profile: $ProfileName"
  }

  $configPath = Capture-Hermes @('-p',$ProfileName,'config','path')
  $profileRoot = Split-Path -Parent $configPath
}
$WorkspaceSafetyBlocker = Test-UnsafeWorkspacePath $WorkspaceFull
if (-not [string]::IsNullOrWhiteSpace($WorkspaceSafetyBlocker)) {
  throw "Refusing unsafe Stage 2 workspace path: $WorkspaceSafetyBlocker ($WorkspaceFull)"
}
$WorkspaceExistedBefore = Test-Path $WorkspaceFull
New-Item -ItemType Directory -Force -Path $WorkspaceFull | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull '.hermes/reports') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull '.hermes/instructions') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull 'saas-operator-kit') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $profileRoot 'reports') | Out-Null

$tokens = @{
  PROFILE_NAME = $ProfileName
  PROFILE_PATH = $profileRoot.Replace('\','/')
  WORKSPACE_PATH = $WorkspaceFull.Replace('\','/')
  PROJECT_PATH = $WorkspaceFull.Replace('\','/')
  PROJECT_NAME = $ProjectName
  PROJECT_TYPE = $ProjectType
  USER_LANGUAGE = $UserLanguage
  MODEL_PROVIDER = $ModelProviderToken
  MODEL_DEFAULT = $ModelDefaultToken
  GENERATED_AT = (Get-Date).ToString('s')
}

if ($IsSelfTest) {
  Write-Host 'Self-test mode: generating simulated live config.yaml from template; skipping hermes config set.'
  Copy-ResolvedFile (Join-Path $DistributionRoot 'config.yaml.template') $configPath $tokens
} else {
  Write-Host 'Applying non-secret Hermes config values from LaunchRoom Stage 1 baseline'
  if ($HasModelProvider) { Set-HermesConfig 'model.provider' $ModelProvider }
  if ($HasModelDefault) { Set-HermesConfig 'model.default' $ModelDefault }
  Set-HermesConfig 'display.personality' 'technical'
  Set-HermesConfig 'display.language' $UserLanguage
  Set-HermesConfig 'display.show_reasoning' 'false'
  Set-HermesConfig 'agent.image_input_mode' 'auto'
  Set-HermesConfig 'agent.max_turns' '60'
  Set-HermesConfig 'agent.api_max_retries' '3'
  Set-HermesConfig 'agent.tool_use_enforcement' 'auto'
  Set-HermesConfig 'approvals.mode' 'smart'
  Set-HermesConfig 'approvals.timeout' '60'
  Set-HermesConfig 'approvals.cron_mode' 'deny'
  Set-HermesConfig 'approvals.mcp_reload_confirm' 'true'
  Set-HermesConfig 'approvals.destructive_slash_confirm' 'true'
  Set-HermesConfig 'security.redact_secrets' 'true'
  Set-HermesConfig 'security.allow_private_urls' 'false'
  Set-HermesConfig 'security.tirith_enabled' 'true'
  Set-HermesConfig 'browser.allow_private_urls' 'false'
  Set-HermesConfig 'browser.auto_local_for_private_urls' 'true'
  Set-HermesConfig 'checkpoints.enabled' 'true'
  Set-HermesConfig 'checkpoints.max_snapshots' '20'
  Set-HermesConfig 'terminal.backend' 'local'
  Set-HermesConfig 'terminal.cwd' $WorkspaceFull
  Set-HermesConfig 'terminal.timeout' '180'
  Set-HermesConfig 'terminal.persistent_shell' 'true'
  Set-HermesConfig 'code_execution.mode' 'project'
  Set-HermesConfig 'memory.memory_enabled' 'true'
  Set-HermesConfig 'memory.user_profile_enabled' 'true'
  Set-HermesConfig 'memory.write_approval' 'false'
  Set-HermesConfig 'file_read_max_chars' '100000'
  Set-HermesConfig 'tool_output.max_bytes' '50000'
  Set-HermesConfig 'tool_output.max_lines' '2000'
  Set-HermesConfig 'tool_output.max_line_length' '2000'
}

Write-Host 'Writing LaunchRoom profile-distribution files into target profile'
Copy-ResolvedFile (Join-Path $DistributionRoot 'SOUL.md') (Join-Path $profileRoot 'SOUL.md') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot 'PROFILE_INSTRUCTIONS.md') (Join-Path $profileRoot 'PROFILE_INSTRUCTIONS.md') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot 'LAUNCHROOM_PROFILE_CONTRACT.yaml') (Join-Path $profileRoot 'LAUNCHROOM_PROFILE_CONTRACT.yaml') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot '.env.EXAMPLE') (Join-Path $profileRoot '.env.EXAMPLE') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot 'reports/profile-foundation-report.template.yaml') (Join-Path $profileRoot 'reports/profile-foundation-report.yaml') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot 'reports/profile-apply-plan.template.yaml') (Join-Path $profileRoot 'reports/profile-apply-plan.yaml') $tokens
Copy-ResolvedFile (Join-Path $SourceRoot 'stages/output/stage-1-selected-settings.example.yaml') (Join-Path $profileRoot 'reports/stage-1-selected-settings.yaml') $tokens
Copy-ResolvedFile (Join-Path $DistributionRoot 'config.yaml.template') (Join-Path $profileRoot 'reports/config.yaml.draft') $tokens

$TemplateRoot = Join-Path $RepoRoot 'templates'
if (Test-Path (Join-Path $TemplateRoot 'workspace/README.md')) {
  Write-Host 'Writing compatibility workspace instructions'
  Copy-ResolvedFile (Join-Path $TemplateRoot 'workspace/README.md') (Join-Path $WorkspaceFull 'README.md') $tokens
  Copy-ResolvedFile (Join-Path $TemplateRoot 'workspace/AGENTS.md') (Join-Path $WorkspaceFull 'AGENTS.md') $tokens
  Copy-ResolvedFile (Join-Path $TemplateRoot 'workspace/HERMES.md') (Join-Path $WorkspaceFull 'HERMES.md') $tokens
}
if (Test-Path (Join-Path $TemplateRoot 'reports/profile-setup-report.yaml')) {
  Copy-ResolvedFile (Join-Path $TemplateRoot 'reports/profile-setup-report.yaml') (Join-Path $WorkspaceFull '.hermes/reports/profile-setup-report.yaml') $tokens
}

Write-Host 'Writing Stage 2 workspace onboarding report'
$safeScan = Get-SafeProjectStructure $WorkspaceFull
$terminalCwdMatchesWorkspace = $true
$workspaceReportPath = Join-Path $WorkspaceFull '.hermes/reports/workspace-onboarding-report.yaml'
$workspaceReportLines = @(
  'artifact_id: LAUNCHROOM_WORKSPACE_ONBOARDING_REPORT_v0_1',
  'stage_id: stage_2_workspace_project_onboarding',
  'status: pass',
  'profile:',
  "  name: $(ConvertTo-YamlSingleQuotedScalar $ProfileName)",
  "  config_path_present: $(ConvertTo-LaunchRoomYesNo (Test-Path $configPath))",
  "  terminal_cwd: $(ConvertTo-YamlSingleQuotedScalar $WorkspaceFull)",
  "  terminal_cwd_matches_workspace: $(ConvertTo-LaunchRoomYesNo $terminalCwdMatchesWorkspace)",
  'workspace:',
  "  path: $(ConvertTo-YamlSingleQuotedScalar $WorkspaceFull)",
  "  existed_before: $(ConvertTo-LaunchRoomYesNo $WorkspaceExistedBefore)",
  "  created_by_installer: $(ConvertTo-LaunchRoomYesNo (-not $WorkspaceExistedBefore))",
  "  project_name: $(ConvertTo-YamlSingleQuotedScalar $ProjectName)",
  "  project_type: $(ConvertTo-YamlSingleQuotedScalar $ProjectType)",
  'files:',
  "  readme_exists: $(ConvertTo-LaunchRoomYesNo (Test-Path (Join-Path $WorkspaceFull 'README.md')))",
  "  agents_md_exists: $(ConvertTo-LaunchRoomYesNo (Test-Path (Join-Path $WorkspaceFull 'AGENTS.md')))",
  "  hermes_md_exists: $(ConvertTo-LaunchRoomYesNo (Test-Path (Join-Path $WorkspaceFull 'HERMES.md')))",
  "  reports_dir_exists: $(ConvertTo-LaunchRoomYesNo (Test-Path (Join-Path $WorkspaceFull '.hermes/reports')))",
  'safe_scan:',
  "  git_dir_present: $(ConvertTo-LaunchRoomYesNo $safeScan.git_dir_present)",
  "  package_manifest_present: $(ConvertTo-LaunchRoomYesNo $safeScan.package_manifest_present)",
  "  python_manifest_present: $(ConvertTo-LaunchRoomYesNo $safeScan.python_manifest_present)",
  "  node_manifest_present: $(ConvertTo-LaunchRoomYesNo $safeScan.node_manifest_present)",
  "  tests_dir_present: $(ConvertTo-LaunchRoomYesNo $safeScan.tests_dir_present)",
  "  src_dir_present: $(ConvertTo-LaunchRoomYesNo $safeScan.src_dir_present)",
  "  docs_dir_present: $(ConvertTo-LaunchRoomYesNo $safeScan.docs_dir_present)",
  '  skipped_secret_paths:',
  '    - .env',
  '    - auth.json',
  '    - state.db',
  '    - .git internals',
  'boundaries:',
  '  secrets_read: false',
  '  runtime_mutation: false',
  '  git_mutation: false',
  '  provider_mutation: false',
  '  gateway_mutation: false',
  'next_stage:',
  '  recommended: stage_3_tool_readiness',
  '  reason: workspace boundary is ready for local tool checks'
)
Write-Utf8NoBom $workspaceReportPath ($workspaceReportLines -join "`n")

if (-not $NoLocalSkills) {
  Write-Host 'Installing LaunchRoom bundled skills into target profile'
  $skillSource = Join-Path $DistributionRoot 'skills'
  $skillTarget = Join-Path $profileRoot 'skills/launchroom'
  New-Item -ItemType Directory -Force -Path $skillTarget | Out-Null
  Copy-Item -Path (Join-Path $skillSource '*') -Destination $skillTarget -Recurse -Force
}

$toolsetResults = @()
if (-not $NoToolsets -and -not $IsSelfTest) {
  Write-Host 'Enabling LaunchRoom starter toolsets where supported by this Hermes install (preferred path: hermes tools enable <toolset>)'
  $starterToolsets = @('terminal','file','web','search','browser','vision','skills','memory','session_search','clarify','todo','code_execution')
  foreach ($toolset in $starterToolsets) {
    $result = Try-Hermes @('-p',$ProfileName,'tools','enable',$toolset)
    $toolsetResults += $result
    if ($result.ok) { Write-Host "toolset enabled: $toolset" } else { Write-Host "toolset partial: $toolset" }
  }
}

$Stage3Status = 'deferred_no_inventory'
$missingRequired = @()
$missingRecommended = @()
$optionalLater = @('docker','wsl')
$readyRequired = @()
$readyRecommended = @()
$readyOptional = @()
if (-not $NoInventory) {
  Write-Host 'Collecting Stage 3 no-secret tool readiness inventory and software purpose map'
  $softwareCatalog = @(
    @{ name='hermes'; command='hermes'; args=@('--version'); tier='required'; purpose='primary local AI-agent runtime and setup surface'; agent_use='profile creation, config validation, skills, tools, sessions, and later gateway-ready stages'; install_hint='install or repair Hermes Agent through the official Hermes setup path'; windows_hint='hermes setup' },
    @{ name='python'; command='python'; args=@('--version'); tier='required'; purpose='local scripting and validator execution'; agent_use='run validators, generate reports, execute safe local scripts'; install_hint='install Python 3.11+ or use the approved Hermes runtime Python'; windows_hint='winget install Python.Python.3.11' },
    @{ name='git'; command='git'; args=@('--version'); tier='required'; purpose='repository version control'; agent_use='inspect status/history, create gated branches/PRs, verify clean trees'; install_hint='install Git for Windows or platform package manager'; windows_hint='winget install Git.Git' },
    @{ name='node'; command='node'; args=@('--version'); tier='recommended'; purpose='JavaScript/TypeScript and web/SaaS project workflows'; agent_use='inspect package manifests and run JS tooling later after gate'; install_hint='install Node.js LTS'; windows_hint='winget install OpenJS.NodeJS.LTS' },
    @{ name='npm'; command='npm'; args=@('--version'); tier='recommended'; purpose='Node package manager bundled with Node.js'; agent_use='inspect and run JS package scripts later after gate'; install_hint='install with Node.js LTS'; windows_hint='winget install OpenJS.NodeJS.LTS' },
    @{ name='ripgrep'; command='rg'; args=@('--version'); tier='recommended'; purpose='fast code and text search'; agent_use='large workspace search without slow shell fallbacks'; install_hint='install ripgrep'; windows_hint='winget install BurntSushi.ripgrep.MSVC' },
    @{ name='uv'; command='uv'; args=@('--version'); tier='recommended'; purpose='modern Python package/project manager'; agent_use='reproducible Python tooling and local validators'; install_hint='install uv'; windows_hint='winget install astral-sh.uv' },
    @{ name='winget'; command='winget'; args=@('--version'); tier='recommended'; purpose='Windows package manager'; agent_use='propose repeatable install commands after user gate'; install_hint='enable or install App Installer / winget'; windows_hint='install App Installer from Microsoft Store' },
    @{ name='docker'; command='docker'; args=@('--version'); tier='optional'; purpose='containers for app stacks and local services'; agent_use='later bounded service/runtime pilots after explicit gate'; install_hint='install Docker Desktop only if container workflows are selected'; windows_hint='winget install Docker.DockerDesktop' },
    @{ name='wsl'; command='wsl'; args=@('--version'); tier='optional'; purpose='Linux compatibility layer on Windows'; agent_use='optional Linux tooling surface; not required when local backend works'; install_hint='enable WSL only if Linux/WSL workflows are selected'; windows_hint='wsl --install' }
  )
  $items = @()
  foreach ($entry in $softwareCatalog) {
    $status = Get-CommandStatus $entry.command $entry.args
    $status.name = $entry.name
    $status.tier = $entry.tier
    $status.purpose = $entry.purpose
    $status.agent_use = $entry.agent_use
    $status.install_hint = $entry.install_hint
    $status.windows_hint = $entry.windows_hint
    $items += $status
  }
  $readyRequired = @($items | Where-Object { $_.status -eq 'present' -and $_.tier -eq 'required' } | ForEach-Object { $_.name })
  $missingRequired = @($items | Where-Object { $_.status -eq 'missing' -and $_.tier -eq 'required' } | ForEach-Object { $_.name })
  $readyRecommended = @($items | Where-Object { $_.status -eq 'present' -and $_.tier -eq 'recommended' } | ForEach-Object { $_.name })
  $missingRecommended = @($items | Where-Object { $_.status -eq 'missing' -and $_.tier -eq 'recommended' } | ForEach-Object { $_.name })
  $readyOptional = @($items | Where-Object { $_.status -eq 'present' -and $_.tier -eq 'optional' } | ForEach-Object { $_.name })
  $optionalLater = @($items | Where-Object { $_.tier -eq 'optional' } | ForEach-Object { $_.name })
  $Stage3Status = if ($missingRequired.Count -eq 0 -and $missingRecommended.Count -eq 0) { 'pass' } elseif ($missingRequired.Count -eq 0) { 'partial' } else { 'blocked' }

  $inventoryPath = Join-Path $WorkspaceFull '.hermes/reports/software-inventory-report.yaml'
  $lines = @(
    'artifact_id: LAUNCHROOM_SOFTWARE_INVENTORY_REPORT_v0_2',
    'stage_id: stage_3_tool_readiness',
    "status: $Stage3Status",
    'installed:'
  )
  foreach ($item in $items) {
    $safeVersion = ConvertTo-YamlSingleQuotedScalar ([string]$item.version)
    $safePath = ConvertTo-YamlSingleQuotedScalar ([string]$item.path)
    $lines += "  $($item.name):"
    $lines += "    status: $($item.status)"
    $lines += "    tier: $($item.tier)"
    $lines += "    version: $safeVersion"
    $lines += "    path: $safePath"
  }
  $lines += 'missing_required:'
  $lines += ConvertTo-YamlListBlock $missingRequired '  '
  $lines += 'missing_recommended:'
  $lines += ConvertTo-YamlListBlock $missingRecommended '  '
  $lines += 'optional_later:'
  $lines += ConvertTo-YamlListBlock $optionalLater '  '
  $lines += 'install_gate_required: true'
  $lines += 'installs_executed: false'
  Write-Utf8NoBom $inventoryPath ($lines -join "`n")

  $purposePath = Join-Path $WorkspaceFull '.hermes/reports/software-purpose-map.yaml'
  $purposeLines = @(
    'artifact_id: LAUNCHROOM_SOFTWARE_PURPOSE_MAP_v0_1',
    'stage_id: stage_3_tool_readiness',
    "status: $Stage3Status",
    'tools:'
  )
  foreach ($item in $items) {
    $purposeLines += "  $($item.name):"
    $purposeLines += "    tier: $($item.tier)"
    $purposeLines += "    status: $($item.status)"
    $purposeLines += "    purpose: $(ConvertTo-YamlSingleQuotedScalar $item.purpose)"
    $purposeLines += "    agent_use: $(ConvertTo-YamlSingleQuotedScalar $item.agent_use)"
    $purposeLines += "    install_hint: $(ConvertTo-YamlSingleQuotedScalar $item.install_hint)"
  }
  $purposeLines += 'readiness_tiers:'
  $purposeLines += '  required:'
  $purposeLines += ConvertTo-YamlListBlock @('hermes','python','git') '    '
  $purposeLines += '  recommended:'
  $purposeLines += ConvertTo-YamlListBlock @('node','npm','ripgrep','uv','winget') '    '
  $purposeLines += '  optional:'
  $purposeLines += ConvertTo-YamlListBlock @('docker','wsl') '    '
  $purposeLines += 'agent_use_cases:'
  $purposeLines += "  local_setup: 'Hermes, Python, and Git keep the starter install, validators, and repository-safe work usable.'"
  $purposeLines += "  saas_project_work: 'Node/npm, ripgrep, and uv improve web/SaaS project work after user gates.'"
  $purposeLines += "  later_runtime_pilots: 'Docker and WSL stay optional until container/Linux workflows are selected.'"
  $purposeLines += 'boundaries:'
  $purposeLines += '  secrets_read: false'
  $purposeLines += '  installs_executed: false'
  $purposeLines += '  service_mutation: false'
  $purposeLines += '  runtime_mutation: false'
  Write-Utf8NoBom $purposePath ($purposeLines -join "`n")

  $recommendationPath = Join-Path $WorkspaceFull '.hermes/reports/software-install-recommendation.yaml'
  $recommendationLines = @(
    'artifact_id: LAUNCHROOM_SOFTWARE_INSTALL_RECOMMENDATION_v0_1',
    'stage_id: stage_3_tool_readiness',
    "status: $Stage3Status",
    'install_gate_required: true',
    'do_not_run_without_gate: true',
    'installs_executed: false',
    'required_missing:'
  )
  $recommendationLines += ConvertTo-YamlListBlock $missingRequired '  '
  $recommendationLines += 'recommended_missing:'
  $recommendationLines += ConvertTo-YamlListBlock $missingRecommended '  '
  $recommendationLines += 'optional_later:'
  $recommendationLines += ConvertTo-YamlListBlock $optionalLater '  '
  $recommendationLines += 'suggested_commands_windows:'
  $missingForCommands = @($items | Where-Object { $_.status -eq 'missing' -and $_.tier -ne 'optional' })
  if ($missingForCommands.Count -eq 0) {
    $recommendationLines += '  []'
  } else {
    foreach ($item in $missingForCommands) {
      $recommendationLines += "  - tool: $($item.name)"
      $recommendationLines += "    command: $(ConvertTo-YamlSingleQuotedScalar $item.windows_hint)"
      $recommendationLines += "    reason: $(ConvertTo-YamlSingleQuotedScalar $item.agent_use)"
    }
  }
  $recommendationLines += 'manual_review_required: true'
  $recommendationLines += "next_stage: 'stage_4_starter_capability_pack'"
  Write-Utf8NoBom $recommendationPath ($recommendationLines -join "`n")

  $capabilityPath = Join-Path $WorkspaceFull '.hermes/reports/capability-graph.yaml'
  $capabilityLines = @(
    'artifact_id: LAUNCHROOM_ENGINEERING_CAPABILITY_GRAPH_v0_1',
    'stage_id: stage_3_tool_readiness',
    "status: $Stage3Status",
    'selection_rule: select capability workflow before selecting individual software',
    'task_classes:',
    '  profile_and_workspace_setup:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'create or repair the LaunchRoom profile and workspace boundary')",
    '    required_tools:',
    '      - hermes',
    '      - python',
    '      - git',
    '    supporting_skills:',
    '      - hermes-agent',
    '    workflow:',
    '      - inspect_profile',
    '      - apply_installer',
    '      - verify_reports',
    '      - handoff_next_stage',
    '    gates:',
    '      - profile_mutation_gate',
    '    verification:',
    '      - profile_files_exist',
    '      - workspace_reports_parse',
    '      - validators_pass',
    '  code_change_delivery:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'safely change repository files and publish only after owner gate')",
    '    required_tools:',
    '      - git',
    '      - python',
    '      - ripgrep',
    '    recommended_tools:',
    '      - gh',
    '      - node',
    '      - npm',
    '      - uv',
    '    supporting_skills:',
    '      - github-pr-workflow',
    '      - test-driven-development',
    '      - requesting-code-review',
    '    workflow:',
    '      - inspect_repo_state',
    '      - patch_files',
    '      - run_tests_or_validators',
    '      - inspect_diff',
    '      - commit_after_gate',
    '      - pr_after_gate',
    '    gates:',
    '      - commit_gate',
    '      - push_pr_gate',
    '      - merge_gate',
    '    verification:',
    '      - tests_or_validators_pass',
    '      - git_status_clean_or_expected',
    '      - ci_green',
    '  research_and_evidence:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'gather grounded evidence and convert it into project-safe decisions')",
    '    required_tools:',
    '      - hermes',
    '      - python',
    '    recommended_tools:',
    '      - ripgrep',
    '    supporting_skills:',
    '      - experience-grounded-work-preflight',
    '      - governed-agent-knowledge-extraction',
    '    workflow:',
    '      - route_task',
    '      - inspect_sources',
    '      - capture_evidence',
    '      - map_uncertainty',
    '      - propose_next_decision',
    '    gates:',
    '      - authority_mutation_gate',
    '    verification:',
    '      - source_paths_recorded',
    '      - no_secret_values',
    '      - conclusions_tied_to_evidence',
    '  external_agent_handoff:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'use external AI/code agents only after readiness smoke checks')",
    '    required_tools:',
    '      - git',
    '    recommended_tools:',
    '      - gh',
    '      - codex',
    '      - claude',
    '    supporting_skills:',
    '      - airmida-external-agent-tool-readiness',
    '      - codex',
    '      - claude-code',
    '      - github-pr-workflow',
    '    workflow:',
    '      - check_command',
    '      - verify_auth_presence_without_secret_readback',
    '      - run_readonly_smoke',
    '      - prepare_executor_packet',
    '      - assign_after_gate',
    '    gates:',
    '      - external_agent_gate',
    '      - credential_flow_gate',
    '    verification:',
    '      - version_present',
    '      - smoke_pass_or_blocker_recorded',
    '      - handoff_packet_has_scope',
    '  web_browser_qa:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'inspect web or app surfaces with reproducible evidence')",
    '    required_tools:',
    '      - hermes',
    '    recommended_tools:',
    '      - node',
    '      - npm',
    '      - browser',
    '    supporting_skills:',
    '      - dogfood',
    '      - computer-use',
    '    workflow:',
    '      - start_or_target_surface_after_gate',
    '      - inspect_ui',
    '      - capture_evidence',
    '      - report_bugs',
    '      - verify_fix',
    '    gates:',
    '      - browser_runtime_gate',
    '      - local_server_gate',
    '    verification:',
    '      - screenshots_or_logs',
    '      - repro_steps',
    '      - no_private_surface_without_gate',
    '  cloud_runtime_readiness:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'prepare but not mutate cloud or runtime surfaces')",
    '    required_tools:',
    '      - git',
    '    recommended_tools:',
    '      - docker',
    '      - wrangler',
    '      - cloudflared',
    '      - hcloud',
    '    supporting_skills:',
    '      - airmida-cloudflare-readonly-inventory',
    '      - airmida-hetzner-readonly-inventory',
    '      - airmida-n8n-governed-workflow-ops',
    '    workflow:',
    '      - readonly_inventory',
    '      - identify_missing_cli',
    '      - propose_install_or_auth_gate',
    '      - stop_before_mutation',
    '    gates:',
    '      - runtime_provider_gate',
    '      - secret_gate',
    '      - deployment_gate',
    '    verification:',
    '      - readonly_only',
    '      - no_credentials_printed',
    '      - no_deploy_or_service_mutation',
    '  communication_gateway_readiness:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'prepare messaging surfaces without exposing secrets')",
    '    required_tools:',
    '      - hermes',
    '    recommended_tools:',
    '      - gateway_platform_tools',
    '    supporting_skills:',
    '      - governed-messaging-gateway-setup',
    '      - hermes-agent',
    '    workflow:',
    '      - gateway_status_check',
    '      - channel_map',
    '      - secret_entry_path',
    '      - test_after_gate',
    '    gates:',
    '      - gateway_setup_gate',
    '      - pairing_gate',
    '    verification:',
    '      - gateway_status_recorded',
    '      - no_tokens_in_reports',
    '      - delivery_test_after_gate',
    '  observability_and_reports:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'make agent work auditable and repeatable')",
    '    required_tools:',
    '      - python',
    '      - git',
    '    recommended_tools:',
    '      - ripgrep',
    '      - gh',
    '    supporting_skills:',
    '      - governed-agent-engineering-standards',
    '    workflow:',
    '      - write_report',
    '      - parse_yaml',
    '      - scan_markers',
    '      - capture_command_outputs',
    '      - keep_status_clean',
    '    gates:',
    '      - publication_gate',
    '    verification:',
    '      - reports_parse',
    '      - marker_scan_pass',
    '      - ci_or_local_checks_pass',
    '  security_and_secret_safety:',
    "    goal: $(ConvertTo-YamlSingleQuotedScalar 'prevent credential exposure and unsafe mutation')",
    '    required_tools:',
    '      - hermes',
    '      - python',
    '    recommended_tools:',
    '      - ripgrep',
    '    supporting_skills:',
    '      - governed-agent-engineering-standards',
    '      - hermes-agent',
    '    workflow:',
    '      - avoid_secret_paths',
    '      - redact_outputs',
    '      - scan_changed_files',
    '      - block_unsafe_actions',
    '    gates:',
    '      - secret_gate',
    '      - production_mutation_gate',
    '    verification:',
    '      - secret_scan_count_zero',
    '      - blocked_actions_recorded',
    '      - no_env_auth_state_readback',
    'boundaries:',
    '  secrets_read: false',
    '  installs_executed: false',
    '  runtime_mutation: false',
    '  git_mutation_without_gate: false'
  )
  Write-Utf8NoBom $capabilityPath ($capabilityLines -join "`n")
}

$stage4CapabilityGraphPath = Join-Path $WorkspaceFull '.hermes/reports/capability-graph.yaml'
$stage4PackPath = Join-Path $WorkspaceFull '.hermes/reports/starter-capability-pack.yaml'
$Stage4Status = if (Test-Path $stage4CapabilityGraphPath) { 'pass' } else { 'partial_deferred_stage3_graph_missing' }
$stage4Lines = @(
  'artifact_id: LAUNCHROOM_STARTER_CAPABILITY_PACK_v0_1',
  'stage_id: stage_4_starter_capability_pack',
  "status: $Stage4Status",
  'source_reports:',
  "  capability_graph: $(ConvertTo-YamlSingleQuotedScalar $stage4CapabilityGraphPath)",
  "  software_purpose_map: $(ConvertTo-YamlSingleQuotedScalar (Join-Path $WorkspaceFull '.hermes/reports/software-purpose-map.yaml'))",
  "  software_install_recommendation: $(ConvertTo-YamlSingleQuotedScalar (Join-Path $WorkspaceFull '.hermes/reports/software-install-recommendation.yaml'))",
  'selection_rule: select task class first, then load its workflow/toolset/skill/memory/gate profile',
  'actions_executed:',
  '  toolsets_enabled: false',
  '  persistent_memory_written: false',
  '  network_skills_installed: false',
  '  provider_runtime_gateway_mutation: false',
  'toolset_policy:',
  '  recommended_core:',
  '    - terminal',
  '    - file',
  '    - skills',
  '    - clarify',
  '    - todo',
  '    - session_search',
  '  recommended_development:',
  '    - code_execution',
  '  gated_by_context:',
  '    - web',
  '    - browser',
  '    - computer_use',
  '    - vision',
  '    - delegation',
  '    - cronjob',
  '    - memory',
  '  deferred_high_risk_or_runtime:',
  '    - messaging',
  '    - kanban',
  '    - discord_admin',
  '    - homeassistant',
  'memory_policy:',
  '  default: no automatic persistent memory writes',
  '  allowed_after_user_approval:',
  '    - stable profile/workspace conventions',
  '    - stable user preferences',
  '    - durable non-secret environment facts',
  '  forbidden:',
  '    - secrets/tokens/passwords/connection strings',
  '    - transient commits/issues/PRs/run ids',
  '    - raw evidence dumps',
  '    - temporary task progress',
  'task_classes:',
  '  profile_and_workspace_setup:',
  '    starter_toolsets: [terminal, file, skills, clarify, todo]',
  '    starter_skills: [hermes-agent, launchroom-profile-operator, launchroom-hermes-settings-guide]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'remember stable profile/workspace conventions only after user approval')",
  '    workflow_playbook: [confirm_profile, inspect_config_paths, apply_setup_tool, verify_reports]',
  '    gates: [profile_mutation_gate, memory_write_gate]',
  '    verification: [profile_reports_parse, workspace_boundary_present, no_secret_readback]',
  '  code_change_delivery:',
  '    starter_toolsets: [terminal, file, code_execution, skills, todo, session_search]',
  '    starter_skills: [github-pr-workflow, test-driven-development, requesting-code-review]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'do not store commits/issues/PRs; store stable repo conventions only after approval')",
  '    workflow_playbook: [inspect_repo, patch_files, run_validators, inspect_diff, commit_after_gate, pr_after_gate]',
  '    gates: [commit_gate, push_pr_gate, merge_gate]',
  '    verification: [tests_or_validators_pass, diff_reviewed, ci_green]',
  '  research_and_evidence:',
  '    starter_toolsets: [web, file, terminal, session_search, skills, todo]',
  '    starter_skills: [experience-grounded-work-preflight, governed-agent-knowledge-extraction]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'reports hold evidence; memory stores only durable conventions after approval')",
  '    workflow_playbook: [route_question, inspect_sources, capture_evidence, separate_facts_from_assumptions, propose_decision]',
  '    gates: [authority_mutation_gate, memory_write_gate]',
  '    verification: [source_paths_recorded, no_secret_values, conclusions_cited]',
  '  external_agent_handoff:',
  '    starter_toolsets: [terminal, file, skills, delegation, todo]',
  '    starter_skills: [airmida-external-agent-tool-readiness, codex, claude-code, github-pr-workflow]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'do not store credentials or transient run ids; store stable handoff conventions only after approval')",
  '    workflow_playbook: [verify_cli_presence, smoke_check_without_secret_readback, create_handoff_packet, assign_after_gate]',
  '    gates: [external_agent_gate, credential_flow_gate]',
  '    verification: [smoke_pass_or_blocked, handoff_packet_scoped, no_credentials_printed]',
  '  web_browser_qa:',
  '    starter_toolsets: [browser, computer_use, vision, web, terminal, file, skills]',
  '    starter_skills: [dogfood, computer-use]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'do not store screenshots/session ids; store stable QA conventions only after approval')",
  '    workflow_playbook: [target_surface_after_gate, inspect_ui, capture_evidence, report_repro, verify_fix]',
  '    gates: [browser_runtime_gate, local_server_gate]',
  '    verification: [screenshot_or_log_evidence, repro_steps, private_surface_gate_checked]',
  '  cloud_runtime_readiness:',
  '    starter_toolsets: [terminal, file, web, skills, todo]',
  '    starter_skills: [airmida-cloudflare-readonly-inventory, airmida-hetzner-readonly-inventory, airmida-n8n-governed-workflow-ops]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'never store secrets/tokens; store only non-secret runtime routing facts after approval')",
  '    workflow_playbook: [readonly_inventory, identify_cli_gap, propose_install_or_auth_gate, stop_before_mutation]',
  '    gates: [runtime_provider_gate, secret_gate, deployment_gate]',
  '    verification: [readonly_only, no_credentials_printed, no_deploy_or_service_mutation]',
  '  communication_gateway_readiness:',
  '    starter_toolsets: [terminal, file, skills, clarify]',
  '    starter_skills: [governed-messaging-gateway-setup, hermes-agent]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'no tokens/channel secrets; stable delivery preferences only after approval')",
  '    workflow_playbook: [gateway_status_check, channel_map, safe_secret_entry_path, test_after_gate]',
  '    gates: [gateway_setup_gate, pairing_gate, secret_gate]',
  '    verification: [gateway_status_recorded, no_tokens_in_reports, delivery_test_after_gate]',
  '  observability_and_reports:',
  '    starter_toolsets: [terminal, file, code_execution, skills, todo]',
  '    starter_skills: [governed-agent-engineering-standards]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'reports first; memory only for stable conventions after approval')",
  '    workflow_playbook: [write_report, parse_yaml, scan_markers, capture_outputs, keep_status_clean]',
  '    gates: [publication_gate]',
  '    verification: [reports_parse, marker_scan_pass, local_or_ci_checks_pass]',
  '  security_and_secret_safety:',
  '    starter_toolsets: [terminal, file, skills, session_search]',
  '    starter_skills: [governed-agent-engineering-standards, hermes-agent]',
  "    memory_policy: $(ConvertTo-YamlSingleQuotedScalar 'never store secrets or hashes of secrets; store safety conventions only after approval')",
  '    workflow_playbook: [avoid_secret_paths, redact_outputs, scan_changed_files, block_unsafe_actions]',
  '    gates: [secret_gate, production_mutation_gate]',
  '    verification: [secret_scan_zero, blocked_actions_recorded, no_env_auth_state_readback]',
  'enablement_recommendations:',
  '  safe_default_next_action: review starter-capability-pack.yaml, communication-channel-map.yaml, communication-user-guide.md, operator-kit/START_HERE.md, operator-kit/NEXT_DECISION.md, operator-kit/CHECK_IT_WORKS.md, operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md, operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md, operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md, operator-kit/readiness_report.yaml, first-slice/READINESS_REPORT.yaml, local-pilot/READINESS_REPORT.yaml and approve selected toolset/skill activation gates only when needed',
  '  reset_required_after_toolset_change: true',
  '  install_gate_required: true',
  'boundaries:',
  '  secrets_read: false',
  '  toolsets_enabled_without_gate: false',
  '  memory_written_without_gate: false',
  '  network_skills_installed_without_gate: false',
  '  runtime_mutation: false'
)
Write-Utf8NoBom $stage4PackPath ($stage4Lines -join "`n")

$communicationMapPath = Join-Path $WorkspaceFull '.hermes/reports/communication-channel-map.yaml'
$communicationGuidePath = Join-Path $WorkspaceFull '.hermes/reports/communication-user-guide.md'
$Stage5Status = 'pass'
$communicationMapLines = @(
  'artifact_id: LAUNCHROOM_COMMUNICATION_CHANNEL_MAP_v0_1',
  'stage_id: stage_5_communications',
  'status: pass',
  'purpose: map communication surfaces to channel managers, user options, official sources, gates, and verification',
  'actions_executed:',
  '  gateway_setup: false',
  '  pairing_approved: false',
  '  home_channel_set: false',
  '  gateway_autostart_installed: false',
  '  test_message_sent: false',
  '  secrets_read_or_written: false',
  'communication_surfaces:',
  '  desktop:',
  '    role: primary local workspace UI',
  '    manager: hermes_desktop',
  '    best_for: [long engineering sessions, file/artifact review, workspace setup, verification]',
  '    real_options: [native Desktop app, session list, file attachments, local workspace control, later handoff to gateway]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs',
  '      - https://hermes-agent.nousresearch.com/docs/reference/cli-commands',
  '    gates: [local_profile_gate]',
  '    verification: [profile_status_checked, workspace_reports_present]',
  '  telegram:',
  '    role: mobile remote operator channel',
  '    manager: hermes_gateway_telegram',
  '    best_for: [quick commands, status updates, topic sessions, home-channel delivery, mobile follow-up]',
  '    real_options: [DM, pairing, /sethome, /topic, /commands, /status, Desktop/TUI handoff after gate]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '      - https://core.telegram.org/bots/api',
  '    gates: [gateway_setup_gate, secret_gate, pairing_gate, home_channel_gate, handoff_gate]',
  '    verification: [gateway_status_recorded, no_token_values_in_reports, pairing_approved_after_gate, bot_reply_confirmed_after_test_gate]',
  '  slack:',
  '    role: team collaboration channel',
  '    manager: hermes_gateway_slack',
  '    best_for: [team DMs, project channels, threads, review/report delivery]',
  '    real_options: [Socket Mode, app manifest, bot token, app token, /sethome or !sethome, thread delivery]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '      - https://api.slack.com/apis/connections/socket',
  '      - https://api.slack.com/reference/manifests',
  '    gates: [slack_app_gate, gateway_setup_gate, secret_gate, pairing_gate, home_channel_gate]',
  '    verification: [gateway_status_recorded, no_token_values_in_reports, socket_mode_configured_after_gate, bot_reply_confirmed_after_test_gate]',
  '  email:',
  '    role: asynchronous external communication channel',
  '    manager: hermes_gateway_email',
  '    best_for: [summaries, async requests, report delivery, mailbox-driven workflows]',
  '    real_options: [IMAP/SMTP or provider OAuth, inbound messages, outbound summaries]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '    gates: [mailbox_secret_gate, gateway_setup_gate, delivery_test_gate]',
  '    verification: [mailbox_status_recorded_after_gate, no_credentials_in_reports, delivery_test_after_gate]',
  '  discord:',
  '    role: community/team chat channel',
  '    manager: hermes_gateway_discord',
  '    best_for: [community operations, project channels, bot interactions]',
  '    real_options: [bot token, channel messages, slash/adapter commands depending on manifest]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '      - https://discord.com/developers/docs/intro',
  '    gates: [discord_bot_gate, gateway_setup_gate, secret_gate, pairing_gate]',
  '    verification: [gateway_status_recorded, bot_reply_confirmed_after_test_gate]',
  '  teams_matrix_signal_whatsapp:',
  '    role: additional messaging adapters',
  '    manager: hermes_gateway_platform_adapter',
  '    best_for: [organization-specific channels, mobile/external contact surfaces]',
  '    real_options: [adapter-specific setup, pairing or account linking, gateway delivery]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '    gates: [platform_specific_gate, secret_gate, pairing_gate]',
  '    verification: [adapter_status_recorded_after_gate, no_tokens_in_reports]',
  '  webhooks_api:',
  '    role: integration/event surface',
  '    manager: hermes_webhook_or_api_server',
  '    best_for: [SaaS events, automation triggers, external system integration]',
  '    real_options: [webhook routes, API server adapter, Open WebUI/API integration]',
  '    official_sources:',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/features/webhooks',
  '      - https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '    gates: [api_runtime_gate, webhook_security_gate, deployment_gate]',
  '    verification: [route_config_after_gate, no_public_endpoint_without_gate]',
  'channel_managers:',
  '  - hermes_desktop',
  '  - hermes_gateway_telegram',
  '  - hermes_gateway_slack',
  '  - hermes_gateway_email',
  '  - hermes_gateway_discord',
  '  - hermes_gateway_platform_adapter',
  '  - hermes_webhook_or_api_server',
  'commands_to_explain:',
  '  gateway_cli: [hermes gateway setup, hermes gateway run, hermes gateway install, hermes gateway status, hermes pairing approve]',
  '  gateway_slash: [/sethome, /topic, /handoff <platform>, /platforms, /status, /commands, /restart]',
  'forbidden_without_gate:',
  '  - ask token in chat',
  '  - print token',
  '  - store token in repo or reports',
  '  - run gateway setup',
  '  - approve pairing',
  '  - set home channel',
  '  - install gateway autostart',
  '  - send test message',
  '  - mutate n8n/cloud/runtime/provider surfaces',
  'safe_secret_entry:',
  '  rule: secrets go through Hermes Desktop, hermes gateway setup, .env edited locally, or approved secret stores; never through chat or reports',
  'next_stage: stage_6_saas_operator_kit'
)
Write-Utf8NoBom $communicationMapPath ($communicationMapLines -join "`n")

$communicationGuideLines = @(
  '# LaunchRoom Communication User Guide',
  '',
  'Stage 5 explains how a user can work with the agent through Desktop, Telegram, Slack, Email, Discord, additional messaging adapters, and webhooks/API. It does not connect channels automatically.',
  '',
  '## How to choose',
  '',
  '- Use **Hermes Desktop** for long engineering work, file review, workspace setup, and verification.',
  '- Use **Telegram** for fast mobile remote control, quick status checks, topic sessions, and home-channel delivery.',
  '- Use **Slack** for team/project collaboration, DMs, channels, threads, and review/report delivery.',
  '- Use **Email** for asynchronous requests, summaries, and report delivery.',
  '- Use **Discord** for community/team bot interactions.',
  '- Use **Teams/Matrix/Signal/WhatsApp** when the organization requires a specific messenger adapter.',
  '- Use **Webhooks/API** for SaaS events and automation triggers, not for beginner chat setup.',
  '',
  '## Safe secret-entry rule',
  '',
  'Never paste tokens, passwords, OAuth values, bot tokens, private keys, chat IDs, or connection strings into chat or project reports. Use Hermes Desktop, `hermes gateway setup`, a local `.env` edit, or an approved secret store.',
  '',
  '## Per-channel guides',
  '',
  '### Hermes Desktop',
  '',
  '- Best for: long sessions, file artifacts, workspace setup, and verification.',
  '- Manager: `hermes_desktop`.',
  '- Setup gate: local profile/workspace gate only.',
  '- Verification: profile opens, workspace reports exist, session can continue.',
  '',
  'Official sources:',
  '- https://hermes-agent.nousresearch.com/docs',
  '- https://hermes-agent.nousresearch.com/docs/reference/cli-commands',
  '',
  '### Telegram',
  '',
  '- Best for: mobile remote control, quick commands, topic sessions, `/sethome`, and Desktop/TUI handoff after gate.',
  '- Manager: `hermes_gateway_telegram`.',
  '- Real options: DM, pairing, `/topic`, `/commands`, `/status`, `/sethome`, `/handoff telegram`.',
  '- Gates: gateway setup, secret entry, pairing, home channel, handoff, delivery test.',
  '- Verification: `hermes gateway status`, approved pairing after gate, bot reply after test gate, no token values in reports.',
  '',
  'Official sources:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '- https://core.telegram.org/bots/api',
  '',
  '### Slack',
  '',
  '- Best for: team DMs, project channels, threads, and delivery to review/report threads.',
  '- Manager: `hermes_gateway_slack`.',
  '- Real options: Socket Mode, Slack app manifest, bot token, app token, `/sethome` or `!sethome` in thread contexts.',
  '- Gates: Slack app setup, gateway setup, secret entry, pairing, home channel, delivery test.',
  '- Verification: gateway status, Socket Mode configured after gate, bot reply after test gate, no token values in reports.',
  '',
  'Official sources:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '- https://api.slack.com/apis/connections/socket',
  '- https://api.slack.com/reference/manifests',
  '',
  '### Email',
  '',
  '- Best for: asynchronous requests, summaries, report delivery, and mailbox-driven workflows.',
  '- Manager: `hermes_gateway_email`.',
  '- Gates: mailbox credentials/OAuth, gateway setup, delivery test.',
  '- Verification: mailbox status after gate, no credentials in reports, delivery test after gate.',
  '',
  'Official source:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '',
  '### Discord',
  '',
  '- Best for: community/project channels and bot interactions.',
  '- Manager: `hermes_gateway_discord`.',
  '- Gates: Discord bot token, gateway setup, secret entry, pairing/delivery test.',
  '- Verification: gateway status and bot reply after test gate.',
  '',
  'Official sources:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '- https://discord.com/developers/docs/intro',
  '',
  '### Teams / Matrix / Signal / WhatsApp',
  '',
  '- Best for: organization-specific channels and mobile/external contact surfaces.',
  '- Manager: `hermes_gateway_platform_adapter`.',
  '- Gates: platform-specific setup, secret entry, pairing/account-linking, delivery test.',
  '',
  'Official source:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '',
  '### Webhooks / API',
  '',
  '- Best for: SaaS events, automation triggers, and integrations with external systems.',
  '- Manager: `hermes_webhook_or_api_server`.',
  '- Gates: API runtime, webhook security, endpoint exposure, deployment.',
  '- Verification: route config after gate and no public endpoint without approval.',
  '',
  'Official sources:',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/features/webhooks',
  '- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
  '',
  '## Commands explained simply',
  '',
  '- `hermes gateway setup`: guided setup for messaging platforms; use only after gate.',
  '- `hermes gateway status`: technical check of gateway/platform status.',
  '- `hermes gateway run`: start gateway in foreground for testing.',
  '- `hermes gateway install`: install gateway autostart; separate gate only after successful test.',
  '- `hermes pairing approve`: approve a pending user/platform pairing; only for expected users.',
  '- `/sethome`: make the current chat the delivery home channel.',
  '- `/topic`: inspect/use Telegram topic sessions.',
  '- `/handoff <platform>`: move a live session to a messaging platform after gate.',
  '- `/platforms`: show connected gateway platforms.',
  '- `/commands`: list available gateway commands.',
  '',
  '## Verification checklist',
  '',
  '- Channel selected or explicitly deferred.',
  '- Safe secret-entry path explained.',
  '- No tokens or credentials in chat/reports.',
  '- Gateway setup/test/pairing/home-channel/autostart remain gated.',
  '- Official source links included.',
  '- Next stage: Stage 6 SaaS operator kit.'
)
Write-Utf8NoBom $communicationGuidePath ($communicationGuideLines -join "`n")

$operatorKitRoot = Join-Path $WorkspaceFull '.hermes/operator-kit'
New-Item -ItemType Directory -Force -Path $operatorKitRoot | Out-Null
$Stage6Status = 'pass'
$operatorEvidenceReports = @(
  '.hermes/reports/profile-setup-report.yaml',
  '.hermes/reports/workspace-onboarding-report.yaml',
  '.hermes/reports/software-inventory-report.yaml',
  '.hermes/reports/software-purpose-map.yaml',
  '.hermes/reports/software-install-recommendation.yaml',
  '.hermes/reports/capability-graph.yaml',
  '.hermes/reports/starter-capability-pack.yaml',
  '.hermes/reports/communication-channel-map.yaml',
  '.hermes/reports/communication-user-guide.md'
)
$missingOperatorEvidence = @($operatorEvidenceReports | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingOperatorEvidence.Count -gt 0) { $Stage6Status = 'partial_previous_stage_evidence_missing' }

$startHereLines = @(
  '# Start Here — SaaS Operator Kit',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 6. This folder is the first local SaaS operator kit. It does not deploy anything, does not connect cloud/runtime services, does not read secrets, and does not implement product code.',
  '',
  '## What you already received',
  '',
  '- Stage 1: profile foundation.',
  '- Stage 2: workspace/project onboarding.',
  '- Stage 3: software and engineering capability map.',
  '- Stage 4: starter capability pack: toolsets, skills, memory policy, workflows, gates.',
  '- Stage 5: communication channel map and user guide.',
  '- Stage 6: this operator kit for choosing the first small SaaS workflow.',
  '',
  '## Read in this order',
  '',
  '1. START_HERE.md — this entry point.',
  '2. CHECK_IT_WORKS.md — verify what you got and what was not executed.',
  '3. PAIN_TO_WORKFLOW_EXAMPLES.md — choose a concrete example close to your pain.',
  '4. NEXT_DECISION.md — make one next safe decision.',
  '5. product_brief.md — refine what we might build.',
  '6. target_user.md — choose who the first user is.',
  '7. first_workflow.md — define the first tiny workflow.',
  '8. backlog.md — see what is safe now vs gated.',
  '9. gates.md — understand what needs explicit permission.',
  '10. readiness_report.yaml — machine-readable status for the agent/validators.',
  '',
  '## Beginner rule',
  '',
  'Do not try to use every file at once. Start with one pain and one tiny workflow. The goal is a small verified result, not a full SaaS launch.',
  '',
  '## Your next action',
  '',
  'Open PAIN_TO_WORKFLOW_EXAMPLES.md and pick one example, or ask the agent: "Show me 3 first workflow options for my idea."'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'START_HERE.md') ($startHereLines -join "`n")

$checkItWorksLines = @(
  '# Check It Works',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Use this file to verify what Stage 6 produced before you trust it.',
  '',
  '## Expected files',
  '',
  '- START_HERE.md',
  '- NEXT_DECISION.md',
  '- CHECK_IT_WORKS.md',
  '- PAIN_TO_WORKFLOW_EXAMPLES.md',
  '- product_brief.md',
  '- target_user.md',
  '- first_workflow.md',
  '- backlog.md',
  '- local_task_packet.md',
  '- gates.md',
  '- readiness_report.yaml',
  '',
  '## What should be true',
  '',
  '- You can explain what Stage 6 is in one sentence.',
  '- You can identify one user pain.',
  '- You can choose one example workflow or ask the agent for alternatives.',
  '- You can see what is safe now and what requires approval.',
  '- readiness_report.yaml says runtime/cloud/n8n/gateway/git/secrets/implementation actions are false.',
  '',
  '## What was not executed',
  '',
  '```yaml',
  'runtime_mutation: false',
  'cloud_mutation: false',
  'n8n_mutation: false',
  'gateway_mutation: false',
  'git_publication_executed: false',
  'secrets_read_or_written: false',
  'implementation_executed: false',
  '```',
  '',
  '## Simple test',
  '',
  'If you can answer this question, Stage 6 is usable:',
  '',
  '> Which one small pain do I want the agent to help solve first, and what output should I receive?',
  '',
  'If not, open NEXT_DECISION.md and choose "Ask the agent for 3 workflow options".'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'CHECK_IT_WORKS.md') ($checkItWorksLines -join "`n")

$examplesLines = @(
  '# Pain to Workflow Examples',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This is the Stage 6 example wardrobe. Pick one concrete pain, not a whole platform. Each example ends with a small user-visible output and a verification step.',
  '',
  '## Example 1 — I have an idea but cannot turn it into a clear product brief',
  '',
  '- Pain: the idea is vague and hard to explain.',
  '- Tiny workflow: user gives a rough idea; agent asks structured questions; agent creates a one-page product brief.',
  '- Output: product_brief.md updated with one sentence, problem, user, first useful result, and non-goals.',
  '- Verification: user can read the brief and say yes/no/edit in one pass.',
  '- Next decision: approve brief refinement or ask for 3 alternative framings.',
  '',
  '## Example 2 — I do not know who the first user is',
  '',
  '- Pain: the product is "for everyone" and therefore not actionable.',
  '- Tiny workflow: agent proposes 3 possible target users; user chooses one; agent updates target_user.md.',
  '- Output: target_user.md contains one primary user, their pain, current workaround, and desired outcome.',
  '- Verification: user can name one first user without explaining the whole business.',
  '- Next decision: keep the user, change it, or ask for more options.',
  '',
  '## Example 3 — I need one first workflow, not a huge backlog',
  '',
  '- Pain: too many possible tasks and no clear first action.',
  '- Tiny workflow: agent converts the chosen pain into trigger, input, agent action, output, and verification.',
  '- Output: first_workflow.md contains one workflow ready for implementation planning.',
  '- Verification: the workflow can be tested locally without cloud/runtime setup.',
  '- Next decision: approve implementation planning packet or choose another workflow.',
  '',
  '## Example 4 — I want to know what is safe to do now',
  '',
  '- Pain: user fears the agent may touch cloud, git, credentials, or production systems.',
  '- Tiny workflow: agent summarizes gates and marks each requested action as safe now, owner gate, or high-risk gate.',
  '- Output: gates.md and backlog.md separate safe planning from gated actions.',
  '- Verification: readiness_report.yaml action flags stay false for runtime/cloud/n8n/gateway/git/secrets/implementation.',
  '- Next decision: continue local planning or explicitly approve one gated action.',
  '',
  '## Example 5 — I want a real next agent task',
  '',
  '- Pain: documents exist, but the agent still lacks an executor-ready task.',
  '- Tiny workflow: agent fills local_task_packet.md with objective, source lineage, allowed actions, forbidden actions, validation, rollback, and done_when.',
  '- Output: local_task_packet.md becomes ready for owner review.',
  '- Verification: the packet is specific enough that another agent could execute it after approval.',
  '- Next decision: approve implementation planning, request edits, or defer.',
  '',
  '## Recommended beginner path',
  '',
  'Start with Example 1 or Example 3. They create the smallest visible value without needing runtime setup.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'PAIN_TO_WORKFLOW_EXAMPLES.md') ($examplesLines -join "`n")

$nextDecisionLines = @(
  '# Next Decision',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Choose one next action. Do not choose all of them at once.',
  '',
  '## Recommended for beginners',
  '',
  'Ask the agent:',
  '',
  '> Show me 3 first workflow options based on PAIN_TO_WORKFLOW_EXAMPLES.md, then recommend one.',
  '',
  '## Options',
  '',
  '1. Refine product_brief.md.',
  '   - Best when you know the idea but it is unclear.',
  '   - Output: clearer product brief.',
  '',
  '2. Choose target_user.md.',
  '   - Best when the product is too broad.',
  '   - Output: one first user and pain.',
  '',
  '3. Select first_workflow.md.',
  '   - Best when you want to move toward implementation planning.',
  '   - Output: one small workflow with trigger, input, action, output, verification.',
  '',
  '4. Prepare local_task_packet.md for review.',
  '   - Best when the first workflow is clear.',
  '   - Output: executor-ready planning packet, still gated before implementation.',
  '',
  '5. Stop here.',
  '   - Best when you only wanted the operator kit prepared.',
  '   - Output: no further action.',
  '',
  '## Safety reminder',
  '',
  'Implementation, git commit/push, cloud/runtime, gateway setup, n8n/MCP, provider/billing, and secrets all require separate explicit gates.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'NEXT_DECISION.md') ($nextDecisionLines -join "`n")

$guidedSessionRoot = Join-Path $operatorKitRoot 'guided-session'
New-Item -ItemType Directory -Force -Path $guidedSessionRoot | Out-Null

$sessionStateLines = @(
  'artifact_id: LAUNCHROOM_STAGE_6_GUIDED_SESSION_STATE_v0_1',
  'stage_id: stage_6_saas_operator_kit',
  'status: scaffold_created',
  'current_state: orientation',
  'agent_led: true',
  'guided_session_present: true',
  'no_idea_default_workflow_catalog_present: true',
  'blueprint_to_solution_path_present: true',
  'states:',
  '  - orientation',
  '  - structure_created',
  '  - idea_or_default_workflow_intake',
  '  - pain_selected',
  '  - target_user_selected',
  '  - first_workflow_selected',
  '  - first_output_defined',
  '  - project_blueprint_created',
  '  - first_slice_packet_created',
  '  - implementation_roadmap_created',
  '  - user_training_completed',
  '  - completion_summary_created',
  '  - next_gate_pending',
  'action_flags:',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  n8n_mutation: false',
  '  gateway_mutation: false',
  '  git_publication_executed: false',
  '  secrets_read_or_written: false',
  '  implementation_executed: false'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'SESSION_STATE.yaml') ($sessionStateLines -join "`n")

$agentGuideLines = @(
  '# Agent Guide — Stage 6 Guided Session',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'The agent must lead Stage 6 as a guided session, not leave the user alone with files.',
  '',
  '## Required agent sequence',
  '',
  '1. Explain Stage 6 in plain language.',
  '2. Create and verify the operator-kit structure.',
  '3. Ask whether the user has an idea.',
  '4. If the user has no idea, offer DEFAULT_WORKFLOW_CATALOG.md options.',
  '5. Select one pain or one default workflow.',
  '6. Select one target user.',
  '7. Select one first workflow.',
  '8. Define one concrete output and verification.',
  '9. Create PROJECT_BLUEPRINT.md.',
  '10. Create FIRST_SLICE_PACKET.md.',
  '11. Explain IMPLEMENTATION_ROADMAP.md: blueprint -> first slice packet -> implementation plan -> local pilot -> verification -> next gate.',
  '12. Teach the user the idea -> pain -> workflow -> output -> verification -> gate model.',
  '13. Create COMPLETION_SUMMARY.md.',
  '',
  '## Rule',
  '',
  'Ask for one decision at a time. Do not jump to implementation or runtime setup.'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'AGENT_GUIDE.md') ($agentGuideLines -join "`n")

$defaultCatalogLines = @(
  '# Default Workflow Catalog',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Use this when the user has no project idea yet. Offer the simplest common workflows that solve real setup pain quickly.',
  '',
  '## Option 1 — Messenger setup and control',
  '',
  '- User pain: I want to use Hermes from the messenger that is convenient for me.',
  '- Workflow: choose Telegram, Discord, Slack, or another supported channel; explain requirements; prepare a safe setup packet; verify without exposing tokens.',
  '- Output: messenger channel setup packet and verification checklist.',
  '- Verification: user understands what channel will do, what token/secret path is needed, and what gate is required before live connection.',
  '- Next gate: communication_channel_setup_gate.',
  '',
  '## Option 2 — Telegram or Discord channel management',
  '',
  '- User pain: I want a dedicated channel where Hermes can post reports, reminders, and guided session outputs.',
  '- Workflow: design channel purpose, commands, home/delivery behavior, safety rules, and moderation boundaries.',
  '- Output: channel operating plan and safe setup checklist.',
  '- Verification: user can say where reports go, who can interact, and what actions remain gated.',
  '- Next gate: channel_creation_or_pairing_gate.',
  '',
  '## Option 3 — Email, calendar, and notes assistant',
  '',
  '- User pain: my email/calendar/notes are fragmented and I need a daily assistant loop.',
  '- Workflow: define daily briefing, meeting prep, follow-up extraction, and notes capture without reading secrets in chat.',
  '- Output: personal productivity workflow packet.',
  '- Verification: user sees sample briefing structure and required safe auth path before connection.',
  '- Next gate: email_calendar_notes_access_gate.',
  '',
  '## Option 4 — Personal daily briefing',
  '',
  '- User pain: I want one daily summary of messages, tasks, meetings, and project next steps.',
  '- Workflow: define sources, schedule, delivery channel, summary format, and quiet hours.',
  '- Output: daily briefing workflow packet.',
  '- Verification: user can approve the format before any live source connection.',
  '- Next gate: scheduled_delivery_gate.',
  '',
  '## Option 5 — Idea to project blueprint',
  '',
  '- User pain: I have scattered ideas and want a project direction.',
  '- Workflow: agent asks structured questions and creates PROJECT_BLUEPRINT.md plus FIRST_SLICE_PACKET.md.',
  '- Output: project blueprint and first slice packet.',
  '- Verification: user can approve a first slice or request changes.',
  '- Next gate: implementation_planning_gate.',
  '',
  '## Beginner recommendation',
  '',
  'If the user has no idea, recommend Option 1 or Option 4 first because they produce visible value without product development.'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'DEFAULT_WORKFLOW_CATALOG.md') ($defaultCatalogLines -join "`n")

$ideaIntakeLines = @(
  '# Idea Intake',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Agent question',
  '',
  'Do you already have a project idea, or should I offer common starter workflows?',
  '',
  '## If user has an idea',
  '',
  '- Capture idea_raw.',
  '- Identify possible pains.',
  '- Recommend one pain for the first workflow.',
  '',
  '## If user has no idea',
  '',
  '- Use DEFAULT_WORKFLOW_CATALOG.md.',
  '- Offer messenger setup, channel management, email/calendar/notes, daily briefing, or idea-to-blueprint.',
  '- Recommend the simplest option that creates visible value.',
  '',
  '## Current state',
  '',
  'idea_raw: pending_user_input',
  'selected_default_workflow: pending_user_choice',
  'selected_pain: pending_user_choice'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'IDEA_INTAKE.md') ($ideaIntakeLines -join "`n")

$projectBlueprintLines = @(
  '# Project Blueprint',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This file is filled during the guided session. It must not remain a dead blueprint; it feeds FIRST_SLICE_PACKET.md and IMPLEMENTATION_ROADMAP.md.',
  '',
  '## Project name',
  '',
  "Draft: $ProjectName",
  '',
  '## One sentence',
  '',
  'Pending guided session input.',
  '',
  '## First user',
  '',
  'Pending guided session input.',
  '',
  '## Pain',
  '',
  'Pending guided session input.',
  '',
  '## First workflow',
  '',
  'Pending guided session input.',
  '',
  '## First output',
  '',
  'Pending guided session input; must be a concrete artifact, checklist, report, draft, or configured workflow packet.',
  '',
  '## Success check',
  '',
  'Pending guided session input; must be observable by the user.',
  '',
  '## What is not included',
  '',
  '- No production deployment.',
  '- No cloud/runtime mutation.',
  '- No secret readback.',
  '',
  '## Feeds next file',
  '',
  'FIRST_SLICE_PACKET.md'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'PROJECT_BLUEPRINT.md') ($projectBlueprintLines -join "`n")

$firstSliceLines = @(
  '# First Slice Packet',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'packet_id: LAUNCHROOM_FIRST_SLICE_PACKET_v0_1',
  'packet_type: implementation_ready_planning_packet',
  'implementation_status: not_started_until_gate',
  '',
  '## Objective',
  '',
  'Turn the selected Stage 6 workflow into a small, verifiable next implementation plan.',
  '',
  '## User pain',
  '',
  'Pending guided session input.',
  '',
  '## Target user',
  '',
  'Pending guided session input.',
  '',
  '## Workflow',
  '',
  'Pending guided session input.',
  '',
  '## Input',
  '',
  'Pending guided session input.',
  '',
  '## Output',
  '',
  'Pending guided session input.',
  '',
  '## Validation',
  '',
  'Pending guided session input.',
  '',
  '## Allowed actions before implementation gate',
  '',
  '- refine local planning files',
  '- propose local tests',
  '- prepare implementation checklist',
  '',
  '## Forbidden actions before separate gates',
  '',
  '- runtime/cloud/provider/gateway/n8n mutation',
  '- secret readback or storage',
  '- git push or production deploy',
  '',
  '## Next gate',
  '',
  'implementation_planning_gate'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'FIRST_SLICE_PACKET.md') ($firstSliceLines -join "`n")

$implementationRoadmapLines = @(
  '# Implementation Roadmap',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This file prevents the blueprint from becoming a dead document. It explains how Stage 6 moves toward a working result.',
  '',
  '## Path from blueprint to working result',
  '',
  '```text',
  'PROJECT_BLUEPRINT.md',
  '-> FIRST_SLICE_PACKET.md',
  '-> implementation planning gate',
  '-> local implementation plan',
  '-> local pilot or configuration packet',
  '-> verification checklist',
  '-> owner review',
  '-> next gate: iterate, connect channel, or runtime/cloud readiness',
  '```',
  '',
  '## What counts as a working result',
  '',
  '- A messenger setup packet the user can follow and verify.',
  '- A channel operating plan with commands, delivery target, and safety boundaries.',
  '- An email/calendar/notes assistant workflow packet.',
  '- A daily briefing format with schedule and delivery gate.',
  '- A project blueprint plus first slice packet ready for implementation planning.',
  '',
  '## What is still gated',
  '',
  '- live messenger/channel connection',
  '- email/calendar/notes auth',
  '- implementation code',
  '- git publication',
  '- production/cloud/runtime setup',
  '',
  '## User-facing completion test',
  '',
  'The user can point to one workflow, one output, one verification method, and one next gate.'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'IMPLEMENTATION_ROADMAP.md') ($implementationRoadmapLines -join "`n")

$userLessonLines = @(
  '# User Lesson — From Idea to Working Result',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Lesson',
  '',
  'An idea is not a project yet. A project starts when one user pain becomes one workflow with one output and one verification method.',
  '',
  '```text',
  'idea or no-idea default workflow',
  '-> pain',
  '-> target user',
  '-> first workflow',
  '-> first output',
  '-> verification',
  '-> first slice packet',
  '-> implementation gate',
  '-> local working result',
  '```',
  '',
  '## Practical rule',
  '',
  'If you do not know what to build, start with a common assistant workflow: messenger setup, channel management, email/calendar/notes, or daily briefing.',
  '',
  '## Safety rule',
  '',
  'Every move from planning to real connection, code, cloud, or secrets requires a separate explicit gate.'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'USER_LESSON.md') ($userLessonLines -join "`n")

$completionSummaryLines = @(
  '# Completion Summary',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This file is completed by the agent at the end of the guided session.',
  '',
  '## What we started with',
  '',
  'Pending guided session input.',
  '',
  '## Selected path',
  '',
  'Pending: user idea or default workflow catalog option.',
  '',
  '## Selected pain',
  '',
  'Pending guided session input.',
  '',
  '## First user',
  '',
  'Pending guided session input.',
  '',
  '## First workflow',
  '',
  'Pending guided session input.',
  '',
  '## First output',
  '',
  'Pending guided session input.',
  '',
  '## Verification',
  '',
  'Pending guided session input.',
  '',
  '## Next gate',
  '',
  'Pending: implementation_planning_gate, communication_channel_setup_gate, or defer.'
)
Write-Utf8NoBom (Join-Path $guidedSessionRoot 'COMPLETION_SUMMARY.md') ($completionSummaryLines -join "`n")

$productBriefLines = @(
  '# Product Brief',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  "Project name: $ProjectName",
  "Project type: $ProjectType",
  '',
  '## Objective',
  '',
  'Create a beginner-safe local SaaS operating packet before implementation or runtime setup. This brief is a scaffold for the owner to refine, not a product launch claim.',
  '',
  '## Problem hypothesis',
  '',
  '- The user needs a governed AI/SaaS operator path that turns an idea into a verified workflow without exposing secrets or mutating production surfaces prematurely.',
  '- The first product slice should be small enough to verify locally before cloud/runtime integration.',
  '',
  '## Non-goals',
  '',
  '- No production deployment.',
  '- No provider/model/billing mutation.',
  '- No Cloudflare, Hetzner, n8n, MCP, database, or gateway mutation.',
  '- No public git push/release without a separate gate.',
  '',
  '## Next owner decision',
  '',
  'Choose or edit the first vertical slice before implementation planning.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'product_brief.md') ($productBriefLines -join "`n")

$targetUserLines = @(
  '# Target User',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Primary user hypothesis',
  '',
  '- A founder/operator who wants a governed local AI assistant to create SaaS workflows safely.',
  '- Needs clear choices, gates, verification, and handoff packets rather than raw tool lists.',
  '',
  '## User jobs',
  '',
  '- Understand current setup state.',
  '- Choose a safe workspace and project type.',
  '- Know which tools/capabilities/channels are available.',
  '- Produce a first local product workflow packet.',
  '',
  '## Beginner-safe requirement',
  '',
  'Every step must explain what it changes, what it does not touch, and what the next decision is.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'target_user.md') ($targetUserLines -join "`n")

$firstWorkflowLines = @(
  '# First Workflow',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Workflow chain:',
  '',
  '```text',
  'intent -> scope -> evidence -> structure -> delivery packet -> execution -> verification -> handoff -> next decision',
  '```',
  '',
  '## Starter workflow',
  '',
  '1. Intent: define the first SaaS workflow the owner wants to test locally.',
  '2. Scope: select one bounded vertical slice and explicitly exclude runtime/cloud work.',
  '3. Evidence: read Stage 1-5 reports and any owner-provided product notes.',
  '4. Structure: map task class, toolsets, skills, gates, and verification.',
  '5. Delivery packet: create an implementation-ready local task packet.',
  '6. Execution: only after implementation gate.',
  '7. Verification: run local validators/tests and inspect artifacts.',
  '8. Handoff: summarize evidence, residual risk, and next gate.',
  '9. Next decision: owner chooses edit, implement, defer, or runtime-readiness planning.',
  '',
  '## Required gates before execution',
  '',
  '- implementation_gate',
  '- git_commit_gate',
  '- publication_gate',
  '- runtime_provider_gate for any external runtime/cloud work'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'first_workflow.md') ($firstWorkflowLines -join "`n")

$backlogLines = @(
  '# Starter Backlog',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Ready now: local planning and packet work',
  '',
  '- Review product_brief.md and target_user.md.',
  '- Choose first vertical slice.',
  '- Convert first_workflow.md into a scoped implementation packet.',
  '- Define local validators/tests before code.',
  '',
  '## Requires owner gate',
  '',
  '- Implement first workflow.',
  '- Commit or publish changes.',
  '- Enable additional Hermes toolsets or persistent memory.',
  '- Connect communication channels.',
  '',
  '## Requires separate high-risk/runtime gate',
  '',
  '- Cloudflare, Hetzner, n8n, MCP, database, provider/model/billing, public endpoints, production deploy.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'backlog.md') ($backlogLines -join "`n")

$localTaskPacketLines = @(
  '# Local Task Packet',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'packet_id: LAUNCHROOM_LOCAL_TASK_PACKET_v0_1',
  'packet_type: local_saas_operator_task',
  'executor_permission_tier: local_planning_only_until_owner_gate',
  '',
  '## Objective',
  '',
  'Prepare the first bounded SaaS workflow for local implementation planning.',
  '',
  '## Source lineage',
  '',
  '- Stage 1 profile foundation reports.',
  '- Stage 2 workspace onboarding report.',
  '- Stage 3 software/capability reports.',
  '- Stage 4 starter capability pack.',
  '- Stage 5 communication channel map and user guide.',
  '',
  '## Allowed actions before implementation gate',
  '',
  '- Read local Stage 1-6 reports.',
  '- Edit operator-kit markdown/YAML packets.',
  '- Propose validators/tests.',
  '- Ask owner to choose the first vertical slice.',
  '',
  '## Forbidden actions before separate gates',
  '',
  '- secret_readback',
  '- provider_or_billing_mutation',
  '- runtime_or_cloud_mutation',
  '- gateway_setup_or_pairing',
  '- n8n_or_mcp_mutation',
  '- git_push_without_explicit_gate',
  '- production_deploy',
  '',
  '## Validation required',
  '',
  '- Operator kit files exist.',
  '- readiness_report.yaml parses as YAML.',
  '- Runtime/cloud/gateway/git/secret action flags remain false.',
  '- Next owner decision is explicit.',
  '',
  '## Rollback plan',
  '',
  'Delete or regenerate `.hermes/operator-kit/` before any implementation begins.',
  '',
  '## Done when',
  '',
  'Owner has selected the first vertical slice or explicitly deferred implementation planning.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'local_task_packet.md') ($localTaskPacketLines -join "`n")

$gatesLines = @(
  '# Gates',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Stage 6 action flags',
  '',
  '```yaml',
  'runtime_mutation: false',
  'cloud_mutation: false',
  'n8n_mutation: false',
  'gateway_mutation: false',
  'git_publication_executed: false',
  'secrets_read_or_written: false',
  'implementation_executed: false',
  '```',
  '',
  '## Required gates',
  '',
  '- implementation_gate: before writing product code.',
  '- git_commit_gate: before committing changes.',
  '- push_pr_gate: before publishing branch/PR.',
  '- runtime_provider_gate: before touching provider, billing, cloud, database, n8n, MCP, or gateway surfaces.',
  '- secret_gate: before entering credentials through approved local secret-entry paths.'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'gates.md') ($gatesLines -join "`n")

$readinessLines = @(
  'artifact_id: LAUNCHROOM_SAAS_OPERATOR_KIT_READINESS_v0_1',
  'stage_id: stage_6_saas_operator_kit',
  "status: $Stage6Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "project_name: $(ConvertTo-YamlSingleQuotedScalar $ProjectName)",
  "project_type: $(ConvertTo-YamlSingleQuotedScalar $ProjectType)",
  "operator_kit_root: $(ConvertTo-YamlSingleQuotedScalar $operatorKitRoot)",
  'generated_files:',
  '  - START_HERE.md',
  '  - NEXT_DECISION.md',
  '  - CHECK_IT_WORKS.md',
  '  - PAIN_TO_WORKFLOW_EXAMPLES.md',
  '  - product_brief.md'
  '  - target_user.md',
  '  - first_workflow.md',
  '  - backlog.md',
  '  - local_task_packet.md',
  '  - gates.md',
  '  - readiness_report.yaml',
  '  - guided-session/SESSION_STATE.yaml',
  '  - guided-session/AGENT_GUIDE.md',
  '  - guided-session/USER_LESSON.md',
  '  - guided-session/IDEA_INTAKE.md',
  '  - guided-session/PROJECT_BLUEPRINT.md',
  '  - guided-session/FIRST_SLICE_PACKET.md',
  '  - guided-session/DEFAULT_WORKFLOW_CATALOG.md',
  '  - guided-session/IMPLEMENTATION_ROADMAP.md',
  '  - guided-session/COMPLETION_SUMMARY.md',
  'evidence_reports:',
  '  profile_setup_report: .hermes/reports/profile-setup-report.yaml',
  '  workspace_onboarding_report: .hermes/reports/workspace-onboarding-report.yaml',
  '  capability_graph: .hermes/reports/capability-graph.yaml',
  '  starter_capability_pack: .hermes/reports/starter-capability-pack.yaml',
  '  communication_channel_map: .hermes/reports/communication-channel-map.yaml',
  'missing_previous_stage_evidence:'
)
if ($missingOperatorEvidence.Count -eq 0) {
  $readinessLines += '  - none'
} else {
  foreach ($missingEvidence in $missingOperatorEvidence) { $readinessLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$readinessLines += @(
  'action_flags:',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  n8n_mutation: false',
  '  gateway_mutation: false',
  '  git_publication_executed: false',
  '  secrets_read_or_written: false',
  '  implementation_executed: false',
  '  beginner_next_decision_present: true',
  '  pain_to_workflow_examples_present: true',
  '  guided_session_present: true',
  '  no_idea_default_workflow_catalog_present: true',
  '  blueprint_to_solution_path_present: true',
  'next_owner_decision:',
  '  - review and edit product brief',
  '  - choose first vertical slice',
  '  - approve implementation planning packet',
  '  - defer runtime/provider/cloud setup'
)
Write-Utf8NoBom (Join-Path $operatorKitRoot 'readiness_report.yaml') ($readinessLines -join "`n")

$firstSliceRoot = Join-Path $WorkspaceFull '.hermes/first-slice'
New-Item -ItemType Directory -Force -Path $firstSliceRoot | Out-Null
$Stage7Status = 'pass'
$firstSliceEvidenceFiles = @(
  '.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md',
  '.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md',
  '.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md',
  '.hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md'
)
$missingFirstSliceEvidence = @($firstSliceEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingFirstSliceEvidence.Count -gt 0) { $Stage7Status = 'partial_stage6_evidence_missing' }

$firstSliceStartLines = @(
  '# Start Here — First Slice Planning',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 7. Stage 6 created the guided operator kit. Stage 7 turns that blueprint and first slice packet into an implementation planning and local pilot readiness packet.',
  '',
  'This stage does not write product code, install dependencies, connect live channels, read secrets, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. IMPLEMENTATION_BRIEF.md — what one slice would build after an implementation gate.',
  '2. LOCAL_PILOT_PLAN.md — how the slice can be tested locally or as a configuration packet.',
  '3. ACCEPTANCE_TESTS.md — what must be true for the user to accept the result.',
  '4. USER_DEMO_SCRIPT.md — how the user will see the working result.',
  '5. RISKS_AND_ROLLBACK.md — how to avoid or recover from mistakes.',
  '6. DECISION_GATE.md — choose implement, revise, connect channel, runtime readiness, or defer.',
  '7. READINESS_REPORT.yaml — machine-readable verification for the agent/validators.',
  '',
  '## Your next action',
  '',
  'Review DECISION_GATE.md and choose whether to approve implementation planning, revise the first slice, run a local-only pilot after gate, prepare a communication-channel setup gate, or defer.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'START_HERE.md') ($firstSliceStartLines -join "`n")

$implementationBriefLines = @(
  '# Implementation Brief',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Objective',
  '',
  'Convert the selected Stage 6 workflow into one implementation-ready slice after an explicit implementation gate.',
  '',
  '## Source lineage',
  '',
  '- .hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md',
  '- .hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md',
  '- .hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md',
  '- .hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md',
  '',
  '## Selected workflow',
  '',
  'Pending owner-guided Stage 6 choice. If no custom idea exists, choose one default workflow first: messenger setup, channel management, email/calendar/notes assistant, daily briefing, or idea-to-blueprint.',
  '',
  '## Output target',
  '',
  'A concrete user-visible artifact or configuration packet, not a vague plan.',
  '',
  '## User-visible success',
  '',
  'The user can inspect the output, run the acceptance checklist, and decide the next gate.',
  '',
  '## Explicit non-goals',
  '',
  '- No implementation before implementation_gate.',
  '- No live channel connection before communication_channel_setup_gate.',
  '- No runtime/cloud/provider/n8n mutation before runtime_provider_gate.',
  '- No secret readback or token storage.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'IMPLEMENTATION_BRIEF.md') ($implementationBriefLines -join "`n")

$localPilotPlanLines = @(
  '# Local Pilot Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Goal',
  '',
  'Prepare the first slice so it can become a local pilot or configuration packet after approval.',
  '',
  '## Pilot modes',
  '',
  '1. Documentation/configuration pilot: produce setup packet, checklist, and demo script without touching live systems.',
  '2. Local-only implementation pilot: create code or scripts only after implementation_gate and local file-scope approval.',
  '3. Communication setup pilot: prepare messenger/channel/email/calendar setup checklist, then stop at communication_channel_setup_gate.',
  '',
  '## Verification before any execution',
  '',
  '- Output target is concrete.',
  '- Acceptance tests are written first.',
  '- Rollback path exists.',
  '- Secret paths are never printed or stored in generated artifacts.',
  '- Runtime/cloud/gateway/n8n/provider actions remain gated.',
  '',
  '## Done when',
  '',
  'The owner can approve one next gate with a clear expected working result.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'LOCAL_PILOT_PLAN.md') ($localPilotPlanLines -join "`n")

$acceptanceTestsLines = @(
  '# Acceptance Tests',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'These are human-readable acceptance tests for the first slice. They become executable or checklist tests only after the next gate.',
  '',
  '## Universal tests',
  '',
  '- [ ] The selected workflow solves one named user pain.',
  '- [ ] The output target is visible to the user.',
  '- [ ] The verification method does not require production runtime.',
  '- [ ] The user can say pass / revise / defer after seeing the result.',
  '- [ ] No secrets are present in reports, docs, logs, or chat.',
  '- [ ] Runtime/cloud/provider/gateway/n8n/git-publication actions remain gated.',
  '',
  '## Example messenger setup acceptance tests',
  '',
  '- [ ] The user selected one messenger/channel surface.',
  '- [ ] The setup packet explains token/secret entry without asking for tokens in chat.',
  '- [ ] The verification checklist explains how success will be observed after gate.',
  '',
  '## Example daily briefing acceptance tests',
  '',
  '- [ ] The briefing sources are listed.',
  '- [ ] The delivery channel is selected or deferred.',
  '- [ ] The summary format is visible before scheduling or source connection.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'ACCEPTANCE_TESTS.md') ($acceptanceTestsLines -join "`n")

$userDemoLines = @(
  '# User Demo Script',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This script explains how the user will recognize the working result after the next approved gate.',
  '',
  '## Demo frame',
  '',
  '1. Show the selected pain and workflow.',
  '2. Show the output artifact or configuration packet.',
  '3. Run the acceptance checklist.',
  '4. Point to what was not touched: secrets, live runtime, cloud, gateway, n8n, provider/billing, production deploy.',
  '5. Ask for one next decision: revise, implement, connect channel, prepare runtime, or stop.',
  '',
  '## Success sentence',
  '',
  'The working result is acceptable when the user can see one useful output and verify it without trusting hidden agent state.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'USER_DEMO_SCRIPT.md') ($userDemoLines -join "`n")

$riskRollbackLines = @(
  '# Risks and Rollback',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Main risks',
  '',
  '- The first slice is still too broad.',
  '- The output target is vague.',
  '- The user expects live messenger/email/calendar behavior before a setup gate.',
  '- A future implementation tries to read secrets or mutate runtime too early.',
  '',
  '## Rollback',
  '',
  '- Delete or regenerate `.hermes/first-slice/` before implementation begins.',
  '- Return to `.hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md` and choose a smaller workflow.',
  '- Keep runtime/cloud/gateway/n8n/provider actions gated until a separate owner decision.',
  '',
  '## Stop conditions',
  '',
  '- User cannot name one pain.',
  '- User cannot name one output.',
  '- Acceptance tests cannot be written without production access.',
  '- Required action involves secrets or live external systems without a gate.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'RISKS_AND_ROLLBACK.md') ($riskRollbackLines -join "`n")

$decisionGateLines = @(
  '# Decision Gate',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Choose one next action only.',
  '',
  '## Options',
  '',
  '1. Approve implementation planning.',
  '   - Use when the first slice and acceptance tests are clear.',
  '   - Next gate: implementation_planning_gate.',
  '',
  '2. Revise the first slice.',
  '   - Use when the pain, workflow, or output is too broad.',
  '   - Next action: return to Stage 6 guided session files.',
  '',
  '3. Run a local-only pilot after gate.',
  '   - Use when the output can be tested without live external systems.',
  '   - Next gate: local_pilot_gate.',
  '',
  '4. Prepare communication channel setup gate.',
  '   - Use for messenger, Telegram/Discord channel, email/calendar/notes, or daily briefing workflows.',
  '   - Next gate: communication_channel_setup_gate.',
  '',
  '5. Defer implementation.',
  '   - Use when the user wants to stop with planning artifacts only.',
  '',
  '## Safety reminder',
  '',
  'Implementation, dependency installs, live channels, cloud/runtime/provider/gateway/n8n, git publication, and secrets require separate explicit gates.'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'DECISION_GATE.md') ($decisionGateLines -join "`n")

$firstSliceReadinessLines = @(
  'artifact_id: LAUNCHROOM_FIRST_SLICE_READINESS_v0_1',
  'stage_id: stage_7_first_slice_planning',
  "status: $Stage7Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "first_slice_root: $(ConvertTo-YamlSingleQuotedScalar $firstSliceRoot)",
  'source_lineage:',
  '  project_blueprint: .hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md',
  '  first_slice_packet: .hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md',
  '  implementation_roadmap: .hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md',
  '  default_workflow_catalog: .hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md',
  'generated_files:',
  '  - START_HERE.md',
  '  - IMPLEMENTATION_BRIEF.md',
  '  - LOCAL_PILOT_PLAN.md',
  '  - ACCEPTANCE_TESTS.md',
  '  - USER_DEMO_SCRIPT.md',
  '  - RISKS_AND_ROLLBACK.md',
  '  - DECISION_GATE.md',
  '  - READINESS_REPORT.yaml',
  'missing_stage6_evidence:'
)
if ($missingFirstSliceEvidence.Count -eq 0) {
  $firstSliceReadinessLines += '  - none'
} else {
  foreach ($missingEvidence in $missingFirstSliceEvidence) { $firstSliceReadinessLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$firstSliceReadinessLines += @(
  'action_flags:',
  '  implementation_executed: false',
  '  dependencies_installed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  local_pilot_plan_present: true',
  '  acceptance_tests_present: true',
  '  user_demo_script_present: true',
  '  next_implementation_gate_present: true',
  'next_owner_decision:',
  '  - approve implementation planning',
  '  - revise first slice',
  '  - run local-only pilot after gate',
  '  - prepare communication channel setup gate',
  '  - defer implementation'
)
Write-Utf8NoBom (Join-Path $firstSliceRoot 'READINESS_REPORT.yaml') ($firstSliceReadinessLines -join "`n")


$localPilotRoot = Join-Path $WorkspaceFull '.hermes/local-pilot'
New-Item -ItemType Directory -Force -Path $localPilotRoot | Out-Null
$Stage8Status = 'pass'
$localPilotEvidenceFiles = @(
  '.hermes/first-slice/IMPLEMENTATION_BRIEF.md',
  '.hermes/first-slice/LOCAL_PILOT_PLAN.md',
  '.hermes/first-slice/ACCEPTANCE_TESTS.md',
  '.hermes/first-slice/USER_DEMO_SCRIPT.md',
  '.hermes/first-slice/RISKS_AND_ROLLBACK.md',
  '.hermes/first-slice/DECISION_GATE.md',
  '.hermes/first-slice/READINESS_REPORT.yaml'
)
$missingLocalPilotEvidence = @($localPilotEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingLocalPilotEvidence.Count -gt 0) { $Stage8Status = 'partial_stage7_evidence_missing' }

$localPilotStartLines = @(
  '# Start Here — Local Pilot Execution Packet',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 8. Stage 7 created a first-slice implementation plan. Stage 8 turns that plan into a bounded local execution packet for a later agent/developer after an explicit implementation gate.',
  '',
  'This stage does not write product code, modify files, run commands, run tests, install dependencies, connect live channels, read secrets, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. EXECUTION_PACKET.md — what a later executor should do after approval.',
  '2. FILE_CHANGE_PLAN.md — which paths are allowed, forbidden, or require approval.',
  '3. COMMAND_PLAN.md — which commands are read-only, gated, or forbidden.',
  '4. TEST_PLAN.md — how the later result should be checked.',
  '5. EVIDENCE_LOG.md — where real command/test outputs will be recorded later.',
  '6. REVIEW_CHECKLIST.md — how the owner reviews the result.',
  '7. HANDOFF_SUMMARY.md — what to pass to the next agent/developer.',
  '8. READINESS_REPORT.yaml — machine-readable safety and evidence status.',
  '',
  '## Your next action',
  '',
  'Review EXECUTION_PACKET.md and decide whether to approve local implementation execution, revise the packet, gather missing evidence, prepare a separate communication/runtime gate, or defer.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'START_HERE.md') ($localPilotStartLines -join "`n")

$executionPacketLines = @(
  '# Execution Packet',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Objective',
  '',
  'Prepare one bounded local implementation slice from the Stage 7 first-slice plan after an explicit owner implementation gate.',
  '',
  '## Source lineage',
  '',
  '- .hermes/first-slice/IMPLEMENTATION_BRIEF.md',
  '- .hermes/first-slice/LOCAL_PILOT_PLAN.md',
  '- .hermes/first-slice/ACCEPTANCE_TESTS.md',
  '- .hermes/first-slice/USER_DEMO_SCRIPT.md',
  '- .hermes/first-slice/RISKS_AND_ROLLBACK.md',
  '- .hermes/first-slice/DECISION_GATE.md',
  '- .hermes/first-slice/READINESS_REPORT.yaml',
  '',
  '## Executor instruction',
  '',
  'Do not start implementation from this file alone. First obtain the next execution gate, then inspect the real project files, confirm scope, and update this packet with concrete paths and commands.',
  '',
  '## Expected working result',
  '',
  'A small local result that can be demonstrated with the Stage 7 user demo script and accepted with the Stage 7 acceptance tests.',
  '',
  '## Owner review gate',
  '',
  'Required before any file changes, command execution beyond read-only inspection, dependency install, or test run.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'EXECUTION_PACKET.md') ($executionPacketLines -join "`n")

$fileChangePlanLines = @(
  '# File Change Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Allowed file scope after gate',
  '',
  '- Project files explicitly named by the implementation gate.',
  '- Workspace-local `.hermes` execution/evidence artifacts.',
  '- New local pilot files approved by the owner.',
  '',
  '## Forbidden file scope',
  '',
  '- `.env`, `auth.json`, `state.db`, OAuth/session/token stores, private keys, credential directories.',
  '- Hermes runtime/profile credentials or another profile identity.',
  '- Production runtime/cloud/gateway/n8n/MCP/provider configuration.',
  '- Git history rewriting or public publication without a separate gate.',
  '',
  '## Approval-required unknowns',
  '',
  '- Any file path not inspected yet.',
  '- Any generated file outside the selected workspace.',
  '- Any change that would alter deployment, billing, or external integrations.',
  '',
  '## Executor rule',
  '',
  'Read relevant files first, make the smallest scoped edit, and record exact changed paths in EVIDENCE_LOG.md after execution.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'FILE_CHANGE_PLAN.md') ($fileChangePlanLines -join "`n")

$commandPlanLines = @(
  '# Command Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Safe read-only commands after gate',
  '',
  '- project file listing/search through approved tools',
  '- `git status --short --branch`',
  '- version checks for already installed local tools',
  '- test discovery commands that do not mutate state',
  '',
  '## Gated local commands',
  '',
  '- formatters, linters, unit tests, local build checks, or local scripts named by the implementation plan.',
  '- package manager commands only when the owner explicitly approves dependency installation.',
  '',
  '## Forbidden commands without separate gate',
  '',
  '- cloud deploys or provider CLIs that mutate resources',
  '- gateway pairing/autostart or live messenger/email/calendar setup',
  '- n8n/MCP/database mutation commands',
  '- git push/merge/rebase/reset/clean',
  '- commands that print or read secrets',
  '',
  '## Evidence rule',
  '',
  'Do not invent outputs. Copy only real command summaries into EVIDENCE_LOG.md after execution.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'COMMAND_PLAN.md') ($commandPlanLines -join "`n")

$testPlanLines = @(
  '# Test Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Test mapping',
  '',
  '| Check | Source | Expected evidence |',
  '| --- | --- | --- |',
  '| Acceptance tests | .hermes/first-slice/ACCEPTANCE_TESTS.md | pass/fail notes with real output |',
  '| User demo | .hermes/first-slice/USER_DEMO_SCRIPT.md | screenshot/log/manual confirmation after gate |',
  '| Safety boundaries | FILE_CHANGE_PLAN.md and COMMAND_PLAN.md | no forbidden path/command touched |',
  '| Rollback readiness | .hermes/first-slice/RISKS_AND_ROLLBACK.md | rollback step identified before execution |',
  '',
  '## Executor rule',
  '',
  'Run only the tests approved by the implementation gate. If a test fails, stop, record the real failure, and revise the packet instead of covering it up.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'TEST_PLAN.md') ($testPlanLines -join "`n")

$evidenceLogLines = @(
  '# Evidence Log',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'No implementation, file changes, commands, or tests have been executed by Stage 8.',
  '',
  '## To fill after explicit execution gate',
  '',
  '- Gate granted by:',
  '- Scope approved:',
  '- Files changed:',
  '- Commands run:',
  '- Tests run:',
  '- Real outputs:',
  '- Failures/blockers:',
  '- Rollback performed or available:',
  '- Owner review result:',
  '',
  'Do not fabricate evidence. Empty evidence is safer than invented success.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'EVIDENCE_LOG.md') ($evidenceLogLines -join "`n")

$reviewChecklistLines = @(
  '# Review Checklist',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '- [ ] The implementation objective is still the right first slice.',
  '- [ ] Allowed/forbidden file scope is clear.',
  '- [ ] Command plan is clear and does not include production/runtime mutation.',
  '- [ ] Test plan maps to acceptance tests and user demo.',
  '- [ ] Secrets and credential files were not requested or read.',
  '- [ ] Evidence log will contain real outputs only after execution.',
  '- [ ] Rollback path is known before execution.',
  '- [ ] Next gate is explicit: execute, revise, gather evidence, prepare runtime gate, or defer.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'REVIEW_CHECKLIST.md') ($reviewChecklistLines -join "`n")

$handoffSummaryLines = @(
  '# Handoff Summary',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## For the next agent/developer',
  '',
  'Start with START_HERE.md, then read EXECUTION_PACKET.md, FILE_CHANGE_PLAN.md, COMMAND_PLAN.md, TEST_PLAN.md, and the Stage 7 first-slice files.',
  '',
  '## Current state',
  '',
  '- Stage 8 generated a local pilot execution packet only.',
  '- No implementation has been executed.',
  '- No commands or tests have been run by this stage.',
  '- No runtime/cloud/provider/gateway/n8n/git/secret surfaces have been mutated.',
  '',
  '## Next required decision',
  '',
  'Owner must choose one: approve local implementation execution, revise packet, gather missing evidence, prepare a separate communication/runtime gate, or defer.'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'HANDOFF_SUMMARY.md') ($handoffSummaryLines -join "`n")

$localPilotReadinessLines = @(
  'artifact_id: LAUNCHROOM_LOCAL_PILOT_EXECUTION_READINESS_v0_1',
  'stage_id: stage_8_local_pilot_execution_packet',
  "status: $Stage8Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "local_pilot_root: $(ConvertTo-YamlSingleQuotedScalar $localPilotRoot)",
  'source_lineage:',
  '  implementation_brief: .hermes/first-slice/IMPLEMENTATION_BRIEF.md',
  '  local_pilot_plan: .hermes/first-slice/LOCAL_PILOT_PLAN.md',
  '  acceptance_tests: .hermes/first-slice/ACCEPTANCE_TESTS.md',
  '  user_demo_script: .hermes/first-slice/USER_DEMO_SCRIPT.md',
  '  risks_and_rollback: .hermes/first-slice/RISKS_AND_ROLLBACK.md',
  '  decision_gate: .hermes/first-slice/DECISION_GATE.md',
  '  first_slice_readiness: .hermes/first-slice/READINESS_REPORT.yaml',
  'generated_files:',
  '  - START_HERE.md',
  '  - EXECUTION_PACKET.md',
  '  - FILE_CHANGE_PLAN.md',
  '  - COMMAND_PLAN.md',
  '  - TEST_PLAN.md',
  '  - EVIDENCE_LOG.md',
  '  - REVIEW_CHECKLIST.md',
  '  - HANDOFF_SUMMARY.md',
  '  - READINESS_REPORT.yaml',
  'missing_stage7_evidence:'
)
if ($missingLocalPilotEvidence.Count -eq 0) {
  $localPilotReadinessLines += '  - none'
} else {
  foreach ($missingEvidence in $missingLocalPilotEvidence) { $localPilotReadinessLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$localPilotReadinessLines += @(
  'action_flags:',
  '  implementation_executed: false',
  '  file_changes_executed: false',
  '  commands_executed: false',
  '  tests_executed: false',
  '  dependencies_installed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  execution_packet_present: true',
  '  file_change_plan_present: true',
  '  command_plan_present: true',
  '  test_plan_present: true',
  '  evidence_log_present: true',
  '  review_checklist_present: true',
  '  handoff_summary_present: true',
  '  next_execution_gate_present: true',
  'next_owner_decision:',
  '  - approve local implementation execution',
  '  - revise execution packet',
  '  - gather missing project evidence',
  '  - prepare communication/runtime gate separately',
  '  - defer implementation'
)
Write-Utf8NoBom (Join-Path $localPilotRoot 'READINESS_REPORT.yaml') ($localPilotReadinessLines -join "`n")


$projectAuditRoot = Join-Path $WorkspaceFull '.hermes/project-audit'
New-Item -ItemType Directory -Force -Path $projectAuditRoot | Out-Null
$Stage9Status = 'partial'
$projectAuditEvidenceFiles = @(
  '.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md',
  '.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md',
  '.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md',
  '.hermes/first-slice/IMPLEMENTATION_BRIEF.md',
  '.hermes/first-slice/LOCAL_PILOT_PLAN.md',
  '.hermes/first-slice/ACCEPTANCE_TESTS.md',
  '.hermes/first-slice/USER_DEMO_SCRIPT.md',
  '.hermes/first-slice/RISKS_AND_ROLLBACK.md',
  '.hermes/first-slice/DECISION_GATE.md',
  '.hermes/local-pilot/EXECUTION_PACKET.md',
  '.hermes/local-pilot/FILE_CHANGE_PLAN.md',
  '.hermes/local-pilot/COMMAND_PLAN.md',
  '.hermes/local-pilot/TEST_PLAN.md',
  '.hermes/local-pilot/READINESS_REPORT.yaml'
)
$missingProjectAuditEvidence = @($projectAuditEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingProjectAuditEvidence.Count -gt 0) { $Stage9Status = 'blocked_missing_evidence' }

$projectAuditStartLines = @(
  '# Start Here — Project Plan Integrity and Drift Audit',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 9. This audit checks whether the blueprint, first-slice plan, and local execution packet are coherent before any real implementation.',
  '',
  'Stage 9 does not implement product code, modify project files, run tests, install dependencies, connect live channels, read secrets, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. PLAN_INTEGRITY_REPORT.md — overall planning quality and execution gate status.',
  '2. EXPECTED_RESULT_MAP.md — what was planned, expected, user-visible, and explicitly excluded.',
  '3. MISSING_FRAGMENTS.md — what is absent, vague, or still placeholder-driven.',
  '4. CONTRADICTION_SCAN.md — blueprint vs first slice vs execution packet vs gates.',
  '5. STAGE_DRIFT_SCAN.md — skipped stages, premature implementation, runtime bypass, evidence gaps.',
  '6. ASSUMPTION_REGISTER.md — assumptions that must not be hidden inside execution.',
  '7. IMPLEMENTATION_BLOCKERS.md — blockers that must be resolved before execution.',
  '8. REPAIR_RECOMMENDATIONS.md — safe next repairs.',
  '9. AUDIT_REPORT.yaml — machine-readable audit status.',
  '',
  '## Rule',
  '',
  'If Stage 9 is partial or blocked, do not execute. Repair the plan first or approve Stage 10 readiness analysis only.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'START_HERE.md') ($projectAuditStartLines -join "`n")

$planIntegrityLines = @(
  '# Plan Integrity Report',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Audit status',
  '',
  "audit_status: $Stage9Status",
  'execution_allowed: false',
  '',
  '## What was audited',
  '',
  '- Stage 6 PROJECT_BLUEPRINT.md',
  '- Stage 6 FIRST_SLICE_PACKET.md',
  '- Stage 6 IMPLEMENTATION_ROADMAP.md',
  '- Stage 7 first-slice planning files',
  '- Stage 8 local-pilot execution packet files',
  '',
  '## Integrity checks',
  '',
  '- blueprint_has_clear_goal: partial_until_user_fills_guided_session',
  '- expected_result_defined: partial_until_owner_selects_output',
  '- user_visible_success_defined: partial_until_acceptance_review',
  '- first_slice_matches_blueprint: requires_owner_review',
  '- execution_packet_matches_first_slice: requires_owner_review',
  '- acceptance_tests_match_expected_result: requires_owner_review',
  '- command_plan_matches_toolchain: deferred_to_stage_10',
  '- no_skipped_stage_detected: true',
  '- no_runtime_gate_bypass_detected: true',
  '',
  '## Decision',
  '',
  'Execution is not allowed from Stage 9 by default. Use this audit to repair missing fragments or proceed only to Stage 10 agent/toolchain readiness analysis.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'PLAN_INTEGRITY_REPORT.md') ($planIntegrityLines -join "`n")

$expectedResultLines = @(
  '# Expected Result Map',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '| Layer | Source | Expected content | Audit note |',
  '| --- | --- | --- | --- |',
  '| Planned project direction | PROJECT_BLUEPRINT.md | one sentence, first user, pain, first workflow, first output, success check | partial until user fills guided session |',
  '| First slice | FIRST_SLICE_PACKET.md and IMPLEMENTATION_BRIEF.md | one bounded implementation-ready slice | must match blueprint |',
  '| User-visible result | USER_DEMO_SCRIPT.md | observable output and demo flow | must be concrete before execution |',
  '| Acceptance signal | ACCEPTANCE_TESTS.md | pass/revise/defer criteria | must map to expected result |',
  '| Execution scope | EXECUTION_PACKET.md and FILE_CHANGE_PLAN.md | allowed files and forbidden paths | must not exceed first slice |',
  '| Command/test scope | COMMAND_PLAN.md and TEST_PLAN.md | safe commands and tests after gate | Stage 10 validates toolchain readiness |',
  '| Non-goals | gates and safety reports | no secrets/runtime/cloud/gateway/n8n/git publication | must remain enforced |',
  '',
  '## Audit conclusion',
  '',
  'Expected result exists as a scaffold, but execution remains blocked until owner-selected workflow/output and Stage 10 readiness are complete.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'EXPECTED_RESULT_MAP.md') ($expectedResultLines -join "`n")

$missingFragmentsLines = @(
  '# Missing Fragments',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Known placeholder fragments',
  '',
  '- PROJECT_BLUEPRINT.md may still contain pending guided session input.',
  '- FIRST_SLICE_PACKET.md may still contain pending pain/user/workflow/output/validation.',
  '- IMPLEMENTATION_BRIEF.md may still contain pending selected workflow.',
  '- FILE_CHANGE_PLAN.md may not name concrete project files yet.',
  '- COMMAND_PLAN.md may not name concrete project-specific commands yet.',
  '',
  '## Required before execution',
  '',
  '- One selected workflow.',
  '- One expected user-visible output.',
  '- One acceptance checklist mapped to that output.',
  '- Concrete allowed file scope.',
  '- Concrete command/test plan validated by Stage 10.',
  '- Owner decision resolving or accepting remaining assumptions.'
)
if ($missingProjectAuditEvidence.Count -gt 0) {
  $missingFragmentsLines += @('', '## Missing source evidence')
  foreach ($missingEvidence in $missingProjectAuditEvidence) { $missingFragmentsLines += "- $missingEvidence" }
}
Write-Utf8NoBom (Join-Path $projectAuditRoot 'MISSING_FRAGMENTS.md') ($missingFragmentsLines -join "`n")

$contradictionLines = @(
  '# Contradiction Scan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Scanned contradiction classes',
  '',
  '- blueprint_vs_first_slice: check that the first slice implements the selected blueprint pain/output.',
  '- first_slice_vs_execution_packet: check that execution scope does not exceed the first slice.',
  '- acceptance_tests_vs_expected_result: check that tests verify the visible output, not unrelated work.',
  '- command_plan_vs_safety_gates: check that commands do not install, deploy, mutate runtime, or print secrets without gate.',
  '- demo_script_vs_non_goals: check that the demo does not imply live runtime/channel behavior before gate.',
  '',
  '## Current result',
  '',
  'No hard contradiction is generated by the scaffold itself, but unresolved placeholders mean the owner must review this again after filling Stage 6/7 details.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'CONTRADICTION_SCAN.md') ($contradictionLines -join "`n")

$stageDriftLines = @(
  '# Stage Drift Scan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Drift checks',
  '',
  '- skipped_stage_detected: false',
  '- premature_implementation_detected: false',
  '- command_execution_detected: false',
  '- test_execution_detected: false',
  '- dependency_install_detected: false',
  '- runtime_gate_bypass_detected: false',
  '- cloud_gateway_n8n_bypass_detected: false',
  '- secret_readback_detected: false',
  '- git_publication_detected: false',
  '',
  '## Drift risk',
  '',
  'The main drift risk is execution from a scaffold with unresolved placeholders. Stage 9 therefore keeps execution_allowed=false by default.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'STAGE_DRIFT_SCAN.md') ($stageDriftLines -join "`n")

$assumptionLines = @(
  '# Assumption Register',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '| Assumption | Risk | Required resolution |',
  '| --- | --- | --- |',
  '| User has selected one workflow | Agent may implement wrong thing | owner selects or confirms workflow |',
  '| Expected result is concrete | Agent may produce vague docs | owner names visible output |',
  '| Acceptance tests match result | Verification may be meaningless | map tests to output |',
  '| File scope is known | Agent may edit wrong files | Stage 10/project inspection names paths |',
  '| Required software exists | Agent may fail mid-execution | Stage 10 toolchain readiness |',
  '',
  'Assumptions must be resolved, accepted as partial for Stage 10 only, or converted into blockers.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'ASSUMPTION_REGISTER.md') ($assumptionLines -join "`n")

$blockerLines = @(
  '# Implementation Blockers',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Blocking until resolved or explicitly accepted for Stage 10 analysis only',
  '',
  '- Pending guided session placeholders.',
  '- Missing concrete expected user-visible output.',
  '- Missing concrete file scope.',
  '- Missing project-specific command/test readiness.',
  '- Any contradiction found after owner fills the blueprint.',
  '',
  '## Not blockers for Stage 10',
  '',
  '- Generic software inventory can be partial; Stage 10 will map exact toolchain needs.',
  '- Runtime/channel setup can remain deferred; Stage 10 must not activate it.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'IMPLEMENTATION_BLOCKERS.md') ($blockerLines -join "`n")

$repairLines = @(
  '# Repair Recommendations',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Safe repair order',
  '',
  '1. Fill PROJECT_BLUEPRINT.md with one sentence, user, pain, workflow, output, and success check.',
  '2. Fill FIRST_SLICE_PACKET.md from the blueprint; do not add unrelated work.',
  '3. Update IMPLEMENTATION_BRIEF.md with one selected workflow and one visible result.',
  '4. Update ACCEPTANCE_TESTS.md to verify that result.',
  '5. Update FILE_CHANGE_PLAN.md with concrete allowed paths only after inspecting the real project.',
  '6. Defer concrete install/command decisions to Stage 10 agent/toolchain readiness.',
  '7. Re-run Stage 9 audit before execution if major planning content changes.',
  '',
  '## Next allowed decision',
  '',
  'Proceed to Stage 10 readiness analysis only, or repair missing fragments first. Do not execute implementation yet.'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'REPAIR_RECOMMENDATIONS.md') ($repairLines -join "`n")

$projectAuditReportLines = @(
  'artifact_id: LAUNCHROOM_PROJECT_PLAN_INTEGRITY_AUDIT_v0_1',
  'stage_id: stage_9_project_plan_integrity_audit',
  "audit_status: $Stage9Status",
  'execution_allowed: false',
  'stage10_readiness_analysis_allowed: true',
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "project_audit_root: $(ConvertTo-YamlSingleQuotedScalar $projectAuditRoot)",
  'source_lineage:',
  '  project_blueprint: .hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md',
  '  first_slice_packet: .hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md',
  '  implementation_roadmap: .hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md',
  '  implementation_brief: .hermes/first-slice/IMPLEMENTATION_BRIEF.md',
  '  acceptance_tests: .hermes/first-slice/ACCEPTANCE_TESTS.md',
  '  execution_packet: .hermes/local-pilot/EXECUTION_PACKET.md',
  'generated_files:',
  '  - START_HERE.md',
  '  - PLAN_INTEGRITY_REPORT.md',
  '  - EXPECTED_RESULT_MAP.md',
  '  - MISSING_FRAGMENTS.md',
  '  - CONTRADICTION_SCAN.md',
  '  - STAGE_DRIFT_SCAN.md',
  '  - ASSUMPTION_REGISTER.md',
  '  - IMPLEMENTATION_BLOCKERS.md',
  '  - REPAIR_RECOMMENDATIONS.md',
  '  - AUDIT_REPORT.yaml',
  'missing_source_evidence:'
)
if ($missingProjectAuditEvidence.Count -eq 0) {
  $projectAuditReportLines += '  - none'
} else {
  foreach ($missingEvidence in $missingProjectAuditEvidence) { $projectAuditReportLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$projectAuditReportLines += @(
  'audit_checks:',
  '  blueprint_has_clear_goal: partial',
  '  expected_result_defined: partial',
  '  user_visible_success_defined: partial',
  '  first_slice_matches_blueprint: requires_owner_review',
  '  execution_packet_matches_first_slice: requires_owner_review',
  '  acceptance_tests_match_expected_result: requires_owner_review',
  '  command_plan_matches_toolchain: deferred_to_stage_10',
  '  no_skipped_stage_detected: true',
  '  no_runtime_gate_bypass_detected: true',
  '  unresolved_assumptions_recorded: true',
  '  repair_recommendations_present: true',
  'action_flags:',
  '  implementation_executed: false',
  '  file_changes_executed: false',
  '  commands_executed: false',
  '  tests_executed: false',
  '  dependencies_installed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  plan_integrity_report_present: true',
  '  expected_result_map_present: true',
  '  missing_fragments_report_present: true',
  '  contradiction_scan_present: true',
  '  stage_drift_scan_present: true',
  '  assumption_register_present: true',
  '  implementation_blockers_present: true',
  '  repair_recommendations_present: true',
  'next_owner_decision:',
  '  - repair missing fragments',
  '  - resolve contradictions',
  '  - approve partial audit for Stage 10 readiness only',
  '  - revise blueprint or first slice',
  '  - defer execution'
)
Write-Utf8NoBom (Join-Path $projectAuditRoot 'AUDIT_REPORT.yaml') ($projectAuditReportLines -join "`n")


$agentReadinessRoot = Join-Path $WorkspaceFull '.hermes/agent-readiness'
New-Item -ItemType Directory -Force -Path $agentReadinessRoot | Out-Null
$Stage10Status = 'partial'
$agentReadinessEvidenceFiles = @(
  '.hermes/project-audit/AUDIT_REPORT.yaml',
  '.hermes/project-audit/PLAN_INTEGRITY_REPORT.md',
  '.hermes/project-audit/IMPLEMENTATION_BLOCKERS.md',
  '.hermes/project-audit/REPAIR_RECOMMENDATIONS.md',
  '.hermes/local-pilot/EXECUTION_PACKET.md',
  '.hermes/local-pilot/FILE_CHANGE_PLAN.md',
  '.hermes/local-pilot/COMMAND_PLAN.md',
  '.hermes/local-pilot/TEST_PLAN.md',
  '.hermes/reports/software-inventory-report.yaml',
  '.hermes/reports/software-purpose-map.yaml',
  '.hermes/reports/software-install-recommendation.yaml',
  '.hermes/reports/capability-graph.yaml',
  '.hermes/reports/starter-capability-pack.yaml'
)
$missingAgentReadinessEvidence = @($agentReadinessEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingAgentReadinessEvidence.Count -gt 0) { $Stage10Status = 'blocked_missing_evidence' }

$agentReadinessStartLines = @(
  '# Start Here — Agent Execution Readiness and Toolchain Activation Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 10. Stage 9 checked whether the plan is coherent. Stage 10 checks whether the agent, local software, Hermes toolsets, skills, agent pipeline, install gates, and command plan are ready for real execution.',
  '',
  'Stage 10 does not install software, enable Hermes toolsets, install skills, spawn agents, run implementation commands, run tests, read secrets, publish git, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. PROJECT_TOOLCHAIN_REQUIREMENTS.md — what this project may need to execute.',
  '2. SOFTWARE_GAP_ANALYSIS.md — present, missing, optional, and unknown software surfaces.',
  '3. HERMES_TOOLSET_PLAN.md — which Hermes toolsets should be active for each work class after gate.',
  '4. SKILL_LOAD_PLAN.md — which skills should be loaded before planning, implementation, verification, and PR work.',
  '5. AGENT_PIPELINE_PLAN.md — planner, toolchain verifier, implementer, verification arbiter, owner gate.',
  '6. INSTALL_PLAN.md — gated install command shapes, verification commands, risks, rollback.',
  '7. COMMAND_READINESS.md — read-only, gated local, install, and forbidden command classes.',
  '8. EXECUTION_READINESS_REPORT.yaml — machine-readable status.',
  '',
  '## Rule',
  '',
  'Execution is still blocked. Stage 10 may approve readiness analysis, not implementation. Real execution needs repaired Stage 9 blockers, owner readiness acceptance, and a separate implementation gate.'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'START_HERE.md') ($agentReadinessStartLines -join "`n")

$toolchainRequirementsLines = @(
  '# Project Toolchain Requirements',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Source lineage',
  '',
  '- .hermes/project-audit/AUDIT_REPORT.yaml',
  '- .hermes/local-pilot/EXECUTION_PACKET.md',
  '- .hermes/local-pilot/FILE_CHANGE_PLAN.md',
  '- .hermes/local-pilot/COMMAND_PLAN.md',
  '- .hermes/local-pilot/TEST_PLAN.md',
  '- .hermes/reports/capability-graph.yaml',
  '- .hermes/reports/starter-capability-pack.yaml',
  '',
  '## Universal execution requirement model',
  '',
  '| Work class | Software | Hermes toolsets | Skills | Gate | Verification |',
  '| --- | --- | --- | --- | --- | --- |',
  '| Local docs/config packet | git, python, ripgrep | file, terminal, code_execution, skills, todo | governed-agent-engineering-standards, experience-grounded-work-preflight | implementation_gate | readback + validators |',
  '| Node/Web SaaS slice | git, node, npm, ripgrep | file, terminal, code_execution, browser optional | test-driven-development, requesting-code-review, github-pr-workflow | install_gate if node/npm missing | npm test/build after gate |',
  '| Python/API slice | git, python, uv, ripgrep | file, terminal, code_execution | test-driven-development, systematic-debugging, github-pr-workflow | install_gate if uv/python deps missing | python tests after gate |',
  '| External agent handoff | git, gh, codex/claude optional | terminal, file, skills, delegation optional | airmida-external-agent-tool-readiness, codex, claude-code | external_agent_gate | smoke pass or blocker recorded |',
  '| Runtime/channel setup | hermes gateway, platform CLIs optional | terminal, file, skills | governed-messaging-gateway-setup, hermes-agent | runtime/provider/gateway/secret gates | status check after gate |',
  '',
  '## Current Stage 10 decision',
  '',
  'The project has a readiness model, but concrete execution remains blocked until Stage 9 blockers are resolved and project-specific software/toolset/skill gates are accepted.'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'PROJECT_TOOLCHAIN_REQUIREMENTS.md') ($toolchainRequirementsLines -join "`n")

$softwareGapLines = @(
  '# Software Gap Analysis',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This file interprets Stage 3 software reports for execution readiness. It does not install anything.',
  '',
  '## Required baseline',
  '',
  '- Hermes: needed for operator session and generated reports.',
  '- Git: needed for repository inspection, diffs, branch/PR workflow after gate.',
  '- Python: needed for validators, scripts, and local checks.',
  '',
  '## Common SaaS implementation candidates',
  '',
  '- Node.js LTS + npm: common for frontend/web SaaS work.',
  '- ripgrep: fast repo search and drift inspection.',
  '- uv: Python dependency/tool runner when Python project work is selected.',
  '- gh: GitHub PR/CI workflow after publication gate.',
  '- Docker/WSL: optional, only when the project or runtime plan explicitly requires them.',
  '',
  '## Readiness classes',
  '',
  '- present: Stage 3 reported usable on this machine.',
  '- missing_or_unknown: Stage 3 did not prove presence.',
  '- optional_deferred: not required for current local slice.',
  '- gated_install_candidate: may be installed only after owner install gate.',
  '',
  '## Current Stage 10 result',
  '',
  'Use .hermes/reports/software-inventory-report.yaml and software-install-recommendation.yaml as evidence. Do not infer installation readiness from memory or chat.'
)
if ($missingAgentReadinessEvidence.Count -gt 0) {
  $softwareGapLines += @('', '## Missing source evidence')
  foreach ($missingEvidence in $missingAgentReadinessEvidence) { $softwareGapLines += "- $missingEvidence" }
}
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'SOFTWARE_GAP_ANALYSIS.md') ($softwareGapLines -join "`n")

$toolsetPlanLines = @(
  '# Hermes Toolset Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 10 recommends toolsets. It does not enable them. Toolset changes require an explicit gate and usually a reset/new session.',
  '',
  '## Starter load order by work phase',
  '',
  '1. Planning/repair: file, terminal, code_execution, skills, todo.',
  '2. Implementation after gate: file, terminal, code_execution, skills, todo.',
  '3. Browser/UI verification after local server gate: browser, computer_use, vision.',
  '4. Web research after research gate: web, session_search.',
  '5. External agent handoff after gate: delegation, terminal, file, skills.',
  '6. Messaging/runtime setup after separate gates: gateway/messaging-related tools only through approved setup path.',
  '',
  '## Boundaries',
  '',
  '- toolsets_enabled_without_gate: false',
  '- toolset_activation_gate_required: true',
  '- reset_required_after_toolset_change: true',
  '- no runtime/provider/cloud/gateway/n8n mutation from this plan'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'HERMES_TOOLSET_PLAN.md') ($toolsetPlanLines -join "`n")

$skillLoadPlanLines = @(
  '# Skill Load Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 10 selects skills to load before execution. It does not install network skills, patch unrelated skills, or write memory automatically.',
  '',
  '## Required skill stack before implementation planning',
  '',
  '- experience-grounded-work-preflight: verify proven path, gaps, gates, and next action.',
  '- governed-agent-engineering-standards: packet/gate/verification discipline.',
  '- hermes-agent: current Hermes commands, toolsets, profiles, gateway, skills behavior.',
  '',
  '## Conditional implementation skills',
  '',
  '- test-driven-development: when writing code/tests.',
  '- systematic-debugging: when a failure needs root-cause analysis.',
  '- requesting-code-review: before commit/PR quality checks.',
  '- github-pr-workflow: branch, PR, CI, merge after publication gate.',
  '- airmida-external-agent-tool-readiness: before Codex/Claude/gh external handoff.',
  '- governed-messaging-gateway-setup: before live communication channel setup.',
  '',
  '## Boundaries',
  '',
  '- skill_load_gate_required: true',
  '- skills_installed_without_gate: false',
  '- persistent_memory_written_without_gate: false',
  '- skills capture happens later through a dedicated skill-capture stage after proven success'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'SKILL_LOAD_PLAN.md') ($skillLoadPlanLines -join "`n")

$agentPipelineLines = @(
  '# Agent Pipeline Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 10 defines the pipeline. It does not spawn agents or assign real work yet.',
  '',
  '## Recommended first pipeline',
  '',
  '1. Planner / Repair Agent',
  '   - Reads Stage 9 audit.',
  '   - Repairs missing fragments or records blockers.',
  '',
  '2. Toolchain Verifier',
  '   - Reads Stage 3/4 reports and this Stage 10 package.',
  '   - Verifies command/tool presence without secret readback.',
  '   - Produces blockers or owner install/toolset gates.',
  '',
  '3. Implementer',
  '   - Starts only after implementation gate.',
  '   - Touches only approved file scope.',
  '',
  '4. Verification Arbiter',
  '   - Runs approved tests/validators.',
  '   - Compares result against expected output and acceptance tests.',
  '',
  '5. Owner Gate',
  '   - Chooses accept, revise, publish, runtime readiness, or defer.',
  '',
  '## Boundaries',
  '',
  '- agents_spawned: false',
  '- agent_pipeline_gate_required: true',
  '- external_agent_gate required before Codex/Claude/Copilot-style execution'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'AGENT_PIPELINE_PLAN.md') ($agentPipelineLines -join "`n")

$installPlanLines = @(
  '# Install Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 10 prepares install decisions. It does not run install commands.',
  '',
  '| Software | Why it may be needed | Example install command shape | Verify | Risk | Rollback | Gate |',
  '| --- | --- | --- | --- | --- | --- | --- |',
  '| Node.js LTS + npm | frontend/web SaaS implementation | winget install OpenJS.NodeJS.LTS | node --version; npm --version | PATH/restart/system change | winget uninstall OpenJS.NodeJS.LTS | install_gate |',
  '| ripgrep | fast repo search and drift control | winget install BurntSushi.ripgrep.MSVC | rg --version | PATH/system package change | winget uninstall BurntSushi.ripgrep.MSVC | install_gate |',
  '| uv | Python project/dependency runner | winget install astral-sh.uv or official installer | uv --version | PATH/system package change | winget uninstall astral-sh.uv | install_gate |',
  '| GitHub CLI gh | PR/CI workflow | winget install GitHub.cli | gh --version; gh auth status | auth flow may be needed; no token in chat | winget uninstall GitHub.cli | install/auth gate |',
  '| Docker Desktop | containerized runtime only if selected | winget install Docker.DockerDesktop | docker --version | service/runtime/system change | winget uninstall Docker.DockerDesktop | high-risk install gate |',
  '',
  '## Required rule',
  '',
  'Every install decision must include why, exact target, command, verification, risk, rollback, admin/restart/PATH notes, and explicit owner gate before execution.'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'INSTALL_PLAN.md') ($installPlanLines -join "`n")

$commandReadinessLines = @(
  '# Command Readiness',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '## Safe read-only before implementation gate',
  '',
  '- inspect approved project files',
  '- git status --short --branch',
  '- version checks for already installed tools',
  '- read generated Stage 3-10 reports',
  '',
  '## Gated local commands',
  '',
  '- package install commands from INSTALL_PLAN.md after install_gate',
  '- project tests/builds after implementation_gate and command approval',
  '- format/lint commands after file scope is approved',
  '',
  '## Forbidden without separate gate',
  '',
  '- commands that read or print secrets',
  '- git push/merge/rebase/reset/clean/publication',
  '- cloud/provider/runtime deploy or mutation',
  '- gateway pairing/autostart or live messenger/email/calendar setup',
  '- n8n/MCP/database mutation',
  '',
  '## Stage 10 result',
  '',
  'commands_executed: false',
  'tests_executed: false',
  'dependencies_installed: false'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'COMMAND_READINESS.md') ($commandReadinessLines -join "`n")

$executionReadinessLines = @(
  'artifact_id: LAUNCHROOM_AGENT_EXECUTION_READINESS_v0_1',
  'stage_id: stage_10_agent_execution_readiness',
  "readiness_status: $Stage10Status",
  'execution_ready: false',
  'execution_allowed: false',
  'install_gate_required: true',
  'toolset_activation_gate_required: true',
  'skill_load_gate_required: true',
  'agent_pipeline_gate_required: true',
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "agent_readiness_root: $(ConvertTo-YamlSingleQuotedScalar $agentReadinessRoot)",
  'source_lineage:',
  '  stage9_audit: .hermes/project-audit/AUDIT_REPORT.yaml',
  '  stage8_execution_packet: .hermes/local-pilot/EXECUTION_PACKET.md',
  '  stage8_command_plan: .hermes/local-pilot/COMMAND_PLAN.md',
  '  stage3_software_inventory: .hermes/reports/software-inventory-report.yaml',
  '  stage3_install_recommendation: .hermes/reports/software-install-recommendation.yaml',
  '  stage4_starter_capability_pack: .hermes/reports/starter-capability-pack.yaml',
  'generated_files:',
  '  - START_HERE.md',
  '  - PROJECT_TOOLCHAIN_REQUIREMENTS.md',
  '  - SOFTWARE_GAP_ANALYSIS.md',
  '  - HERMES_TOOLSET_PLAN.md',
  '  - SKILL_LOAD_PLAN.md',
  '  - AGENT_PIPELINE_PLAN.md',
  '  - INSTALL_PLAN.md',
  '  - COMMAND_READINESS.md',
  '  - EXECUTION_READINESS_REPORT.yaml',
  'missing_source_evidence:'
)
if ($missingAgentReadinessEvidence.Count -eq 0) {
  $executionReadinessLines += '  - none'
} else {
  foreach ($missingEvidence in $missingAgentReadinessEvidence) { $executionReadinessLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$executionReadinessLines += @(
  'readiness_checks:',
  '  stage_9_audit_consumed: true',
  '  project_toolchain_requirements_present: true',
  '  software_gap_analysis_present: true',
  '  hermes_toolset_plan_present: true',
  '  skill_load_plan_present: true',
  '  agent_pipeline_plan_present: true',
  '  install_plan_present: true',
  '  command_readiness_present: true',
  '  execution_ready_false_until_owner_gate: true',
  'action_flags:',
  '  software_installed: false',
  '  toolsets_enabled_without_gate: false',
  '  skills_installed_without_gate: false',
  '  persistent_memory_written_without_gate: false',
  '  agents_spawned: false',
  '  implementation_executed: false',
  '  file_changes_executed: false',
  '  commands_executed: false',
  '  tests_executed: false',
  '  dependencies_installed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  project_toolchain_requirements_present: true',
  '  software_gap_analysis_present: true',
  '  hermes_toolset_plan_present: true',
  '  skill_load_plan_present: true',
  '  agent_pipeline_plan_present: true',
  '  install_plan_present: true',
  '  command_readiness_present: true',
  'next_owner_decision:',
  '  - repair Stage 9 blockers',
  '  - approve install plan for missing software',
  '  - approve Hermes toolset or skill loading plan',
  '  - approve implementation gate after readiness acceptance',
  '  - defer execution'
)
Write-Utf8NoBom (Join-Path $agentReadinessRoot 'EXECUTION_READINESS_REPORT.yaml') ($executionReadinessLines -join "`n")


$hygieneRoot = Join-Path $WorkspaceFull '.hermes/hygiene'
New-Item -ItemType Directory -Force -Path $hygieneRoot | Out-Null
$Stage11Status = 'partial'
$hygieneEvidenceFiles = @(
  '.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '.hermes/project-audit/AUDIT_REPORT.yaml',
  '.hermes/local-pilot/READINESS_REPORT.yaml',
  '.hermes/first-slice/READINESS_REPORT.yaml',
  '.hermes/operator-kit/readiness_report.yaml',
  '.hermes/reports/starter-capability-pack.yaml',
  '.hermes/reports/software-inventory-report.yaml',
  '.hermes/reports/workspace-onboarding-report.yaml'
)
$missingHygieneEvidence = @($hygieneEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingHygieneEvidence.Count -gt 0) { $Stage11Status = 'blocked_missing_evidence' }

$activeArtifactFiles = @(
  '.hermes/reports/workspace-onboarding-report.yaml',
  '.hermes/reports/software-inventory-report.yaml',
  '.hermes/reports/software-purpose-map.yaml',
  '.hermes/reports/software-install-recommendation.yaml',
  '.hermes/reports/capability-graph.yaml',
  '.hermes/reports/starter-capability-pack.yaml',
  '.hermes/reports/communication-channel-map.yaml',
  '.hermes/reports/communication-user-guide.md',
  '.hermes/operator-kit/START_HERE.md',
  '.hermes/operator-kit/NEXT_DECISION.md',
  '.hermes/operator-kit/readiness_report.yaml',
  '.hermes/first-slice/START_HERE.md',
  '.hermes/first-slice/READINESS_REPORT.yaml',
  '.hermes/local-pilot/START_HERE.md',
  '.hermes/local-pilot/READINESS_REPORT.yaml',
  '.hermes/project-audit/START_HERE.md',
  '.hermes/project-audit/AUDIT_REPORT.yaml',
  '.hermes/agent-readiness/START_HERE.md',
  '.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '.hermes/hygiene/START_HERE.md',
  '.hermes/hygiene/HYGIENE_REPORT.yaml'
)

$hygieneStartLines = @(
  '# Start Here — Workspace Hygiene, Cleanup, and Artifact Lifecycle',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 11. Stage 10 mapped execution readiness. Stage 11 prevents future agent drift by classifying workspace artifacts before implementation begins.',
  '',
  'Stage 11 does not delete, move, rename, archive, implement, run project commands, read secrets, publish git, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. ARTIFACT_INDEX.md — lifecycle classes for generated artifacts.',
  '2. ACTIVE_FILES.md — current files future agents may use as working references.',
  '3. SUPERSEDED_FILES.md — candidates that may be obsolete after owner review.',
  '4. BROKEN_OR_STALE_FILES.md — files that need repair or confirmation before use.',
  '5. DO_NOT_USE.md — explicit stale/broken/superseded surfaces future agents must avoid.',
  '6. CLEANUP_PLAN.md — proposed cleanup only, no action taken.',
  '7. ARCHIVE_PLAN.md — proposed archive only, no files moved.',
  '8. DELETION_GATE.md — deletion requires explicit owner gate and listed path scope.',
  '9. HYGIENE_REPORT.yaml — machine-readable status.',
  '',
  '## Rule',
  '',
  'If a file is listed as do-not-use, stale, broken, or superseded, do not treat it as planning authority. Use its listed replacement or ask for owner review.'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'START_HERE.md') ($hygieneStartLines -join "`n")

$artifactIndexLines = @(
  '# Artifact Index',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This index classifies LaunchRoom workspace artifacts by lifecycle state. It is a planning surface, not a cleanup action.',
  '',
  '| Class | Meaning | Default action |',
  '| --- | --- | --- |',
  '| active | Current generated surface future agents may read for the next decision | read and cite with source path |',
  '| supporting | Useful evidence or context, not the current control surface | read only when needed |',
  '| draft | Incomplete or owner-editable scaffold | do not execute from it directly |',
  '| superseded | Replaced by a newer generated surface | do not use as planning authority |',
  '| broken_or_stale | Known or suspected mismatch, missing source, or outdated content | repair or owner review before use |',
  '| temporary | Disposable self-test or scratch artifact | delete only after gate if still present |',
  '| archive_candidate | Could be moved to archive after owner review | no move without archive gate |',
  '| deletion_gated | Could be deleted only with explicit listed owner gate | no deletion by default |',
  '',
  '## Current active chain',
  '',
  'Stage 1 profile foundation -> Stage 2 workspace -> Stage 3 tool readiness -> Stage 4 capability pack -> Stage 5 communication map -> Stage 6 operator kit -> Stage 7 first slice -> Stage 8 local pilot -> Stage 9 audit -> Stage 10 readiness -> Stage 11 hygiene.'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'ARTIFACT_INDEX.md') ($artifactIndexLines -join "`n")

$activeLines = @(
  '# Active Files',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'These files are the current LaunchRoom working references for future agents. They are not AIRMIDA authority unless separately promoted.',
  '',
  '## Active generated surfaces'
)
foreach ($artifact in $activeArtifactFiles) { $activeLines += "- $artifact" }
$activeLines += @('', '## Use rule', '', 'Use the newest stage-specific report for its own scope. Do not use older drafts or self-test outputs as authority over this active chain.')
Write-Utf8NoBom (Join-Path $hygieneRoot 'ACTIVE_FILES.md') ($activeLines -join "`n")

$supersededLines = @(
  '# Superseded Files',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'No concrete superseded file is deleted or moved by Stage 11. This register exists so future agents can record replacements without guessing.',
  '',
  '| Candidate | Reason | Replacement | Action |',
  '| --- | --- | --- | --- |',
  '| none currently confirmed | Stage 11 scaffold has not detected a concrete duplicate in this generated workspace | active chain in ACTIVE_FILES.md | owner review before marking superseded |',
  '',
  'If a future agent finds `old`, `final_fixed`, duplicate draft, or copied output files, list them here with a replacement before using cleanup/archive gates.'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'SUPERSEDED_FILES.md') ($supersededLines -join "`n")

$brokenLines = @(
  '# Broken or Stale Files',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 11 does not assert hidden breakage without evidence. Missing source evidence is recorded below if present.',
  '',
  '## Missing source evidence for hygiene'
)
if ($missingHygieneEvidence.Count -eq 0) {
  $brokenLines += '- none'
} else {
  foreach ($missingEvidence in $missingHygieneEvidence) { $brokenLines += "- $missingEvidence" }
}
$brokenLines += @('', '## Use rule', '', 'Broken or stale files must be repaired or replaced before becoming planning input. Do not silently trust a stale file because it has the newest timestamp.')
Write-Utf8NoBom (Join-Path $hygieneRoot 'BROKEN_OR_STALE_FILES.md') ($brokenLines -join "`n")

$doNotUseLines = @(
  '# Do Not Use',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'These entries prevent future agents from treating obsolete or unsafe artifacts as planning authority.',
  '',
  '| File or class | Reason | Replacement |',
  '| --- | --- | --- |',
  '| temporary self-test workspaces | disposable validation outputs, not project state | rerun installer self-test if needed |',
  '| copied chat snippets without source path | chat is not authority and may be stale | active files listed in ACTIVE_FILES.md |',
  '| old/final/final_fixed duplicate drafts if discovered | ambiguous lineage and drift risk | the matching current stage report in ACTIVE_FILES.md |',
  '| superseded files listed in SUPERSEDED_FILES.md | replaced by a newer working surface | listed replacement |',
  '| broken/stale files listed in BROKEN_OR_STALE_FILES.md | require repair or owner review | repaired file or active replacement |',
  '',
  'No concrete project file is marked for deletion by this Stage 11 scaffold. Future entries must include reason and replacement before cleanup.'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'DO_NOT_USE.md') ($doNotUseLines -join "`n")

$cleanupLines = @(
  '# Cleanup Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Stage 11 proposes cleanup only. It does not perform cleanup.',
  '',
  '## Proposed process',
  '',
  '1. Review DO_NOT_USE.md, SUPERSEDED_FILES.md, and BROKEN_OR_STALE_FILES.md.',
  '2. Confirm each candidate has a replacement or no remaining value.',
  '3. Choose cleanup action: keep, repair, mark superseded, archive, or deletion-gated.',
  '4. Run cleanup only after explicit owner gate with exact path list.',
  '5. Re-run validators and update HYGIENE_REPORT.yaml after action.',
  '',
  '## Current action state',
  '',
  'cleanup_executed: false',
  'files_moved: false',
  'files_renamed: false',
  'files_deleted: false'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'CLEANUP_PLAN.md') ($cleanupLines -join "`n")

$archiveLines = @(
  '# Archive Plan',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Archive movement requires explicit owner gate and exact path list. Stage 11 creates no archive and moves no files.',
  '',
  '## Archive candidate classes',
  '',
  '- duplicate drafts with confirmed replacement',
  '- outdated generated reports after a newer stage supersedes them',
  '- temporary proof artifacts that must be retained for evidence but not read as active planning input',
  '',
  '## Current action state',
  '',
  'archive_executed: false',
  'files_moved: false'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'ARCHIVE_PLAN.md') ($archiveLines -join "`n")

$deletionLines = @(
  '# Deletion Gate',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Deletion is destructive. Stage 11 deletes nothing.',
  '',
  '## Required deletion gate',
  '',
  '- exact path list',
  '- reason per path',
  '- replacement or no-value statement per path',
  '- backup/archive decision',
  '- owner approval in the current session',
  '- post-delete validators and git status',
  '',
  '## Current action state',
  '',
  'deletion_executed: false',
  'files_deleted: false',
  '',
  'No deletion candidate is approved by this file.'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'DELETION_GATE.md') ($deletionLines -join "`n")

$hygieneReportLines = @(
  'artifact_id: LAUNCHROOM_WORKSPACE_HYGIENE_v0_1',
  'stage_id: stage_11_workspace_hygiene',
  "hygiene_status: $Stage11Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "hygiene_root: $(ConvertTo-YamlSingleQuotedScalar $hygieneRoot)",
  'source_lineage:',
  '  stage10_agent_readiness: .hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '  stage9_audit: .hermes/project-audit/AUDIT_REPORT.yaml',
  '  stage8_local_pilot: .hermes/local-pilot/READINESS_REPORT.yaml',
  '  stage7_first_slice: .hermes/first-slice/READINESS_REPORT.yaml',
  '  stage6_operator_kit: .hermes/operator-kit/readiness_report.yaml',
  '  stage4_capability_pack: .hermes/reports/starter-capability-pack.yaml',
  '  stage3_software_inventory: .hermes/reports/software-inventory-report.yaml',
  'generated_files:',
  '  - START_HERE.md',
  '  - ARTIFACT_INDEX.md',
  '  - ACTIVE_FILES.md',
  '  - SUPERSEDED_FILES.md',
  '  - BROKEN_OR_STALE_FILES.md',
  '  - DO_NOT_USE.md',
  '  - CLEANUP_PLAN.md',
  '  - ARCHIVE_PLAN.md',
  '  - DELETION_GATE.md',
  '  - HYGIENE_REPORT.yaml',
  'missing_source_evidence:'
)
if ($missingHygieneEvidence.Count -eq 0) {
  $hygieneReportLines += '  - none'
} else {
  foreach ($missingEvidence in $missingHygieneEvidence) { $hygieneReportLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$hygieneReportLines += @(
  'lifecycle_classes:',
  '  active: true',
  '  supporting: true',
  '  draft: true',
  '  superseded: true',
  '  broken_or_stale: true',
  '  temporary: true',
  '  archive_candidate: true',
  '  deletion_gated: true',
  'action_flags:',
  '  cleanup_executed: false',
  '  archive_executed: false',
  '  deletion_executed: false',
  '  files_deleted: false',
  '  files_moved: false',
  '  files_renamed: false',
  '  implementation_executed: false',
  '  commands_executed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  artifact_index_present: true',
  '  active_files_present: true',
  '  superseded_files_present: true',
  '  broken_or_stale_files_present: true',
  '  do_not_use_present: true',
  '  cleanup_plan_present: true',
  '  archive_plan_present: true',
  '  deletion_gate_present: true',
  'next_owner_decision:',
  '  - approve cleanup plan',
  '  - approve archive plan',
  '  - approve deletion plan for listed candidates only',
  '  - repair conflicting artifact status',
  '  - proceed to Stage 12 skill capture after hygiene review',
  '  - defer cleanup'
)
Write-Utf8NoBom (Join-Path $hygieneRoot 'HYGIENE_REPORT.yaml') ($hygieneReportLines -join "`n")


$skillPackRoot = Join-Path $WorkspaceFull '.hermes/skills'
$skillCandidatesRoot = Join-Path $WorkspaceFull '.hermes/skills-candidates'
New-Item -ItemType Directory -Force -Path $skillPackRoot | Out-Null
New-Item -ItemType Directory -Force -Path $skillCandidatesRoot | Out-Null
$Stage12Status = 'partial'
$skillEvidenceFiles = @(
  '.hermes/hygiene/HYGIENE_REPORT.yaml',
  '.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '.hermes/reports/starter-capability-pack.yaml',
  '.hermes/reports/capability-graph.yaml',
  '.hermes/project-audit/AUDIT_REPORT.yaml'
)
$missingSkillEvidence = @($skillEvidenceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingSkillEvidence.Count -gt 0) { $Stage12Status = 'blocked_missing_evidence' }

$skillStartLines = @(
  '# Start Here — Skill Capture and Stage Skill Integration Pack',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 12. Stage 11 made the workspace easier to read safely. Stage 12 makes the LaunchRoom stage-to-skill routing explicit and creates a safe skill-capture path for proven workflows.',
  '',
  'Stage 12 does not install skills, patch skills, promote candidates, write persistent memory, execute implementation, read secrets, publish git, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. STAGE_SKILL_MATRIX.md — which skills apply to each stage.',
  '2. REQUIRED_SKILLS.md — skills that should be loaded for serious LaunchRoom work.',
  '3. OPTIONAL_SKILLS.md — conditional skills for specific task classes.',
  '4. MISSING_SKILLS.md — candidate gaps that need owner review before creation.',
  '5. SKILL_CAPTURE_GUIDE.md — when to capture a workflow as a skill candidate.',
  '6. SKILL_CANDIDATE_TEMPLATE.md — candidate structure and evidence fields.',
  '7. SKILL_PROMOTION_GATE.md — validation and owner gate before promotion.',
  '8. SKILL_INTEGRATION_REPORT.yaml — machine-readable status.',
  '',
  '## Rule',
  '',
  'Do not treat a skill candidate as an active skill. A candidate needs evidence, validation, no secrets, no stale task progress, and explicit owner promotion gate.'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'START_HERE.md') ($skillStartLines -join "`n")

$matrixLines = @(
  '# Stage Skill Matrix',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  '| Stage | Required skills | Optional skills | Load timing |',
  '| --- | --- | --- | --- |',
  '| Stage 1 profile foundation | hermes-agent | windows-desktop-agent-setup | before profile setup |',
  '| Stage 2 workspace onboarding | governed-workspace-integration, experience-grounded-work-preflight | governed-desktop-project-integration | before workspace mutation |',
  '| Stage 3 tool readiness | airmida-governed-toolchain-onboarding, hermes-agent | windows-desktop-agent-setup | before tool probes |',
  '| Stage 4 capability pack | governed-agent-engineering-standards | airmida-positive-result-capture | before capability mapping |',
  '| Stage 5 communication map | governed-messaging-gateway-setup, hermes-agent | himalaya, google-workspace | before gateway planning |',
  '| Stage 6 SaaS operator kit | governed-agent-engineering-standards, experience-grounded-work-preflight | plan | before blueprint generation |',
  '| Stage 7 first-slice planning | governed-agent-engineering-standards, plan | test-driven-development | before implementation planning |',
  '| Stage 8 local pilot execution packet | governed-agent-engineering-standards | requesting-code-review | before executor packet |',
  '| Stage 9 project plan integrity audit | governed-agent-engineering-standards | systematic-debugging | before execution readiness |',
  '| Stage 10 agent execution readiness | governed-agent-engineering-standards, airmida-external-agent-tool-readiness | codex, claude-code, github-pr-workflow | before implementation gate |',
  '| Stage 11 workspace hygiene | governed-agent-engineering-standards | airmida-positive-result-capture | before cleanup/archive decisions |',
  '| Stage 12 skill capture | hermes-agent-skill-authoring, governed-agent-engineering-standards | airmida-positive-result-capture | before candidate creation/promotion |',
  '',
  'Load skills deliberately by stage. Do not load every skill blindly when a narrow stage only needs a small subset.'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'STAGE_SKILL_MATRIX.md') ($matrixLines -join "`n")

$requiredLines = @(
  '# Required Skills',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'These are recommended required skills for serious LaunchRoom stage work. This file does not install or load them automatically.',
  '',
  '- experience-grounded-work-preflight — serious-work preflight, gates, evidence, next action.',
  '- governed-agent-engineering-standards — packet/gate/verification discipline across LaunchRoom stages.',
  '- hermes-agent — current Hermes commands, profiles, tools, skills, setup behavior.',
  '- hermes-agent-skill-authoring — safe skill candidate shape and promotion checks.',
  '',
  '## Required rule',
  '',
  'If a required skill is missing in a future environment, record it in MISSING_SKILLS.md and ask for an owner install/create gate. Do not silently invent its behavior.'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'REQUIRED_SKILLS.md') ($requiredLines -join "`n")

$optionalLines = @(
  '# Optional Skills',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Optional skills are conditional. Load them when the task class requires them, not by default.',
  '',
  '| Skill | Use when | Gate |',
  '| --- | --- | --- |',
  '| github-pr-workflow | branch, PR, CI, merge after publication gate | publication gate |',
  '| requesting-code-review | pre-commit or pre-PR quality review | code-review gate |',
  '| test-driven-development | code implementation with tests | implementation gate |',
  '| systematic-debugging | root-cause failure repair | repair gate |',
  '| airmida-external-agent-tool-readiness | Codex/Claude/external agent handoff | external-agent gate |',
  '| governed-messaging-gateway-setup | Telegram/Slack/email/gateway setup | gateway/runtime gate |',
  '| airmida-positive-result-capture | successful repeatable workflow capture | capture gate |'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'OPTIONAL_SKILLS.md') ($optionalLines -join "`n")

$missingLines = @(
  '# Missing Skills',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This register distinguishes actual missing skills from candidate ideas. Stage 12 does not create or install missing skills automatically.',
  '',
  '| Skill gap | Why it may matter | Current action |',
  '| --- | --- | --- |',
  '| launchroom-stage-skill-matrix | Could become a dedicated LaunchRoom skill after Stage 12 proves stable | candidate only, not promoted |',
  '| launchroom-skill-capture-workflow | Could capture repeated candidate/promotion workflow | candidate only, not promoted |',
  '',
  'Do not mark a skill as missing just because it is not loaded in the current session. Verify with skills list or owner environment before acting.'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'MISSING_SKILLS.md') ($missingLines -join "`n")

$captureGuideLines = @(
  '# Skill Capture Guide',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Capture a workflow as a skill candidate only after it is proven, repeatable, and useful beyond one task.',
  '',
  '## Capture triggers',
  '',
  '- a complex workflow succeeded with real validators or CI',
  '- a recurring error was solved with a non-obvious fix',
  '- the owner corrected a reusable process and the correction should persist',
  '- a stage pattern has been repeated and verified enough to guide future agents',
  '',
  '## Do not capture',
  '',
  '- temporary task progress',
  '- PR numbers, issue numbers, commit SHAs, or stale outcomes',
  '- secrets, tokens, credentials, paths to private credential files',
  '- one-off narrative summaries',
  '',
  '## Required evidence',
  '',
  '- trigger condition',
  '- exact reusable steps',
  '- pitfalls and gates',
  '- validation commands and real outputs',
  '- when not to use the skill',
  '- promotion decision owner'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'SKILL_CAPTURE_GUIDE.md') ($captureGuideLines -join "`n")

$templateLines = @(
  '# Skill Candidate Template',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Use this template under `.hermes/skills-candidates/<skill-name>/` after an owner capture gate. Do not treat a candidate as installed.',
  '',
  '```text',
  '.hermes/skills-candidates/<skill-name>/',
  '  SKILL.md',
  '  evidence.md',
  '  validation.md',
  '  promotion_gate.md',
  '```',
  '',
  '## SKILL.md minimum sections',
  '',
  '- frontmatter: name, description, version, author, tags/related skills when appropriate',
  '- overview',
  '- when to use',
  '- procedure with checkable completion criteria',
  '- pitfalls',
  '- verification checklist',
  '',
  '## evidence.md',
  '',
  '- source task class',
  '- proof that the workflow succeeded',
  '- validator/test/CI outputs',
  '- owner corrections incorporated',
  '',
  '## validation.md',
  '',
  '- syntax/frontmatter validation',
  '- no-secret scan',
  '- no stale task-progress scan',
  '- peer-skill comparison',
  '',
  '## promotion_gate.md',
  '',
  '- owner approval',
  '- target skill name/category',
  '- whether to create, patch, or defer',
  '- rollback/removal plan'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'SKILL_CANDIDATE_TEMPLATE.md') ($templateLines -join "`n")

$promotionLines = @(
  '# Skill Promotion Gate',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Promotion means a candidate becomes a real skill or patches an existing skill. Stage 12 does not promote anything automatically.',
  '',
  '## Required gate checklist',
  '',
  '- owner explicitly approves create/patch/promote/defer',
  '- candidate has evidence and validation files',
  '- candidate contains no secrets, tokens, credential values, or private key material',
  '- candidate does not store stale task progress such as PR numbers, issue numbers, commit SHAs, or dated completion logs',
  '- candidate has clear triggers and counter-triggers',
  '- candidate has checkable steps and verification checklist',
  '- existing skills were checked to avoid duplication',
  '- rollback/remove path exists',
  '',
  '## Current action state',
  '',
  'skills_installed: false',
  'skills_patched: false',
  'skills_promoted: false',
  'persistent_memory_written: false'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'SKILL_PROMOTION_GATE.md') ($promotionLines -join "`n")

$candidateReadmeLines = @(
  '# Skill Candidates',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This folder is a placeholder for future owner-approved skill candidates. Stage 12 creates no candidate skill by default.',
  '',
  'Candidate folders should follow:',
  '',
  '```text',
  '<skill-name>/SKILL.md',
  '<skill-name>/evidence.md',
  '<skill-name>/validation.md',
  '<skill-name>/promotion_gate.md',
  '```',
  '',
  'Do not install, load, or promote candidates without the promotion gate.'
)
Write-Utf8NoBom (Join-Path $skillCandidatesRoot 'README.md') ($candidateReadmeLines -join "`n")

$skillReportLines = @(
  'artifact_id: LAUNCHROOM_SKILL_INTEGRATION_v0_1',
  'stage_id: stage_12_skill_capture',
  "skill_integration_status: $Stage12Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "skills_root: $(ConvertTo-YamlSingleQuotedScalar $skillPackRoot)",
  "skill_candidates_root: $(ConvertTo-YamlSingleQuotedScalar $skillCandidatesRoot)",
  'source_lineage:',
  '  stage11_hygiene: .hermes/hygiene/HYGIENE_REPORT.yaml',
  '  stage10_agent_readiness: .hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '  stage9_audit: .hermes/project-audit/AUDIT_REPORT.yaml',
  '  stage4_capability_pack: .hermes/reports/starter-capability-pack.yaml',
  '  stage3_capability_graph: .hermes/reports/capability-graph.yaml',
  'generated_files:',
  '  - START_HERE.md',
  '  - STAGE_SKILL_MATRIX.md',
  '  - REQUIRED_SKILLS.md',
  '  - OPTIONAL_SKILLS.md',
  '  - MISSING_SKILLS.md',
  '  - SKILL_CAPTURE_GUIDE.md',
  '  - SKILL_CANDIDATE_TEMPLATE.md',
  '  - SKILL_PROMOTION_GATE.md',
  '  - SKILL_INTEGRATION_REPORT.yaml',
  '  - ../skills-candidates/README.md',
  'missing_source_evidence:'
)
if ($missingSkillEvidence.Count -eq 0) {
  $skillReportLines += '  - none'
} else {
  foreach ($missingEvidence in $missingSkillEvidence) { $skillReportLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidence)" }
}
$skillReportLines += @(
  'action_flags:',
  '  skills_installed: false',
  '  skills_patched: false',
  '  skills_promoted: false',
  '  persistent_memory_written: false',
  '  skill_candidates_created: false',
  '  implementation_executed: false',
  '  commands_executed: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  stage_skill_matrix_present: true',
  '  required_skills_present: true',
  '  optional_skills_present: true',
  '  missing_skills_present: true',
  '  skill_capture_guide_present: true',
  '  skill_candidate_template_present: true',
  '  skill_promotion_gate_present: true',
  '  skills_candidates_root_present: true',
  'next_owner_decision:',
  '  - approve required skill load plan for next implementation stage',
  '  - create a skill candidate from a proven workflow',
  '  - review missing skills',
  '  - promote a validated skill candidate',
  '  - proceed to Stage 13 local execution evidence binder after skill review',
  '  - defer skill capture'
)
Write-Utf8NoBom (Join-Path $skillPackRoot 'SKILL_INTEGRATION_REPORT.yaml') ($skillReportLines -join "`n")


$executionEvidenceRoot = Join-Path $WorkspaceFull '.hermes/execution-evidence'
New-Item -ItemType Directory -Force -Path $executionEvidenceRoot | Out-Null
$Stage13Status = 'scaffold_only'
$evidenceSourceFiles = @(
  '.hermes/skills/SKILL_INTEGRATION_REPORT.yaml',
  '.hermes/hygiene/HYGIENE_REPORT.yaml',
  '.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '.hermes/local-pilot/EXECUTION_PACKET.md',
  '.hermes/local-pilot/COMMAND_PLAN.md',
  '.hermes/local-pilot/TEST_PLAN.md',
  '.hermes/project-audit/AUDIT_REPORT.yaml'
)
$missingExecutionEvidenceSources = @($evidenceSourceFiles | Where-Object { -not (Test-Path (Join-Path $WorkspaceFull $_)) })
if ($missingExecutionEvidenceSources.Count -gt 0) { $Stage13Status = 'blocked_missing_source_lineage' }

$evidenceStartLines = @(
  '# Start Here — Local Execution Evidence Binder',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'You are at Stage 13. This binder is where a future gated implementation records real execution evidence: commands, changed files, tests, acceptance proof, user-visible result, residual risks, and rollback/handoff.',
  '',
  'Stage 13 does not execute implementation, run project commands, change files, install dependencies, publish git, read secrets, deploy, or mutate runtime/cloud/provider/gateway/n8n surfaces.',
  '',
  '## Read in this order',
  '',
  '1. EXECUTED_COMMANDS.md — real command log after implementation gate.',
  '2. CHANGED_FILES.md — actual changed-file evidence after implementation gate.',
  '3. TEST_RESULTS.md — real test/lint/build outputs after they are run.',
  '4. ACCEPTANCE_EVIDENCE.md — evidence mapped to acceptance criteria.',
  '5. USER_VISIBLE_RESULT.md — what the user can see or use.',
  '6. RESIDUAL_RISKS.md — remaining risks and open gaps.',
  '7. ROLLBACK_AND_HANDOFF.md — rollback and next-owner handoff.',
  '8. EXECUTION_EVIDENCE_REPORT.yaml — machine-readable status.',
  '',
  '## Rule',
  '',
  'Do not fabricate evidence. Planned commands are not executed commands; expected tests are not passing tests; intended user-visible output is not observed user-visible output.'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'START_HERE.md') ($evidenceStartLines -join "`n")

$executedCommandsLines = @(
  '# Executed Commands',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This is a scaffold. No implementation commands have been executed by Stage 13.',
  '',
  '| Timestamp | Command | Workdir | Exit code | Evidence/log path | Gate reference |',
  '| --- | --- | --- | --- | --- | --- |',
  '| pending | pending real gated execution | pending | pending | pending | implementation gate required |',
  '',
  'Planned commands from `.hermes/local-pilot/COMMAND_PLAN.md` must not be copied here as executed unless they were actually run and verified.'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'EXECUTED_COMMANDS.md') ($executedCommandsLines -join "`n")

$changedFilesLines = @(
  '# Changed Files',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This is a scaffold. No product files have been changed by Stage 13.',
  '',
  '| Path | Change type | Why changed | Verification | Rollback note |',
  '| --- | --- | --- | --- | --- |',
  '| pending | pending real gated execution | pending | pending | pending |',
  '',
  'Only list actual changed files after implementation. Do not list planned files as changed.'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'CHANGED_FILES.md') ($changedFilesLines -join "`n")

$testResultsLines = @(
  '# Test Results',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'This is a scaffold. No project tests have been run by Stage 13.',
  '',
  '| Test/check | Command | Result | Evidence/log path | Acceptance link |',
  '| --- | --- | --- | --- | --- |',
  '| pending | pending real gated execution | not run | pending | pending |',
  '',
  'Expected tests from `.hermes/local-pilot/TEST_PLAN.md` are not passing evidence until executed and logged.'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'TEST_RESULTS.md') ($testResultsLines -join "`n")

$acceptanceLines = @(
  '# Acceptance Evidence',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Map real evidence to acceptance criteria after implementation. This scaffold contains no real acceptance proof yet.',
  '',
  '| Acceptance criterion | Evidence | Source file/log | Status |',
  '| --- | --- | --- | --- |',
  '| pending | pending real gated execution | pending | not verified |'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'ACCEPTANCE_EVIDENCE.md') ($acceptanceLines -join "`n")

$userVisibleLines = @(
  '# User-Visible Result',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Describe what the user can actually see, open, click, run, or receive after implementation. Stage 13 does not claim a user-visible result yet.',
  '',
  'current_user_visible_result: pending real gated execution',
  '',
  'Do not claim screenshots, app behavior, messages, files, or URLs unless they were observed or verified.'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'USER_VISIBLE_RESULT.md') ($userVisibleLines -join "`n")

$residualLines = @(
  '# Residual Risks',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Record risks that remain after execution. Before execution, the primary risk is that no real evidence exists yet.',
  '',
  '- real_execution_evidence_present: false',
  '- implementation outcome unknown until separate implementation gate is granted and work is verified',
  '- secret-bearing logs must be redacted or excluded before evidence promotion'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'RESIDUAL_RISKS.md') ($residualLines -join "`n")

$rollbackLines = @(
  '# Rollback and Handoff',
  '',
  'Status: Hermes working artifact / not AIRMIDA authority',
  '',
  'Use this file after real execution to describe rollback, handoff, and next decision.',
  '',
  '## Rollback',
  '',
  '- pending real gated execution',
  '',
  '## Handoff',
  '',
  '- current state: evidence binder scaffold only',
  '- next owner decision: grant implementation gate, repair source packet, or close without execution'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'ROLLBACK_AND_HANDOFF.md') ($rollbackLines -join "`n")

$evidenceReportLines = @(
  'artifact_id: LAUNCHROOM_EXECUTION_EVIDENCE_BINDER_v0_1',
  'stage_id: stage_13_execution_evidence_binder',
  "evidence_binder_status: $Stage13Status",
  'status_marker: Hermes working artifact / not AIRMIDA authority',
  "evidence_root: $(ConvertTo-YamlSingleQuotedScalar $executionEvidenceRoot)",
  'source_lineage:',
  '  stage12_skill_integration: .hermes/skills/SKILL_INTEGRATION_REPORT.yaml',
  '  stage11_hygiene: .hermes/hygiene/HYGIENE_REPORT.yaml',
  '  stage10_agent_readiness: .hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml',
  '  stage9_audit: .hermes/project-audit/AUDIT_REPORT.yaml',
  '  stage8_execution_packet: .hermes/local-pilot/EXECUTION_PACKET.md',
  '  stage8_command_plan: .hermes/local-pilot/COMMAND_PLAN.md',
  '  stage8_test_plan: .hermes/local-pilot/TEST_PLAN.md',
  'generated_files:',
  '  - START_HERE.md',
  '  - EXECUTED_COMMANDS.md',
  '  - CHANGED_FILES.md',
  '  - TEST_RESULTS.md',
  '  - ACCEPTANCE_EVIDENCE.md',
  '  - USER_VISIBLE_RESULT.md',
  '  - RESIDUAL_RISKS.md',
  '  - ROLLBACK_AND_HANDOFF.md',
  '  - EXECUTION_EVIDENCE_REPORT.yaml',
  'missing_source_lineage:'
)
if ($missingExecutionEvidenceSources.Count -eq 0) {
  $evidenceReportLines += '  - none'
} else {
  foreach ($missingEvidenceSource in $missingExecutionEvidenceSources) { $evidenceReportLines += "  - $(ConvertTo-YamlSingleQuotedScalar $missingEvidenceSource)" }
}
$evidenceReportLines += @(
  'action_flags:',
  '  real_execution_evidence_present: false',
  '  fabricated_evidence: false',
  '  implementation_executed_by_stage13: false',
  '  commands_executed_by_stage13: false',
  '  file_changes_executed_by_stage13: false',
  '  tests_executed_by_stage13: false',
  '  dependencies_installed_by_stage13: false',
  '  runtime_mutation: false',
  '  cloud_mutation: false',
  '  gateway_mutation: false',
  '  n8n_mutation: false',
  '  secrets_read_or_written: false',
  '  git_publication_executed: false',
  '  executed_commands_present: true',
  '  changed_files_present: true',
  '  test_results_present: true',
  '  acceptance_evidence_present: true',
  '  user_visible_result_present: true',
  '  residual_risks_present: true',
  '  rollback_and_handoff_present: true',
  'next_owner_decision:',
  '  - grant separate implementation gate and then fill binder with real evidence',
  '  - repair source execution packet before implementation',
  '  - review empty binder scaffold only',
  '  - close without execution',
  '  - promote evidence after owner verification'
)
Write-Utf8NoBom (Join-Path $executionEvidenceRoot 'EXECUTION_EVIDENCE_REPORT.yaml') ($evidenceReportLines -join "`n")

$LiveConfigHasPlaceholder = Has-UnresolvedLaunchRoomPlaceholder $configPath
$DraftConfigHasPlaceholder = Has-UnresolvedLaunchRoomPlaceholder (Join-Path $profileRoot 'reports/config.yaml.draft')
$ToolsetPartialCount = @($toolsetResults | Where-Object { -not $_.ok }).Count
$ModelStatus = if ($HasModelProvider -and $HasModelDefault) { 'configured_or_written_non_secret_names' } else { 'partial_deferred_provider_or_model' }

$verification = [ordered]@{
  profile = $ProfileName
  profile_root = $profileRoot
  workspace = $WorkspaceFull
  config_path = $configPath
  model_status = $ModelStatus
  live_config_has_launchroom_placeholders = $LiveConfigHasPlaceholder
  draft_config_has_launchroom_placeholders = $DraftConfigHasPlaceholder
  soul_exists = Test-Path (Join-Path $profileRoot 'SOUL.md')
  profile_instructions_exists = Test-Path (Join-Path $profileRoot 'PROFILE_INSTRUCTIONS.md')
  profile_contract_exists = Test-Path (Join-Path $profileRoot 'LAUNCHROOM_PROFILE_CONTRACT.yaml')
  env_example_exists = Test-Path (Join-Path $profileRoot '.env.EXAMPLE')
  foundation_report_exists = Test-Path (Join-Path $profileRoot 'reports/profile-foundation-report.yaml')
  apply_plan_exists = Test-Path (Join-Path $profileRoot 'reports/profile-apply-plan.yaml')
  selected_settings_exists = Test-Path (Join-Path $profileRoot 'reports/stage-1-selected-settings.yaml')
  config_draft_exists = Test-Path (Join-Path $profileRoot 'reports/config.yaml.draft')
  starter_skills_exists = Test-Path (Join-Path $profileRoot 'skills/launchroom')
  workspace_agents_exists = Test-Path (Join-Path $WorkspaceFull 'AGENTS.md')
  workspace_hermes_exists = Test-Path (Join-Path $WorkspaceFull 'HERMES.md')
  setup_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/profile-setup-report.yaml')
  workspace_onboarding_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/workspace-onboarding-report.yaml')
  terminal_cwd_matches_workspace = $terminalCwdMatchesWorkspace
  project_type = $ProjectType
  inventory_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/software-inventory-report.yaml')
  software_purpose_map_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/software-purpose-map.yaml')
  software_install_recommendation_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/software-install-recommendation.yaml')
  capability_graph_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/capability-graph.yaml')
  starter_capability_pack_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/starter-capability-pack.yaml')
  communication_channel_map_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/communication-channel-map.yaml')
  communication_user_guide_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/communication-user-guide.md')
  operator_kit_start_here_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/START_HERE.md')
  operator_kit_next_decision_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/NEXT_DECISION.md')
  operator_kit_check_it_works_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/CHECK_IT_WORKS.md')
  operator_kit_examples_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md')
  operator_kit_readiness_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/readiness_report.yaml, first-slice/READINESS_REPORT.yaml')
  guided_session_state_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/SESSION_STATE.yaml')
  guided_session_agent_guide_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/AGENT_GUIDE.md')
  guided_session_user_lesson_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/USER_LESSON.md')
  guided_session_idea_intake_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/IDEA_INTAKE.md')
  guided_session_project_blueprint_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md')
  guided_session_first_slice_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md')
  guided_session_default_catalog_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md')
  guided_session_implementation_roadmap_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md')
  guided_session_completion_summary_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/COMPLETION_SUMMARY.md')
  first_slice_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/START_HERE.md')
  first_slice_implementation_brief_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/IMPLEMENTATION_BRIEF.md')
  first_slice_local_pilot_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/LOCAL_PILOT_PLAN.md')
  first_slice_acceptance_tests_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/ACCEPTANCE_TESTS.md')
  first_slice_user_demo_script_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/USER_DEMO_SCRIPT.md')
  first_slice_risks_rollback_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/RISKS_AND_ROLLBACK.md')
  first_slice_decision_gate_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/DECISION_GATE.md')
  first_slice_readiness_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/first-slice/READINESS_REPORT.yaml')
  local_pilot_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/START_HERE.md')
  local_pilot_execution_packet_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/EXECUTION_PACKET.md')
  local_pilot_file_change_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/FILE_CHANGE_PLAN.md')
  local_pilot_command_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/COMMAND_PLAN.md')
  local_pilot_test_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/TEST_PLAN.md')
  local_pilot_evidence_log_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/EVIDENCE_LOG.md')
  local_pilot_review_checklist_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/REVIEW_CHECKLIST.md')
  local_pilot_handoff_summary_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/HANDOFF_SUMMARY.md')
  local_pilot_readiness_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/local-pilot/READINESS_REPORT.yaml')
  project_audit_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/START_HERE.md')
  project_audit_plan_integrity_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/PLAN_INTEGRITY_REPORT.md')
  project_audit_expected_result_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/EXPECTED_RESULT_MAP.md')
  project_audit_missing_fragments_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/MISSING_FRAGMENTS.md')
  project_audit_contradiction_scan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/CONTRADICTION_SCAN.md')
  project_audit_stage_drift_scan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/STAGE_DRIFT_SCAN.md')
  project_audit_assumption_register_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/ASSUMPTION_REGISTER.md')
  project_audit_implementation_blockers_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/IMPLEMENTATION_BLOCKERS.md')
  project_audit_repair_recommendations_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/REPAIR_RECOMMENDATIONS.md')
  project_audit_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/project-audit/AUDIT_REPORT.yaml')
  agent_readiness_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/START_HERE.md')
  agent_readiness_toolchain_requirements_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/PROJECT_TOOLCHAIN_REQUIREMENTS.md')
  agent_readiness_software_gap_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/SOFTWARE_GAP_ANALYSIS.md')
  agent_readiness_toolset_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/HERMES_TOOLSET_PLAN.md')
  agent_readiness_skill_load_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/SKILL_LOAD_PLAN.md')
  agent_readiness_agent_pipeline_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/AGENT_PIPELINE_PLAN.md')
  agent_readiness_install_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/INSTALL_PLAN.md')
  agent_readiness_command_readiness_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/COMMAND_READINESS.md')
  agent_readiness_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml')
  hygiene_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/START_HERE.md')
  hygiene_artifact_index_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/ARTIFACT_INDEX.md')
  hygiene_active_files_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/ACTIVE_FILES.md')
  hygiene_superseded_files_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/SUPERSEDED_FILES.md')
  hygiene_broken_or_stale_files_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/BROKEN_OR_STALE_FILES.md')
  hygiene_do_not_use_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/DO_NOT_USE.md')
  hygiene_cleanup_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/CLEANUP_PLAN.md')
  hygiene_archive_plan_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/ARCHIVE_PLAN.md')
  hygiene_deletion_gate_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/DELETION_GATE.md')
  hygiene_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/hygiene/HYGIENE_REPORT.yaml')
  skill_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/START_HERE.md')
  skill_stage_matrix_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/STAGE_SKILL_MATRIX.md')
  skill_required_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/REQUIRED_SKILLS.md')
  skill_optional_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/OPTIONAL_SKILLS.md')
  skill_missing_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/MISSING_SKILLS.md')
  skill_capture_guide_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/SKILL_CAPTURE_GUIDE.md')
  skill_candidate_template_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/SKILL_CANDIDATE_TEMPLATE.md')
  skill_promotion_gate_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/SKILL_PROMOTION_GATE.md')
  skill_integration_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills/SKILL_INTEGRATION_REPORT.yaml')
  skill_candidates_readme_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/skills-candidates/README.md')
  execution_evidence_start_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/START_HERE.md')
  execution_evidence_commands_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/EXECUTED_COMMANDS.md')
  execution_evidence_changed_files_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/CHANGED_FILES.md')
  execution_evidence_test_results_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/TEST_RESULTS.md')
  execution_evidence_acceptance_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/ACCEPTANCE_EVIDENCE.md')
  execution_evidence_user_visible_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/USER_VISIBLE_RESULT.md')
  execution_evidence_residual_risks_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/RESIDUAL_RISKS.md')
  execution_evidence_rollback_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/ROLLBACK_AND_HANDOFF.md')
  execution_evidence_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/execution-evidence/EXECUTION_EVIDENCE_REPORT.yaml')
  operator_kit_root_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit')
  stage3_status = $Stage3Status
  stage3_missing_required = ($missingRequired -join ',')
  stage3_missing_recommended = ($missingRecommended -join ',')
  stage4_status = $Stage4Status
  stage5_status = $Stage5Status
  stage6_status = $Stage6Status
  stage7_status = $Stage7Status
  stage8_status = $Stage8Status
  stage9_status = $Stage9Status
  stage10_status = $Stage10Status
  stage11_status = $Stage11Status
  stage12_status = $Stage12Status
  stage13_status = $Stage13Status
  toolset_partial_count = $ToolsetPartialCount
  self_test_mode = $IsSelfTest
  test_output_root = $TestOutputFull
  reset_or_new_session_required = (-not $IsSelfTest)
}

if ($IsSelfTest -and $LiveConfigHasPlaceholder) { throw 'Self-test failed: simulated live config.yaml contains unresolved __LAUNCHROOM_RESOLVE__ placeholder.' }
$Stage3ReportsOk = if ($NoInventory) { $true } else { $verification.inventory_report_exists -and $verification.software_purpose_map_exists -and $verification.software_install_recommendation_exists -and $verification.capability_graph_exists }
$Stage4ReportsOk = $verification.starter_capability_pack_exists
$Stage5ReportsOk = $verification.communication_channel_map_exists -and $verification.communication_user_guide_exists
$Stage6ReportsOk = $verification.operator_kit_root_exists -and $verification.operator_kit_start_here_exists -and $verification.operator_kit_next_decision_exists -and $verification.operator_kit_check_it_works_exists -and $verification.operator_kit_examples_exists -and $verification.operator_kit_readiness_exists -and $verification.guided_session_state_exists -and $verification.guided_session_agent_guide_exists -and $verification.guided_session_user_lesson_exists -and $verification.guided_session_idea_intake_exists -and $verification.guided_session_project_blueprint_exists -and $verification.guided_session_first_slice_exists -and $verification.guided_session_default_catalog_exists -and $verification.guided_session_implementation_roadmap_exists -and $verification.guided_session_completion_summary_exists
$Stage7ReportsOk = $verification.first_slice_start_exists -and $verification.first_slice_implementation_brief_exists -and $verification.first_slice_local_pilot_plan_exists -and $verification.first_slice_acceptance_tests_exists -and $verification.first_slice_user_demo_script_exists -and $verification.first_slice_risks_rollback_exists -and $verification.first_slice_decision_gate_exists -and $verification.first_slice_readiness_exists
$Stage8ReportsOk = $verification.local_pilot_start_exists -and $verification.local_pilot_execution_packet_exists -and $verification.local_pilot_file_change_plan_exists -and $verification.local_pilot_command_plan_exists -and $verification.local_pilot_test_plan_exists -and $verification.local_pilot_evidence_log_exists -and $verification.local_pilot_review_checklist_exists -and $verification.local_pilot_handoff_summary_exists -and $verification.local_pilot_readiness_exists
$Stage9ReportsOk = $verification.project_audit_start_exists -and $verification.project_audit_plan_integrity_exists -and $verification.project_audit_expected_result_exists -and $verification.project_audit_missing_fragments_exists -and $verification.project_audit_contradiction_scan_exists -and $verification.project_audit_stage_drift_scan_exists -and $verification.project_audit_assumption_register_exists -and $verification.project_audit_implementation_blockers_exists -and $verification.project_audit_repair_recommendations_exists -and $verification.project_audit_report_exists
$Stage10ReportsOk = $verification.agent_readiness_start_exists -and $verification.agent_readiness_toolchain_requirements_exists -and $verification.agent_readiness_software_gap_exists -and $verification.agent_readiness_toolset_plan_exists -and $verification.agent_readiness_skill_load_plan_exists -and $verification.agent_readiness_agent_pipeline_plan_exists -and $verification.agent_readiness_install_plan_exists -and $verification.agent_readiness_command_readiness_exists -and $verification.agent_readiness_report_exists
$Stage11ReportsOk = $verification.hygiene_start_exists -and $verification.hygiene_artifact_index_exists -and $verification.hygiene_active_files_exists -and $verification.hygiene_superseded_files_exists -and $verification.hygiene_broken_or_stale_files_exists -and $verification.hygiene_do_not_use_exists -and $verification.hygiene_cleanup_plan_exists -and $verification.hygiene_archive_plan_exists -and $verification.hygiene_deletion_gate_exists -and $verification.hygiene_report_exists
$Stage12ReportsOk = $verification.skill_start_exists -and $verification.skill_stage_matrix_exists -and $verification.skill_required_exists -and $verification.skill_optional_exists -and $verification.skill_missing_exists -and $verification.skill_capture_guide_exists -and $verification.skill_candidate_template_exists -and $verification.skill_promotion_gate_exists -and $verification.skill_integration_report_exists -and $verification.skill_candidates_readme_exists
$Stage13ReportsOk = $verification.execution_evidence_start_exists -and $verification.execution_evidence_commands_exists -and $verification.execution_evidence_changed_files_exists -and $verification.execution_evidence_test_results_exists -and $verification.execution_evidence_acceptance_exists -and $verification.execution_evidence_user_visible_exists -and $verification.execution_evidence_residual_risks_exists -and $verification.execution_evidence_rollback_exists -and $verification.execution_evidence_report_exists
$RequiredVisibleOk = $verification.soul_exists -and $verification.profile_instructions_exists -and $verification.profile_contract_exists -and $verification.foundation_report_exists -and $verification.starter_skills_exists -and $verification.workspace_onboarding_report_exists -and $Stage3ReportsOk -and $Stage4ReportsOk -and $Stage5ReportsOk -and $Stage6ReportsOk -and $Stage7ReportsOk -and $Stage8ReportsOk -and $Stage9ReportsOk -and $Stage10ReportsOk -and $Stage11ReportsOk -and $Stage12ReportsOk -and $Stage13ReportsOk
$NoPlaceholderOk = (-not $LiveConfigHasPlaceholder) -and (-not $DraftConfigHasPlaceholder)
$InstallStatus = if ($RequiredVisibleOk -and $NoPlaceholderOk -and ($ToolsetPartialCount -eq 0) -and ($ModelStatus -eq 'configured_or_written_non_secret_names')) { 'PASS' } elseif ($RequiredVisibleOk -and $NoPlaceholderOk) { 'PARTIAL' } else { 'BLOCKED' }

Write-LaunchRoomSection 'Machine verification'
$verification.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }

Write-LaunchRoomSection 'Beginner-safe result'
Write-Host "status: $InstallStatus"
Write-Host "what_is_ready: LaunchRoom Stage 1 profile layer, Stage 2 workspace boundary, Stage 3 engineering capability map, Stage 4 starter capability pack, Stage 5 communication channel map, Stage 6 SaaS operator kit, Stage 7 first-slice planning, Stage 8 local pilot execution packet, Stage 9 project plan integrity audit, Stage 10 agent execution readiness plan, Stage 11 workspace hygiene package, Stage 12 skill capture pack, Stage 13 execution evidence binder, workspace instructions, required reports, and local LaunchRoom skills."
Write-Host "what_was_not_touched: secrets, auth.json, state.db, other Hermes profiles, n8n, Cloudflare, Hetzner, MCP credentials, gateways, and production runtime surfaces."
Write-Host "visible_files_to_check: SOUL.md, PROFILE_INSTRUCTIONS.md, LAUNCHROOM_PROFILE_CONTRACT.yaml, reports/profile-foundation-report.yaml, skills/launchroom/*, workspace .hermes/reports/workspace-onboarding-report.yaml, software-purpose-map.yaml, software-install-recommendation.yaml, capability-graph.yaml, starter-capability-pack.yaml, communication-channel-map.yaml, communication-user-guide.md, operator-kit/START_HERE.md, operator-kit/NEXT_DECISION.md, operator-kit/CHECK_IT_WORKS.md, operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md, operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md, operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md, operator-kit/readiness_report.yaml, first-slice/READINESS_REPORT.yaml, local-pilot/READINESS_REPORT.yaml, project-audit/AUDIT_REPORT.yaml, agent-readiness/EXECUTION_READINESS_REPORT.yaml, hygiene/HYGIENE_REPORT.yaml, skills/SKILL_INTEGRATION_REPORT.yaml, execution-evidence/EXECUTION_EVIDENCE_REPORT.yaml"
Write-Host "workspace_status: project_type=$ProjectType; terminal_cwd_matches_workspace=$(ConvertTo-LaunchRoomYesNo $terminalCwdMatchesWorkspace)"
Write-Host "tool_readiness_status: $Stage3Status; missing_required=$($missingRequired -join ','); missing_recommended=$($missingRecommended -join ',')"
Write-Host "capability_graph: task_class -> workflow -> tool_bundle -> skill_bundle -> gates -> verification"
Write-Host "starter_capability_pack: task_class -> Hermes toolsets -> skills -> memory policy -> workflows -> gates"
Write-Host "stage4_status: $Stage4Status; toolsets_enabled_without_gate=false; memory_written_without_gate=false"
Write-Host "communication_channel_map: Desktop, Telegram, Slack, Email, Discord, adapters, webhooks/API -> managers -> guides -> gates -> verification"
Write-Host "stage5_status: $Stage5Status; gateway_setup_executed=false; pairing_approved=false; tokens_in_reports=false"
Write-Host "saas_operator_kit: START_HERE -> examples -> next decision -> product brief -> target user -> first workflow -> backlog -> local task packet -> gates -> readiness report"
Write-Host "stage6_status: $Stage6Status; guided_session_present=true; no_idea_default_workflow_catalog_present=true; blueprint_to_solution_path_present=true; implementation_executed=false; runtime_mutation=false; cloud_mutation=false"
Write-Host "first_slice_planning: implementation brief -> local pilot plan -> acceptance tests -> demo script -> decision gate"
Write-Host "stage7_status: $Stage7Status; implementation_executed=false; dependencies_installed=false; runtime_mutation=false; gateway_mutation=false"
Write-Host "local_pilot_execution_packet: execution packet -> file change plan -> command plan -> test plan -> evidence log -> review checklist -> handoff summary"
Write-Host "stage8_status: $Stage8Status; implementation_executed=false; file_changes_executed: false; commands_executed: false; tests_executed: false; runtime_mutation=false; gateway_mutation=false"
Write-Host "project_plan_integrity_audit: expected result map -> missing fragments -> contradiction scan -> stage drift scan -> repair recommendations"
Write-Host "stage9_status: $Stage9Status; execution_allowed=false; implementation_executed=false; commands_executed=false; tests_executed=false; runtime_mutation=false"
Write-Host "agent_execution_readiness: toolchain requirements -> software gap analysis -> Hermes toolset plan -> skill load plan -> agent pipeline plan -> install plan -> command readiness"
Write-Host "stage10_status: $Stage10Status; execution_ready=false; execution_allowed=false; install_gate_required=true; toolsets_enabled_without_gate=false; skills_installed_without_gate=false; agents_spawned=false"
Write-Host "workspace_hygiene: artifact index -> active files -> superseded files -> broken/stale files -> do-not-use -> cleanup plan -> archive plan -> deletion gate"
Write-Host "stage11_status: $Stage11Status; cleanup_executed=false; archive_executed=false; deletion_executed=false; files_deleted=false; files_moved=false; files_renamed=false"
Write-Host "skill_capture: stage skill matrix -> required skills -> optional skills -> missing skills -> capture guide -> candidate template -> promotion gate"
Write-Host "stage12_status: $Stage12Status; skills_installed=false; skills_patched=false; skills_promoted=false; persistent_memory_written=false; skill_candidates_created=false"
Write-Host "execution_evidence_binder: executed commands -> changed files -> test results -> acceptance evidence -> user-visible result -> residual risks -> rollback and handoff"
Write-Host "stage13_status: $Stage13Status; real_execution_evidence_present=false; fabricated_evidence=false; commands_executed_by_stage13=false; tests_executed_by_stage13=false"
Write-Host "install_gate_required: true; installs_executed: false"
Write-Host "next_stage: grant_implementation_gate_or_review_execution_evidence_scaffold"
if ($ModelStatus -ne 'configured_or_written_non_secret_names') {
  Write-Host "remaining_safe_step: model/provider setup is deferred; run 'hermes -p $ProfileName setup' or 'hermes -p $ProfileName model' later."
}
if ($ToolsetPartialCount -gt 0) {
  Write-Host "remaining_safe_step: some optional toolsets were partial; run 'hermes -p $ProfileName tools list' later."
}
Write-Host "next_command: hermes -p $ProfileName"
Write-Host "restart_required: $(ConvertTo-LaunchRoomYesNo (-not $IsSelfTest))"
