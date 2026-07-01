<#
.SYNOPSIS
  Create or reset an isolated Hermes LaunchRoom test profile on Windows.

.DESCRIPTION
  public LaunchRoom test package / not AIRMIDA authority

  This helper targets a disposable test profile and avoids the user's main/default/AIRMIDA profiles.
  It creates the profile if missing, can export a backup before reset, and can run model setup.
#>
param(
  [string]$ProfileName = 'launchroom-zero',
  [switch]$ResetExisting,
  [ValidateSet('Model','Portal','None')][string]$SetupMode = 'Model',
  [switch]$NoSkills
)

$ErrorActionPreference = 'Stop'
$protected = @('default','airmida','main')
if ($protected -contains $ProfileName) {
  throw "Refusing to reset protected profile: $ProfileName"
}

function Run-Hermes {
  param([string[]]$Arguments)
  & hermes @Arguments
  if ($LASTEXITCODE -ne 0) { throw "hermes $($Arguments -join ' ') failed with exit code $LASTEXITCODE" }
}

Write-Host "LaunchRoom test profile: $ProfileName"
$profiles = (& hermes profile list 2>$null) -join "`n"
$exists = $profiles -match [regex]::Escape($ProfileName)

if ($exists -and $ResetExisting) {
  $backupRoot = Join-Path $env:USERPROFILE 'HermesProfileBackups'
  New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $backupPath = Join-Path $backupRoot "$ProfileName-$stamp.tar.gz"
  Write-Host "Exporting backup to $backupPath"
  Run-Hermes @('profile','export',$ProfileName,$backupPath)
  Write-Host "Deleting existing disposable profile"
  Run-Hermes @('profile','delete',$ProfileName,'--yes')
  $exists = $false
}

if (-not $exists) {
  Write-Host "Creating profile $ProfileName"
  Run-Hermes @('profile','create',$ProfileName)
}

Write-Host "Profile details"
Run-Hermes @('profile','show',$ProfileName)

if ($SetupMode -eq 'Model') {
  Write-Host "Opening Hermes model picker for the test profile"
  Run-Hermes @('-p',$ProfileName,'model')
} elseif ($SetupMode -eq 'Portal') {
  Write-Host "Opening Hermes Portal setup for the test profile"
  Run-Hermes @('-p',$ProfileName,'setup','--portal')
} else {
  Write-Host "SetupMode=None; skipping model setup"
}

if (-not $NoSkills) {
  Write-Host "No automatic skill installation is performed by this helper. Load LaunchRoom from RUN_ME_FIRST.md in a fresh session."
}

Write-Host "Next command: hermes -p $ProfileName"
Write-Host "Then paste: https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST.md"
