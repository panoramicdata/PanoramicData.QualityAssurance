# 📋 Sharing Checklist

Use this checklist before sharing your QA Tools with coworkers.

---

## Pre-Share Checklist

### ✅ Security Verification
- [x] No passwords in .ps1 files
- [x] No passwords in .md files  
- [x] Environment variables are working
- [x] .gitignore is in place
- [x] Scripts read from $env:JIRA_USERNAME and $env:JIRA_PASSWORD

### ✅ Documentation Verification
- [x] README.md exists and is complete
- [x] SETUP-INSTRUCTIONS.md exists
- [x] HOW-TO-SHARE.md exists
- [x] Testing-Ideas.md exists
- [x] .github/copilot-instructions.md exists

### ✅ Files to Include
- [x] All .ps1 scripts
- [x] All .md documentation files
- [x] .github folder (with tools/JIRA.ps1)
- [x] .gitignore file

### ✅ Files to EXCLUDE
- [ ] .env files (if any exist)
- [ ] Logs/ folder
- [ ] baseline/ and current/ folders (test outputs)
- [ ] Any .cred or credential export files
- [ ] Personal notes or sensitive data

---

## Sharing Methods

### Method 1: ZIP File (Easiest)
```powershell
# Create a ZIP file
Compress-Archive -Path C:\Users\amycb\PData\CommandLine\* -DestinationPath C:\Users\amycb\Desktop\QA-Tools.zip

# Share via:
# - Email
# - Teams
# - SharePoint
```

### Method 2: Network Share
```powershell
# Copy to shared location
Copy-Item -Path C:\Users\amycb\PData\CommandLine -Destination \\server\share\QA-Tools -Recurse

# Tell coworkers the path
```

### Method 3: GitHub (Most Professional)
```powershell
# Initialize git (if not already done)
cd C:\Users\amycb\PData\CommandLine
git init
git add .
git commit -m "Initial commit of QA Tools"

# Create repo on GitHub (private recommended)
# Then push:
git remote add origin https://github.com/YOUR-ORG/QA-Tools.git
git push -u origin main
```

---

## What to Tell Your Coworkers

Send them this message:

```
Hi team! 👋

I've created a QA testing toolkit for the MagicSuite CLI. 

📦 Location: [share location here]

📖 Getting Started:
1. Download/copy the QA-Tools folder
2. Open PowerShell in that folder
3. Read SETUP-INSTRUCTIONS.md and follow the steps
4. Set YOUR JIRA credentials (not mine!) using the instructions
5. Run: .\smoke-test.ps1 to verify setup

📚 Documentation:
- README.md - Overview of what's included
- SETUP-INSTRUCTIONS.md - How to set up on your machine
- Testing-Ideas.md - 10 different testing strategies
- HOW-TO-SHARE.md - If you want to share with others

⚙️ You'll need:
- MagicSuite CLI installed (dotnet tool install -g MagicSuite.Cli)
- Your own JIRA credentials
- Your own MagicSuite API token
- PowerShell 5.1+

🔒 Security:
Everyone uses their own credentials - no shared passwords!

Questions? Let me know!
```

---

## Post-Share Follow-Up

After sharing, be ready to help with:
- [ ] Installation issues (MagicSuite CLI)
- [ ] Credential setup questions
- [ ] PowerShell execution policy issues
- [ ] Script path problems
- [ ] Feature requests or improvements

---

## Testing Before You Share (Optional)

If you want to be extra sure, test on a "clean" setup:

1. Ask a coworker to try it first
2. Watch them go through SETUP-INSTRUCTIONS.md
3. See what questions they have
4. Update documentation based on feedback
5. Then share with everyone

---

## Common Questions (FAQ)

**Q: Will my credentials be shared?**
A: No! Your credentials are stored in Windows environment variables on YOUR machine only.

**Q: How do coworkers get their own credentials?**
A: They follow SETUP-INSTRUCTIONS.md and set their own JIRA_USERNAME and JIRA_PASSWORD.

**Q: Can multiple people use the same scripts?**
A: Yes! Each person's scripts use THEIR credentials automatically.

**Q: What if someone doesn't have PowerShell?**
A: These tools require PowerShell 5.1+ which comes with Windows 10/11.

**Q: Can Mac/Linux users use these?**
A: The scripts would need modifications for PowerShell Core and different credential storage.

---

## You're Ready! ✅

Everything is set up and secure. Just:
1. Choose a sharing method
2. Share the files
3. Send the "What to Tell Your Coworkers" message
4. Be available for questions

**The tools will work for everyone with their own credentials!**
