# Setup MagicSuite CLI auto-update on PowerShell startup

Write-Host "Setting up automatic CLI update checks on PowerShell startup..." -ForegroundColor Cyan

$profilePath = $PROFILE.CurrentUserAllHosts
$startupScriptPath = Join-Path $PSScriptRoot "profile-startup.ps1"

# Create profile directory if it doesn't exist
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "Created profile directory: $profileDir" -ForegroundColor Green
}

# Check if profile exists
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "Created PowerShell profile: $profilePath" -ForegroundColor Green
}

# Check if startup script is already referenced
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
$scriptCall = ". `"$startupScriptPath`""

if ($profileContent -notlike "*$startupScriptPath*") {
    # Add to profile
    Add-Content -Path $profilePath -Value "`n# MagicSuite CLI auto-update check`n$scriptCall"
    Write-Host "`n✓ Added CLI update check to PowerShell profile" -ForegroundColor Green
} else {
    Write-Host "`n✓ CLI update check already configured in profile" -ForegroundColor Yellow
}

Write-Host "`nConfiguration complete!" -ForegroundColor Green
Write-Host "`nHow it works:" -ForegroundColor White
Write-Host "  • Checks for CLI updates when you start PowerShell" -ForegroundColor Gray
Write-Host "  • Only checks once per 24 hours (not every terminal)" -ForegroundColor Gray
Write-Host "  • Automatically installs updates when available" -ForegroundColor Gray
Write-Host "  • Runs quick bug verification after updates" -ForegroundColor Gray
Write-Host "`nProfile location: $profilePath" -ForegroundColor Gray
Write-Host "`nTo test now, restart PowerShell or run:" -ForegroundColor Yellow
Write-Host "  . `"$startupScriptPath`"" -ForegroundColor Cyan
