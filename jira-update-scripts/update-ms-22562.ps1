# Add comment to MS-22562 about fix verification

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

The duplicate --profile option has been resolved. Running 'magicsuite api get --help' now shows the --profile option only once:

Options:
  --profile <profile>  Profile to use
  --filter <filter>    Filter by name (contains search)

The help text is now clean and consistent across all commands. Ready to close.
"@

$body = @{
    body = $comment
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Adding comment to MS-22562..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22562/comment" `
        -Method POST `
        -Headers $headers `
        -Body $utf8Body
    
    Write-Host "Successfully added comment to MS-22562" -ForegroundColor Green
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
