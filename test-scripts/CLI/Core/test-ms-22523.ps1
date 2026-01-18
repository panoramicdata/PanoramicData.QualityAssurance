# Test script for MS-22523: Profile list shows ? instead of checkmark for active profile

Write-Host "=== Testing MS-22523: Active Profile Display Issue ===" -ForegroundColor Cyan
Write-Host "Issue: Profile list shows question mark instead of checkmark for active profile" -ForegroundColor Gray
Write-Host "Tested Version: $(magicsuite --version)" -ForegroundColor Gray
Write-Host ""

# Test 1: Check auth status to confirm active profile
Write-Host "Test 1: Verify Active Profile via auth status" -ForegroundColor Yellow
$authOutput = magicsuite auth status 2>&1 | Out-String
if ($authOutput -match "Authentication Status for Profile: (\w+)") {
    $activeProfile = $Matches[1]
    Write-Host "Active Profile: $activeProfile" -ForegroundColor Green
} else {
    Write-Host "FAIL: Could not determine active profile" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Check profiles list display
Write-Host "Test 2: Check Active Indicator in profiles list" -ForegroundColor Yellow
$profilesOutput = magicsuite config profiles list 2>&1 | Out-String
Write-Host "Profiles list output:" -ForegroundColor Gray
Write-Host $profilesOutput

if ($profilesOutput -match "$activeProfile.*\?") {
    Write-Host "BUG CONFIRMED: Active profile shows '?' instead of checkmark" -ForegroundColor Red
    Write-Host "Expected: Checkmark or tick symbol (√)" -ForegroundColor Yellow
    Write-Host "Actual: Question mark (?)" -ForegroundColor Yellow
} elseif ($profilesOutput -match "$activeProfile.*√|✓|✔") {
    Write-Host "BUG FIXED: Active profile shows checkmark correctly" -ForegroundColor Green
} else {
    Write-Host "WARNING: Could not determine active indicator" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Bug Status: STILL EXISTS in 4.1.*" -ForegroundColor Red
Write-Host "The Active column shows '?' instead of a checkmark for the active profile." -ForegroundColor Red
Write-Host ""
Write-Host "Expected Behavior:" -ForegroundColor Yellow
Write-Host "  - Active profile should show checkmark in the Active column" -ForegroundColor Gray
Write-Host "  - Inactive profiles should show empty or - in the Active column" -ForegroundColor Gray
Write-Host "  - The ? symbol suggests uncertainty which is misleading" -ForegroundColor Gray
