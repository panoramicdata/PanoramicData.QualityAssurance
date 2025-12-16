# How to Share This QA Tool Package

## Overview
This guide explains how to package and share these QA tools with your coworkers while keeping credentials secure.

---

## Method 1: Simple File Share (Recommended)

### Step 1: Clean Up Credential Files
Before sharing, make sure no credentials are in the files:

```powershell
# Check for credentials in scripts
Get-ChildItem *.ps1 | Select-String -Pattern "password|amy\.bond|O9Np"
```

### Step 2: Package the Files
Share these files/folders with your team:

**Essential Files:**
- `.github/` folder (contains JIRA.ps1 and documentation)
- `Testing-Ideas.md`
- `SETUP-INSTRUCTIONS.md`
- `README.md`
- `.gitignore`
- `TEMPLATE-create-bug.ps1` (credential-free template)

**Optional Test Scripts:**
- Any test scripts you've created (make sure they don't contain credentials)

### Step 3: Share via Network/Email
- Copy to a shared network drive
- Create a ZIP file and email it
- Use Teams/SharePoint to share

### Step 4: Recipients Follow Setup Instructions
Each person follows `SETUP-INSTRUCTIONS.md` to configure their own credentials.

---

## Method 2: Git Repository (Most Professional)

### Step 1: Initialize Git Repository (if not already done)
```powershell
git init
git add .
git commit -m "Initial commit of QA tools"
```

### Step 2: Create GitHub Repository
```powershell
# Option A: Via GitHub website
# 1. Go to github.com
# 2. Click "New Repository"
# 3. Name it "MagicSuite-QA-Tools" (or similar)
# 4. Make it PRIVATE if it contains any sensitive info
# 5. Don't initialize with README (we have one)

# Option B: Via GitHub CLI (if installed)
gh repo create MagicSuite-QA-Tools --private --source=. --remote=origin --push
```

### Step 3: Push to GitHub
```powershell
git remote add origin https://github.com/YOUR-ORG/MagicSuite-QA-Tools.git
git branch -M main
git push -u origin main
```

### Step 4: Invite Collaborators
1. Go to repository Settings → Collaborators
2. Add your coworkers by username/email
3. They can clone: `git clone https://github.com/YOUR-ORG/MagicSuite-QA-Tools.git`

### Step 5: Keep It Updated
```powershell
# When you make changes
git add .
git commit -m "Description of changes"
git push

# Coworkers pull updates
git pull
```

---

## Method 3: Shared Network Drive

### Setup
1. Copy the entire folder to a shared network location (e.g., `\\server\share\QA-Tools`)
2. Each person can use it directly or copy to their local machine
3. Update paths in scripts to use the shared location

### Pros
- Easy access for everyone
- Automatic updates when you change files
- No Git knowledge required

### Cons
- Changes by one person affect everyone
- No version history
- Potential file locking issues

---

## Security Checklist Before Sharing

Run this checklist before sharing:

```powershell
# 1. Search for your username
Get-ChildItem -Recurse *.ps1, *.md | Select-String -Pattern "amy.bond" -List

# 2. Search for passwords
Get-ChildItem -Recurse *.ps1, *.md | Select-String -Pattern "O9NpW6" -List

# 3. Search for absolute paths with your username
Get-ChildItem -Recurse *.ps1, *.md | Select-String -Pattern "C:\\Users\\amycb" -List

# 4. Check for .env files
Get-ChildItem -Recurse -Force .env

# 5. Verify .gitignore exists
Test-Path .gitignore
```

If any of these return results, clean them up before sharing!

---

## What Each Person Needs to Do

After receiving the files, each coworker must:

1. **Install MagicSuite CLI**
   ```powershell
   dotnet tool install -g MagicSuite.Cli
   ```

2. **Set PowerShell Execution Policy**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Configure JIRA Credentials**
   - Option A: Run `.\.github\tools\JIRA.ps1 -Action status` and enter their credentials
   - Option B: Set environment variables with their credentials

4. **Configure MagicSuite CLI**
   ```powershell
   magicsuite auth token --name their-token-name --key their-token-key
   ```

5. **Test Setup**
   ```powershell
   .\smoke-test.ps1
   ```

---

## Updating the Template for Multi-User Support

Consider creating a `config.template.json` for users to customize:

```json
{
  "jiraUrl": "https://jira.panoramicdata.com",
  "jiraProject": "MS",
  "togglProjectField": "customfield_11200",
  "togglProjectValue": "MagicSuite_R&D",
  "logPath": "C:\\Path\\To\\Logs",
  "outputFormat": "Table"
}
```

Each user copies to `config.json` (which is in `.gitignore`) and customizes.

---

## Best Practices

### ✅ DO:
- Use template scripts without hardcoded credentials
- Document setup requirements clearly
- Use `.gitignore` to prevent credential commits
- Test on a clean machine before sharing
- Provide clear setup instructions
- Use Windows Credential Manager for each user

### ❌ DON'T:
- Include your credentials in shared files
- Hardcode paths with your username
- Share `.env` files
- Share Credential Manager exports
- Assume everyone has the same environment
- Share without testing first

---

## Troubleshooting for Recipients

### "Cannot find JIRA.ps1"
- Make sure the `.github/tools/` folder structure is preserved
- Check that paths in scripts use relative paths

### "Authentication Failed"
- Each user must configure their own JIRA credentials
- Verify credentials work by logging into JIRA web interface

### "magicsuite: command not found"
- Install MagicSuite CLI: `dotnet tool install -g MagicSuite.Cli`
- Restart PowerShell after installation

### "Script execution blocked"
- Set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## Summary

**Recommended Approach:**
1. Remove all credentials from scripts (use the TEMPLATE versions)
2. Ensure `.gitignore` is in place
3. Share via GitHub (private repo) or network share
4. Each person follows SETUP-INSTRUCTIONS.md
5. Each person configures their own credentials

This way, everyone gets the tools but maintains their own secure credentials!
