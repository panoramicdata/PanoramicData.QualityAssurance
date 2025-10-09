# MS-21863 Log Analysis Script
# Analyzes collected logs for SharePoint copy errors and patterns related to the regression

Write-Host "Analyzing MS-21863 logs for SharePoint copy error patterns..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$logFolder = "logs\MS-21863"
$analysisFile = "$logFolder\detailed-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$errorPatternsFile = "$logFolder\error-patterns-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Initialize analysis results
$analysis = @{
    SharePointErrors = @()
    CopyOperations = @()
    NotFoundErrors = @()
    SettingsRmscriptRefs = @()
    TempFolderOps = @()
    VersionInfo = @()
    CAEAgentErrors = @()
}

Write-Host "1. Analyzing SharePoint logs..." -ForegroundColor Yellow

# Load and parse SharePoint logs
$sharepointLogFile = Get-ChildItem "$logFolder\sharepoint-logs-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($sharepointLogFile) {
    try {
        $sharepointData = Get-Content $sharepointLogFile.FullName | ConvertFrom-Json
        $hits = $sharepointData.hits.hits
        
        Write-Host "  Processing $($hits.Count) SharePoint log entries..." -ForegroundColor Gray
        
        foreach ($hit in $hits) {
            $source = $hit._source
            $message = $source.message
            $timestamp = $source.'@timestamp'
            $labels = $source.labels
            
            # Check for version information
            if ($labels -and $labels.Version) {
                $analysis.VersionInfo += @{
                    Timestamp = $timestamp
                    Version = $labels.Version
                    Environment = $labels.Environment
                    Application = $labels.Application
                    Message = $message
                }
            }
            
            # Check for copy-related operations
            if ($message -match "copy|move|file|folder|create" -and $message -match -i "sharepoint") {
                $analysis.CopyOperations += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                    Logger = $source.log.logger
                }
            }
            
            # Check for "not found" errors
            if ($message -match -i "not found|file not found|cannot find|does not exist") {
                $analysis.NotFoundErrors += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                    Logger = $source.log.logger
                }
            }
            
            # Check for Settings.rmscript references
            if ($message -match -i "settings\.rmscript|\.rmscript") {
                $analysis.SettingsRmscriptRefs += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                }
            }
            
            # Check for temp folder operations
            if ($message -match -i "temp|temporary|/temp|\\temp") {
                $analysis.TempFolderOps += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                }
            }
            
            # Check for general SharePoint errors
            if ($message -match -i "error|exception|failed|failure" -and $message -match -i "sharepoint") {
                $analysis.SharePointErrors += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                    Logger = $source.log.logger
                }
            }
        }
        
        Write-Host "  ✓ SharePoint logs analyzed" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Error analyzing SharePoint logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. Analyzing CAE Agent logs..." -ForegroundColor Yellow

# Load and parse CAE Agent logs
$caeLogFile = Get-ChildItem "$logFolder\cae-agent-logs-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($caeLogFile) {
    try {
        $caeData = Get-Content $caeLogFile.FullName | ConvertFrom-Json
        $hits = $caeData.hits.hits
        
        Write-Host "  Processing $($hits.Count) CAE Agent log entries..." -ForegroundColor Gray
        
        foreach ($hit in $hits) {
            $source = $hit._source
            $message = $source.message
            $timestamp = $source.'@timestamp'
            
            # Check for CAE-related errors
            if ($message -match -i "error|exception|failed|failure" -and 
                ($message -match -i "cae|portal|agent")) {
                $analysis.CAEAgentErrors += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                    Logger = $source.log.logger
                }
            }
            
            # Also check for copy operations in CAE context
            if ($message -match -i "copy|move|file|folder" -and 
                ($message -match -i "cae|portal|agent")) {
                $analysis.CopyOperations += @{
                    Timestamp = $timestamp
                    Message = $message
                    Index = $hit._index
                    Source = "CAE Agent"
                }
            }
        }
        
        Write-Host "  ✓ CAE Agent logs analyzed" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Error analyzing CAE Agent logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Generating detailed analysis report..." -ForegroundColor Yellow

# Generate detailed analysis markdown report
$report = @"
# MS-21863 Detailed Log Analysis Report

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Ticket**: MS-21863 - SharePoint File Copy Regression  
**Analysis Period**: September 24, 2025 onwards  

## Executive Summary

