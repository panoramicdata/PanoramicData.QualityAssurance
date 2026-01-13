# CLI Output Tests

Tests for MagicSuite CLI output handling including file operations, formatting, and the `--output` parameter.

## Test Files

### test-ms-22564.ps1
**Bug**: --output parameter not working
- Tests JSON output to file
- Tests table output to file  
- Tests with relative and absolute paths

### test-ms-22612.ps1
**Bug**: --output to non-existent directory returns exit code 0
- Tests non-existent directory handling
- Tests nested non-existent directories
- Tests invalid path characters

## Test Categories

- ✅ File output operations
- ✅ Path handling (relative/absolute)
- ✅ Error handling for invalid paths
- ✅ Output format preservation

## Common Test Patterns

```powershell
# Output to file
magicsuite api get {entity} --output result.json --format Json
magicsuite api get {entity} --output result.txt --format Table

# Test with paths
magicsuite api get {entity} --output .\output\result.json
magicsuite api get {entity} --output C:\full\path\result.json

# Test error conditions
magicsuite api get {entity} --output .\nonexistent\result.json
```

## Running Tests

```powershell
# Run all output tests
Get-ChildItem .\test-scripts\CLI\Output\*.ps1 | ForEach-Object { & $_.FullName }

# Run specific test
.\test-scripts\CLI\Output\test-ms-22564.ps1
```

## Adding New Tests

Place tests here for:
- `--output` parameter bugs
- File write operations
- Path validation issues
- Output format problems
