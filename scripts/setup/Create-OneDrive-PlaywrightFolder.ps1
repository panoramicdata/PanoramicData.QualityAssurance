# Create-OneDrive-PlaywrightFolder.ps1
# Creates a `Panoramic Data\QA\playwright tests` folder inside the user's OneDrive.
# Usage: .\Create-OneDrive-PlaywrightFolder.ps1

$oneDrive = if ($env:OneDrive) { $env:OneDrive }
           elseif ($env:OneDriveCommercial) { $env:OneDriveCommercial }
           elseif ($env:OneDriveConsumer) { $env:OneDriveConsumer }
           else { $null }

if (-not $oneDrive) {
    Write-Error "OneDrive environment variable not found. Please ensure OneDrive is signed in."
    exit 1
}

$target = Join-Path $oneDrive "Panoramic Data\QA\playwright tests"

if (-not (Test-Path $target)) {
    try {
        New-Item -Path $target -ItemType Directory -Force | Out-Null
        Write-Host "Created folder: $target" -ForegroundColor Green
    } catch {
        Write-Error ("Failed to create folder {0}: {1}" -f $target, $_)
        exit 1
    }
} else {
    Write-Host "Folder already exists: $target" -ForegroundColor Yellow
}

# Inform user how to point Playwright to this folder
Write-Host "To store Playwright videos/results in this folder, set the environment variable:" -ForegroundColor Cyan
$line = "`$env:MS_VIDEO_DIR='$target'"
Write-Host $line -ForegroundColor Cyan
Write-Host "Or add it to your PowerShell profile:" -ForegroundColor Cyan
$line = "`$env:MS_VIDEO_DIR='$target'"
Write-Host $line -ForegroundColor Cyan
