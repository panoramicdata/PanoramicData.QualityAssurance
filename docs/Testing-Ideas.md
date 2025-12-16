# Command Line Testing Strategies for MagicSuite CLI

This document outlines various approaches for testing code via command line, specifically tailored for the MagicSuite CLI tool.

---

## 1. Automated Test Scripts

Create PowerShell scripts that run test scenarios and validate outputs automatically.

### Example: Basic Test Runner
```powershell
# test-cli-commands.ps1
$testResults = @()

# Test 1: Check version command
$version = magicsuite --version
$testResults += @{
    Test = "Version Command"
    Expected = "Should return version number"
    Actual = $version
    Pass = $version -match '\d+\.\d+\.\d+'
}

# Test 2: Help command should not error
$helpOutput = magicsuite --help 2>&1
$testResults += @{
    Test = "Help Command"
    Expected = "Should display help without errors"
    Actual = "Exit code: $LASTEXITCODE"
    Pass = $LASTEXITCODE -eq 0
}

# Test 3: Config list should work
$configOutput = magicsuite config list 2>&1
$testResults += @{
    Test = "Config List"
    Expected = "Should display configuration"
    Actual = "Exit code: $LASTEXITCODE"
    Pass = $LASTEXITCODE -eq 0
}

# Report results
Write-Host "`n=== TEST RESULTS ===" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Pass }).Count
$failed = ($testResults | Where-Object { -not $_.Pass }).Count

$testResults | ForEach-Object {
    $status = if ($_.Pass) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($_.Pass) { "Green" } else { "Red" }
    Write-Host "$status - $($_.Test)" -ForegroundColor $color
    if (-not $_.Pass) {
        Write-Host "  Expected: $($_.Expected)" -ForegroundColor Yellow
        Write-Host "  Actual: $($_.Actual)" -ForegroundColor Yellow
    }
}

Write-Host "`nSummary: $passed passed, $failed failed" -ForegroundColor Cyan
```

**Benefits:**
- Automated validation of multiple commands
- Clear pass/fail reporting
- Easy to extend with more tests

---

## 2. Regression Testing

Test all entity types systematically to catch regressions after updates.

### Example: Entity Type Regression Test
```powershell
# regression-test.ps1
$entities = @(
    'tenants', 'connections', 'reportschedules', 
    'reportbatchjobs', 'reportjobs', 'roles', 
    'persons', 'dashboards', 'widgets', 'cases',
    'notifications', 'eventmanagers', 'settings',
    'projects', 'jobs'
)

$results = @()
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "Starting regression test for $($entities.Count) entity types..." -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp`n" -ForegroundColor Gray

foreach ($entity in $entities) {
    Write-Host "Testing: $entity..." -ForegroundColor Yellow
    
    $output = magicsuite api get $entity 2>&1
    $exitCode = $LASTEXITCODE
    
    # Determine error type if failed
    $errorType = "None"
    if ($exitCode -ne 0) {
        if ($output -match "NullReferenceException") {
            $errorType = "NullReferenceException"
        }
        elseif ($output -match "malformed markup") {
            $errorType = "MarkupException"
        }
        elseif ($output -match "Unauthorized") {
            $errorType = "Unauthorized"
        }
        else {
            $errorType = "Other"
        }
    }
    
    $results += [PSCustomObject]@{
        Entity = $entity
        Success = $exitCode -eq 0
        ErrorType = $errorType
        Timestamp = $timestamp
    }
}

# Export results
$csvFile = "regression-test-$timestamp.csv"
$results | Export-Csv $csvFile -NoTypeInformation
Write-Host "`nResults exported to: $csvFile" -ForegroundColor Green

# Summary
$successful = ($results | Where-Object { $_.Success }).Count
$failed = $results.Count - $successful
Write-Host "`n=== REGRESSION TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $successful" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

