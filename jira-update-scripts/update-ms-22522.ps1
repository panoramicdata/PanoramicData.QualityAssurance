# Add verification comment to MS-22522

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

$comment = @"
VERIFIED FIXED in version 4.1.249+73a3bd2565

Comprehensive testing shows the malformed markup exception has been resolved:

Test Results (All Passed):
1. ReportSchedules (Table Format) - SUCCESS
2. Connections (Table Format) - SUCCESS  
3. ReportSchedules (JSON Format) - SUCCESS
4. Connections (JSON Format) - SUCCESS
5. Large Result Set (50 records) - SUCCESS

Commands tested:
- magicsuite api get reportschedules --take 5
- magicsuite api get connections --take 50
- Both table and JSON output formats work correctly

The InvalidOperationException "Encountered malformed markup tag at position 82" no longer occurs. Special characters in entity data are now properly escaped before rendering to the console.

Ready to close.
"@

$body = @{
    body = $comment
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Adding comment to MS-22522..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22522/comment" `
        -Method POST `
        -Headers $headers `
        -Body $utf8Body
    
    Write-Host "Successfully added comment to MS-22522" -ForegroundColor Green
}
catch {
    Write-Error "Failed to add comment: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
