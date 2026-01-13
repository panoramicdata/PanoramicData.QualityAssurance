# Test Scripts Organization

This directory contains organized test scripts for Magic Suite components, organized by application area and test type.

## 📁 Folder Structure

```
test-scripts/
├── CLI/                          # MagicSuite CLI tests
│   ├── Core/                     # Core CLI functionality (config, auth, profiles)
│   ├── API/                      # API command tests (get, patch, delete entities)
│   ├── Output/                   # Output formatting and file operations
│   ├── ExitCodes/                # Exit code behavior tests
│   └── FileSystem/               # File management command tests
├── DataMagic/                    # DataMagic application tests
├── AlertMagic/                   # AlertMagic application tests
├── ReportMagic/                  # ReportMagic application tests
│   └── Docs/                     # Documentation verification tests
├── Connect/                      # Connect application tests
├── Admin/                        # Admin application tests
├── Files/                        # Files UI tests
└── Utilities/                    # Test utilities and helpers
```

## 📝 Naming Conventions

### Test Scripts
- **Bug fix verification**: `test-ms-{TICKET}.ps1` (e.g., `test-ms-22521.ps1`)
- **Feature tests**: `test-{feature-name}.ps1` (e.g., `test-file-upload.ps1`)
- **Regression tests**: `{app}-regression.ps1` (e.g., `cli-regression.ps1`)
- **Verification scripts**: `check-{what}.ps1` (e.g., `check-reportmagic-docs.ps1`)

### Playwright Tests
Located in `playwright/Magic Suite/` - already organized by app:
- `Admin/` - Admin portal tests
- `AlertMagic/` - Alert management tests
- `Connect/` - Connect application tests
- `DataMagic/` - Data visualization tests
- `Docs/` - Documentation site tests
- `ReportMagic/` - Report macro tests
- `Www/` - Main website tests

## 🎯 Test Organization Guidelines

### CLI Tests
**CLI/Core/** - Core functionality
- Authentication and profile management
- Configuration commands
- Version checks
- Basic CLI behavior

**CLI/API/** - API Operations
- Entity CRUD operations (get, patch, delete)
- API formatting (JSON, Table)
- Entity-specific bugs
- API error handling

**CLI/Output/** - Output Handling
- `--output` parameter tests
- File write operations
- Output format validation
- Path handling (relative/absolute)

**CLI/ExitCodes/** - Exit Code Behavior
- Error condition exit codes
- Invalid parameter handling
- Expected failure scenarios

**CLI/FileSystem/** - File Commands
- File upload/download
- Folder operations
- File search functionality
- Path manipulation

### Application Tests
**DataMagic/** - Data visualization and database components
**AlertMagic/** - Alert configuration and management
**ReportMagic/** - Report generation and macro functionality
**Connect/** - Integration and connection management
**Admin/** - Administrative functions
**Files/** - SharePoint integration and file management

### Utilities
Helper scripts, test data generators, and common test functions that support multiple test areas.

## 🚀 Running Tests

### CLI Tests
```powershell
# Run specific test
.\test-scripts\CLI\Core\test-ms-22523.ps1

# Run all CLI API tests
Get-ChildItem .\test-scripts\CLI\API\*.ps1 | ForEach-Object { & $_.FullName }
```

### Playwright Tests
```powershell
# Run specific app tests (Firefox)
cd playwright
npx playwright test DataMagic --project=firefox

# Run all tests for an app
npx playwright test AlertMagic --project=firefox
```

## 📋 Creating New Tests

### For CLI Tests
1. Determine the test category (Core, API, Output, ExitCodes, FileSystem)
2. Create script in appropriate `CLI/` subfolder
3. Use naming convention: `test-ms-{TICKET}.ps1` or `test-{feature}.ps1`
4. Include header comment with test purpose and JIRA ticket reference

### For Playwright Tests
1. Determine the application (DataMagic, AlertMagic, etc.)
2. Create test in `playwright/Magic Suite/{App}/`
3. Use naming convention: `{Feature}.spec.ts` or `MS-{TICKET}.spec.ts`
4. Follow existing test patterns in that folder

## ⚠️ Testing Requirements

- **CLI Version**: Always use 4.1.x for official testing (NOT 4.2.x)
- **Test Environment**: Confirm environment before running (default: test2)
- **Browser**: Use Firefox for Playwright tests (`--project=firefox`)
- **Documentation**: Include JIRA ticket references and environment info

## 📚 Related Documentation

- **Setup Instructions**: `docs/SETUP-INSTRUCTIONS.md`
- **Copilot Instructions**: `.github/copilot-instructions.md`
- **Test Plans**: `test-plans/` directory
- **Playwright README**: `playwright/README.md`
