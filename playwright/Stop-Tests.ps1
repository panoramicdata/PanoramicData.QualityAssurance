# Emergency Stop Script for Playwright Tests
# Run this if tests get stuck or won't stop with Ctrl+C

Write-Host "`n🛑 EMERGENCY STOP - Killing all test processes..." -ForegroundColor Red

# Kill Node.js processes (Playwright test runner)
$nodeProcesses = Get-Process | Where-Object {$_.ProcessName -match "node"}
if ($nodeProcesses) {
    $nodeProcesses | Stop-Process -Force
    Write-Host "✓ Stopped Node.js processes: $($nodeProcesses.Count)" -ForegroundColor Yellow
}

# Kill Chrome/Chromium processes (test browser)
$chromeProcesses = Get-Process | Where-Object {$_.ProcessName -match "chrome|msedge"}
if ($chromeProcesses) {
    $chromeProcesses | Stop-Process -Force
    Write-Host "✓ Stopped Chrome processes: $($chromeProcesses.Count)" -ForegroundColor Yellow
}

# Kill Playwright processes
$playwrightProcesses = Get-Process | Where-Object {$_.ProcessName -match "playwright"}
if ($playwrightProcesses) {
    $playwrightProcesses | Stop-Process -Force
    Write-Host "✓ Stopped Playwright processes: $($playwrightProcesses.Count)" -ForegroundColor Yellow
}

Write-Host "`n✓ All test processes stopped" -ForegroundColor Green
Write-Host "`nNote: If tests were running, they may have left orphaned processes." -ForegroundColor Gray
Write-Host "You can also press Ctrl+C in the terminal to stop tests normally." -ForegroundColor Gray
Write-Host ""
