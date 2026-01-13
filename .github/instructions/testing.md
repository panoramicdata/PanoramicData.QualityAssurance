# Testing Instructions & Requirements

## Critical Testing Rules

### 1. Environment Confirmation (MANDATORY!)
**BEFORE running ANY test, ALWAYS confirm the test environment with the user.**

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

### 2. CLI Version Verification
**ALWAYS verify CLI version before CLI testing:**
```powershell
magicsuite --version
```
Expected: 4.1.x versions ONLY (e.g., 4.1.546+a2e24699c9)

If wrong version:
1. Uninstall: `dotnet tool uninstall -g MagicSuite.Cli`
2. Install correct: `dotnet tool install -g MagicSuite.Cli --version '4.1.*'`
3. Verify: `magicsuite --version`

### 3. Playwright Browser Preference
**ALWAYS use Firefox as default browser:**
```powershell
# Authenticate
npx playwright test auth.setup --project=firefox

# Run tests
npx playwright test [test-name] --project=firefox
```

**NEVER omit --project=firefox flag!**

### 4. Include Version/Environment in Results
All test results must include:
- CLI version (if applicable)
- Test environment URL
- Test date/time
- Application name
- Browser (if UI testing)

## Test Environments

| Environment | URL | Primary Use |
|-------------|-----|-------------|
| test2 (default) | test2.magicsuite.net | Primary QA testing |
| test | test.magicsuite.net | Secondary testing |
| alpha2 | alpha2.magicsuite.net | Alpha releases |
| alpha | alpha.magicsuite.net | Early alpha |
| beta | beta.magicsuite.net | Beta releases |
| staging | staging.magicsuite.net | Pre-production |
| production | magicsuite.net | Live (use caution!) |

**Default to test2 unless specified otherwise.**

## Test Organization

Tests are organized by application and type:

### CLI Tests (`test-scripts/CLI/`)
- **Core/**: Basic CLI functionality, configuration, profiles
- **API/**: API endpoint testing, entity operations
- **Output/**: Output formatting (JSON, CSV, table)
- **ExitCodes/**: Exit code validation
- **FileSystem/**: File operations

### Application Tests (`test-scripts/[App]/`)
- **DataMagic/**: DataMagic-specific tests
- **ReportMagic/**: ReportMagic tests, includes Docs/ subfolder
- **AlertMagic/**: AlertMagic tests
- **Admin/**: Admin panel tests

### Playwright Tests (`playwright/Magic Suite/`)
- **Admin/**: Admin UI tests
- **AlertMagic/**: Alert UI tests
- **Connect/**: Connect app tests
- **DataMagic/**: DataMagic UI tests
- **Docs/**: Documentation verification
- **ReportMagic/**: ReportMagic UI tests
- **Www/**: Main website tests

## Test Workflow

### 1. Planning Phase
1. Read ticket details with JIRA.ps1: `.\.github\tools\JIRA.ps1 -Action GetFull -IssueKey MS-12345`
2. Identify test scope and requirements
3. Determine test environment (ask user if unclear!)
4. Create/update test plan in `test-plans/`
5. Comment on JIRA: "Creating test plan for MS-12345..."

### 2. Setup Phase
1. **Confirm test environment with user**
2. Verify CLI version (if CLI testing)
3. Authenticate Playwright (if UI testing)
4. Check application accessibility
5. Comment on JIRA: "Setup complete, beginning tests..."

### 3. Execution Phase
1. Run tests systematically
2. Capture screenshots for UI tests
3. Save command outputs for CLI tests
4. Document any errors immediately
5. Log results to `test-results/` folder

### 4. Analysis Phase
1. Review all test results
2. Identify patterns or blockers
3. Create bug tickets for issues found
4. Document findings in test results file
5. Update test plan with actual results

### 5. Reporting Phase
1. Create comprehensive test results file
2. Update JIRA with final comment
3. Transition ticket to appropriate state
4. Tag relevant developers if issues found

## Test Results Format

### File Naming
`[ticket]-test-results-[date].md`

Example: `MS-22558-test-results-20260113.md`

### Template
```markdown
# Test Results: MS-12345 - Feature Name

## Test Information
- **Ticket**: MS-12345
- **Tester**: Amy Bond
- **Test Date**: 2026-01-13 14:30:00
- **Environment**: test2.magicsuite.net
- **Application**: DataMagic
- **CLI Version**: 4.1.546+a2e24699c9 (if applicable)
- **Browser**: Firefox 144.0.2 (if applicable)

## Test Summary
Brief overview of what was tested.

## Test Cases

### TC-01: Test Case Name
**Expected**: Description of expected behavior
**Actual**: What actually happened
**Result**: ✓ Pass / ✗ Fail
**Evidence**: Screenshot/log reference

### TC-02: Another Test Case
...

## Issues Found
- **Bug 1**: Description
  - Severity: High/Medium/Low
  - Reproducible: Yes/No
  - JIRA Ticket: MS-12346
- **Bug 2**: Description
  ...

## Artifacts
- Test Plan: `test-plans/MS-12345.md`
- Screenshots: `playwright/screenshots/ms-12345-*.png`
- Logs: `logs/MS-12345/`
- Test Scripts: `test-scripts/[App]/test-ms-12345.ps1`

## Notes
Additional observations or context.

## Recommendation
Pass/Fail/Conditional Pass
```

## Authentication

### CLI Authentication
Create profiles for each environment:
```powershell
magicsuite configure-profile --name test2-amy --base-url https://test2.magicsuite.net
magicsuite configure-profile --name test-amy --base-url https://test.magicsuite.net
```

Use in tests:
```powershell
magicsuite get --entity DataStore --profile test2-amy
```

### Playwright Authentication
Run before tests:
```powershell
cd playwright
npx playwright test auth.setup --project=firefox
```

Credentials saved to `.auth/user.json` and reused automatically.

### Manual Authentication
Use credentials from password manager (1Password):
- **URL**: https://[environment].magicsuite.net
- **Username**: amy.bond
- **Password**: [from 1Password]

## Common Test Types

### Regression Testing
Test existing functionality after changes:
1. Identify affected features
2. Run existing test scripts
3. Compare results to baseline
4. Document any deviations

### Feature Testing
Test new functionality:
1. Create new test plan
2. Define test cases (positive, negative, edge)
3. Execute tests systematically
4. Document results and bugs

### Smoke Testing
Quick verification that major functions work:
1. Login/authentication
2. Navigation
3. Basic CRUD operations
4. Key workflows

### Integration Testing
Test interaction between components:
1. API + UI
2. Multiple applications
3. External integrations
4. Data flow between systems

## Test Data Management

### Test Users
| Username | Role | Permissions |
|----------|------|-------------|
| amy.bond | Admin | Full access |
| test.user | Standard | Limited access |

### Test Data
- Use realistic but non-production data
- Clean up test data after testing
- Document any persistent test data created
- Don't use production data in test environments!

## Screenshot Guidelines

### When to Take Screenshots
- Before and after actions
- Error states
- Success confirmations
- Complex UI states
- Bug evidence

### Naming Convention
`[app]-[feature]-[state]-[date].png`

Examples:
- `datamagic-query-save-success-20260113.png`
- `reportmagic-schedule-error-20260113.png`

### Storage
Save to `playwright/screenshots/` with descriptive names.

## Log Collection

### Application Logs
Use Elastic.ps1 to gather logs:
```powershell
.\.github\tools\Elastic.ps1 -Action Search -Query "application:DataMagic AND level:ERROR" -From "2026-01-13T00:00:00" -To "2026-01-13T23:59:59"
```

### CLI Output
Save command outputs:
```powershell
magicsuite get --entity DataStore --profile test2-amy | Out-File "logs/datastore-output.txt"
```

### Playwright Traces
Enabled by default, view with:
```powershell
npx playwright show-trace test-results/[test-name]/trace.zip
```

## Test Metrics

Track these metrics in test results:
- Total test cases
- Passed / Failed / Skipped
- Execution time
- Bugs found
- Regression issues
- Blockers identified

## Best Practices

### Before Testing
✓ Confirm environment  
✓ Verify tool versions  
✓ Authenticate properly  
✓ Review ticket requirements  
✓ Create test plan  

### During Testing
✓ Test systematically  
✓ Document as you go  
✓ Capture evidence  
✓ Note unexpected behavior  
✓ Update JIRA with progress  

### After Testing
✓ Create bug tickets  
✓ Save all artifacts  
✓ Update test plans  
✓ Post final JIRA comment  
✓ Transition ticket  

## Common Pitfalls

### Environment Mistakes
- ❌ **Wrong**: Testing without confirming environment
- ✅ **Correct**: Always confirm environment before tests
- **Impact**: Could run tests against wrong environment (even production!)

### Version Mismatch
- ❌ **Wrong**: Using CLI 4.2.x for testing
- ✅ **Correct**: Always verify 4.1.x before CLI tests
- **Impact**: Test results don't match production behavior

### Missing Evidence
- ❌ **Wrong**: Reporting bugs without screenshots/logs
- ✅ **Correct**: Always capture evidence for issues
- **Impact**: Bugs can't be reproduced or fixed

### Incomplete Results
- ❌ **Wrong**: Partial test execution or documentation
- ✅ **Correct**: Complete all tests and document fully
- **Impact**: Incomplete testing may miss critical bugs

### Not Updating JIRA
- ❌ **Wrong**: Testing without JIRA updates
- ✅ **Correct**: Comment on progress throughout testing
- **Impact**: Team doesn't know status, duplicated work