# Group failures by error type
if ($failed -gt 0) {
    Write-Host "`nFailures by Error Type:" -ForegroundColor Yellow
    $results | Where-Object { -not $_.Success } | 
        Group-Object ErrorType | 
        ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Yellow
        }
}
```

**Benefits:**
- Comprehensive coverage of all entity types
- Tracks error patterns
- Historical data via CSV exports
- Easy to compare results over time

---

## 3. Performance Testing

Measure command execution times to detect performance regressions.

### Example: Performance Benchmark
```powershell
# performance-test.ps1
$commands = @(
    @{Cmd = "magicsuite --version"; Name = "Version Check"},
    @{Cmd = "magicsuite --help"; Name = "Help Command"},
    @{Cmd = "magicsuite config list"; Name = "Config List"},
    @{Cmd = "magicsuite config profiles list"; Name = "Profiles List"},
    @{Cmd = "magicsuite auth status"; Name = "Auth Status"}
)

Write-Host "=== PERFORMANCE BENCHMARK ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)`n" -ForegroundColor Gray

$results = @()
foreach ($test in $commands) {
    Write-Host "Testing: $($test.Name)..." -ForegroundColor Yellow
    
    # Run multiple times for average
    $times = 1..5 | ForEach-Object {
        (Measure-Command { 
            Invoke-Expression $test.Cmd 2>&1 | Out-Null 
        }).TotalMilliseconds
    }
    
    $avg = ($times | Measure-Object -Average).Average
    $min = ($times | Measure-Object -Minimum).Minimum
    $max = ($times | Measure-Object -Maximum).Maximum
    
    $results += [PSCustomObject]@{
        Command = $test.Name
        AverageMs = [math]::Round($avg, 2)
        MinMs = [math]::Round($min, 2)
        MaxMs = [math]::Round($max, 2)
    }
    
    Write-Host "  Average: $([math]::Round($avg, 2))ms" -ForegroundColor White
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Flag slow commands (>1000ms)
$slow = $results | Where-Object { $_.AverageMs -gt 1000 }
if ($slow) {
    Write-Host "`n⚠️  Slow Commands (>1000ms):" -ForegroundColor Yellow
    $slow | ForEach-Object {
        Write-Host "  $($_.Command): $($_.AverageMs)ms" -ForegroundColor Yellow
    }
}
```

**Benefits:**
- Identifies slow commands
- Tracks performance over time
- Multiple runs for accurate averages
- Highlights performance regressions

---

## 4. Output Validation Testing

Verify output formats and data structure correctness.

### Example: JSON Output Validator
```powershell
# validate-output.ps1

function Test-JsonOutput {
    param(
        [string]$Command,
        [string]$TestName,
        [string[]]$ExpectedProperties
    )
    
    Write-Host "Testing: $TestName" -ForegroundColor Yellow
    
    try {
        $jsonOutput = Invoke-Expression "$Command --format Json" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ❌ Command failed" -ForegroundColor Red
            return $false
        }
        
        $parsed = $jsonOutput | ConvertFrom-Json
        Write-Host "  ✅ Valid JSON output" -ForegroundColor Green
        
        # Check expected properties
        $allPropsFound = $true
        foreach ($prop in $ExpectedProperties) {
            if ($parsed.PSObject.Properties.Name -contains $prop) {
                Write-Host "  ✅ Contains property: $prop" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Missing property: $prop" -ForegroundColor Red
                $allPropsFound = $false
            }
        }
        
        return $allPropsFound
        
    } catch {
        Write-Host "  ❌ Invalid JSON: $_" -ForegroundColor Red
        return $false
    }
}

# Run tests
Write-Host "=== OUTPUT VALIDATION TESTS ===`n" -ForegroundColor Cyan

$tests = @(
    @{
        Cmd = "magicsuite config list"
        Name = "Config List JSON"
        Props = @("ActiveProfile", "DefaultOutputFormat")
    }
)

$results = @()
foreach ($test in $tests) {
    $passed = Test-JsonOutput -Command $test.Cmd -TestName $test.Name -ExpectedProperties $test.Props
    $results += @{Name = $test.Name; Passed = $passed}
    Write-Host ""
}

