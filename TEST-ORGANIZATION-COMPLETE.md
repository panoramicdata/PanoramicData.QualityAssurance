# Test Organization Complete ✅

Your test files are now fully organized by Magic Suite application area!

## 📁 Test Scripts Structure (PowerShell/CLI)

```
test-scripts/
├── README.md                                 # Main organization guide
├── CLI/                                      # MagicSuite CLI Tests
│   ├── Core/                                 # Core CLI functionality
│   │   ├── README.md
│   │   ├── MagicSuite-CLI.Tests.ps1         # General CLI tests
│   │   ├── test-ms-22523.ps1                # Profile display bug
│   │   └── test-ms-22558.ps1                # NuGet package bug
│   ├── API/                                  # API operations
│   │   ├── README.md
│   │   ├── test-ms-22521.ps1                # ReportBatchJobs null ref
│   │   └── test-ms-22522.ps1                # Markup exception
│   ├── Output/                               # Output handling
│   │   ├── README.md
│   │   ├── test-ms-22564.ps1                # --output parameter
│   │   └── test-ms-22612.ps1                # Output to non-existent dir
│   ├── ExitCodes/                            # Exit code behavior
│   │   ├── README.md
│   │   ├── test-ms-22611.ps1                # Negative --take
│   │   └── test-ms-22611-simple.ps1         # Simplified version
│   └── FileSystem/                           # (Future: file commands)
├── DataMagic/                                # DataMagic tests
│   ├── README.md
│   └── test-ms-22556.ps1                    # UI/UX issues
├── ReportMagic/                              # ReportMagic tests
│   └── Docs/                                 # Documentation tests
│       ├── README.md
│       ├── check-reportmagic-docs.ps1
│       └── check-reportmagic-docs-test2.ps1
└── Utilities/                                # Test helpers
    ├── README.md
    └── test-jira-create.ps1                 # JIRA integration test
```

## 🎭 Playwright Tests Structure (UI Tests)

```
playwright/Magic Suite/
├── auth.setup.spec.ts                       # Authentication setup
├── Admin/
│   └── HomePage.spec.ts                     # Admin portal tests
├── AlertMagic/
│   └── HomePage.spec.ts                     # Alert management tests
├── Connect/
│   └── HomePage.spec.ts                     # Connect app tests
├── DataMagic/
│   ├── HomePage.spec.ts                     # DataMagic home page
│   └── MS-22556-UI-Regression.spec.ts       # UI/UX regression tests
├── Docs/
│   ├── HomePage.spec.ts                     # Docs home page
│   └── ReportMagicMacros.spec.ts            # Macro documentation
├── NCalc101/
│   └── HomePage.spec.ts                     # NCalc tutorial site
├── ReportMagic/
│   └── HomePage.spec.ts                     # ReportMagic tests
└── Www/
    └── HomePage.spec.ts                     # Main website tests
```

## 📝 Naming Conventions

### PowerShell Tests
- Bug verification: `test-ms-{TICKET}.ps1` (e.g., `test-ms-22521.ps1`)
- Feature tests: `test-{feature}.ps1` (e.g., `test-file-upload.ps1`)
- Verification: `check-{what}.ps1` (e.g., `check-reportmagic-docs.ps1`)

### Playwright Tests
- Feature tests: `{Feature}.spec.ts` (e.g., `HomePage.spec.ts`)
- Bug tests: `MS-{TICKET}.spec.ts` (e.g., `MS-22556-UI-Regression.spec.ts`)

## 🎯 Where to Put New Tests

### CLI Tests
| Test Type | Location | Example |
|-----------|----------|---------|
| Auth/Config/Profiles | `CLI/Core/` | Profile management bugs |
| API operations | `CLI/API/` | Entity CRUD, formatting |
| File output | `CLI/Output/` | --output parameter |
| Exit codes | `CLI/ExitCodes/` | Error handling |
| File commands | `CLI/FileSystem/` | Upload/download |

### Application Tests (UI)
| Application | Location | Test Type |
|-------------|----------|-----------|
| DataMagic | `playwright/Magic Suite/DataMagic/` | UI/UX, visualization |
| AlertMagic | `playwright/Magic Suite/AlertMagic/` | Alerts, notifications |
| ReportMagic | `playwright/Magic Suite/ReportMagic/` | Reports, macros |
| Admin | `playwright/Magic Suite/Admin/` | Admin functions |
| Connect | `playwright/Magic Suite/Connect/` | Integrations |
| Docs | `playwright/Magic Suite/Docs/` | Documentation |

### Application Tests (PowerShell)
| Application | Location | Test Type |
|-------------|----------|-----------|
| DataMagic | `test-scripts/DataMagic/` | CLI/API tests |
| ReportMagic | `test-scripts/ReportMagic/` | Docs verification |
| Utilities | `test-scripts/Utilities/` | Helper scripts |

## 🚀 Quick Commands

### Run all tests in a category
```powershell
# All CLI API tests
Get-ChildItem .\test-scripts\CLI\API\*.ps1 | ForEach-Object { & $_.FullName }

# All DataMagic Playwright tests (Firefox)
cd playwright; npx playwright test DataMagic --project=firefox
```

### Run specific test
```powershell
# PowerShell test
.\test-scripts\CLI\Core\test-ms-22523.ps1

# Playwright test
cd playwright; npx playwright test "DataMagic/HomePage" --project=firefox
```

## 📚 Documentation

Each folder has a README.md explaining:
- What tests belong there
- How to run the tests
- What to include when adding new tests
- Links to related test areas

## ✨ Benefits

✅ **Easy to find tests** - Organized by what they test
✅ **Clear for regression** - All related tests grouped together
✅ **Simple to extend** - Clear place for new tests
✅ **Well documented** - READMEs in every folder
✅ **Future-proof** - Easy to add new categories

---

**All tests are now organized and ready for regression testing!** 🎉
