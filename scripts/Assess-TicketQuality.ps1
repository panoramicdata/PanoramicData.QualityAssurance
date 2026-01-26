<#
.SYNOPSIS
    Assess the quality and completeness of JIRA ticket specifications.

.DESCRIPTION
    Analyzes a JIRA ticket and scores it based on specification quality factors:
    - Component identification
    - Description completeness
    - Testability (clear pass/fail criteria)
    - Steps to reproduce (for bugs)
    - Current vs expected behavior (for bugs)
    - Environment/version information
    - Attachments/evidence
    
    Helps QA identify tickets that need clarification before testing.

.PARAMETER IssueKey
    The JIRA ticket key (e.g., MS-22886)

.PARAMETER BatchMode
    If set, assesses all Ready for Test tickets

.PARAMETER MinScore
    Minimum acceptable score (default: 50). Tickets below this are flagged.

.PARAMETER ApplyLabels
    If set, applies quality labels to JIRA tickets

.PARAMETER RequestClarification
    If set, posts a comment on low-scoring tickets requesting more info

.PARAMETER OutputFile
    Path to save assessment results as JSON

.EXAMPLE
    .\Assess-TicketQuality.ps1 -IssueKey MS-22886
    
.EXAMPLE
    .\Assess-TicketQuality.ps1 -BatchMode -MinScore 60 -ApplyLabels
#>

param(
    [string]$IssueKey = "",
    [switch]$BatchMode,
    [int]$MinScore = 50,
    [switch]$ApplyLabels,
    [switch]$RequestClarification,
    [string]$OutputFile = ""
)

# Get JIRA credentials using the helper script (Windows Credential Manager)
$credentialScript = Join-Path $PSScriptRoot "..\..\.github\tools\Get-JiraCredentials.ps1"
if (-not (Test-Path $credentialScript)) {
    # Try alternate path
    $credentialScript = Join-Path $PSScriptRoot "..\.github\tools\Get-JiraCredentials.ps1"
}
if (-not (Test-Path $credentialScript)) {
    Write-Error "Could not find Get-JiraCredentials.ps1 helper script"
    exit 1
}

