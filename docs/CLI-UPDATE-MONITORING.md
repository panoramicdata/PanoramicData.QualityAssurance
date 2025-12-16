# MagicSuite CLI Update Monitoring

This directory contains automated scripts for monitoring and testing MagicSuite CLI updates.

## Available Scripts

### 1. `check-cli-updates.ps1` - Manual Update Checker
Manually check for and install CLI updates.

**Usage:**
```powershell
.\check-cli-updates.ps1
```

**Features:**
- Checks current CLI version
- Installs available updates automatically
- Logs update history to `logs/cli-updates/update-history.json`
- Returns structured update information

### 2. `automated-update-check.ps1` - Update Check with Bug Testing
Automatically checks for updates and runs regression tests on known bugs.

**Usage:**
```powershell
.\automated-update-check.ps1
```

**Features:**
- Runs `check-cli-updates.ps1` to check for updates
- If new version detected, automatically tests:
  - MS-22523: Profile active indicator
  - MS-22570: File search markup exception
  - MS-22575: File list root directory markup
  - MS-22563: File type display shows ??
- Saves test results to `logs/cli-updates/bug-test-results.json`
- Generates summary report showing fixed vs outstanding issues

### 3. `schedule-cli-updates.ps1` - Task Scheduler Setup
Creates a Windows scheduled task to run automated checks regularly.

**Usage:**
```powershell
# Schedule checks every 4 hours (default)
.\schedule-cli-updates.ps1

# Schedule hourly checks
.\schedule-cli-updates.ps1 -Frequency Hourly

# Schedule once daily at 9 AM
.\schedule-cli-updates.ps1 -Frequency Daily

# Schedule twice daily (9 AM and 3 PM)
.\schedule-cli-updates.ps1 -Frequency "Twice Daily"

# Remove scheduled task
.\schedule-cli-updates.ps1 -Remove
```

**Features:**
- Creates Windows Task Scheduler job
- Runs as current user with elevated privileges
- Starts when network is available
- Runs even on battery power
- Automatically catches up if system was offline

## Recommended Workflow

### Option 1: Automated Monitoring (Recommended)
Set up scheduled checks to run automatically:
```powershell
# Check every 4 hours
.\schedule-cli-updates.ps1 -Frequency Every4Hours
```

This will:
- Check for CLI updates every 4 hours
- Automatically install updates when available
- Run regression tests after each update
- Log all results for review

### Option 2: Manual Checks
Run checks manually when needed:
```powershell
# Quick update check
.\check-cli-updates.ps1

# Update check with bug testing
.\automated-update-check.ps1
```

## Log Files

All logs are stored in `logs/cli-updates/`:

### `update-history.json`
Records all CLI updates with timestamps and version information:
```json
[
  {
    "Timestamp": "2025-12-11 14:30:00",
    "OldVersion": "4.1.249",
    "NewVersion": "4.1.254",
    "VerifiedVersion": "4.1.254+9bb1b85f0d",
    "UpdateType": "Automatic"
  }
]
```

### `bug-test-results.json`
Records bug test results after each update:
```json
[
  {
    "Timestamp": "2025-12-11 14:30:05",
    "OldVersion": "4.1.249",
    "NewVersion": "4.1.254",
    "Tests": [
      {
        "IssueKey": "MS-22523",
        "Name": "Profile active indicator",
        "Status": "FIXED",
        "Output": "..."
      }
    ]
  }
]
```

## Managing Scheduled Tasks

### View scheduled task
```powershell
Get-ScheduledTask -TaskName "MagicSuite_CLI_Update_Check"
```

### Run task immediately
```powershell
Start-ScheduledTask -TaskName "MagicSuite_CLI_Update_Check"
```

### View task history
```powershell
Get-ScheduledTaskInfo -TaskName "MagicSuite_CLI_Update_Check"
```

### Open Task Scheduler GUI
```powershell
taskschd.msc
```

## Notifications

Consider setting up notifications for new updates:
1. Review the log files in `logs/cli-updates/` regularly
2. Set up file monitoring on the log files
3. Use the scheduled task's email notification feature (requires SMTP configuration)

## Troubleshooting

### Script doesn't run from Task Scheduler
- Ensure execution policy allows scripts: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Check task history in Task Scheduler for errors
- Verify the working directory is set correctly in the task

### Updates not installing
- Verify internet connectivity
- Check that .NET SDK is installed and updated
- Run `dotnet tool list --global` to verify CLI is installed

### Test results show errors
- Ensure CLI profile is configured and authenticated
- Check network connectivity to MagicSuite API
- Review the detailed output in `bug-test-results.json`

## Integration with JIRA

After reviewing test results, you can update JIRA tickets:
- If bugs are fixed, run corresponding update scripts in `jira-update-scripts/`
- Example: `.\jira-update-scripts\update-ms-22523.ps1`

## Best Practices

1. **Start with scheduled checks**: Use `-Frequency Every4Hours` for regular monitoring
2. **Review logs weekly**: Check `update-history.json` and `bug-test-results.json`
3. **Update JIRA tickets**: Document fix verifications when bugs are resolved
4. **Keep scripts updated**: Add new bug tests to `automated-update-check.ps1` as issues are discovered
5. **Monitor for regressions**: The automated testing helps catch when fixes break

## Files Overview

```
check-cli-updates.ps1           # Core update checker
automated-update-check.ps1      # Update checker + bug tests
schedule-cli-updates.ps1        # Task scheduler setup
logs/
  cli-updates/
    update-history.json         # Update log
    bug-test-results.json       # Test results log
```
