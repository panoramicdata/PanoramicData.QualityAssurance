# Setup Instructions for QA Tools

This document explains how to set up the MagicSuite CLI QA tools on your local machine.

---

## Prerequisites

1. **MagicSuite CLI Tool** installed globally
2. **PowerShell 5.1 or later**
3. **JIRA Account** with access to https://jira.panoramicdata.com
4. **MagicSuite Access** with API credentials

---

## Step 1: Install MagicSuite CLI

If not already installed:

```powershell
dotnet tool install -g MagicSuite.Cli
```

Verify installation:
```powershell
magicsuite --version
```

---

## Step 2: Configure PowerShell Execution Policy

Allow local scripts to run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

---

## Step 3: Set Up JIRA Credentials

### Option A: Windows Credential Manager (Recommended for Windows)

1. Open the JIRA tool and it will prompt you for credentials:
```powershell
.\.github\tools\JIRA.ps1 -Action status
```

2. When prompted, enter:
   - **Username**: Your JIRA username (e.g., `firstname.lastname`)
   - **Password**: Your JIRA password or API token

The credentials will be securely stored in Windows Credential Manager under the target `PanoramicData_JIRA`.

### Option B: Environment Variables

Set environment variables for your session:

```powershell
$env:JIRA_USERNAME = "your.username"
$env:JIRA_PASSWORD = "your-password-or-api-token"
```

To make them permanent (current user only):
```powershell
[System.Environment]::SetEnvironmentVariable('JIRA_USERNAME', 'your.username', 'User')
[System.Environment]::SetEnvironmentVariable('JIRA_PASSWORD', 'your-password', 'User')
```

### Option C: Configuration File (Not Recommended - Security Risk)

Create a `.env` file in your project directory (make sure it's in `.gitignore`):
```
JIRA_USERNAME=your.username
JIRA_PASSWORD=your-password
```

---

## Step 4: Configure MagicSuite CLI

### Set Up Your Profile

```powershell
magicsuite config profiles add --name myprofile --api-url https://your-api-url.com
```

### Set Authentication

```powershell
magicsuite auth token --name your-token-name --key your-token-key
```

### Select Default Tenant

```powershell
magicsuite tenant select YOUR_TENANT_CODE
```

---

## Step 5: Verify Setup

Run a quick smoke test:

```powershell
.\smoke-test.ps1
```

Or manually test:

```powershell
# Test CLI
magicsuite --version
magicsuite auth status

# Test JIRA integration
.\.github\tools\JIRA.ps1 -Action recent -Parameters @{ProjectKey='MS'; MaxResults=5}
```

---

## Step 6: Customize for Your Environment

### Update Configuration Files

Some scripts may have hardcoded paths. Update these references:

1. **In test scripts**: Look for paths like `C:\Users\amycb\...` and update to your path
2. **In JIRA scripts**: Verify the JIRA URL matches your instance
3. **In monitoring scripts**: Update log paths to your preferred location

### Common Configuration Points

- **JIRA URL**: `https://jira.panoramicdata.com` (in JIRA.ps1)
- **JIRA Project Key**: `MS` for MagicSuite (in bug creation scripts)
- **JIRA Toggl Field**: `customfield_11200` with value `MagicSuite_R&D`
- **Log Paths**: Update in monitoring and regression test scripts

---

## Security Best Practices

### ✅ DO:
- Use Windows Credential Manager for password storage
- Use environment variables for session-based credentials
- Keep `.env` files in `.gitignore`
- Use JIRA API tokens instead of passwords when possible
- Rotate credentials regularly

### ❌ DON'T:
- Commit credentials to version control
- Share credential files via email or chat
- Hardcode passwords in scripts
- Use the same password for multiple services

---

## Troubleshooting

### JIRA Authentication Fails

```powershell
# Clear stored credentials
cmdkey /delete:PanoramicData_JIRA

# Re-run JIRA tool to re-enter credentials
.\.github\tools\JIRA.ps1 -Action status
```

### MagicSuite CLI "Unauthorized" Errors

```powershell
# Check auth status
magicsuite auth status

# Re-authenticate
magicsuite auth token --name your-token-name --key your-token-key
```

### Script Execution Blocked

```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### "Cannot find path" Errors in Scripts

Update hardcoded paths in the scripts to match your directory structure.

---

## Getting JIRA API Tokens

1. Log in to JIRA: https://jira.panoramicdata.com
2. Click your profile icon → **Account Settings**
3. Navigate to **Security** → **API Tokens**
4. Click **Create API Token**
5. Give it a name (e.g., "QA Tools")
6. Copy the token (you won't see it again!)
7. Use this token as your password in the JIRA tool

---

## File Overview

### Core Tools
- `.github/tools/JIRA.ps1` - JIRA integration tool
- `.github/copilot-instructions.md` - Reference documentation

### Bug Reporting
- `create-jira-bug.ps1` - Template for creating bug tickets

### Testing Scripts
- `smoke-test.ps1` - Quick validation tests
- `regression-test.ps1` - Comprehensive entity testing
- `performance-test.ps1` - Execution time benchmarks
- `validate-output.ps1` - JSON output validation
- `error-handling-test.ps1` - Edge case testing
- `test-and-report.ps1` - Auto-reporting test failures
- `compare-versions.ps1` - Before/after comparisons
- `test-coverage.ps1` - Coverage tracking

### Documentation
- `Testing-Ideas.md` - Comprehensive testing strategies
- `SETUP-INSTRUCTIONS.md` - This file

---

## Next Steps

1. Complete the setup steps above
2. Review `Testing-Ideas.md` for testing approaches
3. Run `smoke-test.ps1` to verify everything works
4. Customize scripts for your workflow
5. Start testing!

---

## Support

If you encounter issues:
1. Check this documentation first
2. Review error messages carefully
3. Verify credentials are set correctly
4. Check that paths are updated for your machine
5. Ask the team for help!

---

## Contributing

When creating new test scripts or tools:
- Don't hardcode credentials
- Use environment variables or credential manager
- Document any new setup requirements
- Update this file with new configuration needs
- Share improvements with the team