$credentials = & $credentialScript
if (-not $credentials -or -not $credentials.Username -or -not $credentials.Password) {
    Write-Error "Failed to retrieve JIRA credentials"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($credentials.Username):$($credentials.Password)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Quality factor weights
$weights = @{
    Component = 15
    Description = 20
    Testability = 20
    StepsToReproduce = 15
    CurrentVsExpected = 15
    EnvironmentVersion = 10
    Attachments = 5
}

# Patterns for detection
$testabilityPatterns = @(
    "should\s+(be|display|show|return|have|not)",
    "must\s+(be|display|show|return|have|not)",
    "verify\s+that",
    "acceptance\s+criteria",
    "h3\.\s*acceptance\s+criteria",
    "expected\s+(result|behavior|behaviour|outcome)",
    "pass\s+criteria",
    "success\s+criteria"
)

$stepsPatterns = @(
    "steps?\s*(to\s+reproduce|:)",
    "^\s*\d+\.\s+",
    "^\s*-\s+",
    "how\s+to\s+reproduce",
    "reproduction\s+steps",
    "repro\s+steps"
)

$currentBehaviorPatterns = @(
    "current(ly)?(\s+behavior|\s+behaviour)?:",
    "h3\.\s*current\s*(behavior|behaviour)",
    "\*\*current\s*(behavior|behaviour)\*\*",
    "actual(\s+behavior|\s+behaviour)?:",
    "what\s+happens:",
    "observed:",
    "bug:",
    "issue:",
    "problem:"
)

$expectedBehaviorPatterns = @(
    "expected(\s+behavior|\s+behaviour)?:",
    "h3\.\s*expected\s*(behavior|behaviour)",
    "\*\*expected\s*(behavior|behaviour)\*\*",
    "should\s+be:",
    "desired:",
    "correct\s+behavior:",
    "fix:",
    "solution:",
    "h2\.\s*acceptance\s+criteria",
    "h3\.\s*acceptance\s+criteria",
    "acceptance\s+criteria:",
    "\*\*acceptance\s+criteria\*\*"
)

function Assess-Ticket {
    param($Issue)
    
    $key = $Issue.key
    $summary = $Issue.fields.summary ?? ""
    $description = $Issue.fields.description ?? ""
    $issueType = $Issue.fields.issuetype.name ?? "Unknown"
    $status = $Issue.fields.status.name ?? "Unknown"
    $components = $Issue.fields.components ?? @()
    $labels = $Issue.fields.labels ?? @()
    $fixVersions = $Issue.fields.fixVersions ?? @()
    $attachments = $Issue.fields.attachment ?? @()
    
    $fullText = "$summary`n$description"
    $isBug = $issueType -match "Bug|Defect"
    
    # Statuses where fix version is expected (later stages of workflow)
    $fixVersionExpectedStatuses = @(
        "Ready for Test",
        "In Test",
        "Ready for Release",
        "Closed",
        "Done",
        "Resolved"
    )
    $shouldHaveFixVersion = $fixVersionExpectedStatuses -contains $status
    
    $scores = @{}
    $findings = @()
    $recommendations = @()
    
    # 1. Component Identification (15%)
    $componentScore = 0
    if ($components.Count -gt 0) {
        $componentScore = 100
        $findings += "✓ Component: $($components[0].name)"
    }
    elseif ($labels | Where-Object { $_ -match "DataMagic|ReportMagic|AlertMagic|Admin|Connect|CLI|Docs" }) {
        $componentScore = 70
        $matchedLabel = $labels | Where-Object { $_ -match "DataMagic|ReportMagic|AlertMagic|Admin|Connect|CLI|Docs" } | Select-Object -First 1
        $findings += "⚠ Component: Via label ($matchedLabel)"
        $recommendations += "Set JIRA component field"
    }
    elseif ($summary -match "DataMagic|ReportMagic|AlertMagic|Admin|Connect|CLI|Docs|Report\s*Studio") {
        $componentScore = 50
        $findings += "⚠ Component: Mentioned in summary only"
        $recommendations += "Set JIRA component field explicitly"
    }
    else {
        $componentScore = 0
        $findings += "✗ Component: Not identified"
        $recommendations += "Add component to ticket"
    }
    $scores.Component = $componentScore
    
    # 2. Description Completeness (20%)
    $wordCount = ($description -split '\s+' | Where-Object { $_.Length -gt 0 }).Count
    $descScore = 0
    if ($wordCount -ge 100) {
        $descScore = 100
        $findings += "✓ Description: $wordCount words (comprehensive)"
    }
    elseif ($wordCount -ge 50) {
        $descScore = 80
        $findings += "✓ Description: $wordCount words (adequate)"
    }
    elseif ($wordCount -ge 20) {
        $descScore = 50
        $findings += "⚠ Description: $wordCount words (brief)"
        $recommendations += "Add more context to description"
    }
    elseif ($wordCount -gt 0) {
        $descScore = 25
        $findings += "⚠ Description: $wordCount words (minimal)"
        $recommendations += "Expand description with details"
    }
    else {
        $descScore = 0
        $findings += "✗ Description: Empty"
        $recommendations += "Add description"
    }
    $scores.Description = $descScore
    
    # 3. Testability (20%)
    $testabilityScore = 0
    $testabilityMatches = 0
    foreach ($pattern in $testabilityPatterns) {
        if ($fullText -match $pattern) {
            $testabilityMatches++
        }
    }
    
    if ($testabilityMatches -ge 3) {
        $testabilityScore = 100
        $findings += "✓ Testability: Clear criteria found"
    }
    elseif ($testabilityMatches -ge 1) {
        $testabilityScore = 60
        $findings += "⚠ Testability: Some criteria found"
        $recommendations += "Add explicit pass/fail criteria"
    }
    else {
        $testabilityScore = 20
        $findings += "✗ Testability: No clear criteria"
        $recommendations += "Define acceptance criteria"
    }
    $scores.Testability = $testabilityScore
    
    # 4. Steps to Reproduce (15%) - weighted more for bugs
    $stepsScore = 0
    $hasSteps = $false
    $stepCount = 0
    
    foreach ($pattern in $stepsPatterns) {
        if ($fullText -match $pattern) {
            $hasSteps = $true
        }
    }
    
    # Count numbered steps
    $numberedSteps = [regex]::Matches($description, '^\s*\d+\.\s+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $stepCount = $numberedSteps.Count
    
    if ($isBug) {
        if ($stepCount -ge 3) {
            $stepsScore = 100
            $findings += "✓ Steps to Reproduce: $stepCount steps found"
        }
        elseif ($hasSteps -or $stepCount -ge 1) {
            $stepsScore = 60
            $findings += "⚠ Steps to Reproduce: Partial ($stepCount steps)"
            $recommendations += "Add detailed numbered steps"
        }
        else {
            $stepsScore = 0
            $findings += "✗ Steps to Reproduce: Missing"
            $recommendations += "Add steps to reproduce the bug"
        }
    }
    else {
        # For non-bugs, steps are nice-to-have
        if ($hasSteps) {
            $stepsScore = 100
            $findings += "✓ Steps: Workflow documented"
        }
        else {
            $stepsScore = 50
            $findings += "○ Steps: Not required for this type"
        }
    }
    $scores.StepsToReproduce = $stepsScore
    
    # 5. Current vs Expected Behavior (15%) - critical for bugs
    $currentExpectedScore = 0
    $hasCurrent = $false
    $hasExpected = $false
    
    foreach ($pattern in $currentBehaviorPatterns) {
        if ($fullText -match $pattern) {
            $hasCurrent = $true
        }
    }
    
    foreach ($pattern in $expectedBehaviorPatterns) {
        if ($fullText -match $pattern) {
            $hasExpected = $true
        }
    }
    
    if ($isBug) {
        if ($hasCurrent -and $hasExpected) {
            $currentExpectedScore = 100
            $findings += "✓ Current vs Expected: Both documented"
        }
        elseif ($hasCurrent -or $hasExpected) {
            $currentExpectedScore = 50
            $missing = if (-not $hasCurrent) { "current" } else { "expected" }
            $findings += "⚠ Current vs Expected: Missing $missing behavior"
            $recommendations += "Document both current and expected behavior"
        }
        else {
            $currentExpectedScore = 0
            $findings += "✗ Current vs Expected: Neither documented"
            $recommendations += "Add current behavior and expected behavior sections"
        }
    }
    else {
        # For features, expected behavior is important
        if ($hasExpected) {
            $currentExpectedScore = 100
            $findings += "✓ Expected Behavior: Documented"
        }
        else {
            $currentExpectedScore = 40
            $findings += "⚠ Expected Behavior: Not explicit"
            $recommendations += "Clarify expected outcome"
        }
    }
    $scores.CurrentVsExpected = $currentExpectedScore
    
    # 6. Environment/Version (10%)
    $envScore = 0
    $hasFixVersion = $fixVersions.Count -gt 0
    $hasEnvMention = $fullText -match "test2|alpha|beta|staging|production|environment"
    
    if ($hasFixVersion) {
        $envScore += 70
        $findings += "✓ Fix Version: $($fixVersions[0].name)"
    }
    elseif ($shouldHaveFixVersion) {
        # Only flag as missing if ticket is in a stage where fix version is expected
        $findings += "⚠ Fix Version: Not specified (expected for '$status' status)"
        $recommendations += "Add fix version"
    }
    else {
        # For planning/development stages, no fix version is fine
        $envScore += 70  # Don't penalize
        $findings += "○ Fix Version: Not required yet (status: $status)"
    }
    
    if ($hasEnvMention) {
        $envScore += 30
    }
    
    $scores.EnvironmentVersion = [Math]::Min(100, $envScore)
    
    # 7. Attachments/Evidence (5%)
    $attachScore = 0
    if ($attachments.Count -gt 0) {
        $attachScore = 100
        $findings += "✓ Attachments: $($attachments.Count) file(s)"
    }
    elseif ($description -match "!\[|screenshot|image|http.*\.(png|jpg|gif)") {
        $attachScore = 70
        $findings += "✓ Attachments: Inline images found"
    }
    else {
        $attachScore = 0
        $findings += "○ Attachments: None"
        if ($isBug) {
            $recommendations += "Add screenshot or error log"
        }
    }
    $scores.Attachments = $attachScore
    
    # Calculate weighted total
    $totalScore = 0
    foreach ($factor in $weights.Keys) {
        $totalScore += ($scores[$factor] * $weights[$factor] / 100)
    }
    
    # Determine grade
    $grade = if ($totalScore -ge 80) { "EXCELLENT" }
             elseif ($totalScore -ge 60) { "GOOD" }
             elseif ($totalScore -ge 50) { "ADEQUATE" }
             elseif ($totalScore -ge 30) { "NEEDS IMPROVEMENT" }
             else { "POOR" }
    
    return @{
        Key = $key
        Summary = $summary
        IssueType = $issueType
        TotalScore = [Math]::Round($totalScore)
        Grade = $grade
        Scores = $scores
        Findings = $findings
        Recommendations = $recommendations
        IsBug = $isBug
    }
}

function Display-Assessment {
    param($Assessment)
    
    $score = $Assessment.TotalScore
    $scoreColor = switch ($score) {
        { $_ -ge 80 } { "Green" }
        { $_ -ge 60 } { "Cyan" }
        { $_ -ge 50 } { "Yellow" }
        { $_ -ge 30 } { "DarkYellow" }
        default { "Red" }
    }
    
    # Fixed width for content area (inside the box)
    $contentWidth = 63
    
    # Build score bar
    $barWidth = 30
    $filled = [Math]::Floor($score / 100 * $barWidth)
    $empty = $barWidth - $filled
    $scoreBar = ([char]0x2588).ToString() * $filled + ([char]0x2591).ToString() * $empty
    
    # Helper function to pad line to exact width
    function Format-Line {
        param([string]$Text, [int]$Width = $contentWidth)
        if ($Text.Length -gt $Width) {
            return $Text.Substring(0, $Width)
        }
        return $Text + (" " * ($Width - $Text.Length))
    }
    
    $border = "─" * $contentWidth
    
    Write-Host ""
    Write-Host "┌─$border─┐" -ForegroundColor DarkCyan
    
    # Header
    $line = Format-Line "TICKET QUALITY: $($Assessment.Key)"
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host $line -ForegroundColor Cyan -NoNewline
    Write-Host " │" -ForegroundColor DarkCyan
    
    $line = Format-Line "Type: $($Assessment.IssueType)"
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host $line -ForegroundColor Gray -NoNewline
    Write-Host " │" -ForegroundColor DarkCyan
    
    Write-Host "├─$border─┤" -ForegroundColor DarkCyan
    
    # Score with bar
    $scoreLine = "Score: $score/100 $scoreBar"
    $line = Format-Line $scoreLine
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host $line -ForegroundColor $scoreColor -NoNewline
    Write-Host " │" -ForegroundColor DarkCyan
    
    # Grade
    $gradeLine = "Grade: [$($Assessment.Grade)]"
    $line = Format-Line $gradeLine
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host $line -ForegroundColor $scoreColor -NoNewline
    Write-Host " │" -ForegroundColor DarkCyan
    
    Write-Host "├─$border─┤" -ForegroundColor DarkCyan
    
    # Factors header
    $line = Format-Line "FACTORS:"
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host $line -ForegroundColor White -NoNewline
    Write-Host " │" -ForegroundColor DarkCyan
    
    foreach ($finding in $Assessment.Findings) {
        $findingColor = if ($finding.StartsWith("✓")) { "Green" }
                       elseif ($finding.StartsWith("⚠")) { "Yellow" }
                       elseif ($finding.StartsWith("✗")) { "Red" }
                       else { "Gray" }
        
        $line = Format-Line "  $finding"
        Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $line -ForegroundColor $findingColor -NoNewline
        Write-Host " │" -ForegroundColor DarkCyan
    }
    
    if ($Assessment.Recommendations.Count -gt 0) {
        Write-Host "├─$border─┤" -ForegroundColor DarkCyan
        
        $line = Format-Line "RECOMMENDATIONS:"
        Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $line -ForegroundColor Yellow -NoNewline
        Write-Host " │" -ForegroundColor DarkCyan
        
        foreach ($rec in $Assessment.Recommendations) {
            $line = Format-Line "  → $rec"
            Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
            Write-Host $line -ForegroundColor Yellow -NoNewline
            Write-Host " │" -ForegroundColor DarkCyan
        }
    }
    
    Write-Host "└─$border─┘" -ForegroundColor DarkCyan
}

function Add-JiraLabel {
    param([string]$IssueKey, [string]$Label, [array]$ExistingLabels)
    
    if ($Label -in $ExistingLabels) { return }
    
    $allLabels = @($ExistingLabels) + @($Label) | Select-Object -Unique
    
    $body = @{
        update = @{
            labels = @(@{ set = $allLabels })
        }
    } | ConvertTo-Json -Depth 5
    
    try {
        $null = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
            -Method PUT -Headers $headers -Body $body
        Write-Host "  Applied label: $Label" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to apply label: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Post-ClarificationRequest {
    param([string]$IssueKey, $Assessment)
    
    $comment = @"
h2. 🤖 Ticket Quality Assessment

This ticket has been assessed for specification completeness.

*Score:* $($Assessment.TotalScore)/100 - $($Assessment.Grade)

h3. Missing Information

The following improvements would help testing:
$( ($Assessment.Recommendations | ForEach-Object { "* $_" }) -join "`n" )

h3. What We Need

$(if ($Assessment.IsBug) {
@"
For bugs, please ensure:
# Numbered steps to reproduce
# Current (actual) behavior description
# Expected behavior description
# Screenshot or error log if applicable
"@
} else {
@"
For features, please ensure:
# Clear acceptance criteria
# Expected behavior/outcome
# Any relevant examples
"@
})

_This assessment was generated automatically to help improve testing efficiency._
"@
    
    $body = @{ body = $comment } | ConvertTo-Json
    
    try {
        $null = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey/comment" `
            -Method POST -Headers $headers -Body $body
        Write-Host "  Posted clarification request to $IssueKey" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to post comment: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           TICKET QUALITY ASSESSMENT                           " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$assessments = @()

if ($BatchMode) {
    Write-Host ""
    Write-Host "Fetching Ready for Test tickets..." -ForegroundColor Yellow
    
    $jql = "project=MS AND status='Ready for Test' ORDER BY priority DESC"
    $body = @{
        jql = $jql
        maxResults = 100
        fields = @("key", "summary", "description", "issuetype", "status", "priority", "components", "labels", "fixVersions", "attachment")
    } | ConvertTo-Json
    
    try {
        $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/search" `
            -Method POST -Headers $headers -Body $body
    }
    catch {
        Write-Error "Failed to fetch tickets: $($_.Exception.Message)"
        exit 1
    }
    
    Write-Host "Assessing $($result.issues.Count) tickets..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($issue in $result.issues) {
        $assessment = Assess-Ticket -Issue $issue
        $assessments += $assessment
        
        # Quick summary line
        $scoreColor = if ($assessment.TotalScore -ge $MinScore) { "Green" } else { "Red" }
        $indicator = if ($assessment.TotalScore -ge $MinScore) { "✓" } else { "✗" }
        Write-Host "$indicator $($assessment.Key) [$($assessment.TotalScore)/100] " -ForegroundColor $scoreColor -NoNewline
        Write-Host "$($assessment.Summary.Substring(0, [Math]::Min(45, $assessment.Summary.Length)))..." -ForegroundColor White
        
        # Apply labels if requested
        if ($ApplyLabels) {
            $label = if ($assessment.TotalScore -ge 80) { "ai-spec-excellent" }
                     elseif ($assessment.TotalScore -ge 60) { "ai-spec-good" }
                     elseif ($assessment.TotalScore -ge 50) { "ai-spec-adequate" }
                     else { "ai-needs-clarification" }
            
            Add-JiraLabel -IssueKey $assessment.Key -Label $label -ExistingLabels $issue.fields.labels
        }
        
        # Request clarification if below threshold
        if ($RequestClarification -and $assessment.TotalScore -lt $MinScore -and $assessment.Recommendations.Count -gt 0) {
            Post-ClarificationRequest -IssueKey $assessment.Key -Assessment $assessment
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "BATCH ASSESSMENT SUMMARY" -ForegroundColor Cyan
    Write-Host ""
    
    $excellent = ($assessments | Where-Object { $_.TotalScore -ge 80 }).Count
    $good = ($assessments | Where-Object { $_.TotalScore -ge 60 -and $_.TotalScore -lt 80 }).Count
    $adequate = ($assessments | Where-Object { $_.TotalScore -ge 50 -and $_.TotalScore -lt 60 }).Count
    $needsWork = ($assessments | Where-Object { $_.TotalScore -lt 50 }).Count
    
    Write-Host "Excellent (80+): $excellent" -ForegroundColor Green
    Write-Host "Good (60-79):    $good" -ForegroundColor Cyan
    Write-Host "Adequate (50-59): $adequate" -ForegroundColor Yellow
    Write-Host "Needs Work (<50): $needsWork" -ForegroundColor Red
    Write-Host ""
    
    $avgScore = [Math]::Round(($assessments | Measure-Object -Property TotalScore -Average).Average)
    Write-Host "Average Score: $avgScore/100" -ForegroundColor White
    
    # Show worst tickets
    if ($needsWork -gt 0) {
        Write-Host ""
        Write-Host "Tickets needing clarification:" -ForegroundColor Yellow
        $assessments | Where-Object { $_.TotalScore -lt $MinScore } | Sort-Object TotalScore | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $($_.Key) [$($_.TotalScore)] - $($_.Recommendations[0])" -ForegroundColor Red
        }
    }
}
else {
    # Single ticket mode
    if (-not $IssueKey) {
        Write-Error "Please specify -IssueKey or use -BatchMode"
        exit 1
    }
    
    Write-Host ""
    Write-Host "Fetching ticket $IssueKey..." -ForegroundColor Yellow
    
    try {
        $issue = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
            -Method GET -Headers $headers
    }
    catch {
        Write-Error "Failed to fetch ticket: $($_.Exception.Message)"
        exit 1
    }
    
    $assessment = Assess-Ticket -Issue $issue
    $assessments += $assessment
    
    Display-Assessment -Assessment $assessment
    
    # Apply label if requested
    if ($ApplyLabels) {
        $label = if ($assessment.TotalScore -ge 80) { "ai-spec-excellent" }
                 elseif ($assessment.TotalScore -ge 60) { "ai-spec-good" }
                 elseif ($assessment.TotalScore -ge 50) { "ai-spec-adequate" }
                 else { "ai-needs-clarification" }
        
        Add-JiraLabel -IssueKey $IssueKey -Label $label -ExistingLabels $issue.fields.labels
    }
    
    # Request clarification if below threshold
    if ($RequestClarification -and $assessment.TotalScore -lt $MinScore -and $assessment.Recommendations.Count -gt 0) {
        Post-ClarificationRequest -IssueKey $IssueKey -Assessment $assessment
    }
}

# Save to file if requested
if ($OutputFile) {
    $output = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        MinScore = $MinScore
        TotalAssessed = $assessments.Count
        Assessments = $assessments
    }
    $output | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $OutputFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
