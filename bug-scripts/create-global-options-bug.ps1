# Helper script to create JIRA bug for MagicSuite CLI global options positioning issue

# Get credentials
$credTarget = "PanoramicData_JIRA"
$cred = $null

try {
    $credObject = Get-StoredCredential -Target $credTarget -ErrorAction SilentlyContinue
    if ($credObject) {
        $cred = $credObject
    }
} catch {
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
    }
}

if (-not $cred) {
    Write-Error "No JIRA credentials found."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
    "Content-Type" = "application/json"
}

$summary = "MagicSuite CLI: Global options must be placed before subcommand"

$description = @"
h2. Summary
Global options like {{--verbose}} and {{--quiet}} are documented in the main help but only work when placed BEFORE the subcommand, not after. This is counterintuitive and inconsistent with standard CLI behavior.

h2. Environment
* MagicSuite CLI Version: 4.1.249+73a3bd2565
* Installation Path: {{C:\Users\amycb\.dotnet\tools\magicsuite.exe}}
* Date Tested: December 10, 2025

h2. Steps to Reproduce
1. Run command: {{magicsuite api get tenants --verbose}}
2. Observe the error message
3. Run command: {{magicsuite --verbose api get tenants}}
4. Observe that it works correctly

h2. Actual Result
When global options are placed after the subcommand:

{code}
PS> magicsuite api get tenants --verbose
Unrecognized command or argument '--verbose'.
{code}

When placed before the subcommand, it works:
{code}
PS> magicsuite --verbose api get tenants
Fetching Tenant...
[works correctly]
{code}

h2. Expected Result
Global options should work in either position:
* {{magicsuite --verbose api get tenants}} (before subcommand)
* {{magicsuite api get tenants --verbose}} (after subcommand)

This is standard behavior for most CLI tools (git, docker, kubectl, etc.)

h2. Impact
* Confusing user experience - natural expectation is to add options at the end
* Documentation shows these as "global options" but they don't behave globally
* Users receive unhelpful error messages instead of the options working
* Affects all global options: {{--verbose}}, {{--quiet}}, {{--profile}}, {{--api-url}}, {{--token-name}}, {{--token-key}}, {{--tenant}}

h2. Affected Commands
All subcommands are affected:
* {{api get}}, {{api get-by-id}}, {{api patch}}, {{api delete}}
* {{file list}}, {{file upload}}, {{file download}}
* {{config}} commands
* {{tenant}} commands

h2. Additional Context
The main help ({{magicsuite --help}}) documents these options:
{code}
Options:
  --verbose                  Enable verbose logging
  --quiet                    Suppress non-essential output
  --profile <profile>        Use named profile
  [etc...]
{code}

But the subcommand help ({{magicsuite api get --help}}) only shows command-specific options, giving no hint that global options must be placed earlier.

h2. Suggested Fix
Options:
# Modify argument parser to accept global options in any position (preferred)
# Update all help text to explicitly state global options must come first
# Show global options in subcommand help with a note about positioning
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = $summary
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Creating JIRA bug ticket for global options positioning issue..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST `
        -Headers $headers `
        -Body $utf8Body
    
    Write-Host "Successfully created issue: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to create JIRA issue: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
