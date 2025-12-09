# Helper script to create JIRA bug for MagicSuite CLI .NET 10 SDK requirement

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

$summary = "MagicSuite CLI requires .NET 10 SDK for installation - undocumented dependency"

$description = @"
h2. Summary
The MagicSuite.Cli tool requires .NET 10 SDK to be installed before it can be installed as a global dotnet tool. This dependency is not clearly documented and may cause installation failures for users.

h2. Environment
* Tool: MagicSuite.Cli
* Installation Method: {{dotnet tool install -g MagicSuite.Cli}}
* Required Dependency: .NET 10 SDK
* Date Reported: December 8, 2025

h2. Steps to Reproduce
1. Attempt to install MagicSuite CLI without .NET 10 SDK installed
2. Run command: {{dotnet tool install -g MagicSuite.Cli}}
3. Observe installation behavior

h2. Actual Result
Installation fails or requires .NET 10 SDK to be present. Users may encounter:
* Tool installation errors
* Runtime errors if incompatible .NET version is present
* Unclear error messages about missing dependencies

h2. Expected Result
Either:
* Clear error message indicating .NET 10 SDK is required
* Documentation should prominently specify .NET 10 SDK as a prerequisite
* Tool should target a more widely available .NET version (e.g., .NET 8 LTS) if possible

h2. Additional Context
* .NET 10 is a preview/newer version that may not be installed by default
* Many users may have .NET 6 or .NET 8 LTS versions installed
* The update command also fails with package validation errors

h2. Impact
* Blocks users from installing the CLI tool
* Requires additional SDK installation step that may not be obvious
* May not be clear to users what dependency is missing
* Affects all new users attempting to install the tool

h2. Suggested Fix
* Add clear prerequisite documentation to README/installation guide
* Consider targeting .NET 8 LTS for broader compatibility
* Improve error messaging during installation to indicate SDK version requirement
* Add version check or helpful error message when incompatible .NET version is detected
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = $summary
        description = $description
        customfield_11200 = @("MagicSuite_R&D")  # Required: Toggl Project field
    }
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Creating JIRA bug ticket..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host "✅ Successfully created bug: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to create bug: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}
