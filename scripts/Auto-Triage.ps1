    <#
.SYNOPSIS
    Auto-Triage Ready for Test tickets using pattern matching to categorize by test approach.

.DESCRIPTION
    Analyzes JIRA tickets in "Ready for Test" status and categorizes them by:
    - Test type: CLI, Playwright, Both, Manual
    - Difficulty: Easy, Medium, Hard
    - Auto-testability: Can be auto-verified, needs human verification
    - Environment specificity: Any environment vs tenant/config-specific
    
    Can also generate AI prompts for QA engineers to use with Copilot.

.PARAMETER ApplyLabels
    If set, applies AI-triage labels to JIRA tickets

.PARAMETER OutputFile
    Path to output the triage results as JSON

.PARAMETER MaxResults
    Maximum number of tickets to process (default: 100)

.PARAMETER GeneratePrompt
    If set with -IssueKey, generates an AI prompt for testing the ticket

.PARAMETER IssueKey
    Specific ticket to analyze (used with -GeneratePrompt)

.PARAMETER PromptOutputFile
    Path to save the generated prompt (default: prints to console)

.EXAMPLE
    .\Auto-Triage.ps1 -OutputFile "triage-results.json"
    
.EXAMPLE
    .\Auto-Triage.ps1 -ApplyLabels -MaxResults 50

.EXAMPLE
    .\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-22886
#>

param(
    [switch]$ApplyLabels,
    [string]$OutputFile = "",
    [int]$MaxResults = 100,
    [switch]$GeneratePrompt,
    [string]$IssueKey = "",
    [string]$PromptOutputFile = ""
)

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

# Pattern definitions for categorization
$cliPatterns = @(
    "CLI", "command line", "command-line", "magicsuite", 
    "exit code", "exit-code", "--", "parameter", 
    "dotnet tool", "api get", "api post"
)

$playwrightPatterns = @(
    "button", "modal", "dialog", "popup", "pop-up",
    "click", "hover", "dropdown", "menu", "icon",
    "dark mode", "light mode", "theme", "color", "colour",
    "UI", "user interface", "display", "visible", "hidden",
    "page", "screen", "form", "input", "toast", "notification"
)

$easyPatterns = @(
    "should be visible", "should display", "should show",
    "color", "colour", "icon", "text", "label",
    "button should", "link should"
)

$hardPatterns = @(
    "integration", "external", "third-party", "API",
    "performance", "load", "concurrent", "security",
    "migration", "database", "sync", "async"
)

$autoTestablePatterns = @(
    "should display", "should show", "should be visible",
    "should not", "should error", "should return",
    "exit code", "output format"
)

# Environment-specific patterns (tickets that need specific tenant/config)
$environmentSpecificPatterns = @(
    "tenant", "customer", "specific", "configuration",
    "their", "client", "production", "live",
    "particular", "certain", "only on", "only in",
    "meraki", "logicmonitor", "connectwise", "halopsa", "toggl",
    "sharepoint", "azure", "kubernetes", "k8s",
    "integration", "sync", "connection", "credential"
)

# Any-environment patterns (can test anywhere)
$anyEnvironmentPatterns = @(
    "all users", "any user", "general", "generic",
    "UI", "button", "color", "theme", "dark mode",
    "menu", "navigation", "icon", "text", "label",
    "report studio", "admin", "docs", "ncalc"
)

# Manual verification patterns (need human eyes)
$manualVerificationPatterns = @(
    "layout", "alignment", "spacing", "position",
    "diagram", "chart", "graph", "visual",
    "look", "feel", "design", "aesthetic",
    "readable", "readable", "usability", "user experience"
)

