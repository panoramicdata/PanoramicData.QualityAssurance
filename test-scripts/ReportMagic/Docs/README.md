# ReportMagic Documentation Tests

Tests for ReportMagic documentation and macro verification.

## Test Files

### check-reportmagic-docs.ps1
Verifies ReportMagic documentation is accessible and correctly formatted.

### check-reportmagic-docs-test2.ps1
Same as above but specifically for test2 environment.

## Test Categories

- ✅ Documentation accessibility
- ✅ Macro page verification
- ✅ Help content validation
- ✅ Documentation structure

## Related Playwright Tests

For UI-based documentation testing, see:
- `playwright/Magic Suite/Docs/ReportMagicMacros.spec.ts`
- `playwright/Magic Suite/ReportMagic/HomePage.spec.ts`

## Running Tests

```powershell
# Run documentation checks
.\test-scripts\ReportMagic\Docs\check-reportmagic-docs.ps1
.\test-scripts\ReportMagic\Docs\check-reportmagic-docs-test2.ps1
```

## Adding New Tests

Place tests here for:
- Documentation verification
- Macro help validation
- ReportMagic documentation structure
- Documentation accessibility
