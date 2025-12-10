# Helper script to create JIRA bug for MagicSuite CLI issue

$description = "Summary: The 'magicsuite api get reportbatchjobs' command throws a null reference exception and fails to retrieve any data.

Environment:
- MagicSuite CLI Version: 3.28.258+b2ef011bc7
- Installation Path: C:\Users\amycb\.dotnet\tools\magicsuite.exe
- Date Tested: December 2, 2025

Steps to Reproduce:
1. Run command: magicsuite api get reportbatchjobs
2. Observe the error

Actual Result:
Fetching ReportBatchJob...
Error: Exception has been thrown by the target of an invocation.
Object reference not set to an instance of an object.

Expected Result:
The command should return a list of ReportBatchJob entities in table format, or an empty result if no entities exist.

Additional Testing:
The issue persists across different configurations:
- With --verbose flag: Same error
- With --format Json: Same error
- With --format Table: Same error (default)

Impact:
Users cannot retrieve or manage ReportBatchJob entities via the CLI, blocking any automation or scripting that depends on this entity type.

Entity Type:
ReportBatchJob is listed as one of the 119 supported entity types in the CLI help documentation."

$params = @{
    ProjectKey = 'MS'
    IssueType = 'Task'
    Summary = 'MagicSuite CLI: Null Reference Exception when listing ReportBatchJobs'
    Description = $description
}

& "$PSScriptRoot\.github\tools\JIRA.ps1" -Action create -Parameters $params
