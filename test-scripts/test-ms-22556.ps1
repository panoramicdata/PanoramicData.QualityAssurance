# Test script for MS-22556: DataMagic UI/UX Issues on alpha2
# Tests the various UI rendering and usability problems reported

$ErrorActionPreference = "Stop"

Write-Host "Testing MS-22556: DataMagic UI/UX Issues" -ForegroundColor Cyan
Write-Host "Environment: https://data.alpha2.magicsuite.net/" -ForegroundColor Yellow
Write-Host ""

# Set environment variable for alpha2
$env:MS_ENV = "alpha2"

# Change to playwright directory
Set-Location "$PSScriptRoot\..\playwright"

Write-Host "Running Playwright tests for DataMagic..." -ForegroundColor Green
npx playwright test "Magic Suite/DataMagic" --headed

Write-Host ""
Write-Host "Test complete. Check the output above for issues." -ForegroundColor Cyan
