# Helper script to create JIRA bug for MagicSuite CLI duplicate --profile option issue

# Get credentials
$credTarget = "PanoramicData_JIRA"
$cred = $null

try {
    $credObject = Get-StoredCredential -Target $credTarget -ErrorAction SilentlyContinue
    if ($credObject) {
        $cred = $credObject
    }
} catch {
    # Fallback to environment variables
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
    }
}

if (-not $cred) {
    Write-Error "No JIRA credentials found. Please set up credentials in Windows Credential Manager or environment variables."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
    "Content-Type" = "application/json"
}

$summary = "MagicSuite CLI: Duplicate --profile option in help text"

$description = @"
h2. Summary
The MagicSuite CLI help text shows the {{--profile}} option twice in multiple commands, creating confusion about which option to use.

h2. Environment
* MagicSuite CLI Version: 4.1.184+7504ce11bc
* Installation Path: {{C:\Users\amycb\.dotnet\tools\magicsuite.exe}}
* Date Tested: December 9, 2025

h2. Steps to Reproduce
1. Run command: {{magicsuite api get --help}}
2. Observe the Options section
3. Repeat with other commands: {{magicsuite api get-by-id --help}}

h2. Actual Result
The help text shows {{--profile}} twice:

{code}
Options:
  --profile <profile>        Profile to use
  [... other options ...]
  --profile <profile>        Use named profile (e.g., production, alpha3, local)
  --api-url <api-url>        Override API URL from profile/config
{code}

h2. Expected Result
The {{--profile}} option should appear only once in the help text, with a clear and consistent description.

h2. Impact
* Confuses users about which {{--profile}} option to use
* Makes the help text look unprofessional
* Suggests potential code duplication in option handling
* Affects multiple commands: {{api get}}, {{api get-by-id}}, {{api patch}}, {{api delete}}, {{file}} commands

h2. Additional Context
This appears to be a case where both command-specific options and global options are being merged, resulting in duplicate entries. The issue affects all commands that accept the {{--profile}} parameter.

h2. Suggested Fix
Either:
# Show only command-specific options in the command help (preferred)
# Clearly separate 'Command Options' and 'Global Options' sections
# Deduplicate options when merging command and global options
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = $summary
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Creating JIRA bug ticket for duplicate --profile option..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
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
