<#
.SYNOPSIS
  Create or reset an isolated Hermes LaunchRoom test profile on Windows.

.DESCRIPTION
  public LaunchRoom test package / not AIRMIDA authority

  This script is for clean LaunchRoom onboarding tests. It does NOT reset the
  main/default Hermes profile and does NOT remove installed Windows tools such
  as Python/Git/Node/Docker. It only creates or safely recreates one Hermes
  profile, usually `launchroom-zero`.

  Default behavior is safe:
    - if the profile does not exist, create it;
    - if the profile exists, leave it unchanged unless -ResetExisting is passed;
    - run only the model picker by default;
    - do not run terminal/gateway/tools setup.

.EXAMPLES
  # First clean test profile creation + model picker
  powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1

  # Recreate the test profile from scratch, with backup export first
  powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1 -ResetExisting

  # Create/reset profile but do not launch any setup wizard
  powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1 -ResetExisting -SetupMode None

  # Use Nous Portal setup instead of plain model picker
  powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1 -ResetExisting -SetupMode Portal

.NOTES
  Secrets stay in Hermes auth/.env mechanisms. Do not paste API keys or tokens
  into chat while using this script.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [ValidatePattern('^[a-z0-9][a-z0-9-]*$')]
  [string]$ProfileName = 'launchroom-zero',

  # If omitted and the profile already exists, the script will NOT delete it.
  [Parameter()]
  [switch]$ResetExisting,

  # Model = only `hermes -p <profile> model`.
  # Portal = `hermes -p <profile> setup --portal` for Nous Portal OAuth/model path.
  # None = create/reset profile only; user runs setup manually later.
  [Parameter()]
  [ValidateSet('None', 'Model', 'Portal')]
  [string]$SetupMode = 'Model',

  [Parameter()]
  [switch]$NoAlias,

  [Parameter()]
  [switch]$NoSkills,

  # Use only if you deliberately want `hermes` without -p to target this test profile.
  [Parameter()]
  [switch]$MakeSticky,

  # Optional live model smoke test after setup. This spends one tiny model call.
  [Parameter()]
  [switch]$SmokeTest,

  [Parameter()]
  [string]$BackupRoot = (Join-Path $HOME 'HermesProfileBackups'),

  # Safety escape hatch for advanced users. Not needed for launchroom-zero.
  [Parameter()]
  [switch]$AllowNonTestName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
  param([string]$Message)
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Warn {
  param([string]$Message)
  Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Run-Hermes {
  param([Parameter(Mandatory=$true)][string[]]$Arguments)
  Write-Host ("hermes " + ($Arguments -join ' ')) -ForegroundColor DarkGray
  & hermes @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: hermes $($Arguments -join ' ')"
  }
}

function Test-HermesProfileExists {
  param([Parameter(Mandatory=$true)][string]$Name)
  & hermes profile show $Name *> $null
  return ($LASTEXITCODE -eq 0)
}

function Assert-SafeProfileNameForReset {
  param([Parameter(Mandatory=$true)][string]$Name)

  $reserved = @('default', 'airmida', 'main', 'work', 'personal', 'prod', 'production')
  if ($reserved -contains $Name) {
    throw "Refusing to reset reserved/non-test profile '$Name'. Use a disposable name such as launchroom-zero."
  }

  $looksLikeTest = ($Name -like 'launchroom-*' -or $Name -like 'test-*' -or $Name -like '*-test' -or $Name -like '*-zero')
  if (-not $looksLikeTest -and -not $AllowNonTestName) {
    throw "Profile '$Name' does not look like a disposable test profile. Re-run with -AllowNonTestName only if you are sure."
  }
}

Write-Step "Hermes LaunchRoom test profile reset/create"
Write-Host "ProfileName: $ProfileName"
Write-Host "ResetExisting: $ResetExisting"
Write-Host "SetupMode: $SetupMode"
Write-Host "BackupRoot: $BackupRoot"