function Get-TicketCategory {
    param([string]$Summary, [string]$Description, [array]$Labels)
    
    $text = "$Summary $Description".ToLower()
    $labelText = ($Labels -join " ").ToLower()
    
    # Determine test type
    $isCli = $false
    $isPlaywright = $false
    
    foreach ($pattern in $cliPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $isCli = $true
            break
        }
    }
    
    foreach ($pattern in $playwrightPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $isPlaywright = $true
            break
        }
    }
    
    # Check labels for hints
    if ($labelText -match "cli") { $isCli = $true }
    if ($labelText -match "ui|web|blazor") { $isPlaywright = $true }
    
    # Determine difficulty
    $difficulty = "Medium"
    foreach ($pattern in $easyPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $difficulty = "Easy"
            break
        }
    }
    foreach ($pattern in $hardPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $difficulty = "Hard"
            break
        }
    }
    
    # Determine auto-testability
    $autoTestable = $false
    foreach ($pattern in $autoTestablePatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $autoTestable = $true
            break
        }
    }
    
    # Determine environment specificity
    $envSpecificScore = 0
    $anyEnvScore = 0
    
    foreach ($pattern in $environmentSpecificPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $envSpecificScore++
        }
    }
    
    foreach ($pattern in $anyEnvironmentPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $anyEnvScore++
        }
    }
    
    $environmentType = if ($envSpecificScore -gt $anyEnvScore + 1) { "TenantSpecific" }
                       elseif ($envSpecificScore -gt 0 -and $anyEnvScore -eq 0) { "ConfigSpecific" }
                       else { "AnyEnvironment" }
    
    # Determine if manual verification is needed
    $needsManualVerification = $false
    $manualSteps = @()
    foreach ($pattern in $manualVerificationPatterns) {
        if ($text -match [regex]::Escape($pattern.ToLower())) {
            $needsManualVerification = $true
            $manualSteps += $pattern
        }
    }
    
    # Build result
    $testType = if ($isCli -and $isPlaywright) { "Both" }
                elseif ($isCli) { "CLI" }
                elseif ($isPlaywright) { "Playwright" }
                else { "Manual" }
    
    return @{
        TestType = $testType
        Difficulty = $difficulty
        AutoTestable = $autoTestable
        EnvironmentType = $environmentType
        NeedsManualVerification = $needsManualVerification
        ManualVerificationAreas = $manualSteps
        SuggestedLabels = @(
            "ai-triage-$($testType.ToLower())"
            "ai-difficulty-$($difficulty.ToLower())"
            if ($autoTestable) { "ai-auto-testable" }
            if ($environmentType -eq "TenantSpecific") { "ai-tenant-specific" }
            elseif ($environmentType -eq "ConfigSpecific") { "ai-config-specific" }
            else { "ai-any-environment" }
        ) | Where-Object { $_ }
    }
}

