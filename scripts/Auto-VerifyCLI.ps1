<#
.SYNOPSIS
    Auto-verify CLI-related tickets by extracting and running commands from ticket descriptions.

.DESCRIPTION
    For CLI-testable JIRA tickets, this script:
    1. Fetches the ticket description
    2. Extracts CLI commands mentioned (magicsuite, dotnet, etc.)
    3. Identifies what's being tested (exit codes, output format, errors)
    4. Runs the commands with various inputs
    5. Verifies the expected behavior
    6. Posts results back to JIRA as a comment

.PARAMETER IssueKey
    The JIRA ticket key (e.g., MS-22611)

.PARAMETER Profile
    The MagicSuite CLI profile to use (default: test2)

.PARAMETER PostToJira
    If set, posts the test results as a comment on the JIRA ticket

.PARAMETER DryRun
    If set, only extracts and displays commands without executing

.EXAMPLE
    .\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -Profile test2
    
.EXAMPLE
    .\Auto-VerifyCLI.ps1 -IssueKey MS-22611 -PostToJira
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IssueKey,
    [string]$Profile = "test2",
    [switch]$PostToJira,
    [switch]$DryRun
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

# Test patterns and their verification logic
$testPatterns = @{
    "exit code" = @{
        Description = "Exit code verification"
        VerifyFunction = {
            param($command, $expectedExitCode)
            $result = Invoke-Expression $command 2>&1
            $actualExitCode = $LASTEXITCODE
            return @{
                Passed = ($actualExitCode -eq $expectedExitCode)
                Expected = $expectedExitCode
                Actual = $actualExitCode
                Output = $result | Out-String
            }
        }
    }
    "output format" = @{
        Description = "Output format verification"
        VerifyFunction = {
            param($command)
            $result = Invoke-Expression "$command --format Json" 2>&1 | Out-String
            try {
                $null = $result | ConvertFrom-Json
                return @{ Passed = $true; Output = "Valid JSON output" }
            }
            catch {
                return @{ Passed = $false; Output = "Invalid JSON: $($_.Exception.Message)" }
            }
        }
    }
    "should error" = @{
        Description = "Error behavior verification"
        VerifyFunction = {
            param($command)
            $result = Invoke-Expression $command 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            return @{
                Passed = ($exitCode -ne 0)
                Output = "Exit code: $exitCode`n$result"
            }
        }
    }
    "should not error" = @{
        Description = "Success behavior verification"
        VerifyFunction = {
            param($command)
            $result = Invoke-Expression $command 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            return @{
                Passed = ($exitCode -eq 0)
                Output = "Exit code: $exitCode`n$result"
            }
        }
    }
}

function Extract-CLICommands {
    param([string]$Text)
    
    $commands = @()
    
    # Pattern 1: Commands in code blocks
    $codeBlockPattern = '```(?:powershell|bash|shell|cmd)?\s*(magicsuite[^\n`]+)'
    $matches = [regex]::Matches($Text, $codeBlockPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $commands += $m.Groups[1].Value.Trim()
    }
    
    # Pattern 2: Inline magicsuite commands
    $inlinePattern = '(magicsuite\s+[a-z]+(?:\s+[a-z0-9-]+)*(?:\s+--[a-z-]+(?:\s+[^\s]+)?)*)'
    $matches = [regex]::Matches($Text, $inlinePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $cmd = $m.Groups[1].Value.Trim()
        if ($cmd -notin $commands) {
            $commands += $cmd
        }
    }
    
    # Pattern 3: dotnet tool commands
    $dotnetPattern = '(dotnet\s+tool\s+[a-z]+[^\n]+)'
    $matches = [regex]::Matches($Text, $dotnetPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $commands += $m.Groups[1].Value.Trim()
    }
    
    return $commands
}

function Detect-TestType {
    param([string]$Text)
    
    $text = $Text.ToLower()
    $detectedTypes = @()
    
    foreach ($pattern in $testPatterns.Keys) {
        if ($text -match [regex]::Escape($pattern)) {
            $detectedTypes += $pattern
        }
    }
    
    # Check for specific exit code values
    if ($text -match 'exit code[:\s]+(\d+)') {
        $detectedTypes += "specific-exit-code:$($Matches[1])"
    }
    
    # Check for negative/invalid input testing
    if ($text -match 'negative|invalid|error|fail') {
        $detectedTypes += "negative-testing"
    }
    
    return $detectedTypes
}

