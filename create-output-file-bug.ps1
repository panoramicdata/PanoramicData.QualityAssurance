# Helper script to create JIRA bug for MagicSuite CLI output file issue

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

$summary = "MagicSuite CLI: --output parameter doesn't save to file, writes to console instead"

$description = @"
h2. Summary
The {{--output}} parameter for {{magicsuite api}} commands does not save output to the specified file. Instead, the output is written to the console as if the parameter was not provided.

h2. Environment
* MagicSuite CLI Version: 4.1.184+7504ce11bc
* Installation Path: {{C:\Users\amycb\.dotnet\tools\magicsuite.exe}}
* Date Tested: December 9, 2025

h2. Steps to Reproduce
1. Run command: {{magicsuite api get connections --select Name --output test-output.json --format json}}
2. Observe that output is written to console
3. Check if file was created: {{Test-Path test-output.json}}

h2. Actual Result
* Output is displayed in the console (full JSON array of 100+ connections)
* File {{test-output.json}} is NOT created
* {{Test-Path test-output.json}} returns {{False}}

h2. Expected Result
* Output should be written to {{test-output.json}} file
* Console should show minimal feedback (e.g., "Output written to test-output.json")
* File should contain the JSON output
* {{Test-Path test-output.json}} should return {{True}}

h2. Impact
* Breaks scripting and automation workflows that rely on file output
* Cannot redirect large API responses to files for processing
* Forces users to use PowerShell redirection operators instead of built-in option
* Documented feature does not work as described

h2. Additional Context
The {{--output}} parameter is documented in the help text:
{code}
--output <output>          Write output to file instead of console
{code}

This suggests the feature is intended but not functioning correctly.

h2. Suggested Fix
* Implement file writing logic for the {{--output}} parameter
* Suppress console output when {{--output}} is specified
* Provide user feedback confirming file was written
* Ensure proper error handling if file cannot be written (permissions, path issues, etc.)
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
    Write-Host "Creating JIRA bug ticket for --output parameter issue..."
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
