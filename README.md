# PanoramicData Quality Assurance Workspace

This workspace contains automated testing tools, test plans, and documentation for Panoramic Data's Magic Suite quality assurance processes.

## 📂 Folder Structure

### `.github/` - GitHub Integration Tools
- **`tools/`** - PowerShell integration scripts (JIRA, XWiki, Elastic, Regression Runner)

### `docs/` - Documentation
- **`Test-Migration-Plan.md`** - Comprehensive test automation migration plan
- Setup instructions, sharing guides, and other documentation

### `scripts/` - Organized Scripts
- **`setup/`** - Environment and tool setup (Run-Setup.ps1, authentication, profiles)
- **`automation/`** - Automated monitoring and maintenance
- **`utilities/`** - Helper scripts and templates

### `playwright/` - Automated UI Tests
- **`Magic Suite/`** - Test specs by application (Admin, AlertMagic, DataMagic, etc.)
- Test results, screenshots, videos, and traces

### `test-plans/` - Manual Test Plans
- Test plans for JIRA tickets (MS-XXXXX.md format)

### `test-scripts/` - CLI & API Test Scripts
- PowerShell tests for MagicSuite CLI and API

### `bug-scripts/` - Bug Ticket Creation
- Automated JIRA bug creation scripts

### `jira-update-scripts/` - JIRA Updates
- Scripts for updating JIRA tickets

### `logs/` - Log Analysis
- Collected logs organized by JIRA ticket

## 🚀 Quick Start

### 1. Initial Setup
```powershell
.\scripts\setup\Run-Setup.ps1
```

### 2. Run Playwright Tests
```powershell
cd playwright
npx playwright test
npx playwright show-report
```

### 3. Run Regression Tests
```powershell
.\.github\tools\RunRegressionTests.ps1 -Environment test
```

## 📋 Test Migration

See [docs/Test-Migration-Plan.md](docs/Test-Migration-Plan.md) for the comprehensive plan to migrate manual tests to Playwright/CLI automation.

**Progress:**
- ✅ Playwright setup complete
- ✅ Authentication flows working
- ✅ Basic navigation tests
- 🔄 Comprehensive test suite in progress

## 🔗 Links

- **Playwright Guide:** https://wiki.panoramicdata.com/bin/view/QA%20Home/PlaywrightGuide
- **XWiki QA Home:** https://wiki.panoramicdata.com/bin/view/QA%20Home/
- **JIRA:** https://jira.panoramicdata.com/browse/MS

---

**Last Updated:** December 16, 2025  
**Maintained By:** Panoramic Data QA Team
