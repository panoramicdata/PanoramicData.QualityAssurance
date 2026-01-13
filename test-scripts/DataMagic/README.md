# DataMagic Tests

Tests for DataMagic application - database visualization and data management components.

## PowerShell Test Files

### test-ms-22556.ps1
**Bug**: DataMagic UI/UX Issues on alpha2
- Tests various UI rendering problems
- Validates usability issues
- Checks display consistency

## Playwright Test Files

Located in `playwright/Magic Suite/DataMagic/`:

### HomePage.spec.ts
Tests DataMagic home page loading and basic functionality.

### MS-22556-UI-Regression.spec.ts
Comprehensive UI/UX regression tests including:
- Left-hand feedback/search pane visibility
- Waffle menu collapsibility
- Font rendering across the product
- Filter box behavior
- White border issues
- Home page image display
- Column options display
- Reload error frequency
- External link button rendering
- Full page visual regression

## Test Categories

- ✅ UI/UX rendering
- ✅ Page load performance
- ✅ Navigation functionality
- ✅ Data visualization
- ✅ Filter and search operations

## Running Tests

### PowerShell Tests
```powershell
.\test-scripts\DataMagic\test-ms-22556.ps1
```

### Playwright Tests (Firefox)
```powershell
cd playwright
$env:MS_ENV='test2'
npx playwright test DataMagic --project=firefox --headed
```

## Adding New Tests

**PowerShell tests** - Place here for:
- CLI-based DataMagic operations
- API integration tests
- Backend functionality

**Playwright tests** - Add to `playwright/Magic Suite/DataMagic/` for:
- UI/UX issues
- Browser-based functionality
- Visual regression tests
- User interaction flows
