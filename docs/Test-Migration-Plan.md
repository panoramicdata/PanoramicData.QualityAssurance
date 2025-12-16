# Test Migration Plan: Wiki Regression Tests → Playwright + CLI

**Date:** December 16, 2025  
**Author:** QA Team  
**Version:** 1.0

## Executive Summary

The current regression testing approach uses:
- **UI Regression Tool** (C# desktop app with Chrome automation)
- **Manual testing** following wiki checklists
- **PPTX Regression CLI tool** (command line, requires LibreOffice)
- **Report schedules** that run and compare output

**Goal:** Migrate to modern Playwright tests + CLI automation using MagicSuite CLI tool

---

## Phase 1: Magic Suite UI Tests → Playwright

### 1.1 Report Magic UI Tests
**Priority: HIGH** | **Complexity: Medium**

#### Current Coverage
- Login/logout flows (SA, TA, Regular User, Unapproved)
- Navigation and page loading
- Report Studio macro insertion and execution
- Schedule management (create, run, edit, cron)
- File operations (rename, move, copy, download)
- Connection status page
- Feedback submission
- User/role/RBAC management

#### Playwright Test Structure
```
playwright/Magic Suite/ReportMagic/
├── Auth/
│   ├── Login.spec.ts (SA, TA, Regular, Unapproved users)
│   └── Logout.spec.ts
├── ReportStudio/
│   ├── MacroInsertion.spec.ts
│   ├── MacroExecution.spec.ts
│   └── ErrorHandling.spec.ts (Warning, MacroError, SystemError)
├── Schedules/
│   ├── CreateSchedule.spec.ts
│   ├── RunNow.spec.ts
│   ├── CronScheduling.spec.ts
│   └── ProgressMonitoring.spec.ts
├── FileSystem/
│   ├── FileOperations.spec.ts (rename, move, copy, download)
│   └── FolderCreation.spec.ts
├── Admin/
│   ├── Connections.spec.ts
│   ├── Users.spec.ts
│   ├── ApiTokens.spec.ts
│   └── RBAC.spec.ts
└── Regression/
    └── NewBuildChecks.spec.ts (comprehensive smoke test)
```

### 1.2 Data Magic UI Tests
**Priority: MEDIUM** | **Complexity: Low**

#### Current Coverage
- Login/logout
- Page navigation
- Search/filter/sort on tables
- Left pane collapse/expand

#### Playwright Test Structure
```
playwright/Magic Suite/DataMagic/
├── Navigation.spec.ts
├── TableOperations.spec.ts
└── UIInteractions.spec.ts
```

### 1.3 Alert Magic UI Tests
**Priority: MEDIUM** | **Complexity: Low**

#### Current Coverage
- Login/access to all pages
- (More detail needed from wiki)

#### Playwright Test Structure
```
playwright/Magic Suite/AlertMagic/
├── Navigation.spec.ts
└── PageAccess.spec.ts
```

### 1.4 Admin App UI Tests
**Priority: MEDIUM** | **Complexity: Low**

#### Playwright Test Structure
```
playwright/Magic Suite/Admin/
├── Navigation.spec.ts
└── AdminOperations.spec.ts
```

### 1.5 Docs App UI Tests
**Priority: LOW** | **Complexity: Low**

#### Current Coverage
- Access documentation sections (Navigation, Admin, AlertMagic, DataMagic, etc.)
- Macro help pages

#### Playwright Test Structure
```
playwright/Magic Suite/Docs/
├── NavigationAccess.spec.ts
├── MacroHelp.spec.ts
└── ReleaseNotes.spec.ts
```

### 1.6 Universal UI Tests
**Priority: HIGH** | **Complexity: Low**

#### Current Coverage
- Help access
- Search functionality
- Feedback submission (logged in/out)
- Left pane interactions

#### Playwright Test Structure
```
playwright/Magic Suite/Common/
├── Help.spec.ts
├── Search.spec.ts
├── Feedback.spec.ts
└── UIComponents.spec.ts
```

---

## Phase 2: Backend/API Tests → CLI

### 2.1 MagicSuite CLI Integration Tests
**Priority: HIGH** | **Complexity: Medium**

#### Test Categories

**A. Authentication & Authorization**
```powershell
test-scripts/CLI/CLI-Auth.Tests.ps1
- Test profile switching
- Test token authentication
- Test tenant selection
- Test permission levels (SA, TA, Regular)
```

**B. API CRUD Operations**
```powershell
test-scripts/CLI/CLI-CRUD.Tests.ps1
- Test get operations (with filters, pagination)
- Test get-by-id
- Test patch operations
- Test delete operations
- Verify against expected entities (119 types)
```

**C. File Operations**
```powershell
test-scripts/CLI/CLI-Files.Tests.ps1
- Upload files
- Download files
- List files/folders
- Delete files
- Rename/move files
- Search files
- Verify file integrity
```

**D. Report Schedules**
```powershell
test-scripts/CLI/CLI-Schedules.Tests.ps1
- Create schedules via API
- Trigger schedule execution
- Monitor job status
- Retrieve output
- Compare with baseline
```

### 2.2 Report Output Regression Tests
**Priority: HIGH** | **Complexity: HIGH**

#### Current Approach
- Run schedules manually
- Compare PNG diffs in SharePoint
- Visual inspection of PDFs

#### New CLI Approach
```powershell
test-scripts/Regression/ReportRegression.Tests.ps1

1. Use MagicSuite CLI to:
   - Download baseline reports from SharePoint
   - Trigger regression schedules
   - Download new output
   - Compare outputs programmatically

2. Automate diff.png.zip comparison:
   - Extract and parse txt files
   - Compare with known baseline
   - Report new diffs vs expected diffs

3. PDF comparison:
   - Use PDF comparison libraries
   - Generate automated reports
```

#### Core Regression Schedule
```powershell
.\RunRegressionTests.ps1 -Environment test -Type CoreRegression
- Downloads baseline from SharePoint
- Runs schedule via CLI
- Compares output
- Generates diff report
```

#### LogicMonitor Regression Schedule
```powershell
.\RunRegressionTests.ps1 -Environment test -Type LogicMonitorRegression
- Same approach as Core
- Focus on LM macro outputs
```

#### PPTX Regression
```powershell
.\RunRegressionTests.ps1 -Environment test -Type PPTXRegression
- Integrate existing PPTX tool
- Use LibreOffice for comparison
- Report differences
```

### 2.3 Macro Execution Tests
**Priority: HIGH** | **Complexity: MEDIUM**

#### Current Approach
- Manual copy/paste into Report Studio
- Visual verification of output

#### New CLI Approach
```powershell
test-scripts/Regression/MacroExecution.Tests.ps1

- Create report templates programmatically
- Use CLI to execute via report schedules
- Parse output for expected values
- Verify variable types and values

Test Categories:
- Agent macros (SQL queries)
- ReportMagic macros (system properties)
- JIRA macros (user lists)
- LogicMonitor macros (graphs, data)
- Toggl macros (projects, reports)
- String/Date/Calculate macros
- ForEach loops
```

---

## Phase 3: Integration & Automation

### 3.1 Unified Test Runner
**Priority: HIGH** | **Complexity: MEDIUM**

```powershell
.\.github\tools\RunFullRegressionSuite.ps1 -Environment test -BuildNumber 4.1.278

Executes:
1. Playwright UI tests (all apps)
2. CLI API tests
3. Report output regression
4. Macro execution verification
5. File system operations

Outputs:
- JUnit XML for CI/CD
- HTML report
- Screenshots/videos for failures
- Comparison to previous build
```

### 3.2 Build Validation Script
**Priority: HIGH** | **Complexity: LOW**

```powershell
.\.github\tools\ValidateNewBuild.ps1 -Environment test -BuildNumber 4.1.278

Quick smoke tests:
1. Version verification (hover tooltip, About page)
2. Connection status (green ticks)
3. Basic macro execution (New Build schedule)
4. Login flows (SA, TA, Regular)
5. File operations
6. Blogger cache refresh

Pass/Fail status: Ready for full regression or needs fixing
```

### 3.3 CI/CD Integration
**Priority: MEDIUM** | **Complexity: HIGH**

- GitHub Actions workflow
- Triggered on new build deployment
- Runs validation then full regression
- Posts results to JIRA ticket
- Teams notification with summary

---

## Phase 4: Test Data Management

### 4.1 Baseline Management
```
test-baselines/
├── CoreRegression/
│   ├── v4.1.275/
│   └── v4.1.278/
├── LogicMonitorRegression/
│   ├── v4.1.275/
│   └── v4.1.278/
└── PPTXRegression/
    ├── v4.1.275/
    └── v4.1.278/
```

### 4.2 Test Tenant Management

**Script:** `Setup-TestTenant.ps1`
- Create panoramicdatatest.onmicrosoft.com tenant
- Set up file systems
- Create test users (TA, Regular, Dummy)
- Create API tokens
- Create RBAC roles

**Script:** `Teardown-TestTenant.ps1`
- Delete tenant
- Verify cleanup (users, tokens removed)

---

## Implementation Priority

### Sprint 1 (High Priority)
1. ✅ Playwright auth setup (DONE)
2. Report Magic core UI tests (Login, ReportStudio, Schedules)
3. CLI authentication and basic CRUD tests
4. Build validation script

### Sprint 2
1. Report output regression automation
2. Macro execution CLI tests
3. File operations (UI + CLI)
4. Data Magic UI tests

### Sprint 3
1. Admin/RBAC tests (UI + CLI)
2. Alert Magic UI tests
3. Unified test runner
4. Baseline management system

### Sprint 4
1. CI/CD integration
2. PPTX regression integration
3. Test data management scripts
4. Documentation and training

---

## Success Metrics

- **Coverage:** 80%+ of manual wiki tests automated
- **Execution Time:** Full regression < 30 minutes
- **Reliability:** < 5% flaky tests
- **Maintenance:** Easy to update when UI changes
- **Reporting:** Clear pass/fail with screenshots/videos
- **Integration:** Automated on build deployment

---

## Current Test Inventory

### Existing UI Regression Tool Tests
The C# desktop UI Regression Tool currently covers:
- Element existence checks
- Navigation verification
- Functional testing
- Authorization level testing (SA, TA, Regular)

**Migration Strategy:** Map each test case to equivalent Playwright test

### Existing Manual Wiki Tests
From "Build Validation Checks" and "New Build Checks" pages:

#### Report Magic Tests
- General checks (version, about page, connections)
- Schedule operations (7 different schedules)
- Report Studio macro execution
- New tenant workflow (comprehensive RBAC testing)
- User level checks (Regular, TA, SA, Unapproved)

#### Magic Suite UI Tests
- Login/logout flows
- Feedback submission
- Help access
- Search functionality
- Table operations

#### Per-App Tests
- Data Magic: Navigation, tables, UI interactions
- Alert Magic: Page access
- Admin App: Admin operations
- Docs App: Documentation access
- Ops App: Page access

**Migration Strategy:** Convert to Playwright specs following test structure outlined in Phase 1

### Existing Report Output Regression
- Core Regression schedule (baseline in SharePoint)
- LogicMonitor Regression schedule (baseline in SharePoint)
- PPTX Regression (CLI tool with LibreOffice)
- LogicMonitor HealthCheck (Legacy and Normal modes)

**Migration Strategy:** Automate with CLI in Phase 2

---

## Technical Requirements

### Tools & Technologies
- **Playwright:** Browser automation
- **PowerShell:** Test scripting and CLI automation
- **MagicSuite CLI:** API operations and file management
- **Node.js:** Playwright runtime
- **Git:** Version control for baselines
- **JUnit XML:** Test result format for CI/CD

### Infrastructure
- **Test Environments:** alpha, alpha2, test, test2, beta, staging
- **Test Accounts:** SA, TA, Regular, Unapproved users per environment
- **SharePoint:** Baseline storage and output comparison
- **JIRA:** Test result reporting
- **Teams:** Notifications

### Prerequisites
- Playwright browsers installed
- MagicSuite CLI configured with profiles
- Authentication setup for all environments
- Access to SharePoint test folders
- JIRA and XWiki credentials

---

## Risk Assessment

### High Risk
- **Report output comparison:** Complex PDF/PPTX comparison may have false positives
- **Test data dependencies:** Tests may interfere with each other if not isolated
- **Environment stability:** Test environments may be unstable during deployments

**Mitigation:**
- Implement retry logic for flaky tests
- Use test isolation (cleanup after each test)
- Add environment health checks before test execution

### Medium Risk
- **Baseline management:** Keeping baselines current as features change
- **Test maintenance:** UI changes require test updates
- **Execution time:** Full regression may take longer than expected

**Mitigation:**
- Automated baseline update workflow
- Use page object pattern for maintainability
- Parallelize test execution

### Low Risk
- **Learning curve:** Team needs to learn Playwright
- **Tool compatibility:** LibreOffice for PPTX comparison

**Mitigation:**
- Training sessions and documentation
- Docker containers for consistent tool versions

---

## Next Steps

1. **Review & Approve:** Stakeholder review of this plan
2. **Environment Setup:** Ensure all test environments and accounts are ready
3. **Sprint 1 Kickoff:** Begin implementing high-priority tests
4. **Weekly Reviews:** Progress updates and adjustments
5. **Continuous Delivery:** Deploy tests as they're completed

---

## Appendices

### Appendix A: Existing Test Pages on Wiki
- "User Interface Regression Testing Tool" (QA Home)
- "Build Validation Checks" (QA Home.ReportMagic Information for Testers)
- "New build checks and minimum acceptance checks on all systems" (QA Home)
- "Beta/Staging customer report regression testing" (OPS)

### Appendix B: Existing Playwright Tests
- `auth.setup.spec.ts` - Authentication setup ✅
- `DataMagic/HomePage.spec.ts` - Basic navigation ✅
- `DataMagic/MS-22556-UI-Regression.spec.ts` - Specific bug regression ✅
- Other HomePage.spec.ts files for various apps ✅

### Appendix C: Existing Test Scripts
- `test-ms-22521.ps1` through `test-ms-22564.ps1` - Bug reproduction tests
- `MagicSuite-CLI.Tests.ps1` - CLI testing framework
- Bug creation scripts in `bug-scripts/` folder
- JIRA update scripts in `jira-update-scripts/` folder

### Appendix D: Test Plan Templates
Location: `test-plans/` folder
- `MS-21863.md` through `MS-22573.md` - Existing test plans
- `README.md` - Test plan template

---

**Document End**