### Total Findings
- **Version References**: $($analysis.VersionInfo.Count) entries
- **SharePoint Errors**: $($analysis.SharePointErrors.Count) entries  
- **Copy Operations**: $($analysis.CopyOperations.Count) entries
- **"Not Found" Errors**: $($analysis.NotFoundErrors.Count) entries
- **Settings.rmscript References**: $($analysis.SettingsRmscriptRefs.Count) entries
- **Temp Folder Operations**: $($analysis.TempFolderOps.Count) entries
- **CAE Agent Errors**: $($analysis.CAEAgentErrors.Count) entries

## Version Information Analysis

### Detected Versions
"@

# Add version information
if ($analysis.VersionInfo.Count -gt 0) {
    $report += "`n"
    $uniqueVersions = $analysis.VersionInfo | Group-Object Version | Sort-Object Name
    foreach ($version in $uniqueVersions) {
        $report += "- **Version $($version.Name)**: $($version.Count) occurrences`n"
        $latestEntry = $version.Group | Sort-Object Timestamp -Descending | Select-Object -First 1
        $report += "  - Latest: $($latestEntry.Timestamp) in $($latestEntry.Environment)`n"
    }
} else {
    $report += "`nNo version information found in analyzed logs.`n"
}

# Add critical findings sections
$report += @"

## Critical Findings for MS-21863

### "Not Found" Errors
"@

if ($analysis.NotFoundErrors.Count -gt 0) {
    $report += "`n**Found $($analysis.NotFoundErrors.Count) 'Not Found' errors - CRITICAL for regression analysis**`n`n"
    $analysis.NotFoundErrors | ForEach-Object {
        $report += "- **$($_.Timestamp)**: $($_.Message)`n"
        $report += "  - Index: $($_.Index)`n"
        if ($_.Logger) { $report += "  - Logger: $($_.Logger)`n" }
        $report += "`n"
    }
} else {
    $report += "`nNo 'Not Found' errors detected in analyzed logs.`n"
}

$report += @"

### Settings.rmscript File References
"@

if ($analysis.SettingsRmscriptRefs.Count -gt 0) {
    $report += "`n**Found $($analysis.SettingsRmscriptRefs.Count) Settings.rmscript references**`n`n"
    $analysis.SettingsRmscriptRefs | ForEach-Object {
        $report += "- **$($_.Timestamp)**: $($_.Message)`n"
        $report += "  - Index: $($_.Index)`n`n"
    }
} else {
    $report += "`nNo Settings.rmscript file references found in analyzed logs.`n"
}

$report += @"

### Temp Folder Operations
"@

if ($analysis.TempFolderOps.Count -gt 0) {
    $report += "`n**Found $($analysis.TempFolderOps.Count) temp folder operations**`n`n"
    $analysis.TempFolderOps | ForEach-Object {
        $report += "- **$($_.Timestamp)**: $($_.Message)`n"
        $report += "  - Index: $($_.Index)`n`n"
    }
} else {
    $report += "`nNo temp folder operations found in analyzed logs.`n"
}

$report += @"

### SharePoint-Specific Errors
"@

if ($analysis.SharePointErrors.Count -gt 0) {
    $report += "`n**Found $($analysis.SharePointErrors.Count) SharePoint-related errors**`n`n"
    $analysis.SharePointErrors | ForEach-Object {
        $report += "- **$($_.Timestamp)**: $($_.Message)`n"
        $report += "  - Index: $($_.Index)`n"
        if ($_.Logger) { $report += "  - Logger: $($_.Logger)`n" }
        $report += "`n"
    }
} else {
    $report += "`nNo SharePoint-specific errors found in analyzed logs.`n"
}

$report += @"

### CAE Agent Errors
"@

if ($analysis.CAEAgentErrors.Count -gt 0) {
    $report += "`n**Found $($analysis.CAEAgentErrors.Count) CAE Agent errors**`n`n"
    $analysis.CAEAgentErrors | ForEach-Object {
        $report += "- **$($_.Timestamp)**: $($_.Message)`n"
        $report += "  - Index: $($_.Index)`n"
        if ($_.Logger) { $report += "  - Logger: $($_.Logger)`n" }
        $report += "`n"
    }
} else {
    $report += "`nNo CAE Agent errors found in analyzed logs.`n"
}

$report += @"

## Recommendations

