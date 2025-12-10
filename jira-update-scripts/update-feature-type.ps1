# Update MS-22532 to change issue type to Feature

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

$body = @{
    fields = @{
        issuetype = @{ name = "Feature" }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Updating MS-22532 issue type to Feature..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/MS-22532" -Method PUT -Headers $headers -Body $body
    Write-Host "Success! Updated issue MS-22532 to Feature type" -ForegroundColor Green
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
