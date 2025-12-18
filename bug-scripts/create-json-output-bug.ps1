# Script to create JIRA ticket for CLI JSON output bug
# Bug: --quiet flag doesn't suppress status messages in JSON output
# Date: 2025-12-18

Write-Host "`n=== Creating JIRA Ticket for CLI JSON Output Bug ===" -ForegroundColor Cyan

# Get credentials from environment
$JIRA_USERNAME = $env:JIRA_USERNAME
$JIRA_PASSWORD = $env:JIRA_PASSWORD

if (-not $JIRA_USERNAME -or -not $JIRA_PASSWORD) {
    Write-Error "JIRA credentials not found in environment variables."
    Write-Host "Please set JIRA_USERNAME and JIRA_PASSWORD environment variables." -ForegroundColor Yellow
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JIRA_USERNAME}:${JIRA_PASSWORD}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Store description in variable first
$description = 'h2. Summary
When using {{--format json}} with the {{--quiet}} flag, the CLI still outputs status messages like "Fetching..." which get mixed into the JSON output, making it unparseable. This breaks automation scripts that need to consume JSON output programmatically.

h2. Environment
* *CLI Version:* 4.1.323+b1d2df9293
* *Test Environment:* test.magicsuite.net
* *Test Date:* 2025-12-18
* *Operating System:* Windows
* *PowerShell Version:* 5.1

h2. Steps to Reproduce
1. Run the following command:
{{magicsuite api get tenants --take 1 --format json --quiet}}
2. Pipe the output to a JSON parser:
{{magicsuite api get tenants --take 1 --format json --quiet | ConvertFrom-Json}}
3. Observe the parsing error

h2. Expected vs Actual Behavior
*Expected:*
* {{--quiet}} flag should suppress ALL non-essential output including status messages
* Output should be *pure JSON only*, suitable for piping to JSON parsers
* No "Fetching..." or other status text in the output stream
* JSON should be parseable without errors

*Actual:*
* Status message "Fetching Tenant..." is still output BEFORE the JSON
* This breaks JSON parsing with error: "Invalid JSON primitive: Fetching."
* The {{--quiet}} flag does not suppress status messages when using {{--format json}}

h2. Output Example
{code}
Fetching Tenant...
[
  {
    "Id": 1,
    "Name": "Panoramic Data"
  }
]
{code}

The "Fetching Tenant..." line should NOT be present when {{--quiet}} is used.

h2. Impact
* *Breaks automation scripts* - Cannot parse CLI output in PowerShell, Python, or other tools that consume JSON
* *Makes CLI unsuitable for pipelines* - Cannot reliably use CLI in CI/CD or data processing workflows
* *Workarounds are fragile* - Users must use string manipulation to strip status messages before parsing
* *Inconsistent with {{--quiet}} semantics* - The {{--quiet}} flag should mean "output only the requested data"
* *Blocks programmatic use* - Any script that needs to consume CLI output as JSON will fail

h2. Test Evidence
{code:powershell}
PS> magicsuite api get tenants --take 1 --format json --quiet | ConvertFrom-Json
ConvertFrom-Json : Invalid JSON primitive: Fetching.
At line:1 char:61
    + CategoryInfo          : NotSpecified: (:) [ConvertFrom-Json], ArgumentException
    + FullyQualifiedErrorId : System.ArgumentException,Microsoft.PowerShell.Commands.ConvertFromJsonCommand
{code}

h2. Affected Commands
This affects ALL {{api get}} and {{api get-by-id}} commands when using {{--format json}}:
* {{magicsuite api get <entity-type> --format json --quiet}}
* {{magicsuite api get-by-id <entity-type> <id> --format json --quiet}}

h2. Recommended Fix
When {{--format json}} is used (regardless of {{--quiet}}), ALL status messages should be suppressed automatically. Status messages should either:
1. Go to stderr (so they do not pollute stdout/JSON), OR
2. Be completely suppressed when outputting structured data formats (json)

*Best Practice:* Progress/status messages should go to stderr, data output to stdout.

h2. Workaround (for users until fixed)
{code:powershell}
# Option 1: Filter out non-JSON lines
magicsuite api get tenants --take 1 --format json --quiet 2>&1 | 
  Where-Object { $_ -match "^\[|^\{" } | ConvertFrom-Json

# Option 2: Use --output to file
magicsuite api get tenants --take 1 --format json --output temp.json
$data = Get-Content temp.json | ConvertFrom-Json
{code}

h2. Related Issues
This is a separate issue from MS-22608 (exit code bugs) - this is about data output corruption.

h2. Test Results Document
Full test results: {{test-results/new-cli-bugs-found-20251218-session2.md}}'

# Create the issue
$issue = @{
    fields = @{
        project = @{key = "MS"}
        issuetype = @{name = "Bug"}
        summary = "MagicSuite CLI: --quiet flag doesn't suppress status messages in JSON output, breaking JSON parsing"
        description = $description
        priority = @{id = "2"}  # Critical
        labels = @("CLI", "JSON", "automation-blocker", "data-corruption", "quiet-flag")
        customfield_11200 = @('MagicSuite_R&D')
    }
}

$body = $issue | ConvertTo-Json -Depth 10

try {
    Write-Host "Creating JIRA ticket..." -ForegroundColor Gray
    $result = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST -Headers $headers -Body $body
    
    Write-Host "✓ Created: $($result.key)" -ForegroundColor Green
    Write-Host "  URL: https://jira.panoramicdata.com/browse/$($result.key)" -ForegroundColor Cyan
    
    # Add comment with additional context
    Write-Host "Adding detailed comment..." -ForegroundColor Gray
    $comment = @{
        body = "This bug is critical for automation users. The CLI cannot be used reliably in scripts or pipelines when JSON output is required. Common use cases affected: CI/CD pipelines, data extraction scripts, infrastructure-as-code tools, monitoring integrations."
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$($result.key)/comment" `
        -Method POST -Headers $headers -Body $comment | Out-Null
    Write-Host "✓ Added context comment" -ForegroundColor Green
    
    Write-Host "`n=== Success ===" -ForegroundColor Green
    Write-Host "Ticket $($result.key) created successfully" -ForegroundColor White
    Write-Host "Priority: Critical" -ForegroundColor Red
    Write-Host "Labels: CLI, JSON, automation-blocker, data-corruption, quiet-flag" -ForegroundColor Gray
}
catch {
    Write-Host "✗ Failed to create ticket: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Response:" -ForegroundColor Yellow
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5 | Write-Host
    }
    exit 1
}
