# Helper script to create JIRA bug for MagicSuite CLI file type display issue

# Get credentials using the helper script (Windows Credential Manager)
$credentialScript = Join-Path $PSScriptRoot "..\..\..\.github\tools\Get-JiraCredentials.ps1"
if (-not (Test-Path $credentialScript)) {
    $credentialScript = Join-Path $PSScriptRoot "..\..\.github\tools\Get-JiraCredentials.ps1"
}
$credentials = & $credentialScript
if (-not $credentials -or -not $credentials.Username -or -not $credentials.Password) {
    Write-Error "Failed to retrieve JIRA credentials."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($credentials.Username):$($credentials.Password)"))
    "Content-Type" = "application/json"
}

$summary = "MagicSuite CLI: File type column shows '??' instead of file/folder indicators"

$description = @"
h2. Summary
The {{magicsuite file list}} command displays {{??}} in the Type column for all files and folders, instead of showing proper file type indicators.

h2. Environment
* MagicSuite CLI Version: 4.1.184+7504ce11bc
* Installation Path: {{C:\Users\amycb\.dotnet\tools\magicsuite.exe}}
* Date Tested: December 9, 2025

h2. Steps to Reproduce
1. Run command: {{magicsuite file list /Library}}
2. Observe the Type column in the output

h2. Actual Result
The Type column displays {{??}} for all items:

{code}
┌──────┬────────────────────────────────────────────┬───────────┬──────────────────┐
│ Type │ Name                                       │ Size      │ Modified         │
├──────┼────────────────────────────────────────────┼───────────┼──────────────────┤
│ ??   │ index.json                                 │ 16.94 KB  │ 2025-11-06 14:43 │
│ ??   │ Library 1.txt                              │ 77 B      │ 2022-12-08 12:03 │
│ ??   │ Agent Installer                            │ --        │ 2024-11-11 15:20 │
│ ??   │ HealthCheck Archives                       │ --        │ 2025-08-26 20:32 │
└──────┴────────────────────────────────────────────┴───────────┴──────────────────┘
{code}

h2. Expected Result
The Type column should display clear indicators such as:
* {{F}} or {{file}} for files
* {{D}} or {{folder}}/{{dir}} for directories
* Or appropriate icons if the terminal supports them

h2. Impact
* Reduces usability of the file listing command
* Users cannot easily distinguish between files and folders
* Makes it harder to navigate the file system via CLI
* Cosmetic issue that affects user experience

h2. Priority
Minor - Functionality works but display is unclear

h2. Additional Context
The command correctly identifies files vs folders (files show size, folders show {{--}}), but the Type column doesn't reflect this information.

h2. Suggested Fix
Update the Type column rendering logic to:
# Display 'File' or 'F' for files
# Display 'Folder' or 'D' for directories
# Ensure proper character encoding for any icon characters
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = $summary
        description = $description
        priority = @{ name = "Minor" }
        customfield_11200 = @("MagicSuite_R&D")
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Creating JIRA bug ticket for file type display issue..."
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
