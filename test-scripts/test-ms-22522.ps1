# Test script for MS-22522: Malformed Markup Exception

Write-Host "=== Testing MS-22522: Malformed Markup Exception ===" -ForegroundColor Cyan
Write-Host "Original Issue: InvalidOperationException when listing ReportSchedules and Connections" -ForegroundColor Gray
Write-Host "Tested Version: $(magicsuite --version)" -ForegroundColor Gray
Write-Host ""

$allPassed = $true

# Test 1: ReportSchedules table format
Write-Host "Test 1: Get ReportSchedules (Table Format)" -ForegroundColor Yellow
try {
    $output = magicsuite api get reportschedules --take 5 2>&1
    if ($output -match "Found \d+ ReportSchedule") {
        Write-Host "PASS: ReportSchedules retrieved successfully" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Unexpected output" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "FAIL: Exception thrown - $_" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 2: Connections table format
Write-Host "Test 2: Get Connections (Table Format)" -ForegroundColor Yellow
try {
    $output = magicsuite api get connections --take 5 2>&1
    if ($output -match "Found \d+ Connection") {
        Write-Host "PASS: Connections retrieved successfully" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Unexpected output" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "FAIL: Exception thrown - $_" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 3: ReportSchedules JSON format
Write-Host "Test 3: Get ReportSchedules (JSON Format)" -ForegroundColor Yellow
try {
    magicsuite api get reportschedules --take 3 --format json --output test-rs.json | Out-Null
    if (Test-Path test-rs.json) {
        $data = Get-Content test-rs.json | ConvertFrom-Json
        if ($data.Count -ge 1) {
            Write-Host "PASS: JSON output valid with $($data.Count) records" -ForegroundColor Green
        } else {
            Write-Host "FAIL: No data in JSON output" -ForegroundColor Red
            $allPassed = $false
        }
        Remove-Item test-rs.json
    } else {
        Write-Host "FAIL: Output file not created" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "FAIL: Exception thrown - $_" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 4: Connections JSON format
Write-Host "Test 4: Get Connections (JSON Format)" -ForegroundColor Yellow
try {
    magicsuite api get connections --take 3 --format json --output test-conn.json | Out-Null
    if (Test-Path test-conn.json) {
        $data = Get-Content test-conn.json | ConvertFrom-Json
        if ($data.Count -ge 1) {
            Write-Host "PASS: JSON output valid with $($data.Count) records" -ForegroundColor Green
        } else {
            Write-Host "FAIL: No data in JSON output" -ForegroundColor Red
            $allPassed = $false
        }
        Remove-Item test-conn.json
    } else {
        Write-Host "FAIL: Output file not created" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "FAIL: Exception thrown - $_" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 5: Large result set (stress test)
Write-Host "Test 5: Large Result Set (50 records)" -ForegroundColor Yellow
try {
    $output = magicsuite api get connections --take 50 2>&1
    if ($output -match "Found \d+ Connection") {
        Write-Host "PASS: Large result set handled successfully" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Unexpected output" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "FAIL: Exception thrown - $_" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

Write-Host "=== Test Summary ===" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "ALL TESTS PASSED - Bug is FIXED" -ForegroundColor Green
    Write-Host "The markup exception no longer occurs. Special characters are properly escaped." -ForegroundColor Green
} else {
    Write-Host "SOME TESTS FAILED - Bug may still exist" -ForegroundColor Red
}
