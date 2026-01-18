# Run-Auth-Setup-With-OneDrive.ps1
# Sets MS_VIDEO_DIR to the OneDrive Playwright folder (if present) and runs auth.setup in headed mode.

$oneDrive = if ($env:OneDrive) { $env:OneDrive } elseif ($env:OneDriveCommercial) { $env:OneDriveCommercial } elseif ($env:OneDriveConsumer) { $env:OneDriveConsumer } else { $null }
if ($oneDrive) {
  $env:MS_VIDEO_DIR = Join-Path $oneDrive 'Panoramic Data\QA\playwright tests'
} else {
  $env:MS_VIDEO_DIR = (Resolve-Path '..\test-results').Path
}

Write-Host "MS_VIDEO_DIR=$env:MS_VIDEO_DIR"

# Run the auth.setup test (headed) - pauses for manual login
Set-Location $PSScriptRoot
npx playwright test setup/auth.setup.ts --headed --project=default-chromium