# Summary
$passed = ($results | Where-Object { $_.Passed }).Count
$failed = $results.Count - $passed
Write-Host "Summary: $passed passed, $failed failed" -ForegroundColor Cyan
```

**Benefits:**
- Validates JSON structure
- Ensures expected data fields exist
- Catches data format regressions
- Can validate both JSON and Table formats

---

## 5. Error Handling Tests

Test edge cases and invalid inputs to ensure proper error handling.

### Example: Error Handling Test Suite
```powershell
# error-handling-test.ps1
$errorTests = @(
    @{
        Name = "Invalid Entity Type"
        Cmd = "magicsuite api get faketype"
        ExpectedError = "Unknown entity type"
        ShouldFail = $true
    },
    @{
        Name = "Invalid ID Type"
        Cmd = "magicsuite api get-by-id tenant abc"
        ExpectedError = "Cannot parse argument"
        ShouldFail = $true
    },
    @{
        Name = "Missing Required Parameter"
        Cmd = "magicsuite api patch tenant 1 --set"
        ExpectedError = "Required argument missing"
        ShouldFail = $true
    },
    @{
        Name = "Negative ID"
        Cmd = "magicsuite api get-by-id tenant -1"
        ExpectedError = "error"
        ShouldFail = $true
    },
    @{
        Name = "Empty Filter"
        Cmd = "magicsuite api get tenants --filter ''"
        ExpectedError = $null
        ShouldFail = $false
    }
)

Write-Host "=== ERROR HANDLING TESTS ===`n" -ForegroundColor Cyan

