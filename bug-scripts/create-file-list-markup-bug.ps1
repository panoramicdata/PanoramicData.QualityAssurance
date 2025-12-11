# Create JIRA bug for file list markup exception (regression in 4.1.254)

Write-Host "Creating JIRA bug for file list markup exception regression..." -ForegroundColor Cyan

# Get credentials from Windows Credential Manager or environment variables
$credential = $null
try {
    $credential = Get-StoredCredential -Target "PanoramicData_JIRA"
    Write-Host "Using credentials from Windows Credential Manager" -ForegroundColor Green
} catch {
    Write-Host "Credential Manager not available, checking environment variables..." -ForegroundColor Yellow
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
        Write-Host "Using credentials from environment variables" -ForegroundColor Green
    } else {
        Write-Host "No credentials found. Please set JIRA_USERNAME and JIRA_PASSWORD environment variables." -ForegroundColor Red
        exit 1
    }
}

$username = $credential.UserName
$password = $credential.GetNetworkCredential().Password

# Create base64 encoded credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

# JIRA API endpoint
$jiraUrl = "https://jira.panoramicdata.com/rest/api/2/issue"

# Create the issue
$issueData = @{
    fields = @{
        project = @{
            key = "MS"
        }
        issuetype = @{
            name = "Bug"
        }
        summary = "MagicSuite CLI: File list command throws markup exception for root directory (regression)"
        description = @"
h2. Summary
The {{magicsuite file list /}} command throws a markup exception when listing the root directory in version 4.1.254. This is a *regression* - the command worked correctly in version 4.1.249.

h2. Environment
* *CLI Version*: 4.1.254+9bb1b85f0d
* *Profile*: AmyTest2 (test2.magicsuite.net)
* *Command*: {{magicsuite file list /}}
* *Previous Working Version*: 4.1.249

h2. Steps to Reproduce
1. Update to CLI version 4.1.254
2. Open PowerShell terminal
3. Ensure MagicSuite CLI is authenticated with a valid profile
4. Run: {{magicsuite file list /}}
5. Observe the error

h2. Actual Result
{code}
Listing files in: /
Error: Encountered malformed markup tag at position 6.
{code}

The command fails completely with no file listing.

h2. Expected Result
The command should display a table of files and folders in the root directory, as it did in version 4.1.249.

h2. Additional Context
* This is a *REGRESSION* introduced in version 4.1.254
* The command works correctly for subdirectories:
  * {{magicsuite file list /Amy}} - Works fine
  * {{magicsuite file list /Sam}} - Works fine
* Only fails when listing the root directory {{/}}
* Likely related to MS-22522, MS-22570 (other Spectre.Console markup issues)
* The error suggests a filename or folder name in root contains characters that need escaping
* Using {{--format json}} works as a workaround

h2. Workaround
Use JSON output format: {{magicsuite file list / --format json}}

h2. Impact
* *Severity*: Medium - Breaks root directory listing but subdirectories work
* *Affected Users*: Any user attempting to list the root directory
* *Regression*: Feature that worked in 4.1.249 is now broken

h2. Previous Version Behavior
In version 4.1.249, {{magicsuite file list /}} successfully displayed 103 items with no errors.
"@
        customfield_11200 = @("MagicSuite_R&D")  # Toggl Project - required field
    }
}

try {
    $jsonBody = $issueData | ConvertTo-Json -Depth 10
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }
    
    # Convert to UTF-8 bytes to prevent encoding issues
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
    
    $response = Invoke-RestMethod -Uri $jiraUrl -Method Post -Headers $headers -Body $bodyBytes -ContentType "application/json; charset=utf-8"
    
    Write-Host "`nJIRA bug created successfully!" -ForegroundColor Green
    Write-Host "Issue Key: $($response.key)" -ForegroundColor Cyan
    Write-Host "Issue URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
    
    # Link to MS-22522 and MS-22570 as related issues
    Write-Host "`nLinking to related markup issues..." -ForegroundColor Yellow
    
    foreach ($relatedIssue in @("MS-22522", "MS-22570")) {
        $linkData = @{
            type = @{
                name = "Relates"
            }
            inwardIssue = @{
                key = $response.key
            }
            outwardIssue = @{
                key = $relatedIssue
            }
        } | ConvertTo-Json -Depth 10
        
        $linkBytes = [System.Text.Encoding]::UTF8.GetBytes($linkData)
        Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method Post -Headers $headers -Body $linkBytes -ContentType "application/json; charset=utf-8" | Out-Null
        Write-Host "Linked to $relatedIssue successfully!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "`nError creating JIRA issue:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}