Write-Step "Checking hermes command"
$hermesCmd = Get-Command hermes -ErrorAction SilentlyContinue
if (-not $hermesCmd) {
  throw "Hermes CLI was not found in PATH. Open a fresh PowerShell/Terminal or reinstall Hermes first."
}
Write-Host "Found: $($hermesCmd.Source)"
Run-Hermes @('--version')

$exists = Test-HermesProfileExists -Name $ProfileName

if ($exists) {
  Write-Step "Profile '$ProfileName' already exists"
  if (-not $ResetExisting) {
    Write-Warn "Not resetting because -ResetExisting was not provided."
    Write-Host "If you want a true clean test profile, re-run with:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1 -ResetExisting" -ForegroundColor Green
  } else {
    Assert-SafeProfileNameForReset -Name $ProfileName

    Write-Step "Exporting backup before reset"
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupFile = Join-Path $BackupRoot "$ProfileName-$timestamp.tar.gz"
    Run-Hermes @('profile', 'export', $ProfileName, '--output', $backupFile)
    if (-not (Test-Path $backupFile)) {
      throw "Backup file was not created: $backupFile"
    }
    Write-Host "Backup created: $backupFile" -ForegroundColor Green

    Write-Step "Deleting existing test profile"
    Run-Hermes @('profile', 'delete', $ProfileName, '--yes')
    $exists = $false
  }
}

if (-not $exists) {
  Write-Step "Creating clean Hermes profile '$ProfileName'"
  $createArgs = @('profile', 'create', $ProfileName, '--description', 'Disposable LaunchRoom clean onboarding test profile. Safe to reset.')
  if ($NoAlias) { $createArgs += '--no-alias' }
  if ($NoSkills) { $createArgs += '--no-skills' }
  Run-Hermes $createArgs
}

Write-Step "Profile details"
Run-Hermes @('profile', 'show', $ProfileName)

Write-Step "Profile config paths (paths only, no secret values)"
Run-Hermes @('-p', $ProfileName, 'config', 'path')
Run-Hermes @('-p', $ProfileName, 'config', 'env-path')

switch ($SetupMode) {
  'None' {
    Write-Step "SetupMode None: no setup wizard launched"
    Write-Host "Next manual command if needed: hermes -p $ProfileName model" -ForegroundColor Green
  }
  'Model' {
    Write-Step "Launching model picker only"
    Write-Host "Choose the model/provider path. Do not run terminal/gateway/tools setup in this clean baseline unless you intentionally test that path." -ForegroundColor Yellow
    Run-Hermes @('-p', $ProfileName, 'model')
  }
  'Portal' {
    Write-Step "Launching Nous Portal setup"
    Write-Host "This may configure Nous Portal/model and managed tool gateway choices. Use Model mode if you need stricter 'model only'." -ForegroundColor Yellow
    Run-Hermes @('-p', $ProfileName, 'setup', '--portal')
  }
}

if ($MakeSticky) {
  Write-Step "Setting sticky default profile"
  Write-Warn "Plain `hermes` commands will now target '$ProfileName' until you run: hermes profile use default"
  Run-Hermes @('profile', 'use', $ProfileName)
}

if ($SmokeTest) {
  Write-Step "Running optional model smoke test"
  Run-Hermes @('-p', $ProfileName, 'chat', '-q', 'Ответь строго одним словом: OK', '--quiet')
}

Write-Step "Done"
Write-Host "Clean test profile is ready: $ProfileName" -ForegroundColor Green
Write-Host "To start a clean LaunchRoom test in CLI:"
Write-Host "  hermes -p $ProfileName" -ForegroundColor Green
Write-Host "Then paste the one-link runbook:"
Write-Host "  https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST_RU.md" -ForegroundColor Green
Write-Host ""
Write-Host "Important: this profile reset does not uninstall Python/Git/Node/Docker and does not touch your main/default Hermes profile." -ForegroundColor Yellow
