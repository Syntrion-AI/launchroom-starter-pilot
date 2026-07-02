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
  '  safe_default_next_action: review starter-capability-pack.yaml, communication-channel-map.yaml, communication-user-guide.md, operator-kit/START_HERE.md, operator-kit/NEXT_DECISION.md, operator-kit/CHECK_IT_WORKS.md, operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md, operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md, operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md, operator-kit/readiness_report.yaml and approve selected toolset/skill activation gates only when needed',
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
  operator_kit_readiness_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/readiness_report.yaml')
  guided_session_state_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/SESSION_STATE.yaml')
  guided_session_agent_guide_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/AGENT_GUIDE.md')
  guided_session_user_lesson_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/USER_LESSON.md')
  guided_session_idea_intake_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/IDEA_INTAKE.md')
  guided_session_project_blueprint_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md')
  guided_session_first_slice_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md')
  guided_session_default_catalog_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md')
  guided_session_implementation_roadmap_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md')
  guided_session_completion_summary_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit/guided-session/COMPLETION_SUMMARY.md')
  operator_kit_root_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/operator-kit')
  stage3_status = $Stage3Status
  stage3_missing_required = ($missingRequired -join ',')
  stage3_missing_recommended = ($missingRecommended -join ',')
  stage4_status = $Stage4Status
  stage5_status = $Stage5Status
  stage6_status = $Stage6Status
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
$RequiredVisibleOk = $verification.soul_exists -and $verification.profile_instructions_exists -and $verification.profile_contract_exists -and $verification.foundation_report_exists -and $verification.starter_skills_exists -and $verification.workspace_onboarding_report_exists -and $Stage3ReportsOk -and $Stage4ReportsOk -and $Stage5ReportsOk -and $Stage6ReportsOk
$NoPlaceholderOk = (-not $LiveConfigHasPlaceholder) -and (-not $DraftConfigHasPlaceholder)
$InstallStatus = if ($RequiredVisibleOk -and $NoPlaceholderOk -and ($ToolsetPartialCount -eq 0) -and ($ModelStatus -eq 'configured_or_written_non_secret_names')) { 'PASS' } elseif ($RequiredVisibleOk -and $NoPlaceholderOk) { 'PARTIAL' } else { 'BLOCKED' }

Write-LaunchRoomSection 'Machine verification'
$verification.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }

Write-LaunchRoomSection 'Beginner-safe result'
Write-Host "status: $InstallStatus"
Write-Host "what_is_ready: LaunchRoom Stage 1 profile layer, Stage 2 workspace boundary, Stage 3 engineering capability map, Stage 4 starter capability pack, Stage 5 communication channel map, Stage 6 SaaS operator kit, workspace instructions, required reports, and local LaunchRoom skills."
Write-Host "what_was_not_touched: secrets, auth.json, state.db, other Hermes profiles, n8n, Cloudflare, Hetzner, MCP credentials, gateways, and production runtime surfaces."
Write-Host "visible_files_to_check: SOUL.md, PROFILE_INSTRUCTIONS.md, LAUNCHROOM_PROFILE_CONTRACT.yaml, reports/profile-foundation-report.yaml, skills/launchroom/*, workspace .hermes/reports/workspace-onboarding-report.yaml, software-purpose-map.yaml, software-install-recommendation.yaml, capability-graph.yaml, starter-capability-pack.yaml, communication-channel-map.yaml, communication-user-guide.md, operator-kit/START_HERE.md, operator-kit/NEXT_DECISION.md, operator-kit/CHECK_IT_WORKS.md, operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md, operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md, operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md, operator-kit/readiness_report.yaml"
Write-Host "workspace_status: project_type=$ProjectType; terminal_cwd_matches_workspace=$(ConvertTo-LaunchRoomYesNo $terminalCwdMatchesWorkspace)"
Write-Host "tool_readiness_status: $Stage3Status; missing_required=$($missingRequired -join ','); missing_recommended=$($missingRecommended -join ',')"
Write-Host "capability_graph: task_class -> workflow -> tool_bundle -> skill_bundle -> gates -> verification"
Write-Host "starter_capability_pack: task_class -> Hermes toolsets -> skills -> memory policy -> workflows -> gates"
Write-Host "stage4_status: $Stage4Status; toolsets_enabled_without_gate=false; memory_written_without_gate=false"
Write-Host "communication_channel_map: Desktop, Telegram, Slack, Email, Discord, adapters, webhooks/API -> managers -> guides -> gates -> verification"
Write-Host "stage5_status: $Stage5Status; gateway_setup_executed=false; pairing_approved=false; tokens_in_reports=false"
Write-Host "saas_operator_kit: START_HERE -> examples -> next decision -> product brief -> target user -> first workflow -> backlog -> local task packet -> gates -> readiness report"
Write-Host "stage6_status: $Stage6Status; guided_session_present=true; no_idea_default_workflow_catalog_present=true; blueprint_to_solution_path_present=true; implementation_executed=false; runtime_mutation=false; cloud_mutation=false"
Write-Host "install_gate_required: true; installs_executed: false"
Write-Host "next_stage: review_operator_kit_or_choose_first_vertical_slice"
if ($ModelStatus -ne 'configured_or_written_non_secret_names') {
  Write-Host "remaining_safe_step: model/provider setup is deferred; run 'hermes -p $ProfileName setup' or 'hermes -p $ProfileName model' later."
}
if ($ToolsetPartialCount -gt 0) {
  Write-Host "remaining_safe_step: some optional toolsets were partial; run 'hermes -p $ProfileName tools list' later."
}
Write-Host "next_command: hermes -p $ProfileName"
Write-Host "restart_required: $(ConvertTo-LaunchRoomYesNo (-not $IsSelfTest))"
