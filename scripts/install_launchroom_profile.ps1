<#
.SYNOPSIS
  Install a real LaunchRoom Starter profile layer for Hermes on Windows.

.DESCRIPTION
  public LaunchRoom test package / not AIRMIDA authority

  This is the primary LaunchRoom setup tool. It does not only create a blank
  Hermes profile. It creates or selects a profile, applies non-secret config,
  creates a workspace, writes profile-level instructions, writes workspace
  instructions, installs local starter skills, collects a no-secret inventory,
  and writes a setup report.

  It never copies .env, auth.json, state.db, OAuth stores, or session stores.
  It never asks for or writes secret values.
#>
param(
  [string]$ProfileName = 'launchroom',
  [string]$WorkspacePath = '',
  [string]$UserLanguage = 'auto',
  [switch]$Yes,
  [switch]$NoLocalSkills,
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

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$TemplateRoot = Join-Path $RepoRoot 'templates'

function Run-Hermes {
  param([string[]]$Arguments)
  & hermes @Arguments
  if ($LASTEXITCODE -ne 0) { throw "hermes $($Arguments -join ' ') failed with exit code $LASTEXITCODE" }
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

function Write-Template {
  param([string]$TemplatePath, [string]$DestinationPath, [hashtable]$Tokens)
  $text = Get-Content -Raw -Encoding UTF8 $TemplatePath
  foreach ($key in $Tokens.Keys) {
    $text = $text.Replace("{{${key}}}", [string]$Tokens[$key])
  }
  $parent = Split-Path -Parent $DestinationPath
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  Set-Content -Path $DestinationPath -Value $text -Encoding UTF8
}

function Get-CommandStatus {
  param([string]$Name, [string[]]$VersionArgs)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { return @{ name=$Name; status='missing'; version=''; path='' } }
  $version = ''
  try { $version = (& $Name @VersionArgs 2>&1 | Select-Object -First 1 | Out-String).Trim() } catch { $version = 'present_version_probe_failed' }
  return @{ name=$Name; status='present'; version=$version; path=$cmd.Source }
}

$WorkspaceFull = [System.IO.Path]::GetFullPath($WorkspacePath)
$plan = @"
LaunchRoom Starter profile setup plan
Profile: $ProfileName
Workspace: $WorkspaceFull
User language mode: $UserLanguage
Will create/update:
- Hermes profile if missing
- non-secret Hermes config values
- profile SOUL.md
- workspace README.md, AGENTS.md, HERMES.md
- workspace .hermes/reports/profile-setup-report.yaml
- workspace .hermes/reports/software-inventory-report.yaml
- local LaunchRoom starter skills in the target profile
Will not touch:
- .env
- auth.json
- state.db
- OAuth/session stores
- cloud/provider/runtime/gateway credentials
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

Write-Host 'Applying non-secret Hermes config values'
Run-Hermes @('-p',$ProfileName,'config','set','terminal.cwd',$WorkspaceFull)
Run-Hermes @('-p',$ProfileName,'config','set','approvals.mode','smart')
Run-Hermes @('-p',$ProfileName,'config','set','security.redact_secrets','true')
Run-Hermes @('-p',$ProfileName,'config','set','display.language',$UserLanguage)
Run-Hermes @('-p',$ProfileName,'config','set','memory.memory_enabled','true')
Run-Hermes @('-p',$ProfileName,'config','set','memory.user_profile_enabled','true')

$tokens = @{
  PROFILE_NAME = $ProfileName
  WORKSPACE_PATH = $WorkspaceFull
  USER_LANGUAGE = $UserLanguage
  GENERATED_AT = (Get-Date).ToString('s')
}

Write-Host 'Writing profile-level and workspace-level instructions'
Write-Template (Join-Path $TemplateRoot 'profile/SOUL.md') (Join-Path $profileRoot 'SOUL.md') $tokens
Write-Template (Join-Path $TemplateRoot 'workspace/README.md') (Join-Path $WorkspaceFull 'README.md') $tokens
Write-Template (Join-Path $TemplateRoot 'workspace/AGENTS.md') (Join-Path $WorkspaceFull 'AGENTS.md') $tokens
Write-Template (Join-Path $TemplateRoot 'workspace/HERMES.md') (Join-Path $WorkspaceFull 'HERMES.md') $tokens
Write-Template (Join-Path $TemplateRoot 'reports/profile-setup-report.yaml') (Join-Path $WorkspaceFull '.hermes/reports/profile-setup-report.yaml') $tokens

if (-not $NoLocalSkills) {
  Write-Host 'Installing local LaunchRoom starter skills into target profile'
  $skillSource = Join-Path $TemplateRoot 'starter-skills'
  $skillTarget = Join-Path $profileRoot 'skills/launchroom'
  New-Item -ItemType Directory -Force -Path $skillTarget | Out-Null
  Copy-Item -Path (Join-Path $skillSource '*') -Destination $skillTarget -Recurse -Force
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
  Set-Content -Path $inventoryPath -Value ($lines -join "`n") -Encoding UTF8
}

$verification = @{
  profile = $ProfileName
  profile_root = $profileRoot
  workspace = $WorkspaceFull
  config_path = $configPath
  soul_exists = Test-Path (Join-Path $profileRoot 'SOUL.md')
  workspace_agents_exists = Test-Path (Join-Path $WorkspaceFull 'AGENTS.md')
  workspace_hermes_exists = Test-Path (Join-Path $WorkspaceFull 'HERMES.md')
  starter_skills_exists = Test-Path (Join-Path $profileRoot 'skills/launchroom')
  setup_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/profile-setup-report.yaml')
  inventory_report_exists = Test-Path (Join-Path $WorkspaceFull '.hermes/reports/software-inventory-report.yaml')
}

Write-Host 'LaunchRoom profile setup complete.'
$verification.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }
Write-Host "Next: hermes -p $ProfileName"
