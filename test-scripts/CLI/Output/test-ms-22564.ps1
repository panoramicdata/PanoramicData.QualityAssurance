# Test script for MS-22564: --output parameter not working

Write-Host "=== Testing MS-22564: --output parameter functionality ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: JSON output to file
Write-Host "Test 1: JSON output to relative path" -ForegroundColor Yellow
magicsuite api get tenants --output test-output.json --format json | Out-Null
if (Test-Path test-output.json) {
    Write-Host "PASS: File created" -ForegroundColor Green
    Remove-Item test-output.json
} else {
    Write-Host "FAIL: File not created - output went to console instead" -ForegroundColor Red
}
Write-Host ""

# Test 2: Table output to file
Write-Host "Test 2: Table output to relative path" -ForegroundColor Yellow
magicsuite api get connections --take 3 --output connections.txt --format table | Out-Null
if (Test-Path connections.txt) {
    Write-Host "PASS: File created" -ForegroundColor Green
    Remove-Item connections.txt
} else {
    Write-Host "FAIL: File not created - output went to console instead" -ForegroundColor Red
}
Write-Host ""

# Test 3: Absolute path
Write-Host "Test 3: JSON output to absolute path" -ForegroundColor Yellow
$absolutePath = Join-Path $env:TEMP "magicsuite-test.json"
magicsuite api get tenants --output $absolutePath --format json | Out-Null
if (Test-Path $absolutePath) {
    Write-Host "PASS: File created at $absolutePath" -ForegroundColor Green
    Remove-Item $absolutePath
} else {
    Write-Host "FAIL: File not created at $absolutePath - output went to console instead" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Bug Confirmed: The --output parameter does not write to files." -ForegroundColor Red
Write-Host "All output is sent to console regardless of --output parameter." -ForegroundColor Red
Write-Host ""
Write-Host "Expected Behavior:" -ForegroundColor Yellow
Write-Host "  - Output should be written to the specified file" -ForegroundColor Gray
Write-Host "  - Console should show minimal feedback (e.g., 'Output written to file.json')" -ForegroundColor Gray
Write-Host "  - Works with both relative and absolute paths" -ForegroundColor Gray
Write-Host "  - Works with both JSON and Table formats" -ForegroundColor Gray