function Add-JiraLabels {
    param([string]$IssueKey, [array]$Labels, [array]$ExistingLabels)
    
    # Only add labels that don't already exist
    $newLabels = $Labels | Where-Object { $_ -notin $ExistingLabels }
    
    if ($newLabels.Count -eq 0) {
        Write-Host "  No new labels to add for $IssueKey" -ForegroundColor Gray
        return
    }
    
    # Add labels via JIRA API
    $allLabels = @($ExistingLabels) + @($newLabels) | Select-Object -Unique
    
    $body = @{
        update = @{
            labels = @(
                @{ set = $allLabels }
            )
        }
    } | ConvertTo-Json -Depth 5
    
    try {
        $null = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
            -Method PUT -Headers $headers -Body $body
        Write-Host "  Added labels to ${IssueKey}: $($newLabels -join ', ')" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to add labels to ${IssueKey}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Generate-TestPrompt {
    param(
        [string]$IssueKey,
        [string]$Summary,
        [string]$Description,
        [string]$IssueType,
        [string]$FixVersion,
        [array]$Components,
        $Category
    )
    
    # Determine app name from components or summary
    $appName = if ($Components.Count -gt 0) { $Components[0].name } 
               elseif ($Summary -match "Report\s*Studio|ReportMagic") { "ReportMagic" }
               elseif ($Summary -match "DataMagic") { "DataMagic" }
               elseif ($Summary -match "AlertMagic") { "AlertMagic" }
               elseif ($Summary -match "Admin") { "Admin" }
               elseif ($Summary -match "Connect") { "Connect" }
               elseif ($Summary -match "Docs|Documentation") { "Docs" }
               elseif ($Summary -match "CLI") { "CLI" }
               else { "MagicSuite" }
    
    # Build environment guidance
    $envGuidance = switch ($Category.EnvironmentType) {
        "TenantSpecific" { 
            "⚠️ **IMPORTANT**: This ticket appears to be TENANT-SPECIFIC. Before testing, confirm which tenant/customer configuration is needed and ensure the test environment has the required setup."
        }
        "ConfigSpecific" {
            "ℹ️ **Note**: This ticket may require specific configuration. Check if any particular connections, integrations, or settings need to be in place before testing."
        }
        default {
            "✅ This ticket can be tested in any standard test environment (test2 recommended)."
        }
    }
    
    # Build manual verification steps
    $manualSteps = ""
    if ($Category.NeedsManualVerification) {
        $manualSteps = @"

## 🔍 Manual Verification Required

After automated tests complete, please confirm the following manually:

"@
        $stepNum = 1
        foreach ($area in $Category.ManualVerificationAreas) {
            $verificationStep = switch -Regex ($area) {
                "layout|alignment|spacing|position" { "Review the $appName page layout and confirm elements are properly aligned and spaced as per the ticket specification" }
                "diagram|chart|graph" { "Review the $appName diagram/chart and confirm the visual representation is correct and readable" }
                "visual|look|feel|design|aesthetic" { "Visually inspect the $appName UI and confirm the appearance matches the expected design" }
                "readable|usability" { "Verify the content is readable and the user experience is intuitive" }
                default { "Manually verify: $area" }
            }
            $manualSteps += "$stepNum. $verificationStep`n"
            $stepNum++
        }
        $manualSteps += "`n**Please respond with your observations for each point above.**"
    }
    
    # Build test approach section
    $testApproach = switch ($Category.TestType) {
        "CLI" {
            @"
## 🖥️ Suggested Test Approach: CLI

1. Verify CLI version: `magicsuite --version` (should be 4.1.x)
2. Run the relevant CLI commands mentioned in the ticket
3. Verify exit codes and output format
4. Capture command output as evidence
"@
        }
        "Playwright" {
            @"
## 🎭 Suggested Test Approach: Playwright UI Test

1. Authenticate first: `npx playwright test auth.setup --project=firefox`
2. Navigate to the affected page in $appName
3. Verify the fix as described in the ticket
4. Take screenshots as evidence (before/after if applicable)
"@
        }
        "Both" {
            @"
## 🔄 Suggested Test Approach: CLI + UI Verification

**CLI Verification:**
1. Run relevant CLI commands to verify API/backend behavior
2. Check exit codes and output

**UI Verification:**
1. Navigate to $appName in the browser
2. Verify the UI reflects the expected behavior
3. Take screenshots as evidence
"@
        }
        default {
            @"
## 📋 Suggested Test Approach: Manual Testing

This ticket requires manual testing. Please:
1. Navigate to the affected area in $appName
2. Follow the steps to reproduce (if it's a bug) or test the new functionality
3. Document your findings with screenshots
"@
        }
    }
    
    # Build the full prompt
    $prompt = @"
# Test Ticket: $IssueKey

## 📋 Ticket Details

**Summary:** $Summary
**Type:** $IssueType
**Fix Version:** $FixVersion
**Application:** $appName

## 📝 Description

$Description

---

## 🌍 Environment Guidance

$envGuidance

$testApproach
$manualSteps

---

## ✅ Test Execution Checklist

Please help me test this ticket by:

1. **Confirming the test environment** - I will be testing on [ENVIRONMENT - please specify: test2/alpha/beta]
2. **Running automated verification** where applicable
3. **Capturing evidence** (screenshots, command outputs, logs)
4. **Documenting results** in a format suitable for JIRA

### What I need from you:

- Generate or run appropriate test scripts for this ticket
- Guide me through any manual verification steps
- Help me document the results
- Flag any issues or blockers encountered

### When testing is complete:

- Summarize the test results
- Prepare a JIRA comment with the findings
- Recommend whether to PASS, FAIL, or request more information

---

**Ready to begin testing? Please confirm the environment first.**
"@
    
    return $prompt
}

# Check if we're in prompt generation mode
if ($GeneratePrompt) {
    if (-not $IssueKey) {
        Write-Error "Please specify -IssueKey when using -GeneratePrompt"
        exit 1
    }
    
    Write-Host "=== Generating Test Prompt for $IssueKey ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Fetch the specific ticket
    try {
        $issue = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
            -Method GET -Headers $headers
    }
    catch {
        Write-Error "Failed to fetch ticket: $($_.Exception.Message)"
        exit 1
    }
    
    $summary = $issue.fields.summary
    $description = $issue.fields.description ?? "(No description provided)"
    $issueType = $issue.fields.issuetype.name
    $fixVersions = ($issue.fields.fixVersions | ForEach-Object { $_.name }) -join ", "
    $components = $issue.fields.components ?? @()
    $labels = $issue.fields.labels ?? @()
    
    # Categorize the ticket
    $category = Get-TicketCategory -Summary $summary -Description $description -Labels $labels
    
    # Generate the prompt
    $prompt = Generate-TestPrompt `
        -IssueKey $IssueKey `
        -Summary $summary `
        -Description $description `
        -IssueType $issueType `
        -FixVersion $fixVersions `
        -Components $components `
        -Category $category
    
    # Output the prompt
    if ($PromptOutputFile) {
        $prompt | Out-File $PromptOutputFile -Encoding UTF8
        Write-Host "Prompt saved to: $PromptOutputFile" -ForegroundColor Green
        Write-Host ""
        Write-Host "Copy this file content and paste into GitHub Copilot to begin testing." -ForegroundColor Yellow
    }
    else {
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "COPY THE TEXT BELOW AND PASTE INTO GITHUB COPILOT" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $prompt
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    }
    
    # Show category info
    Write-Host ""
    Write-Host "Ticket Analysis:" -ForegroundColor Cyan
    Write-Host "  Test Type: $($category.TestType)" -ForegroundColor White
    Write-Host "  Difficulty: $($category.Difficulty)" -ForegroundColor White
    Write-Host "  Environment: $($category.EnvironmentType)" -ForegroundColor White
    Write-Host "  Auto-Testable: $($category.AutoTestable)" -ForegroundColor White
    Write-Host "  Needs Manual Review: $($category.NeedsManualVerification)" -ForegroundColor White
    
    exit 0
}

# Main execution
Write-Host "=== Auto-Triage: Ready for Test Tickets ===" -ForegroundColor Cyan
Write-Host "Fetching tickets from JIRA..." -ForegroundColor Yellow

# Query JIRA
$jql = "project=MS AND status='Ready for Test' ORDER BY priority DESC, created ASC"
$body = @{
    jql = $jql
    maxResults = $MaxResults
    fields = @("key", "summary", "description", "labels", "issuetype", "priority", "fixVersions", "components")
} | ConvertTo-Json

try {
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/search" `
        -Method POST -Headers $headers -Body $body
}
catch {
    Write-Error "Failed to query JIRA: $($_.Exception.Message)"
    exit 1
}

Write-Host "Found $($result.total) tickets total, processing $($result.issues.Count)" -ForegroundColor Yellow
Write-Host ""

# Process each ticket
$triageResults = @{
    Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    TotalTickets = $result.total
    ProcessedTickets = $result.issues.Count
    Categories = @{
        CLI = @()
        Playwright = @()
        Both = @()
        Manual = @()
    }
    Difficulty = @{
        Easy = @()
        Medium = @()
        Hard = @()
    }
    Environment = @{
        AnyEnvironment = @()
        ConfigSpecific = @()
        TenantSpecific = @()
    }
    AutoTestable = @()
    NeedsManualVerification = @()
}

foreach ($issue in $result.issues) {
    $key = $issue.key
    $summary = $issue.fields.summary
    $description = $issue.fields.description ?? ""
    $labels = $issue.fields.labels ?? @()
    $priority = $issue.fields.priority.name
    $fixVersions = ($issue.fields.fixVersions | ForEach-Object { $_.name }) -join ", "
    
    # Categorize
    $category = Get-TicketCategory -Summary $summary -Description $description -Labels $labels
    
    $ticketInfo = @{
        Key = $key
        Summary = $summary.Substring(0, [Math]::Min(70, $summary.Length))
        Priority = $priority
        FixVersion = $fixVersions
        TestType = $category.TestType
        Difficulty = $category.Difficulty
        AutoTestable = $category.AutoTestable
        EnvironmentType = $category.EnvironmentType
        NeedsManualVerification = $category.NeedsManualVerification
    }
    
    # Add to results
    $triageResults.Categories[$category.TestType] += $ticketInfo
    $triageResults.Difficulty[$category.Difficulty] += $key
    $triageResults.Environment[$category.EnvironmentType] += $key
    if ($category.AutoTestable) {
        $triageResults.AutoTestable += $key
    }
    if ($category.NeedsManualVerification) {
        $triageResults.NeedsManualVerification += $key
    }
    
    # Display
    $color = switch ($category.TestType) {
        "CLI" { "Cyan" }
        "Playwright" { "Magenta" }
        "Both" { "Yellow" }
        "Manual" { "Gray" }
    }
    
    $diffColor = switch ($category.Difficulty) {
        "Easy" { "Green" }
        "Medium" { "Yellow" }
        "Hard" { "Red" }
    }
    
    $envIndicator = switch ($category.EnvironmentType) {
        "TenantSpecific" { "🏢" }
        "ConfigSpecific" { "⚙️" }
        default { "🌍" }
    }
    
    $autoIndicator = if ($category.AutoTestable) { "⚡" } else { "" }
    $manualIndicator = if ($category.NeedsManualVerification) { "👁️" } else { "" }
    
    Write-Host "$key [$($category.TestType)] " -ForegroundColor $color -NoNewline
    Write-Host "[$($category.Difficulty)] " -ForegroundColor $diffColor -NoNewline
    Write-Host "$envIndicator$autoIndicator$manualIndicator " -NoNewline
    Write-Host "$($summary.Substring(0, [Math]::Min(45, $summary.Length)))..." -ForegroundColor White
    
    # Apply labels if requested
    if ($ApplyLabels) {
        Add-JiraLabels -IssueKey $key -Labels $category.SuggestedLabels -ExistingLabels $labels
    }
}

# Summary
Write-Host ""
Write-Host "=== TRIAGE SUMMARY ===" -ForegroundColor Cyan
Write-Host "CLI Only:        $($triageResults.Categories.CLI.Count) tickets" -ForegroundColor Cyan
Write-Host "Playwright Only: $($triageResults.Categories.Playwright.Count) tickets" -ForegroundColor Magenta
Write-Host "Both:            $($triageResults.Categories.Both.Count) tickets" -ForegroundColor Yellow
Write-Host "Manual:          $($triageResults.Categories.Manual.Count) tickets" -ForegroundColor Gray
Write-Host ""
Write-Host "Easy:   $($triageResults.Difficulty.Easy.Count)" -ForegroundColor Green
Write-Host "Medium: $($triageResults.Difficulty.Medium.Count)" -ForegroundColor Yellow
Write-Host "Hard:   $($triageResults.Difficulty.Hard.Count)" -ForegroundColor Red
Write-Host ""
Write-Host "🌍 Any Environment:    $($triageResults.Environment.AnyEnvironment.Count) tickets" -ForegroundColor Green
Write-Host "⚙️  Config-Specific:    $($triageResults.Environment.ConfigSpecific.Count) tickets" -ForegroundColor Yellow
Write-Host "🏢 Tenant-Specific:    $($triageResults.Environment.TenantSpecific.Count) tickets" -ForegroundColor Red
Write-Host ""
Write-Host "⚡ Auto-Testable:       $($triageResults.AutoTestable.Count) tickets" -ForegroundColor Green
Write-Host "👁️  Needs Manual Review: $($triageResults.NeedsManualVerification.Count) tickets" -ForegroundColor Yellow

# Output to file if requested
if ($OutputFile) {
    $triageResults | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $OutputFile" -ForegroundColor Green
}

# Generate quick-start recommendations
Write-Host ""
Write-Host "=== QUICK START RECOMMENDATIONS ===" -ForegroundColor Cyan

# Priority 1: Easy, any-environment Playwright tests
$easyAnyEnvPlaywright = $triageResults.Categories.Playwright | Where-Object { 
    $_.Difficulty -eq "Easy" -and $_.EnvironmentType -eq "AnyEnvironment" 
} | Select-Object -First 5
if ($easyAnyEnvPlaywright) {
    Write-Host ""
    Write-Host "🎭🌍 Easy Playwright (any environment - start here!):" -ForegroundColor Green
    foreach ($t in $easyAnyEnvPlaywright) {
        Write-Host "   $($t.Key): $($t.Summary)" -ForegroundColor White
    }
}

# Priority 2: Easy CLI tests
$easyCli = $triageResults.Categories.CLI | Where-Object { $_.Difficulty -eq "Easy" } | Select-Object -First 5
if ($easyCli) {
    Write-Host ""
    Write-Host "💻 Easy CLI Tests:" -ForegroundColor Cyan
    foreach ($t in $easyCli) {
        Write-Host "   $($t.Key): $($t.Summary)" -ForegroundColor White
    }
}

# Auto-testable tickets
$autoTestable = $triageResults.Categories.Playwright | Where-Object { $triageResults.AutoTestable -contains $_.Key } | Select-Object -First 5
if ($autoTestable) {
    Write-Host ""
    Write-Host "⚡ Auto-Testable (generate smoke tests):" -ForegroundColor Green
    foreach ($t in $autoTestable) {
        Write-Host "   $($t.Key): $($t.Summary)" -ForegroundColor White
    }
}

# Tenant-specific tickets (need special attention)
$tenantSpecific = $triageResults.Categories.Playwright + $triageResults.Categories.Both + $triageResults.Categories.Manual | 
    Where-Object { $_.EnvironmentType -eq "TenantSpecific" } | Select-Object -First 5
if ($tenantSpecific) {
    Write-Host ""
    Write-Host "🏢 Tenant-Specific (need special setup):" -ForegroundColor Red
    foreach ($t in $tenantSpecific) {
        Write-Host "   $($t.Key): $($t.Summary)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== GENERATE AI PROMPTS ===" -ForegroundColor Cyan
Write-Host "To generate a test prompt for any ticket, run:" -ForegroundColor Yellow
Write-Host "   .\Auto-Triage.ps1 -GeneratePrompt -IssueKey MS-XXXXX" -ForegroundColor White
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
