# Test script for MS-22611: MagicSuite CLI: Negative --take parameter returns exit code 0
# Bug Discovery Date: 2025-12-18
# CLI Version: 4.1.*
# Related: MS-22608 (parent issue - CLI returns exit code 0 on failure)

Write-Host "`n=== MS-22611: Negative --take Parameter Exit Code Test ===" -ForegroundColor Cyan
Write-Host "Bug: CLI shows validation error but returns exit code 0" -ForegroundColor Yellow
Write-Host "Expected: Non-zero exit code for validation errors`n" -ForegroundColor Yellow

# Test 1: Negative value
Write-Host "Test 1: Negative --take value (-5)" -ForegroundColor White
Write-Host "Command: magicsuite api get tenants --take -5`n" -ForegroundColor Gray

magicsuite api get tenants --take -5 2>&1 | Out-Null
$exitCode1 = $LASTEXITCODE

if ($exitCode1 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero)" -ForegroundColor Red
    Write-Host "Bug Status: NOT FIXED" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode1" -ForegroundColor Green
    Write-Host "Bug Status: FIXED" -ForegroundColor Green
}

# Test 2: Zero value (if invalid)
Write-Host "`nTest 2: Zero --take value (0)" -ForegroundColor White
Write-Host "Command: magicsuite api get tenants --take 0`n" -ForegroundColor Gray

magicsuite api get tenants --take 0 2>&1 | Out-Null
$exitCode2 = $LASTEXITCODE

if ($exitCode2 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero if invalid)" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode2" -ForegroundColor Green
}

# Test 3: Extremely large negative value
Write-Host "`nTest 3: Large negative --take value (-999999)" -ForegroundColor White
Write-Host "Command: magicsuite api get tenants --take -999999`n" -ForegroundColor Gray

magicsuite api get tenants --take -999999 2>&1 | Out-Null
$exitCode3 = $LASTEXITCODE

if ($exitCode3 -eq 0) {
    Write-Host "Result: FAIL - Exit code is 0 (should be non-zero)" -ForegroundColor Red
} else {
    Write-Host "Result: PASS - Exit code is $exitCode3" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Test 1 (negative): Exit code $exitCode1" -ForegroundColor $(if ($exitCode1 -eq 0) {'Red'} else {'Green'})
Write-Host "Test 2 (zero): Exit code $exitCode2" -ForegroundColor $(if ($exitCode2 -eq 0) {'Red'} else {'Green'})
Write-Host "Test 3 (large negative): Exit code $exitCode3" -ForegroundColor $(if ($exitCode3 -eq 0) {'Red'} else {'Green'})

$failCount = @($exitCode1, $exitCode2, $exitCode3) | Where-Object {$_ -eq 0} | Measure-Object | Select-Object -ExpandProperty Count

if ($failCount -gt 0) {
    Write-Host "`n✗ MS-22611 NOT FIXED: $failCount validation errors returned exit code 0" -ForegroundColor Red
    Write-Host "Impact: Scripts cannot detect parameter validation failures" -ForegroundColor Yellow
} else {
    Write-Host "`n✓ MS-22611 FIXED: All validation errors return non-zero exit codes" -ForegroundColor Green
}

Write-Host "`nJIRA: https://jira.panoramicdata.com/browse/MS-22611" -ForegroundColor Cyan
