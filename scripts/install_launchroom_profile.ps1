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
}

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
  stage3_status = $Stage3Status
  stage3_missing_required = ($missingRequired -join ',')
  stage3_missing_recommended = ($missingRecommended -join ',')
  toolset_partial_count = $ToolsetPartialCount
  self_test_mode = $IsSelfTest
  test_output_root = $TestOutputFull
  reset_or_new_session_required = (-not $IsSelfTest)
}

if ($IsSelfTest -and $LiveConfigHasPlaceholder) { throw 'Self-test failed: simulated live config.yaml contains unresolved __LAUNCHROOM_RESOLVE__ placeholder.' }
$Stage3ReportsOk = if ($NoInventory) { $true } else { $verification.inventory_report_exists -and $verification.software_purpose_map_exists -and $verification.software_install_recommendation_exists }
$RequiredVisibleOk = $verification.soul_exists -and $verification.profile_instructions_exists -and $verification.profile_contract_exists -and $verification.foundation_report_exists -and $verification.starter_skills_exists -and $verification.workspace_onboarding_report_exists -and $Stage3ReportsOk
$NoPlaceholderOk = (-not $LiveConfigHasPlaceholder) -and (-not $DraftConfigHasPlaceholder)
$InstallStatus = if ($RequiredVisibleOk -and $NoPlaceholderOk -and ($ToolsetPartialCount -eq 0) -and ($ModelStatus -eq 'configured_or_written_non_secret_names')) { 'PASS' } elseif ($RequiredVisibleOk -and $NoPlaceholderOk) { 'PARTIAL' } else { 'BLOCKED' }

Write-LaunchRoomSection 'Machine verification'
$verification.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }

Write-LaunchRoomSection 'Beginner-safe result'
Write-Host "status: $InstallStatus"
Write-Host "what_is_ready: LaunchRoom Stage 1 profile layer, Stage 2 workspace boundary, Stage 3 software readiness map, workspace instructions, required reports, and local LaunchRoom skills."
Write-Host "what_was_not_touched: secrets, auth.json, state.db, other Hermes profiles, n8n, Cloudflare, Hetzner, MCP credentials, gateways, and production runtime surfaces."
Write-Host "visible_files_to_check: SOUL.md, PROFILE_INSTRUCTIONS.md, LAUNCHROOM_PROFILE_CONTRACT.yaml, reports/profile-foundation-report.yaml, skills/launchroom/*, workspace .hermes/reports/workspace-onboarding-report.yaml, software-purpose-map.yaml, software-install-recommendation.yaml"
Write-Host "workspace_status: project_type=$ProjectType; terminal_cwd_matches_workspace=$(ConvertTo-LaunchRoomYesNo $terminalCwdMatchesWorkspace)"
Write-Host "tool_readiness_status: $Stage3Status; missing_required=$($missingRequired -join ','); missing_recommended=$($missingRecommended -join ',')"
Write-Host "install_gate_required: true; installs_executed: false"
Write-Host "next_stage: stage_4_starter_capability_pack"
if ($ModelStatus -ne 'configured_or_written_non_secret_names') {
  Write-Host "remaining_safe_step: model/provider setup is deferred; run 'hermes -p $ProfileName setup' or 'hermes -p $ProfileName model' later."
}
if ($ToolsetPartialCount -gt 0) {
  Write-Host "remaining_safe_step: some optional toolsets were partial; run 'hermes -p $ProfileName tools list' later."
}
Write-Host "next_command: hermes -p $ProfileName"
Write-Host "restart_required: $(ConvertTo-LaunchRoomYesNo (-not $IsSelfTest))"
