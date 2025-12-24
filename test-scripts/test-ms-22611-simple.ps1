# Test MS-22611: Negative --take parameter
Write-Host "`n=== Testing MS-22611: Negative --take Parameter ===" -ForegroundColor Cyan
Write-Host "CLI Version: 4.2.49+226761fe4d`n" -ForegroundColor Gray

magicsuite api get tenants --take -5 2>&1 | Out-Null
$exit1 = $LASTEXITCODE
Write-Host "Test 1 (--take -5): Exit code $exit1" -ForegroundColor $(if ($exit1 -eq 0) {'Red'} else {'Green'})

magicsuite api get tenants --take 0 2>&1 | Out-Null
$exit2 = $LASTEXITCODE
Write-Host "Test 2 (--take 0): Exit code $exit2" -ForegroundColor $(if ($exit2 -eq 0) {'Red'} else {'Green'})

if (($exit1 -ne 0) -and ($exit2 -ne 0)) {
    Write-Host "`n MS-22611 FIXED" -ForegroundColor Green
} else {
    Write-Host "`n MS-22611 NOT FIXED" -ForegroundColor Red
}
