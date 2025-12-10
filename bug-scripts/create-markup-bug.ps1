# Create JIRA bug for ReportSchedules markup parsing error

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
The 'magicsuite api get reportschedules' command throws an InvalidOperationException due to malformed markup at position 82 in the console output rendering.

*Environment*
- MagicSuite CLI Version: 3.28.258+b2ef011bc7
- Installation Path: C:\Users\amycb\.dotnet\tools\magicsuite.exe
- Date Tested: December 2, 2025

*Steps to Reproduce*
1. Run command: {{magicsuite api get reportschedules}}
2. Observe the unhandled exception

*Actual Result*
{code}
Fetching ReportSchedule...
Unhandled exception: System.InvalidOperationException: Encountered malformed markup tag at position 82.
   at Spectre.Console.MarkupTokenizer.ReadMarkup()
   at Spectre.Console.MarkupTokenizer.MoveNext()
   at Spectre.Console.MarkupParser.Parse(String text, Style style)
   at Spectre.Console.AnsiConsoleExtensions.Markup(IAnsiConsole console, String value)
   at Spectre.Console.AnsiConsoleExtensions.MarkupLine(IAnsiConsole console, String value)
   at Spectre.Console.AnsiConsole.MarkupLine(String value)
   at MagicSuite.Cli.Commands.ApiCommands.<>c__DisplayClass5_0.<<CreateGetCommand>b__1>d.MoveNext() in C:\Users\david\Projects\Magic Suite\MagicSuite.Cli\Commands\ApiCommands.cs:line 221
{code}

*Expected Result*
The command should return a list of ReportSchedule entities in table format, or an empty result if no entities exist. Any special characters in the data should be properly escaped before rendering to the console.

*Additional Testing*
This markup parsing error also occurs with:
- {{magicsuite api get connections}} - Same error at position 82
Other entities show different errors (NullReferenceException)

*Root Cause Analysis*
The error occurs in {{ApiCommands.cs:line 221}} when attempting to render output using Spectre.Console.MarkupLine(). The data being rendered contains characters at position 82 that are interpreted as Spectre.Console markup tags (likely square brackets {{[}}, curly braces {{\{}} or other special characters) but are malformed or unescaped.

*Impact*
Users cannot retrieve or view ReportSchedule or Connection entities via the CLI. This blocks automation and management of these critical entity types. The unhandled exception crashes the CLI command completely.

*Suggested Fix*
Escape special Spectre.Console markup characters in entity data before rendering, or use plain text rendering instead of markup rendering for dynamic data output.
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Bug" }
        summary = "MagicSuite CLI: Malformed Markup Exception when listing ReportSchedules and Connections"
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating JIRA bug ticket..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" -Method POST -Headers $headers -Body $body
    Write-Host "Success! Created issue: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
    $response
}
catch {
    Write-Host "Error Response:" -ForegroundColor Red
    Write-Host $_.Exception.Response.StatusCode
    Write-Host $_.Exception.Response.StatusDescription
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Host $responseBody
}
