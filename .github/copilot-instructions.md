# GitHub Copilot Instructions - PanoramicData QA

## 📚 Modular Documentation Structure

This workspace uses a modular instruction system for easier navigation as documentation grows.

### 📖 Instruction Modules

| Module | File | Purpose |
|--------|------|---------|
| 🎯 **JIRA** | [instructions/jira.md](instructions/jira.md) | JIRA.ps1 tool usage, bug creation, workflow tracking |
| 📝 **XWiki** | [instructions/xwiki.md](instructions/xwiki.md) | XWiki.ps1 tool, documentation testing, content editing |
| 🎭 **Playwright** | [instructions/playwright.md](instructions/playwright.md) | UI testing with Playwright, Firefox setup, test execution |
| 💻 **CLI Reference** | [instructions/cli-reference.md](instructions/cli-reference.md) | MagicSuite CLI commands, options, version management |
| 🧪 **Testing** | [instructions/testing.md](instructions/testing.md) | Testing workflow, environment confirmation, test organization |

---

## ⚠️ CRITICAL RULES (Read Every Time!)

### 1. Test Environment Confirmation (MANDATORY!)
**BEFORE running ANY test, ALWAYS confirm the test environment:**

Template:
```
⚠️ TEST ENVIRONMENT CONFIRMATION REQUIRED

I'm about to run tests against: [ENVIRONMENT].magicsuite.net
Application: [APP_NAME]
Test Type: [TEST_TYPE]
Expected Duration: ~[TIME]

Is this the correct test environment? Please confirm before I proceed.
```

**Never proceed without explicit confirmation!**

Environments: alpha, alpha2, test, **test2 (default)**, beta, staging, production

### 2. MagicSuite CLI Version: 4.1.x ONLY
- ❌ **NEVER use 4.2.x** for official testing
- ✅ **Always use 4.1.x** (use `4.1.*` to mean "install the latest 4.1.x available")
- ✅ Check before tests: `magicsuite --version`
- ✅ Document exact version in all JIRA updates

### 3. Playwright: Firefox Default with --project Flag
- ✅ **Always use**: `npx playwright test [test-name] --project=firefox`
- ❌ **Never omit** `--project` flag (opens ALL browsers!)
- ✅ **Authenticate first**: `npx playwright test auth.setup --project=firefox`
- ✅ Use test name patterns, not file paths

### 4. Tool Scripts: Never Bypass
- **JIRA**: Always use `.github/tools/JIRA.ps1`
- **XWiki**: Always use `.github/tools/XWiki.ps1`
- **Elastic**: Always use `.github/tools/Elastic.ps1`
- Exception: Complex JIRA bug creation may require REST API

### 5. JIRA Updates: Track Progress
- Update ticket throughout work (not just at end)
- Include: environment, version, date, findings
- Transition tickets: Ready for Progress → In Progress → Ready for Test → In Test

### 6. Test Organization: By Application
**All tests are organized by application area:**
- **CLI tests**: `test-scripts/CLI/` (Core, API, Output, ExitCodes, FileSystem)
- **Playwright tests**: `playwright/Magic Suite/` (DataMagic, AlertMagic, Admin, etc.)
- **App-specific**: `test-scripts/{App}/` (DataMagic, ReportMagic, etc.)
- **Always place new tests in the correct folder** based on what they test

---

## 🔗 Quick Reference Guide

### Most Common Tasks

