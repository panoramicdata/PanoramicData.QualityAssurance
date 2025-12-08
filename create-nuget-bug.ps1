# Create JIRA bug for NuGet package issue

# Get credentials from environment variables
$username = $env:JIRA_USERNAME
$password = $env:JIRA_PASSWORD

if (-not $username -or -not $password) {
    Write-Host "❌ JIRA credentials not found in environment variables." -ForegroundColor Red
    Write-Host "Please set JIRA_USERNAME and JIRA_PASSWORD environment variables." -ForegroundColor Yellow
    exit 1
}

$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

$headers = @{
    "Authorization" = "Basic $credentials"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$description = @"
*Summary*
The latest MagicSuite.Cli NuGet package is missing the required DotnetToolSettings.xml file, preventing users from installing or updating the global tool.

*Environment*
- Current Working Version: 3.28.258
- NuGet Package: MagicSuite.Cli
- Date Tested: December 8, 2025

*Steps to Reproduce*
1. Attempt to update the tool: dotnet tool update -g MagicSuite.Cli
2. OR attempt to install the tool: dotnet tool install -g MagicSuite.Cli
3. Observe the error

*Actual Result*
{code}
Tool 'magicsuite.cli' failed to update due to the following:
The settings file in the tool's NuGet package is invalid: Settings file 'DotnetToolSettings.xml' was not found in the package.
Tool 'magicsuite.cli' failed to install. Contact the tool author for assistance.
{code}

*Expected Result*
The tool should install or update successfully. The NuGet package must include a valid DotnetToolSettings.xml file as required by the .NET global tool specification.

*Impact*
- Users cannot update to the latest version of the CLI
- New users cannot install the CLI at all
- Bug fixes and new features in recent releases are inaccessible
- Blocks deployment of fixes for other reported issues (e.g., MS-22522 markup error fix)

*Root Cause*
The NuGet package is missing the DotnetToolSettings.xml file which is required for .NET global tools. This file should be included in the package at build/publish time.

*Workaround*
Users can install the last working version explicitly:
{code}
dotnet tool install -g MagicSuite.Cli --version 3.28.258
{code}

*Suggested Fix*
1. Verify the build/publish process includes DotnetToolSettings.xml
2. Check the .csproj file has the correct PackAsTool and ToolCommandName settings
3. Republish the NuGet package with the correct contents
4. Test the package installation before publishing

*Severity*
High - This is a blocking issue that prevents all users from accessing the latest CLI version.
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = "MagicSuite CLI NuGet package missing DotnetToolSettings.xml - blocks installation/updates"
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
        assignee = @{ name = "david.bond" }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating JIRA bug ticket..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $body
    Write-Host "Success! Created issue: $($response.key)" -ForegroundColor Green
    Write-Host "Assigned to: david.bond" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
    $response
}
catch {
    Write-Host "Error Response:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host $responseBody
    }
}