$results = @()
foreach ($test in $errorTests) {
    Write-Host "Testing: $($test.Name)..." -ForegroundColor Yellow
    
    $output = Invoke-Expression $test.Cmd 2>&1
    $actualFailed = $LASTEXITCODE -ne 0
    
    $passed = $actualFailed -eq $test.ShouldFail
    
    if ($test.ExpectedError) {
        $errorFound = $output -match $test.ExpectedError
        $passed = $passed -and $errorFound
    }
    
    $status = if ($passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    
    Write-Host "  $status" -ForegroundColor $color
    
    if (-not $passed) {
        Write-Host "  Expected to fail: $($test.ShouldFail)" -ForegroundColor Yellow
        Write-Host "  Actually failed: $actualFailed" -ForegroundColor Yellow
        if ($test.ExpectedError) {
            Write-Host "  Expected error: $($test.ExpectedError)" -ForegroundColor Yellow
            Write-Host "  Error found: $errorFound" -ForegroundColor Yellow
        }
    }
    
    $results += @{Test = $test.Name; Passed = $passed}
    Write-Host ""
}

# Summary
$passed = ($results | Where-Object { $_.Passed }).Count
$failed = $results.Count - $passed
Write-Host "Summary: $passed passed, $failed failed" -ForegroundColor Cyan
```

**Benefits:**
- Validates error messages
- Tests boundary conditions
- Ensures graceful failure handling
- Catches unexpected behavior

---

## 6. Integration Testing with JIRA

Automatically create bug tickets when tests fail.

### Example: Test with Auto-Reporting
```powershell
# test-and-report.ps1
param(
    [switch]$CreateJiraTickets
)

$testEntity = "reportbatchjobs"

Write-Host "Testing entity: $testEntity" -ForegroundColor Cyan
$output = magicsuite api get $testEntity 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "❌ Test FAILED" -ForegroundColor Red
    Write-Host "Error output:" -ForegroundColor Yellow
    Write-Host $output -ForegroundColor Gray
    
    if ($CreateJiraTickets) {
        Write-Host "`nCreating JIRA ticket..." -ForegroundColor Yellow
        
        $description = @"
*Automated Test Failure*

*Entity Type:* $testEntity
*Command:* magicsuite api get $testEntity
*Date:* $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
*Machine:* $env:COMPUTERNAME
*User:* $env:USERNAME

*Error Output:*
{code}
$output
{code}

*Exit Code:* $exitCode

*Environment:*
- CLI Version: $(magicsuite --version)
- PowerShell Version: $($PSVersionTable.PSVersion)
"@
        
        try {
            .\.github\tools\JIRA.ps1 -Action create -Parameters @{
                ProjectKey = 'MS'
                IssueType = 'Bug'
                Summary = "Automated Test Failure: magicsuite api get $testEntity"
                Description = $description
            }
            
            Write-Host "✅ JIRA ticket created successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to create JIRA ticket: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "✅ Test PASSED" -ForegroundColor Green
}
```

**Usage:**
```powershell
# Run test only
.\test-and-report.ps1

# Run test and create JIRA ticket if it fails
.\test-and-report.ps1 -CreateJiraTickets
```

**Benefits:**
- Automated bug reporting
- Consistent bug documentation
- Reduces manual ticket creation
- Includes comprehensive error details

---

## 7. Comparative Testing

Compare outputs before and after updates to detect changes.

### Example: Version Comparison
```powershell
# compare-versions.ps1
$baselineDir = "baseline"
$currentDir = "current"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $baselineDir, $currentDir | Out-Null

function Capture-Output {
    param([string]$OutputDir)
    
    Write-Host "Capturing output to: $OutputDir" -ForegroundColor Cyan
    
    # Version
    magicsuite --version | Out-File "$OutputDir\version.txt"
    
    # Config
    magicsuite config list | Out-File "$OutputDir\config.txt"
    
    # Profiles
    magicsuite config profiles list | Out-File "$OutputDir\profiles.txt"
    
    # Auth status
    magicsuite auth status 2>&1 | Out-File "$OutputDir\auth-status.txt"
    
    Write-Host "Capture complete" -ForegroundColor Green
}

# Capture baseline before update
Write-Host "=== CAPTURING BASELINE ===`n" -ForegroundColor Yellow
Capture-Output -OutputDir $baselineDir

Write-Host "`nBaseline captured. Update the CLI now, then press Enter..." -ForegroundColor Yellow
Read-Host

# Capture current after update
Write-Host "`n=== CAPTURING CURRENT ===`n" -ForegroundColor Yellow
Capture-Output -OutputDir $currentDir

# Compare
Write-Host "`n=== COMPARING RESULTS ===`n" -ForegroundColor Cyan

$files = Get-ChildItem -Path $baselineDir -Filter *.txt
foreach ($file in $files) {
    $baselinePath = "$baselineDir\$($file.Name)"
    $currentPath = "$currentDir\$($file.Name)"
    
    Write-Host "Comparing: $($file.Name)" -ForegroundColor Yellow
    
    $diff = Compare-Object (Get-Content $baselinePath) (Get-Content $currentPath)
    
    if ($diff) {
        Write-Host "  ⚠️  Differences found:" -ForegroundColor Yellow
        $diff | ForEach-Object {
            $indicator = if ($_.SideIndicator -eq "<=") { "BEFORE" } else { "AFTER" }
            Write-Host "    $indicator : $($_.InputObject)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ No differences" -ForegroundColor Green
    }
    Write-Host ""
}
```

**Benefits:**
- Detects unexpected changes
- Validates updates don't break functionality
- Documents changes between versions
- Useful for release validation

---

## 8. Smoke Testing Suite

Quick validation that basic functionality works after deployment.

### Example: Smoke Test Suite
```powershell
# smoke-test.ps1
function Test-Command {
    param(
        [string]$Name, 
        [string]$Command,
        [string]$ExpectedOutput = $null
    )
    
    try {
        $output = Invoke-Expression $Command 2>&1
        $success = $LASTEXITCODE -eq 0
        
        if ($ExpectedOutput -and $success) {
            $success = $output -match $ExpectedOutput
        }
        
        if ($success) {
            Write-Host "✅ $Name" -ForegroundColor Green
        } else {
            Write-Host "❌ $Name" -ForegroundColor Red
            if ($ExpectedOutput) {
                Write-Host "   Expected: $ExpectedOutput" -ForegroundColor Yellow
                Write-Host "   Got: $output" -ForegroundColor Yellow
            }
        }
        
        return $success
    } catch {
        Write-Host "❌ $Name - Exception: $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "=== SMOKE TEST SUITE ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host "Version: $(magicsuite --version)`n" -ForegroundColor Gray

$tests = @(
    @{Name="Version Check"; Cmd="magicsuite --version"; Expected="\d+\.\d+\.\d+"},
    @{Name="Help Display"; Cmd="magicsuite --help"; Expected="Usage"},
    @{Name="Config List"; Cmd="magicsuite config list"; Expected="Active Profile"},
    @{Name="Profiles List"; Cmd="magicsuite config profiles list"; Expected=$null},
    @{Name="Auth Status"; Cmd="magicsuite auth status"; Expected=$null}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    if (Test-Command -Name $test.Name -Command $test.Cmd -ExpectedOutput $test.Expected) {
        $passed++
    } else {
        $failed++
    }
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`n✅ All smoke tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some tests failed!" -ForegroundColor Red
    exit 1
}
```

**Benefits:**
- Quick validation (< 30 seconds)
- Run after every deployment
- Catches critical failures immediately
- Exit codes for CI/CD integration

---

## 9. Continuous Monitoring

Schedule tests to run periodically and alert on failures.

### Example: Scheduled Monitoring
```powershell
# setup-monitoring.ps1
# This script creates a scheduled task for continuous monitoring

$scriptPath = "C:\Users\amycb\PData\CommandLine\smoke-test.ps1"
$logPath = "C:\Users\amycb\PData\CommandLine\Logs"

# Create log directory
New-Item -ItemType Directory -Force -Path $logPath | Out-Null

# Create monitoring script that logs results
$monitorScript = @"
`$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
`$logFile = "$logPath\test-`$timestamp.log"

# Run smoke test and capture output
& '$scriptPath' | Tee-Object -FilePath `$logFile

# Check if test passed
if (`$LASTEXITCODE -ne 0) {
    # Send alert (email, Teams, etc.)
    Write-Host "Tests failed! Check log: `$logFile" -ForegroundColor Red
}
"@

$monitorScriptPath = "$PSScriptRoot\monitor-cli.ps1"
$monitorScript | Out-File -FilePath $monitorScriptPath -Encoding UTF8

Write-Host "Creating scheduled task..." -ForegroundColor Yellow

# Create scheduled task to run daily
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$monitorScriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At 9am

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

try {
    Register-ScheduledTask `
        -TaskName "MagicSuite CLI Monitor" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Daily smoke tests for MagicSuite CLI" `
        -Force
    
    Write-Host "✅ Scheduled task created successfully" -ForegroundColor Green
    Write-Host "   Task runs daily at 9:00 AM" -ForegroundColor Gray
    Write-Host "   Logs saved to: $logPath" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
}
```

**Benefits:**
- Proactive monitoring
- Historical log tracking
- Early detection of issues
- Automated alerting on failures

---

## 10. Test Coverage Matrix

Track which features have been tested and their status.

### Example: Coverage Tracker
```powershell
# test-coverage.ps1
$coverage = @{
    'Core Commands' = @{
        'version' = @{Tested=$true; Status='Pass'; LastTest='2025-12-08'}
        'help' = @{Tested=$true; Status='Pass'; LastTest='2025-12-08'}
    }
    'Config Commands' = @{
        'list' = @{Tested=$true; Status='Pass'; LastTest='2025-12-08'}
        'set' = @{Tested=$false; Status='Unknown'; LastTest=$null}
        'get' = @{Tested=$false; Status='Unknown'; LastTest=$null}
    }
    'Auth Commands' = @{
        'status' = @{Tested=$true; Status='Pass'; LastTest='2025-12-08'}
        'token' = @{Tested=$false; Status='Unknown'; LastTest=$null}
        'logout' = @{Tested=$false; Status='Unknown'; LastTest=$null}
    }
    'API Commands' = @{
        'get' = @{Tested=$true; Status='Fail'; LastTest='2025-12-08'}
        'get-by-id' = @{Tested=$true; Status='Pass'; LastTest='2025-12-08'}
        'patch' = @{Tested=$false; Status='Unknown'; LastTest=$null}
        'delete' = @{Tested=$false; Status='Unknown'; LastTest=$null}
    }
    'File Commands' = @{
        'list' = @{Tested=$true; Status='Fail-Auth'; LastTest='2025-12-08'}
        'upload' = @{Tested=$false; Status='Unknown'; LastTest=$null}
        'download' = @{Tested=$false; Status='Unknown'; LastTest=$null}
        'delete' = @{Tested=$false; Status='Unknown'; LastTest=$null}
    }
    'Tenant Commands' = @{
        'current' = @{Tested=$true; Status='Fail-Auth'; LastTest='2025-12-08'}
        'select' = @{Tested=$false; Status='Unknown'; LastTest=$null}
    }
}

# Calculate statistics
$allTests = @()
foreach ($category in $coverage.Keys) {
    foreach ($command in $coverage[$category].Keys) {
        $allTests += $coverage[$category][$command]
    }
}

$tested = ($allTests | Where-Object { $_.Tested }).Count
$passed = ($allTests | Where-Object { $_.Status -eq 'Pass' }).Count
$failed = ($allTests | Where-Object { $_.Status -like 'Fail*' }).Count
$untested = ($allTests | Where-Object { -not $_.Tested }).Count
$total = $allTests.Count

# Display report
Write-Host "=== TEST COVERAGE REPORT ===" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Commands: $total" -ForegroundColor White
Write-Host "  Tested: $tested ($([math]::Round($tested/$total*100, 1))%)" -ForegroundColor Cyan
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor Red
Write-Host "  Untested: $untested ($([math]::Round($untested/$total*100, 1))%)" -ForegroundColor Yellow
Write-Host ""

# Detailed breakdown
foreach ($category in $coverage.Keys) {
    Write-Host "$category" -ForegroundColor Cyan
    foreach ($command in $coverage[$category].Keys) {
        $test = $coverage[$category][$command]
        $status = switch ($test.Status) {
            'Pass' { "✅ Pass" }
            'Fail' { "❌ Fail" }
            'Fail-Auth' { "⚠️  Fail (Auth)" }
            'Unknown' { "❓ Not Tested" }
        }
        $lastTest = if ($test.LastTest) { $test.LastTest } else { "Never" }
        Write-Host "  $command : $status (Last: $lastTest)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Export to JSON
$jsonFile = "test-coverage-$(Get-Date -Format 'yyyyMMdd').json"
$coverage | ConvertTo-Json -Depth 5 | Out-File $jsonFile
Write-Host "Coverage data exported to: $jsonFile" -ForegroundColor Green

# Identify gaps
Write-Host "`n=== TESTING GAPS ===" -ForegroundColor Yellow
foreach ($category in $coverage.Keys) {
    $untested = $coverage[$category].Keys | Where-Object { 
        -not $coverage[$category][$_].Tested 
    }
    if ($untested) {
        Write-Host "$category : $($untested -join ', ')" -ForegroundColor Yellow
    }
}
```

**Benefits:**
- Visual overview of test coverage
- Identifies untested features
- Tracks testing progress
- Historical tracking via JSON exports

---

## Summary

These 10 testing strategies provide comprehensive coverage for command-line testing:

1. **Automated Test Scripts** - Basic validation with pass/fail reporting
2. **Regression Testing** - Systematic testing of all features
3. **Performance Testing** - Measure and track execution times
4. **Output Validation** - Verify data structure and format
5. **Error Handling Tests** - Validate edge cases and error messages
6. **JIRA Integration** - Auto-create bug tickets for failures
7. **Comparative Testing** - Compare before/after updates
8. **Smoke Testing** - Quick critical path validation
9. **Continuous Monitoring** - Scheduled automated testing
10. **Coverage Tracking** - Monitor what's tested and what's not

### Recommended Testing Workflow

1. **Daily**: Run smoke tests (5 minutes)
2. **After updates**: Run comparative and regression tests (15 minutes)
3. **Weekly**: Full regression suite with coverage review (30 minutes)
4. **Continuous**: Automated monitoring with JIRA integration

### Next Steps

1. Choose which testing approaches fit your needs
2. Customize scripts for your specific scenarios
3. Set up automated monitoring if desired
4. Integrate with JIRA for automated bug reporting
5. Build a testing dashboard to track metrics over time
