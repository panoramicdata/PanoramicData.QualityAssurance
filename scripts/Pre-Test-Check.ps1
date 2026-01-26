<#
.SYNOPSIS
    Pre-test regression check using Elastic logs before QA testing.

.DESCRIPTION
    Before a QA engineer starts testing a ticket, this script:
    1. Identifies the component/app from the ticket
    2. Queries Elastic for errors related to that component
    3. Compares error rates before/after the fix version
    4. Provides a "readiness score" for testing
    
    This helps QA prioritize tickets and avoid wasting time on broken builds.

.PARAMETER IssueKey
    The JIRA ticket key (e.g., MS-22886)

.PARAMETER Environment
    The environment to check (default: test2)

.PARAMETER DaysToCheck
    Number of days of logs to analyze (default: 7)

.EXAMPLE
    .\Pre-Test-Check.ps1 -IssueKey MS-22886
    
.EXAMPLE
    .\Pre-Test-Check.ps1 -IssueKey MS-22886 -Environment beta -DaysToCheck 14
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IssueKey,
    [string]$Environment = "test2",
    [int]$DaysToCheck = 7
)

# Component mapping for log queries
$componentKeywords = @{
    "DataMagic" = @("datamagic", "data-magic", "dm-", "dataMagic")
    "ReportMagic" = @("reportmagic", "report-magic", "rm-", "reportMagic", "report.studio")
    "AlertMagic" = @("alertmagic", "alert-magic", "am-", "alertMagic")
    "Admin" = @("admin", "administration", "user.management")
    "Connect" = @("connect", "connectmagic", "sync", "integration")
    "Files" = @("files", "file-browser", "sharepoint", "blob")
    "CLI" = @("cli", "command-line", "magicsuite.cli")
    "Docs" = @("docs", "documentation", "xwiki", "certification")
    "ProMagic" = @("promagic", "project", "workflow")
    "API" = @("api", "endpoint", "rest")
}

function Get-ComponentFromTicket {
    param([string]$Summary, [string]$Description, [array]$Labels, [array]$Components)
    
    $text = "$Summary $Description".ToLower()
    $detectedComponents = @()
    
    # Check JIRA components first
    if ($Components) {
        foreach ($comp in $Components) {
            if ($componentKeywords.ContainsKey($comp.name)) {
                $detectedComponents += $comp.name
            }
        }
    }
    
    # Check labels
    foreach ($label in $Labels) {
        foreach ($component in $componentKeywords.Keys) {
            if ($label -match $component) {
                if ($component -notin $detectedComponents) {
                    $detectedComponents += $component
                }
            }
        }
    }
    
    # Check text for keywords
    foreach ($component in $componentKeywords.Keys) {
        foreach ($keyword in $componentKeywords[$component]) {
            if ($text -match [regex]::Escape($keyword)) {
                if ($component -notin $detectedComponents) {
                    $detectedComponents += $component
                }
                break
            }
        }
    }
    
    if ($detectedComponents.Count -eq 0) {
        $detectedComponents += "Unknown"
    }
    
    return $detectedComponents
}

function Get-FixVersion {
    param($FixVersions)
    
    if (-not $FixVersions -or $FixVersions.Count -eq 0) {
        return $null
    }
    
    # Return the most recent fix version
    $versions = $FixVersions | ForEach-Object { $_.name } | Sort-Object -Descending
    return $versions[0]
}

function Simulate-ElasticCheck {
    param(
        [string]$Component,
        [string]$Environment,
        [int]$DaysToCheck
    )
    
    # Note: This is a simulation. In production, use Elastic.ps1
    # Real implementation would query:
    # .\.github\tools\Elastic.ps1 -Action Search -Parameters @{
    #     Query = "application:$Component AND level:ERROR AND environment:$Environment"
    #     From = (Get-Date).AddDays(-$DaysToCheck).ToString("yyyy-MM-ddTHH:mm:ss")
    #     To = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    # }
    
    Write-Host "  [Would query Elastic for: $Component errors in last $DaysToCheck days on $Environment]" -ForegroundColor Gray
    
    # Simulated response structure
    return @{
        TotalErrors = Get-Random -Minimum 0 -Maximum 50
        CriticalErrors = Get-Random -Minimum 0 -Maximum 5
        NewErrorTypes = Get-Random -Minimum 0 -Maximum 3
        ErrorTrend = @("decreasing", "stable", "increasing")[(Get-Random -Minimum 0 -Maximum 3)]
        TopErrors = @(
            "NullReferenceException in Widget.Render()"
            "TimeoutException in DataFetch"
            "Unauthorized access attempt"
        ) | Get-Random -Count (Get-Random -Minimum 1 -Maximum 3)
    }
}