| Task | Module | Quick Command |
|------|--------|---------------|
| Get JIRA ticket | [JIRA](instructions/jira.md#get-ticket-information) | `.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-12345` |
| Create JIRA bug | [JIRA](instructions/jira.md#creating-bug-tickets) | Use REST API with required fields |
| Update JIRA | [JIRA](instructions/jira.md#add-comments) | `.\.github\tools\JIRA.ps1 -Action Comment -IssueKey MS-12345` |
| Check CLI version | [CLI](instructions/cli-reference.md#check-current-version) | `magicsuite --version` |
| Run Playwright auth | [Playwright](instructions/playwright.md#authentication) | `npx playwright test auth.setup --project=firefox` |
| Run Playwright test | [Playwright](instructions/playwright.md#running-tests) | `npx playwright test [name] --project=firefox` |
| Get XWiki page | [XWiki](instructions/xwiki.md#get-page-content) | `.\.github\tools\XWiki.ps1 -Action Get -Space "MagicSuite"` |

### Key Information

| Info | Value |
|------|-------|
| **Default Test Environment** | test2.magicsuite.net |
| **CLI Version for Testing** | 4.1.x ONLY (use `4.1.*` to mean latest 4.1.x) |
| **Default Browser** | Firefox with `--project=firefox` |
| **JIRA Project** | MS (Magic Suite) |
| **Primary QA Tester** | Amy Bond (amy.bond) |

---

## 👥 Team Quick Reference

### QA Team
- **Amy Bond** (`amy.bond`) - Testing & automation (primary user)
- **Claire Campbell** (`claire.campbell`) - Testing assignments
- **Sam Walters** (`sam.walters`) - In Test / Ready for Test

### Developers
- **Roland Banks** (`roland.banks`) - API/backend, critical issues
- **John Odlin** (`john.odlin`) - UI/Frontend, DataMagic
- **David Bond** (`david.bond`) - General development
- **Daniel Abbott** - General development

### Applications in Magic Suite
- **DataMagic** - Database & visualization
- **ReportMagic** - Report scheduling & generation
- **AlertMagic** - Alerting system
- **Admin** - Administration panel
- **Connect** - Integration platform
- **Docs** - Documentation (XWiki)
- **Files UI** - SharePoint integration
- **Estate Tree** - Navigation & hierarchy

---

## 📝 Workflow Summary

### Starting Work on a Ticket
1. Get ticket details: `.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-12345`
2. Transition to "In Progress"
3. **Confirm test environment** with user
4. Verify tool versions (CLI, browsers)
5. Add JIRA comment: "Starting work on MS-12345..."

### During Testing
1. Run tests systematically
2. Capture evidence (screenshots, logs, outputs)
3. Document issues immediately
4. Update JIRA at milestones

### Completing Work
1. Save all artifacts to appropriate folders
2. Create bug tickets for issues found
3. Post final JIRA comment with full results
4. Transition ticket to appropriate state

---

## 📂 Repository Structure

```
PanoramicData.QualityAssurance/
├── .github/
│   ├── instructions/          # Modular instruction files
│   │   ├── jira.md           # JIRA integration guide
│   │   ├── xwiki.md          # XWiki integration guide
│   │   ├── playwright.md     # Playwright testing guide
│   │   ├── cli-reference.md  # CLI command reference
│   │   └── testing.md        # Testing workflow & requirements
│   └── tools/
│       ├── JIRA.ps1          # JIRA automation tool
│       ├── XWiki.ps1         # XWiki automation tool
│       └── Elastic.ps1       # Log collection tool
├── test-scripts/             # PowerShell/CLI test scripts
│   ├── CLI/                  # CLI-specific tests
│   │   ├── Core/            # Basic functionality
│   │   ├── API/             # API endpoint tests
│   │   ├── Output/          # Output formatting tests
│   │   └── ExitCodes/       # Exit code validation
│   ├── DataMagic/           # DataMagic tests
│   ├── ReportMagic/         # ReportMagic tests
│   └── Utilities/           # General utility tests
├── playwright/              # Playwright UI tests
│   └── Magic Suite/
│       ├── Admin/           # Admin UI tests
│       ├── DataMagic/       # DataMagic UI tests
│       ├── ReportMagic/     # ReportMagic UI tests
│       ├── AlertMagic/      # AlertMagic UI tests
│       ├── Docs/            # Documentation tests
│       └── ...              # Other applications
├── test-plans/              # Test planning documents
├── test-results/            # Test result reports
├── logs/                    # Collected logs
└── docs/                    # Additional documentation
```

---

## 🚨 Common Pitfalls to Avoid

See detailed module documentation for complete pitfall lists:
- [JIRA Common Pitfalls](instructions/jira.md#common-pitfalls)
- [XWiki Common Pitfalls](instructions/xwiki.md#common-pitfalls)
- [Playwright Common Pitfalls](instructions/playwright.md#common-pitfalls)
- [CLI Common Pitfalls](instructions/cli-reference.md#common-pitfalls)
- [Testing Common Pitfalls](instructions/testing.md#common-pitfalls)

### Quick Reminder of Top Issues
1. ⚠️ Not confirming test environment before running tests
2. ⚠️ Using CLI 4.2.x instead of 4.1.x
3. ⚠️ Missing `--project=firefox` flag in Playwright commands
4. ⚠️ Using ampersands in double quotes for JIRA bug creation
5. ⚠️ Not updating JIRA tickets throughout work

---

## 📚 Additional Resources

- **JIRA**: https://jira.panoramicdata.com
- **XWiki Docs**: https://docs.panoramicdata.com
- **Test2 Environment**: https://test2.magicsuite.net
- **Playwright Documentation**: https://playwright.dev/

---

## 🎓 For More Details

**This is a quick reference only.** For comprehensive information:

1. **JIRA integration** → Read [instructions/jira.md](instructions/jira.md)
2. **XWiki & documentation** → Read [instructions/xwiki.md](instructions/xwiki.md)
3. **Playwright UI testing** → Read [instructions/playwright.md](instructions/playwright.md)
4. **CLI commands & usage** → Read [instructions/cli-reference.md](instructions/cli-reference.md)
5. **Testing workflow** → Read [instructions/testing.md](instructions/testing.md)

Each module contains:
- Detailed command references
- Code examples
- Best practices
- Common pitfalls
- Troubleshooting guides

---

**Last Updated**: 2026-01-13  
**Version**: 2.0 (Modular Structure)
**Post progress comments at key milestones:**
- Test plan created
- Logs collected
- Analysis complete
- Blockers encountered

**Example**:
```
Progress Update: Created test plan with 6 test cases. 
Collected 1.25MB of logs from Elastic for analysis.
Environment: test2.magicsuite.net
Version: v4.1.546
```

### Completing Work
1. **Final comment**: Summarize findings, link artifacts
2. **Transition**: In Progress → Ready for Test (or In Test if executing)
3. **Include**: Environment, version, test date, results

### Test Results Format
**Always include**:
- Environment: test2.magicsuite.net
- Application: DataMagic
- Version: v4.1.546
- Test Date: 2026-01-13 14:30:00
- Browser (if UI test): Firefox 144.0.2
- Results summary

---

## 🔧 MagicSuite CLI Reference

### Global Options
```
--profile <name>          Use named profile
--api-url <url>          Override API URL
--tenant <id>            Tenant context
--format <Json|Table>    Output format
--output <file>          Write to file
--verbose                Detailed logging
--version                Show version
```

### Main Commands
```powershell
# Configuration
magicsuite config profiles list
magicsuite config profiles add --name test2 --api-url https://api.test2.magicsuite.net

# Authentication
magicsuite auth token --name <token> --key <key>
magicsuite auth status

# API Operations
magicsuite api get tenants
magicsuite api get connections --filter Logic
magicsuite api get-by-id tenant 1
magicsuite api patch tenant 1 --set Name="New Name"

# File Operations
magicsuite file list /Library
magicsuite file upload local.pdf /Reports/monthly.pdf
magicsuite file download /Reports/monthly.pdf ./local.pdf
magicsuite file search 'budget'
```

### Entity Types (Common)
Tenant, Connection, Dashboard, ReportSchedule, ReportJob, Person, Role, Setting, Widget, Case, Project, EventManager, Sync, DataMagicSync

---

## 💡 Best Practices

### Asking Clarifying Questions
**Before starting work, ask:**
- Which environment? (default: test2)
- Expected timeline?
- Specific regression areas?
- Automated or manual tests?
- Priority level?
- Known blockers?
- Browsers/devices required?

### Progress Communication
**Update JIRA proactively:**
- Start of work
- Key milestones
- Significant findings
- Status transitions
- Work completion

### Security
- Use environment variables: `$env:JIRA_USERNAME`, `$env:JIRA_PASSWORD`
- Never commit credentials
- Never use `Get-StoredCredential` (not universal)

### Documentation
- Keep test plans in `test-plans/`
- Name format: `MS-12345.md`
- Include environment and version info
- Link artifacts in JIRA comments

### Test Organization
**Tests are organized by application area:**

**CLI Tests** (`test-scripts/CLI/`):
- `Core/` - Auth, profiles, config, package integrity
- `API/` - Entity CRUD operations, formatting bugs
- `Output/` - File output, `--output` parameter
- `ExitCodes/` - Exit code validation
- `FileSystem/` - File upload/download commands

**Playwright Tests** (`playwright/Magic Suite/`):
- Already organized: `DataMagic/`, `AlertMagic/`, `Admin/`, `Connect/`, `Docs/`, `ReportMagic/`, `Www/`

**App-Specific Tests** (`test-scripts/{App}/`):
- `DataMagic/` - Data visualization tests
- `ReportMagic/Docs/` - Documentation verification
- `Utilities/` - Helper scripts

**Creating New Tests:**
- CLI bug: Place in `test-scripts/CLI/{Category}/test-ms-{TICKET}.ps1`
- Playwright test: Place in `playwright/Magic Suite/{App}/{Feature}.spec.ts`
- Always update the folder's README.md with test description
- See `test-scripts/README.md` for complete guide

---

## 🚨 Common Pitfalls

### JIRA Bug Creation
- ❌ Ampersands in hashtables: Use single quotes `@('MagicSuite_R&D')`
- ❌ Here-strings in hashtables: Use variables instead
- ❌ Missing `customfield_11200`: Required for MS project
- ❌ Wrong priority format: Use `@{id = "2"}` not `"Critical"`

### Playwright
- ❌ No --project flag: Opens all browsers
- ❌ File paths: Use test name patterns
- ❌ No auth state: Run auth.setup first
- ❌ Wrong environment: Check `$env:MS_ENV`

### CLI Testing
- ❌ Using 4.2.x: Only 4.1.x allowed
- ❌ Wrong profile: Verify with `--profile`
- ❌ Wrong environment: Check API URL

---

## 📞 Resources

- **JIRA**: https://jira.panoramicdata.com
- **XWiki**: https://wiki.panoramicdata.com
- **Elastic**: https://pdl-elastic-prod.panoramicdata.com
- **Test Plans**: `test-plans/` directory
- **Setup Guide**: `docs/SETUP-INSTRUCTIONS.md`

---

**Last Updated**: January 2026
**Version**: 2.0 (Reorganized)
