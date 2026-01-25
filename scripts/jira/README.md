# JIRA Scripts

Reusable scripts for JIRA queries and analysis.

## Scripts

### Get-ReadyForTestTickets.ps1
Analyzes Ready for Test tickets and categorizes them by testing method (CLI vs Playwright).

```powershell
# Basic usage - outputs to ready-for-test-analysis.md
.\scripts\jira\Get-ReadyForTestTickets.ps1

# Custom output
.\scripts\jira\Get-ReadyForTestTickets.ps1 -MaxResults 100 -OutputPath "my-analysis.md"
```

### Search-Jira.ps1
Quick JIRA search with file output (avoids terminal buffer issues).

```powershell
# Default: Ready for Test tickets as JSON
.\scripts\jira\Search-Jira.ps1

# Custom JQL
.\scripts\jira\Search-Jira.ps1 -JQL "project=MS AND labels=CLI"

# Table format
.\scripts\jira\Search-Jira.ps1 -Format table -OutputPath "results.txt"
```

## Lessons Learned

### Terminal Buffer Issues
- **Problem**: Long console output corrupts VS Code terminal buffer
- **Solution**: Always output to file, not console
- **Avoid**: Multi-line commands pasted into terminal

### JQL Limitations
- **Problem**: `component in (CLI)` fails if component doesn't exist (400 Bad Request)
- **Solution**: Use `labels in (CLI)` or `summary ~ 'CLI'` instead
- **Avoid**: Referencing components without verifying they exist first

### JIRA.ps1 vs REST API
- **JIRA.ps1**: Great for simple operations (Get, Comment, Transition)
- **REST API**: Better for complex queries with custom field selection
- **Use REST API when**: You need specific fields or complex JQL

### Quick Reference

```powershell
# Simple ticket lookup (use JIRA.ps1)
.\.github\tools\JIRA.ps1 -Action Get -IssueKey MS-12345
.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-12345

# Add comment
.\.github\tools\JIRA.ps1 -Action Comment -IssueKey MS-12345 -Parameters @{Comment="Testing complete"}

# Complex search (use scripts)
.\scripts\jira\Search-Jira.ps1 -JQL "project=MS AND status='Ready for Test' AND updated >= -7d"
.\scripts\jira\Get-ReadyForTestTickets.ps1
```

## Prerequisites

Environment variables must be set:
```powershell
$env:JIRA_USERNAME = "your.username"
$env:JIRA_PASSWORD = "your-api-token"
```
