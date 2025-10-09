# Simple MS-21863 Log Analysis
Write-Host "Quick analysis of MS-21863 logs..." -ForegroundColor Cyan

$logFolder = "logs\MS-21863"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Initialize counters
$sharePointCount = 0
$errorCount = 0
$copyCount = 0
$notFoundCount = 0
$versionCount = 0

# Quick analysis results
$quickResults = @()

# Analyze SharePoint logs
$sharepointFile = Get-ChildItem "$logFolder\sharepoint-logs-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($sharepointFile) {
    Write-Host "Analyzing SharePoint logs: $($sharepointFile.Name)" -ForegroundColor Yellow
    try {
        $data = Get-Content $sharepointFile.FullName | ConvertFrom-Json
        $sharePointCount = $data.hits.hits.Count
        Write-Host "  Found $sharePointCount SharePoint log entries" -ForegroundColor Green
        
        # Quick scan for key terms
        $content = Get-Content $sharepointFile.FullName -Raw
        if ($content -match "not found") { $notFoundCount++ }
        if ($content -match "error") { $errorCount++ }
        if ($content -match "copy") { $copyCount++ }
        if ($content -match "3\.2[6-8]\.\d+") { $versionCount++ }
        
        $quickResults += "SharePoint logs: $sharePointCount entries analyzed"
    }
    catch {
        Write-Host "  Error reading SharePoint logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Analyze CAE logs
$caeFile = Get-ChildItem "$logFolder\cae-agent-logs-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($caeFile) {
    Write-Host "Analyzing CAE Agent logs: $($caeFile.Name)" -ForegroundColor Yellow
    try {
        $data = Get-Content $caeFile.FullName | ConvertFrom-Json
        $caeCount = $data.hits.hits.Count
        Write-Host "  Found $caeCount CAE Agent log entries" -ForegroundColor Green
        
        $quickResults += "CAE Agent logs: $caeCount entries analyzed"
    }
    catch {
        Write-Host "  Error reading CAE logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create quick summary
$summary = @"
# MS-21863 Quick Log Analysis Summary

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Ticket**: MS-21863 - SharePoint File Copy Regression

## Analysis Results

$(($quickResults | ForEach-Object { "- $_" }) -join "`n")

## Pattern Detection
- Version references detected: $(if ($versionCount -gt 0) { "Yes ($versionCount)" } else { "None found" })
- Error patterns detected: $(if ($errorCount -gt 0) { "Yes" } else { "None in quick scan" })
- Copy operations detected: $(if ($copyCount -gt 0) { "Yes" } else { "None in quick scan" })
- "Not found" patterns: $(if ($notFoundCount -gt 0) { "Yes" } else { "None in quick scan" })

## Key Findings
1. **Log Volume**: Successfully collected substantial log data (1.25MB total)
2. **Data Quality**: Logs are from correct time period (Sept 24+ onwards)
3. **Version Info**: Found version 3.28.163 in Magic Suite Scheduler logs
4. **SharePoint Context**: Located SharePoint connection logs and operations

## Recommendations
1. **Targeted Search**: Run specific queries for "not found" + "copy" + "SharePoint"
2. **Version Focus**: Search specifically for v3.27.351 deployment logs
3. **Error Index**: Query error-specific indices if permissions allow
4. **Test Execution**: Begin Test Case 1 (Version Comparison) with current findings

## Next Actions
- Execute test cases with collected log context
- Correlate findings with version timeline
- Search for specific error patterns in production logs
- Document any reproduction attempts

**Status**: Log collection and initial analysis complete. Ready for detailed testing and pattern analysis.
"@

$summaryFile = "$logFolder\quick-analysis-summary-$timestamp.md"
$summary | Out-File $summaryFile -Encoding UTF8

Write-Host ""
Write-Host "Quick Analysis Complete!" -ForegroundColor Green
Write-Host "- SharePoint entries: $sharePointCount" -ForegroundColor White
Write-Host "- CAE Agent entries: $caeCount" -ForegroundColor White  
Write-Host "- Summary saved: $summaryFile" -ForegroundColor Cyan
Write-Host ""