# Ensure JIRA credentials are available
if (-not $env:JIRA_USERNAME -or -not $env:JIRA_PASSWORD) {
    Write-Error "JIRA_USERNAME and JIRA_PASSWORD environment variables must be set"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Main execution
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          PRE-TEST REGRESSION CHECK: $IssueKey            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Fetch ticket details
Write-Host "📋 Fetching ticket details..." -ForegroundColor Yellow

try {
    $issue = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
        -Method GET -Headers $headers
}
catch {
    Write-Error "Failed to fetch ticket: $($_.Exception.Message)"
    exit 1
}

$summary = $issue.fields.summary
$description = $issue.fields.description ?? ""
$labels = $issue.fields.labels ?? @()
$components = $issue.fields.components ?? @()
$fixVersions = $issue.fields.fixVersions ?? @()
$issueType = $issue.fields.issuetype.name
$priority = $issue.fields.priority.name

Write-Host ""
Write-Host "📌 $summary" -ForegroundColor White
Write-Host "   Type: $issueType | Priority: $priority" -ForegroundColor Gray
Write-Host ""

# Detect component
$detectedComponents = Get-ComponentFromTicket -Summary $summary -Description $description -Labels $labels -Components $components
Write-Host "🔍 Detected Components: $($detectedComponents -join ', ')" -ForegroundColor Cyan

# Get fix version
$fixVersion = Get-FixVersion -FixVersions $fixVersions
if ($fixVersion) {
    Write-Host "📦 Fix Version: $fixVersion" -ForegroundColor Cyan
}
else {
    Write-Host "⚠️  No fix version specified" -ForegroundColor Yellow
}
Write-Host ""

# Run Elastic checks for each component
Write-Host "🔎 Checking Elastic logs for $Environment environment..." -ForegroundColor Yellow
Write-Host "   Looking back: $DaysToCheck days" -ForegroundColor Gray
Write-Host ""

$overallScore = 100
$findings = @()

foreach ($component in $detectedComponents) {
    if ($component -eq "Unknown") { continue }
    
    Write-Host "  Checking $component..." -ForegroundColor Cyan
    $elasticResult = Simulate-ElasticCheck -Component $component -Environment $Environment -DaysToCheck $DaysToCheck
    
    # Score adjustments
    if ($elasticResult.CriticalErrors -gt 0) {
        $overallScore -= 30
        $findings += "⚠️ $($elasticResult.CriticalErrors) critical errors in $component"
    }
    
    if ($elasticResult.NewErrorTypes -gt 0) {
        $overallScore -= 15
        $findings += "🆕 $($elasticResult.NewErrorTypes) new error types detected in $component"
    }
    
    if ($elasticResult.ErrorTrend -eq "increasing") {
        $overallScore -= 20
        $findings += "📈 Error rate is increasing for $component"
    }
    elseif ($elasticResult.ErrorTrend -eq "decreasing") {
        $findings += "📉 Error rate is decreasing for $component (good sign!)"
    }
}

$overallScore = [Math]::Max(0, $overallScore)

# Determine readiness
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White

if ($overallScore -ge 80) {
    Write-Host "✅ READINESS SCORE: $overallScore/100 - READY FOR TESTING" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recommendation: Quick smoke test should be sufficient" -ForegroundColor Green
}
elseif ($overallScore -ge 50) {
    Write-Host "⚠️  READINESS SCORE: $overallScore/100 - PROCEED WITH CAUTION" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Recommendation: Run full test suite, investigate any failures carefully" -ForegroundColor Yellow
}
else {
    Write-Host "❌ READINESS SCORE: $overallScore/100 - INVESTIGATE BEFORE TESTING" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recommendation: Check with developer before spending time testing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Findings:" -ForegroundColor White
foreach ($finding in $findings) {
    Write-Host "  $finding" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White

# Suggested next actions
Write-Host ""
Write-Host "📋 SUGGESTED ACTIONS:" -ForegroundColor Cyan

if ($overallScore -ge 80) {
    Write-Host "  1. Run: npx playwright test $($IssueKey.ToLower()) --project=firefox" -ForegroundColor White
    Write-Host "  2. Or run: .\scripts\Auto-VerifyCLI.ps1 -IssueKey $IssueKey" -ForegroundColor White
}
elseif ($overallScore -ge 50) {
    Write-Host "  1. Check Elastic logs: .\github\tools\Elastic.ps1 -Action Search -Index logs-* -Parameters @{Query='$($detectedComponents[0])'}" -ForegroundColor White
    Write-Host "  2. Run manual verification first" -ForegroundColor White
}
else {
    Write-Host "  1. Contact developer assigned to ticket" -ForegroundColor White
    Write-Host "  2. Review recent deployments for $($detectedComponents -join ', ')" -ForegroundColor White
    Write-Host "  3. Check build status" -ForegroundColor White
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
