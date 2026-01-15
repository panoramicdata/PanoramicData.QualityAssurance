# Magic Suite Test Files

This directory contains organized Playwright tests for Magic Suite products.

## 📁 Directory Structure

```
Magic Suite/
├── Admin/                          # Admin Portal tests
│   └── HomePage.spec.ts
├── AlertMagic/                     # AlertMagic tests  
│   └── HomePage.spec.ts
├── Connect/                        # Connect Portal tests
│   └── HomePage.spec.ts
├── DataMagic/                      # DataMagic tests
│   ├── HomePage.spec.ts
│   └── MS-22556-UI-Regression.spec.ts
├── Docs/                           # Documentation tests
│   ├── HomePage.spec.ts
│   └── ReportMagicMacros.spec.ts
├── NCalc101/                       # NCalc 101 tests
│   └── HomePage.spec.ts
├── ReportMagic/                    # ReportMagic tests
│   └── HomePage.spec.ts
├── Www/                            # Main Portal tests
│   └── HomePage.spec.ts
├── tests/                          # Special test suites
│   └── deep-link-validation.spec.ts
└── utils/                          # Shared utilities
    ├── urls.ts
    └── magic-suite-urls.ts
```

## ⚠️ Old Files (Deprecated)

The following files have been replaced and are kept for reference only:
- `auth.setup*.OLD.txt` - Replaced by `../setup/auth.setup.ts`
- `example.*.EXAMPLE.txt` - Example code for reference

**Note**: Authentication setup is now in `../setup/auth.setup.ts`

## 🧪 Running Tests

### Run all tests:
```powershell
npx playwright test
```

### Run tests for specific product:
```powershell
npx playwright test DataMagic/
npx playwright test ReportMagic/
npx playwright test Admin/
```

### Run specific test file:
```powershell
npx playwright test DataMagic/HomePage.spec.ts
```

### Run with specific authentication:
```powershell
npx playwright test Admin/ --project=super-admin
npx playwright test --project=regular-user
```

## 📝 Test Organization

Tests are organized by Magic Suite product/portal:
- **Product folders** (Admin, DataMagic, etc.) - Main product tests
- **tests/** - Cross-product or special test suites
- **utils/** - Shared utilities and helpers

## 🔧 Adding New Tests

1. Create test file in appropriate product folder
2. Name it descriptively: `FeatureName.spec.ts`
3. Import utilities from `./utils/` folder
4. Follow existing test patterns
5. Run locally before committing

## 📚 Documentation

- [Setup Guide](../setup/README.md)
- [Deep Links Reference](../DEEP-LINKS-REFERENCE.md)
- [Authentication Guide](../.auth/README.md)
- [Main README](../README.md)
