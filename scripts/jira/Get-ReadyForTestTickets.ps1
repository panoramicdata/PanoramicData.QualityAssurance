<#
.SYNOPSIS
    Gets Ready for Test tickets from JIRA and categorizes them by testing method.

.DESCRIPTION
    Queries JIRA for Magic Suite tickets in "Ready for Test" status,
    analyzes them for CLI/Playwright testability, and outputs a prioritized list.
    
    LESSONS LEARNED:
    - Always output to file, not console (terminal buffer issues)
    - Use REST API directly for complex queries (JIRA.ps1 has limitations)
    - Component names must exist exactly or JQL fails with 400 error
    - Keep commands simple - avoid multi-line commands in terminal

.PARAMETER MaxResults
    Maximum number of tickets to retrieve. Default: 50

.PARAMETER OutputPath
    Path to save results. Default: ready-for-test-analysis.md

.EXAMPLE
    .\Get-ReadyForTestTickets.ps1
    .\Get-ReadyForTestTickets.ps1 -MaxResults 100 -OutputPath "my-results.md"

.NOTES
    Requires: $env:JIRA_USERNAME and $env:JIRA_PASSWORD
    Author: QA Team
    Last Updated: 2026-01-25
#>

param(
    [int]$MaxResults = 50,
    [string]$OutputPath = "ready-for-test-analysis.md"
)

# Verify credentials
if (-not $env:JIRA_USERNAME -or -not $env:JIRA_PASSWORD) {
    Write-Error "Missing JIRA credentials. Set `$env:JIRA_USERNAME and `$env:JIRA_PASSWORD"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{ 
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json" 
}

# Simple JQL - avoid component filters (they fail if component doesn't exist)
$jql = "project=MS AND status='Ready for Test' ORDER BY updated DESC"
$body = @{ 
    jql = $jql
    maxResults = $MaxResults
    fields = @("summary", "issuetype", "labels", "fixVersions", "updated", "description") 
} | ConvertTo-Json

Write-Host "Querying JIRA..." -ForegroundColor Cyan

try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/search" -Method POST -Headers $headers -Body $body
} catch {
    Write-Error "JIRA API call failed: $_"
    exit 1
}

Write-Host "Found $($result.total) total Ready for Test tickets" -ForegroundColor Green

# Keywords for categorization
$cliKeywords = @('CLI', 'command line', 'exit code', 'dotnet tool', 'magicsuite', 'api get', 'api patch', '--output', '--profile')
$playwrightKeywords = @('UI', 'button', 'dialog', 'page', 'display', 'menu', 'icon', 'click', 'save', 'open', 'NCalc', 'DataMagic', 'ReportMagic', 'Admin', 'dashboard')
$easyKeywords = @('icon', 'button', 'formatting', 'display', 'visual', 'prompt', 'exit code', 'error message')
$hardKeywords = @('migration', 'refactor', 'split', 'remove', 'processor', 'integration', 'SSR', 'SignalR')

# Categorize tickets
$cliTickets = @()
$playwrightTickets = @()
$bothTickets = @()

