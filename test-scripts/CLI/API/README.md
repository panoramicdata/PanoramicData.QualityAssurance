# CLI API Tests

Tests for MagicSuite CLI API operations including entity CRUD operations, formatting, and API-specific bugs.

## Test Files

### test-ms-22521.ps1
**Bug**: Null Reference Exception when listing ReportBatchJobs
- Tests: `magicsuite api get reportbatchjobs`
- Validates entity retrieval
- Tests with `--verbose` and format options

### test-ms-22522.ps1
**Bug**: Malformed Markup Exception in table formatting
- Tests ReportSchedules and Connections in table format
- Tests JSON format output
- Includes stress tests with large result sets

## Test Categories

- ✅ Entity retrieval (get commands)
- ✅ Output formatting (Table vs JSON)
- ✅ API error handling
- ✅ Large result sets

## Common Test Patterns

```powershell
# Test entity retrieval
magicsuite --profile AmyTest2 api get {entity}

# Test with formatting
magicsuite --profile AmyTest2 api get {entity} --format Json
magicsuite --profile AmyTest2 api get {entity} --format Table

# Test with filters
magicsuite --profile AmyTest2 api get {entity} --filter {search}
```

## Running Tests

```powershell
# Run all API tests
Get-ChildItem .\test-scripts\CLI\API\*.ps1 | ForEach-Object { & $_.FullName }

# Run specific test
.\test-scripts\CLI\API\test-ms-22521.ps1
```

## Adding New Tests

Place tests here for:
- Entity-specific API bugs
- CRUD operation tests
- API formatting issues
- Entity retrieval problems
