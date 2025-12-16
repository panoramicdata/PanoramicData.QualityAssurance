# Scheduled CLI Update Check with Bug Testing
# This script checks for CLI updates and automatically tests known bugs

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "MagicSuite CLI - Update Check & Bug Testing" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

# Run the update checker
$updateResult = & "$PSScriptRoot\check-cli-updates.ps1"

if ($updateResult.Updated) {
    Write-Host "`n📋 NEW VERSION DETECTED - Running automated bug tests...`n" -ForegroundColor Yellow
    
    $testResults = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        OldVersion = $updateResult.OldVersion
        NewVersion = $updateResult.NewVersion
        Tests = @()
    }
    
    # Test MS-22523 - Profile display issue
    Write-Host "Testing MS-22523 (Profile active indicator)..." -ForegroundColor Cyan
    try {
        $profileOutput = magicsuite config profiles list 2>&1 | Out-String
        $ms22523Fixed = $profileOutput -match "│\s+√\s+│"
        
        $testResults.Tests += @{
            IssueKey = "MS-22523"
            Name = "Profile active indicator"
            Status = if ($ms22523Fixed) { "FIXED" } else { "STILL EXISTS" }
            Output = $profileOutput.Substring(0, [Math]::Min(500, $profileOutput.Length))
        }
        
        if ($ms22523Fixed) {
            Write-Host "  ✓ MS-22523: FIXED - Profile shows checkmark" -ForegroundColor Green
        } else {
            Write-Host "  ✗ MS-22523: STILL EXISTS - Profile shows ?" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ⚠ MS-22523: TEST FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test MS-22570 - File search markup exception
    Write-Host "Testing MS-22570 (File search markup exception)..." -ForegroundColor Cyan
    try {
        $searchOutput = magicsuite file search "test" 2>&1 | Out-String
        $ms22570Fixed = -not ($searchOutput -match "Unhandled exception|InvalidOperationException")
        
        $testResults.Tests += @{
            IssueKey = "MS-22570"
            Name = "File search markup exception"
            Status = if ($ms22570Fixed) { "FIXED" } else { "STILL EXISTS" }
            Output = $searchOutput.Substring(0, [Math]::Min(500, $searchOutput.Length))
        }
        
        if ($ms22570Fixed) {
            Write-Host "  ✓ MS-22570: FIXED - File search works" -ForegroundColor Green
        } else {
            Write-Host "  ✗ MS-22570: STILL EXISTS - File search throws exception" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ⚠ MS-22570: TEST FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test MS-22575 - File list root directory markup exception
    Write-Host "Testing MS-22575 (File list root directory markup)..." -ForegroundColor Cyan
    try {
        $listOutput = magicsuite file list / 2>&1 | Out-String
        $ms22575Fixed = -not ($listOutput -match "Error:|Encountered malformed markup")
        
        $testResults.Tests += @{
            IssueKey = "MS-22575"
            Name = "File list root directory markup exception"
            Status = if ($ms22575Fixed) { "FIXED" } else { "STILL EXISTS" }
            Output = $listOutput.Substring(0, [Math]::Min(500, $listOutput.Length))
        }
        
        if ($ms22575Fixed) {
            Write-Host "  ✓ MS-22575: FIXED - File list root works" -ForegroundColor Green
        } else {
            Write-Host "  ✗ MS-22575: STILL EXISTS - File list root throws error" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ⚠ MS-22575: TEST FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test MS-22563 - File type display shows ??
    Write-Host "Testing MS-22563 (File type display shows ??)..." -ForegroundColor Cyan
    try {
        $fileListOutput = magicsuite file list /Amy 2>&1 | Out-String
        $ms22563Fixed = -not ($fileListOutput -match "│\s+\?\?\s+│")
        
        $testResults.Tests += @{
            IssueKey = "MS-22563"
            Name = "File type display shows ??"
            Status = if ($ms22563Fixed) { "FIXED" } else { "STILL EXISTS" }
            Output = $fileListOutput.Substring(0, [Math]::Min(500, $fileListOutput.Length))
        }
        
        if ($ms22563Fixed) {
            Write-Host "  ✓ MS-22563: FIXED - File type displays correctly" -ForegroundColor Green
        } else {
            Write-Host "  ✗ MS-22563: STILL EXISTS - File type shows ??" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ⚠ MS-22563: TEST FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Save test results
    $testLogDir = Join-Path $PSScriptRoot "logs" "cli-updates"
    if (-not (Test-Path $testLogDir)) {
        New-Item -ItemType Directory -Path $testLogDir -Force | Out-Null
    }
    
    $testLogFile = Join-Path $testLogDir "bug-test-results.json"
    $testHistory = @()
    if (Test-Path $testLogFile) {
        $testHistory = Get-Content $testLogFile -Raw | ConvertFrom-Json
    }
    $testHistory += $testResults
    $testHistory | ConvertTo-Json -Depth 10 | Set-Content $testLogFile -Encoding UTF8
    
    Write-Host "`n  Test results saved to: $testLogFile" -ForegroundColor Gray
    
    # Generate summary report
    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "Test Summary for Version $($updateResult.NewVersion)" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    
    $fixedCount = ($testResults.Tests | Where-Object { $_.Status -eq "FIXED" }).Count
    $stillExistsCount = ($testResults.Tests | Where-Object { $_.Status -eq "STILL EXISTS" }).Count
    
    Write-Host "Fixed: $fixedCount | Still Exists: $stillExistsCount | Total Tests: $($testResults.Tests.Count)" -ForegroundColor White
    
    if ($fixedCount -gt 0) {
        Write-Host "`n✓ Newly Fixed Issues:" -ForegroundColor Green
        $testResults.Tests | Where-Object { $_.Status -eq "FIXED" } | ForEach-Object {
            Write-Host "  - $($_.IssueKey): $($_.Name)" -ForegroundColor Green
        }
    }
    
    if ($stillExistsCount -gt 0) {
        Write-Host "`n✗ Outstanding Issues:" -ForegroundColor Red
        $testResults.Tests | Where-Object { $_.Status -eq "STILL EXISTS" } | ForEach-Object {
            Write-Host "  - $($_.IssueKey): $($_.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n=====================================================" -ForegroundColor Cyan
    
} else {
    Write-Host "`nNo new updates available. Current version: $($updateResult.CurrentVersion)" -ForegroundColor Green
}

Write-Host "`nNext check recommended: $(Get-Date).AddHours(4) -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Cyan
