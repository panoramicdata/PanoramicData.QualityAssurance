# Test script for MS-22612: MagicSuite CLI: --output to non-existent directory returns exit code 0
# Bug Discovery Date: 2025-12-18
# CLI Version: 4.1.323+b1d2df9293
# Related: MS-22608 (parent issue), MS-22611 (sibling issue)

Write-Host "`n=== MS-22612: --output Directory Error Exit Code Test ===" -ForegroundColor Cyan
Write-Host "Bug: CLI shows file I/O error but returns exit code 0" -ForegroundColor Yellow
Write-Host "Expected: Non-zero exit code for file write failures`n" -ForegroundColor Yellow

# Test 1: Non-existent directory
Write-Host "Test 1: Output to non-existent directory" -ForegroundColor White
$testPath1 = "C:\NonExistentDirectory_$(Get-Random)\output.txt"
Write-Host "Command: magicsuite api get tenants --take 1 --output `"$testPath1`"`n" -ForegroundColor Gray

magicsuite api get tenants --take 1 --output "$testPath1" 2>&1 | Out-Null
$exitCode1 = $LASTEXITCODE

if ($exitCode1 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero)" -ForegroundColor Red
    Write-Host "Bug Status: NOT FIXED" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode1" -ForegroundColor Green
    Write-Host "Bug Status: FIXED" -ForegroundColor Green
}

# Verify file was NOT created
if (Test-Path $testPath1) {
    Write-Host "Warning: File was created despite error!" -ForegroundColor Yellow
} else {
    Write-Host "Confirmed: File was not created (expected)" -ForegroundColor Gray
}

# Test 2: Nested non-existent directories
Write-Host "`nTest 2: Output to deeply nested non-existent path" -ForegroundColor White
$testPath2 = "C:\NonExist1\NonExist2\NonExist3\output.txt"
Write-Host "Command: magicsuite api get tenants --take 1 --output `"$testPath2`"`n" -ForegroundColor Gray

magicsuite api get tenants --take 1 --output "$testPath2" 2>&1 | Out-Null
$exitCode2 = $LASTEXITCODE

if ($exitCode2 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero)" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode2" -ForegroundColor Green
}

# Test 3: Invalid path characters (if Windows)
Write-Host "`nTest 3: Output to path with invalid characters" -ForegroundColor White
$testPath3 = "C:\InvalidPath<>|`"?\output.txt"
Write-Host "Command: magicsuite api get tenants --take 1 --output `"$testPath3`"`n" -ForegroundColor Gray

magicsuite api get tenants --take 1 --output "$testPath3" 2>&1 | Out-Null
$exitCode3 = $LASTEXITCODE

if ($exitCode3 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero)" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode3" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Test 1 (non-existent dir): Exit code $exitCode1" -ForegroundColor $(if ($exitCode1 -eq 0) {'Red'} else {'Green'})
Write-Host "Test 2 (nested non-existent): Exit code $exitCode2" -ForegroundColor $(if ($exitCode2 -eq 0) {'Red'} else {'Green'})
Write-Host "Test 3 (invalid chars): Exit code $exitCode3" -ForegroundColor $(if ($exitCode3 -eq 0) {'Red'} else {'Green'})

$failCount = @($exitCode1, $exitCode2, $exitCode3) | Where-Object {$_ -eq 0} | Measure-Object | Select-Object -ExpandProperty Count

if ($failCount -gt 0) {
    Write-Host "`n✗ MS-22612 NOT FIXED: $failCount file I/O errors returned exit code 0" -ForegroundColor Red
    Write-Host "Impact: Silent data loss risk - scripts cannot detect output failures" -ForegroundColor Yellow
} else {
    Write-Host "`n✓ MS-22612 FIXED: All file I/O errors return non-zero exit codes" -ForegroundColor Green
}

Write-Host "`nJIRA: https://jira.panoramicdata.com/browse/MS-22612" -ForegroundColor Cyan
