# Query JIRA for Ready for Test tickets - Output to file
$outputFile = "c:\Users\DavidBond\PanoramicData.QualityAssurance\ready-for-test-output.txt"
$jsonFile = "c:\Users\DavidBond\PanoramicData.QualityAssurance\ready-for-test-tickets.json"

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

$jql = "project=MS AND status='Ready for Test' ORDER BY updated DESC"
$fields = "summary,issuetype,labels,fixVersions,description"
$uri = "https://jira.panoramicdata.com/rest/api/2/search?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=50&fields=$fields"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
    
    $output = @()
    $output += "=== JIRA Ready for Test Tickets ==="
    $output += "Total found: $($response.total)"
    $output += ""
    
    foreach ($issue in $response.issues) {
        $output += "-------------------------------------------"
        $output += "KEY: $($issue.key)"
        $output += "SUMMARY: $($issue.fields.summary)"
        $output += "TYPE: $($issue.fields.issuetype.name)"
        $output += "LABELS: $($issue.fields.labels -join ', ')"
        $output += "VERSIONS: $(($issue.fields.fixVersions | ForEach-Object { $_.name }) -join ', ')"
        
        if ($issue.fields.description) {
            $desc = $issue.fields.description -replace "`r`n|`n", " "
            if ($desc.Length -gt 600) { 
                $desc = $desc.Substring(0, 600) + "..." 
            }
            $output += "DESCRIPTION: $desc"
        } else {
            $output += "DESCRIPTION: None"
        }
        $output += ""
    }
    
    # Save output to text file
    $output | Out-File $outputFile -Encoding UTF8
    
    # Save raw JSON data
    $response | ConvertTo-Json -Depth 10 | Out-File $jsonFile -Encoding UTF8
    
    Write-Output "SUCCESS: Data saved to $outputFile and $jsonFile"
    
} catch {
    "ERROR: $($_.Exception.Message)" | Out-File $outputFile -Encoding UTF8
    Write-Output "ERROR: $($_.Exception.Message)"
}