foreach ($issue in $result.issues) {
    $summary = $issue.fields.summary
    $description = if ($issue.fields.description) { $issue.fields.description } else { "" }
    $labels = if ($issue.fields.labels) { $issue.fields.labels -join ", " } else { "" }
    $version = if ($issue.fields.fixVersions -and $issue.fields.fixVersions.Count -gt 0) { 
        ($issue.fields.fixVersions | Select-Object -First 1).name 
    } else { "-" }
    $combined = "$summary $description $labels".ToLower()
    
    # Determine testing method
    $isCli = $false
    $isPlaywright = $false
    
    foreach ($kw in $cliKeywords) {
        if ($combined -match [regex]::Escape($kw.ToLower())) { $isCli = $true; break }
    }
    foreach ($kw in $playwrightKeywords) {
        if ($combined -match [regex]::Escape($kw.ToLower())) { $isPlaywright = $true; break }
    }
    
    # Determine ease
    $ease = "Medium"
    foreach ($kw in $easyKeywords) {
        if ($combined -match [regex]::Escape($kw.ToLower())) { $ease = "Easy"; break }
    }
    foreach ($kw in $hardKeywords) {
        if ($combined -match [regex]::Escape($kw.ToLower())) { $ease = "Hard"; break }
    }
    
    $ticket = [PSCustomObject]@{
        Key = $issue.key
        Summary = $summary
        Labels = $labels
        Version = $version
        Ease = $ease
        Updated = $issue.fields.updated
    }
    
    if ($isCli -and $isPlaywright) {
        $bothTickets += $ticket
    } elseif ($isCli) {
        $cliTickets += $ticket
    } elseif ($isPlaywright) {
        $playwrightTickets += $ticket
    } else {
        # Default to Playwright for UI-heavy project
        $playwrightTickets += $ticket
    }
}

# Sort by ease
$easeOrder = @{ "Easy" = 1; "Medium" = 2; "Hard" = 3 }
$cliTickets = $cliTickets | Sort-Object { $easeOrder[$_.Ease] }
$playwrightTickets = $playwrightTickets | Sort-Object { $easeOrder[$_.Ease] }

# Generate Markdown output
$output = @"
# Ready for Test Tickets Analysis

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Total Found:** $($result.total)  
**Analyzed:** $($result.issues.Count)

---

## 🖥️ CLI Testable ($($cliTickets.Count) tickets)

| Ticket | Ease | Summary | Version |
|--------|------|---------|---------|
"@

foreach ($t in $cliTickets) {
    $summaryShort = if ($t.Summary.Length -gt 50) { $t.Summary.Substring(0, 50) + "..." } else { $t.Summary }
    $output += "`n| $($t.Key) | $($t.Ease) | $summaryShort | $($t.Version) |"
}

$output += @"


---

## 🎭 Playwright Testable ($($playwrightTickets.Count) tickets)

| Ticket | Ease | Summary | Version |
|--------|------|---------|---------|
"@

foreach ($t in $playwrightTickets) {
    $summaryShort = if ($t.Summary.Length -gt 50) { $t.Summary.Substring(0, 50) + "..." } else { $t.Summary }
    $output += "`n| $($t.Key) | $($t.Ease) | $summaryShort | $($t.Version) |"
}

$output += @"


---

## 🔄 Both CLI & Playwright ($($bothTickets.Count) tickets)

| Ticket | Ease | Summary | Version |
|--------|------|---------|---------|
"@

foreach ($t in $bothTickets) {
    $summaryShort = if ($t.Summary.Length -gt 50) { $t.Summary.Substring(0, 50) + "..." } else { $t.Summary }
    $output += "`n| $($t.Key) | $($t.Ease) | $summaryShort | $($t.Version) |"
}

$output += @"


---

## 🚀 Quick Start Recommendations

### CLI Testing (run in terminal)
"@

$cliEasy = $cliTickets | Where-Object { $_.Ease -eq "Easy" } | Select-Object -First 3
foreach ($t in $cliEasy) {
    $output += "`n1. **$($t.Key)** - $($t.Summary)"
}

$output += @"


### Playwright Testing (run with --project=firefox)
"@

$pwEasy = $playwrightTickets | Where-Object { $_.Ease -eq "Easy" } | Select-Object -First 3
foreach ($t in $pwEasy) {
    $output += "`n1. **$($t.Key)** - $($t.Summary)"
}

$output += @"


---

*Use ``.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-XXXXX`` for full ticket details*
"@

# Save to file
$output | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nResults saved to: $OutputPath" -ForegroundColor Green
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  CLI tickets: $($cliTickets.Count)" 
Write-Host "  Playwright tickets: $($playwrightTickets.Count)"
Write-Host "  Both: $($bothTickets.Count)"
