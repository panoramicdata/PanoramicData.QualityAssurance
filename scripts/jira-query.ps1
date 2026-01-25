# Simple JIRA query script - writes results to file
$ErrorActionPreference = 'Stop'
$outputFile = "c:\Users\DavidBond\PanoramicData.QualityAssurance\jira-ready-for-test.json"

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

$body = @{
    jql = "project=MS AND status='Ready for Test' ORDER BY updated DESC"
    maxResults = 50
    fields = @("summary", "issuetype", "labels", "fixVersions", "description", "status", "priority")
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/search" -Headers $headers -Method POST -Body $body -ContentType "application/json"
    $response | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
    Write-Output "SUCCESS: Found $($response.total) issues. Saved to $outputFile"
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