### Immediate Actions
1. **Focus on "Not Found" Errors**: $(if ($analysis.NotFoundErrors.Count -gt 0) { "Investigate the $($analysis.NotFoundErrors.Count) detected errors" } else { "Expand search to find copy-related failures" })
2. **Version Correlation**: $(if ($analysis.VersionInfo.Count -gt 0) { "Analyze version transition timeline" } else { "Search for version 3.27.351 specifically" })
3. **File Operation Patterns**: $(if ($analysis.CopyOperations.Count -gt 0) { "Review $($analysis.CopyOperations.Count) copy operations for failures" } else { "Expand search for file system operations" })

### Extended Analysis Needed
1. **Targeted Error Search**: Query error-specific indices if available
2. **Version-Specific Logs**: Search specifically for v3.27.351 logs  
3. **File System Logs**: Look for system-level file operation logs
4. **Timeline Correlation**: Map findings to MS-21863 creation date (Sept 24)

## Test Plan Correlation

The findings should be correlated with:
- **Test Case 1**: Version Comparison Testing (3.26.501 vs 3.27.351)
- **Test Case 2**: Basic SharePoint File Copy Reproduction  
- **Test Case 3**: File System Variation Testing

## Next Steps

1. **Deep Dive**: Focus on any identified error patterns
2. **Extended Search**: Run additional queries based on findings
3. **Test Execution**: Use findings to guide test case execution
4. **Root Cause**: Correlate log patterns with code changes between versions

---

**Analysis Complete**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Status**: $(if (($analysis.NotFoundErrors.Count -gt 0) -or ($analysis.SharePointErrors.Count -gt 0)) { "Critical patterns found - proceed with targeted investigation" } else { "No critical patterns found - expand search criteria" })
"@

# Save the analysis report
$report | Out-File $analysisFile -Encoding UTF8

Write-Host "  ✓ Detailed analysis report saved: $analysisFile" -ForegroundColor Green

Write-Host ""
Write-Host "4. Extracting error patterns..." -ForegroundColor Yellow

# Create error patterns summary
$errorPatterns = @()
$errorPatterns += "# MS-21863 Error Pattern Extraction"
$errorPatterns += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$errorPatterns += ""

if ($analysis.NotFoundErrors.Count -gt 0) {
    $errorPatterns += "## 'Not Found' Error Patterns"
    $analysis.NotFoundErrors | ForEach-Object {
        $errorPatterns += $_.Message
    }
    $errorPatterns += ""
}

if ($analysis.SharePointErrors.Count -gt 0) {
    $errorPatterns += "## SharePoint Error Patterns" 
    $analysis.SharePointErrors | ForEach-Object {
        $errorPatterns += $_.Message
    }
    $errorPatterns += ""
}

if ($analysis.CAEAgentErrors.Count -gt 0) {
    $errorPatterns += "## CAE Agent Error Patterns"
    $analysis.CAEAgentErrors | ForEach-Object {
        $errorPatterns += $_.Message  
    }
}

$errorPatterns -join "`n" | Out-File $errorPatternsFile -Encoding UTF8

Write-Host "  ✓ Error patterns extracted: $errorPatternsFile" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Log Analysis Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Key Results:" -ForegroundColor White
Write-Host "- Version References: $($analysis.VersionInfo.Count)" -ForegroundColor $(if ($analysis.VersionInfo.Count -gt 0) { "Green" } else { "Yellow" })
Write-Host "- 'Not Found' Errors: $($analysis.NotFoundErrors.Count)" -ForegroundColor $(if ($analysis.NotFoundErrors.Count -gt 0) { "Red" } else { "Green" })  
Write-Host "- SharePoint Errors: $($analysis.SharePointErrors.Count)" -ForegroundColor $(if ($analysis.SharePointErrors.Count -gt 0) { "Red" } else { "Green" })
Write-Host "- Settings.rmscript Refs: $($analysis.SettingsRmscriptRefs.Count)" -ForegroundColor $(if ($analysis.SettingsRmscriptRefs.Count -gt 0) { "Green" } else { "Yellow" })
Write-Host "- Temp Folder Ops: $($analysis.TempFolderOps.Count)" -ForegroundColor $(if ($analysis.TempFolderOps.Count -gt 0) { "Green" } else { "Yellow" })
Write-Host "- CAE Agent Errors: $($analysis.CAEAgentErrors.Count)" -ForegroundColor $(if ($analysis.CAEAgentErrors.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Reports saved to logs\MS-21863\ folder" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan