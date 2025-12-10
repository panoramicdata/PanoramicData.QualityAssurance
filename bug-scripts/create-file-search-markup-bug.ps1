# Create JIRA bug for file search markup exception
# Related to MS-22522 - markup exception was fixed for API commands but not file commands

Write-Host "Creating JIRA bug for file search markup exception..." -ForegroundColor Cyan

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
        summary = "MagicSuite CLI: File search throws markup exception with unescaped characters"
        description = @"
h2. Summary
The {{magicsuite file search}} command throws an unhandled Spectre.Console markup exception when searching for certain terms, making file search functionality unusable in those cases.

h2. Environment
* *CLI Version*: 4.1.249+73a3bd2565
* *Profile*: AmyTest2 (test2.magicsuite.net)
* *Command*: {{magicsuite file search "test"}}

h2. Steps to Reproduce
1. Open PowerShell terminal
2. Ensure MagicSuite CLI is authenticated with a valid profile
3. Run: {{magicsuite file search "test"}}
4. Observe the exception

h2. Actual Result
{code}
Searching for: 'test' in /
Unhandled exception: System.InvalidOperationException: Encountered unescaped ']' token at position 39
   at Spectre.Console.MarkupTokenizer.ReadText()
   at MagicSuite.Cli.Commands.FileCommands.cs:line 729
{code}

The command crashes completely with no search results.

h2. Expected Result
The command should display a table of search results with properly escaped special characters in filenames/paths, similar to how {{magicsuite file search "library"}} works correctly.

h2. Additional Context
* This bug is *related to MS-22522* which was fixed in version 4.1.249
* MS-22522 fixed markup exceptions for {{magicsuite api get}} commands
* However, the fix appears incomplete - it addressed {{ApiCommands.cs}} but not {{FileCommands.cs}}
* The {{file search "library"}} command works correctly, returning 28 results
* This suggests certain search terms or result sets trigger the unescaped character issue
* The exception occurs in {{FileCommands.cs:line 729}} (different location than MS-22522's {{ApiCommands.cs:line 221}})

h2. Impact
* *Severity*: High - File search is completely broken for affected search terms
* *Workaround*: None - users cannot search for certain terms
* *Affected Users*: Any user attempting to search the MagicSuite file system

h2. Suggested Fix
Apply the same Spectre.Console character escaping logic that fixed MS-22522 to the file search command path in {{FileCommands.cs}}.
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
    
    # Link to MS-22522 as related issue
    Write-Host "`nLinking to MS-22522..." -ForegroundColor Yellow
    $linkData = @{
        type = @{
            name = "Relates"
        }
        inwardIssue = @{
            key = $response.key
        }
        outwardIssue = @{
            key = "MS-22522"
        }
    } | ConvertTo-Json -Depth 10
    
    $linkBytes = [System.Text.Encoding]::UTF8.GetBytes($linkData)
    Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issueLink" -Method Post -Headers $headers -Body $linkBytes -ContentType "application/json; charset=utf-8" | Out-Null
    Write-Host "Linked to MS-22522 successfully!" -ForegroundColor Green
    
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
