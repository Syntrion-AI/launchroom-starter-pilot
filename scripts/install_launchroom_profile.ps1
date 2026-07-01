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

  The source package is profile-distribution/launchroom-saas. The old
  templates/ directory is kept only for compatibility with earlier pilot stages.
#>
param(
  [string]$ProfileName = 'launchroom',
  [string]$WorkspacePath = '',
  [string]$ProjectName = '',
  [string]$UserLanguage = 'auto',
  [string]$ModelProvider = '',
  [string]$ModelDefault = '',
  [switch]$Yes,
  [switch]$NoLocalSkills,
  [switch]$NoToolsets,
  [switch]$NoInventory,
  [switch]$ShowPlanOnly
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
  $WorkspacePath = Join-Path $env:USERPROFILE (Join-Path 'LaunchRoom' $ProfileName)
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = $ProfileName
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

function Has-UnresolvedLaunchRoomPlaceholder {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $false }
  $text = Get-Content -Raw -Encoding UTF8 $Path
  return ($text -match '__LAUNCHROOM_RESOLVE__')
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

$WorkspaceFull = [System.IO.Path]::GetFullPath($WorkspacePath)
$HasModelProvider = -not [string]::IsNullOrWhiteSpace($ModelProvider)
$HasModelDefault = -not [string]::IsNullOrWhiteSpace($ModelDefault)
$ModelProviderToken = if ($HasModelProvider) { $ModelProvider } else { 'DEFERRED_MODEL_PROVIDER' }
$ModelDefaultToken = if ($HasModelDefault) { $ModelDefault } else { 'DEFERRED_MODEL_DEFAULT' }

$plan = @"
LaunchRoom Starter profile setup plan
Profile: $ProfileName
Project: $ProjectName
Workspace: $WorkspaceFull
User language mode: $UserLanguage
Distribution source: $DistributionRoot
Will create/update:
- Hermes profile if missing
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
- workspace .hermes/reports/software-inventory-report.yaml unless -NoInventory
Will not touch:
- .env
- auth.json
- state.db
- OAuth/session/memory stores
- cloud/provider/runtime/gateway credentials
- raw MCP credential values
Model config:
- provider: $(if ($HasModelProvider) { $ModelProvider } else { 'deferred' })
- default model: $(if ($HasModelDefault) { $ModelDefault } else { 'deferred' })
"@
Write-Host $plan
if ($ShowPlanOnly) { exit 0 }
Confirm-Step "Apply this LaunchRoom Starter profile setup?"

$profiles = (Capture-Hermes @('profile','list'))
if ($profiles -notmatch [regex]::Escape($ProfileName)) {
  Write-Host "Creating Hermes profile: $ProfileName"
  Run-Hermes @('profile','create',$ProfileName,'--description','LaunchRoom Starter profile for local SaaS project setup and governed AI-operator work.')
} else {
  Write-Host "Using existing Hermes profile: $ProfileName"
}

$configPath = Capture-Hermes @('-p',$ProfileName,'config','path')
$profileRoot = Split-Path -Parent $configPath
New-Item -ItemType Directory -Force -Path $WorkspaceFull | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull '.hermes/reports') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull '.hermes/instructions') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $WorkspaceFull 'saas-operator-kit') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $profileRoot 'reports') | Out-Null

$tokens = @{
  PROFILE_NAME = $ProfileName
  PROFILE_PATH = $profileRoot
  WORKSPACE_PATH = $WorkspaceFull
  PROJECT_PATH = $WorkspaceFull
  PROJECT_NAME = $ProjectName
  USER_LANGUAGE = $UserLanguage
  MODEL_PROVIDER = $ModelProviderToken
  MODEL_DEFAULT = $ModelDefaultToken
  GENERATED_AT = (Get-Date).ToString('s')
}

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

if (-not $NoLocalSkills) {
  Write-Host 'Installing LaunchRoom bundled skills into target profile'
  $skillSource = Join-Path $DistributionRoot 'skills'
  $skillTarget = Join-Path $profileRoot 'skills/launchroom'
  New-Item -ItemType Directory -Force -Path $skillTarget | Out-Null
  Copy-Item -Path (Join-Path $skillSource '*') -Destination $skillTarget -Recurse -Force
}

$toolsetResults = @()
if (-not $NoToolsets) {
  Write-Host 'Enabling LaunchRoom starter toolsets where supported by this Hermes install (preferred path: hermes tools enable <toolset>)'
  $starterToolsets = @('terminal','file','web','search','browser','vision','skills','memory','session_search','clarify','todo','code_execution')
  foreach ($toolset in $starterToolsets) {
    $result = Try-Hermes @('-p',$ProfileName,'tools','enable',$toolset)
    $toolsetResults += $result
    if ($result.ok) { Write-Host "toolset enabled: $toolset" } else { Write-Host "toolset partial: $toolset" }
  }
}

if (-not $NoInventory) {
  Write-Host 'Collecting no-secret software inventory'
  $items = @(
    (Get-CommandStatus 'hermes' @('--version')),
    (Get-CommandStatus 'python' @('--version')),
    (Get-CommandStatus 'git' @('--version')),
    (Get-CommandStatus 'node' @('--version')),
    (Get-CommandStatus 'npm' @('--version')),
    (Get-CommandStatus 'docker' @('--version')),
    (Get-CommandStatus 'rg' @('--version')),
    (Get-CommandStatus 'uv' @('--version')),
    (Get-CommandStatus 'winget' @('--version')),
    (Get-CommandStatus 'wsl' @('--version'))
  )
  $inventoryPath = Join-Path $WorkspaceFull '.hermes/reports/software-inventory-report.yaml'
  $lines = @('installed:')
  foreach ($item in $items) {
    $safeVersion = ([string]$item.version).Replace('"','\"')
    $lines += "  $($item.name):"
    $lines += "    status: $($item.status)"
    $lines += "    version: `"$safeVersion`""
  }
  $missingRequired = @($items | Where-Object { $_.status -eq 'missing' -and $_.name -in @('hermes','python','git') } | ForEach-Object { $_.name })
  $missingRecommended = @($items | Where-Object { $_.status -eq 'missing' -and $_.name -in @('node','npm','docker','rg','uv','winget') } | ForEach-Object { $_.name })
  $lines += 'missing_required:'
  if ($missingRequired.Count -eq 0) { $lines += '  []' } else { foreach ($m in $missingRequired) { $lines += "  - $m" } }
  $lines += 'missing_recommended:'
  if ($missingRecommended.Count -eq 0) { $lines += '  []' } else { foreach ($m in $missingRecommended) { $lines += "  - $m" } }
  $lines += 'optional_later:'
  $lines += '  - wsl'
  $lines += 'install_gate_required: true'
  Write-Utf8NoBom $inventoryPath ($lines -join "`n")
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
  inventory_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/software-inventory-report.yaml')
  toolset_partial_count = $ToolsetPartialCount
  reset_or_new_session_required = $true
}

Write-Host 'LaunchRoom profile setup complete.'
$verification.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }
Write-Host "Next: restart Hermes or start a new session, then run: hermes -p $ProfileName"
