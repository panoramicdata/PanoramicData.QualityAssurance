# Copilot Session Learnings

Quick reference for lessons learned during QA automation sessions.

## Terminal Issues

### Problem: Buffer Corruption
Long console output or multi-line commands corrupt VS Code terminal display.

**Symptoms:**
- Repeated/garbled text
- InvokePrompt errors
- Commands not executing properly

**Solutions:**
1. ✅ **Save output to file** instead of console
2. ✅ **Use short, simple commands**
3. ✅ **Run scripts via file** not pasted commands
4. ✅ **Exit and reopen terminal** if corrupted

### Problem: Multi-line Command Pasting
Pasting multi-line PowerShell code often fails.

**Solution:** Create a script file, then execute it:
```powershell
# DON'T paste multi-line code
# DO create a .ps1 file and run it
.\scripts\jira\Search-Jira.ps1
```

---

## JIRA Integration

### JIRA.ps1 vs REST API

| Use JIRA.ps1 for | Use REST API for |
|------------------|------------------|
| Simple ticket lookup | Complex JQL queries |
| Adding comments | Custom field selection |
| Transitioning tickets | Bulk operations |
| Quick ticket info | Analysis scripts |

### JQL Gotchas

```powershell
# ❌ FAILS if component doesn't exist
component in (CLI, 'Command Line Interface')

# ✅ WORKS - use labels instead
labels in (CLI)

# ✅ WORKS - use text search
summary ~ 'CLI' OR description ~ 'CLI'
```

### Quick Commands

```powershell
# Ticket details (use tool)
.\.github\tools\JIRA.ps1 -Action Get -IssueKey MS-12345
.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-12345

# Search (use custom script - outputs to file)
.\scripts\jira\Get-ReadyForTestTickets.ps1
.\scripts\jira\Search-Jira.ps1 -JQL "project=MS AND status='In Test'"
```

---

## Script Organization

### Directory Structure
```
scripts/
├── jira/
│   ├── Get-ReadyForTestTickets.ps1  # Categorizes by CLI/Playwright
│   ├── Search-Jira.ps1               # Generic search to file
│   └── README.md
├── automation/
├── setup/
└── utilities/
```

### Script Best Practices
1. **Always output to file** - avoid console output for data
2. **Minimal console output** - just status messages
3. **Include help comments** - `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
4. **Document lessons learned** - in script header comments
5. **Handle errors gracefully** - check credentials, catch API errors

---

## Common Workflows

### Find Testable Tickets
```powershell
# Run analysis script
.\scripts\jira\Get-ReadyForTestTickets.ps1

# View results
code ready-for-test-analysis.md
```

### Get Full Ticket Details
```powershell
.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-22608
```

### Test Environment Confirmation
Always confirm before testing:
```
⚠️ TEST ENVIRONMENT CONFIRMATION REQUIRED
Environment: test2.magicsuite.net
Application: [APP]
Is this correct?
```

---

## Environment Variables

Required for JIRA:
```powershell
$env:JIRA_USERNAME  # Your JIRA username
$env:JIRA_PASSWORD  # Your JIRA API token/password
```

Check if set:
```powershell
if ($env:JIRA_USERNAME) { "Set" } else { "NOT SET" }
```

---

*Last Updated: 2026-01-25*