function Post-JiraComment {
    param([string]$IssueKey, [string]$Comment)
    
    $body = @{
        body = $Comment
    } | ConvertTo-Json
    
    try {
        $null = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey/comment" `
            -Method POST -Headers $headers -Body $body
        Write-Host "Posted comment to $IssueKey" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to post comment: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "=== Auto-Verify CLI: $IssueKey ===" -ForegroundColor Cyan
Write-Host ""

# Fetch ticket details
Write-Host "Fetching ticket details..." -ForegroundColor Yellow

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

Write-Host "Summary: $summary" -ForegroundColor White
Write-Host ""

# Extract commands
$fullText = "$summary`n$description"
$commands = Extract-CLICommands -Text $fullText
$testTypes = Detect-TestType -Text $fullText

Write-Host "Detected test types: $($testTypes -join ', ')" -ForegroundColor Yellow
Write-Host "Extracted commands:" -ForegroundColor Yellow
foreach ($cmd in $commands) {
    Write-Host "  - $cmd" -ForegroundColor Cyan
}
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN - Commands not executed" -ForegroundColor Yellow
    exit 0
}

# Check CLI version
Write-Host "Checking CLI version..." -ForegroundColor Yellow
$cliVersion = & magicsuite --version 2>&1 | Out-String
Write-Host "CLI Version: $($cliVersion.Trim())" -ForegroundColor Cyan
Write-Host ""

# Run tests
$testResults = @()
$allPassed = $true

if ($commands.Count -eq 0) {
    Write-Host "No CLI commands found in ticket. Generating test based on description..." -ForegroundColor Yellow
    
    # Generate test commands based on test types
    if ("exit code" -in $testTypes) {
        # Look for parameter mentions
        if ($description -match 'take.*parameter|--take') {
            $commands += "magicsuite api get tenants --take -1 --profile $Profile"
            $commands += "magicsuite api get tenants --take 1 --profile $Profile"
        }
    }
}

foreach ($cmd in $commands) {
    Write-Host "Testing: $cmd" -ForegroundColor Cyan
    
    # Add profile if not present
    if ($cmd -match '^magicsuite' -and $cmd -notmatch '--profile') {
        $cmd = "$cmd --profile $Profile"
    }
    
    $testResult = @{
        Command = $cmd
        StartTime = Get-Date
        Passed = $false
        ExitCode = $null
        Output = ""
        Error = ""
    }
    
    try {
        $output = Invoke-Expression $cmd 2>&1
        $testResult.ExitCode = $LASTEXITCODE
        $testResult.Output = $output | Out-String
        
        # Determine pass/fail based on test type
        if ("should error" -in $testTypes -or "negative-testing" -in $testTypes) {
            $testResult.Passed = ($LASTEXITCODE -ne 0)
        }
        elseif ("exit code" -in $testTypes) {
            # Check for specific expected exit code
            $expectedCode = 0
            foreach ($type in $testTypes) {
                if ($type -match 'specific-exit-code:(\d+)') {
                    $expectedCode = [int]$Matches[1]
                }
            }
            $testResult.Passed = ($LASTEXITCODE -eq $expectedCode)
        }
        else {
            # Default: command should succeed
            $testResult.Passed = ($LASTEXITCODE -eq 0)
        }
    }
    catch {
        $testResult.Error = $_.Exception.Message
        $testResult.Passed = $false
    }
    
    $testResult.EndTime = Get-Date
    $testResult.Duration = ($testResult.EndTime - $testResult.StartTime).TotalSeconds
    
    # Display result
    $statusColor = if ($testResult.Passed) { "Green" } else { "Red" }
    $statusIcon = if ($testResult.Passed) { "✓" } else { "✗" }
    Write-Host "  $statusIcon Exit Code: $($testResult.ExitCode) - $(if ($testResult.Passed) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor
    
    $testResults += $testResult
    if (-not $testResult.Passed) { $allPassed = $false }
}

# Generate report
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
$passCount = ($testResults | Where-Object { $_.Passed }).Count
$failCount = ($testResults | Where-Object { -not $_.Passed }).Count
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

# Format JIRA comment
$jiraComment = @"
h2. 🤖 Auto-CLI Verification Results

*Ticket:* $IssueKey
*Test Date:* $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
*CLI Version:* $($cliVersion.Trim())
*Profile:* $Profile
*Overall Result:* $(if ($allPassed) { '✅ PASSED' } else { '❌ FAILED' })

h3. Test Details

|Command|Exit Code|Result|Duration|
"@

foreach ($result in $testResults) {
    $status = if ($result.Passed) { "✓ Pass" } else { "✗ Fail" }
    $cmdDisplay = $result.Command.Replace("|", "\\|")
    $jiraComment += "|{code}$cmdDisplay{code}|$($result.ExitCode)|$status|$([math]::Round($result.Duration, 2))s|`n"
}

$jiraComment += @"

h3. Output Samples
{code}
$($testResults[0].Output.Substring(0, [Math]::Min(500, $testResults[0].Output.Length)))...
{code}

_This verification was performed automatically. Please review for accuracy._
"@

Write-Host "JIRA Comment Preview:" -ForegroundColor Yellow
Write-Host $jiraComment -ForegroundColor Gray

if ($PostToJira) {
    Write-Host ""
    Post-JiraComment -IssueKey $IssueKey -Comment $jiraComment
}
else {
    Write-Host ""
    Write-Host "Use -PostToJira to post this comment to JIRA" -ForegroundColor Yellow
}

# Return exit code based on test results
exit $(if ($allPassed) { 0 } else { 1 })
