# CLI Exit Code Tests

Tests for MagicSuite CLI exit code behavior, especially for error conditions and invalid parameters.

## Test Files

### test-ms-22611.ps1
**Bug**: Negative --take parameter returns exit code 0
- Tests negative --take values
- Tests zero --take value
- Tests extremely large negative values
- Validates proper error exit codes

### test-ms-22611-simple.ps1
Simplified version of MS-22611 test for quick validation.

## Test Categories

- ✅ Parameter validation exit codes
- ✅ Error condition exit codes
- ✅ Invalid input handling
- ✅ Expected failure scenarios

## Expected Exit Codes

| Scenario | Expected Exit Code |
|----------|-------------------|
| Success | 0 |
| Invalid parameter | Non-zero (typically 1) |
| API error | Non-zero |
| File not found | Non-zero |
| Authentication error | Non-zero |

## Common Test Patterns

```powershell
# Test with invalid parameter
magicsuite api get {entity} --take -5
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Write-Host "❌ FAIL: Exit code should be non-zero for invalid parameter"
} else {
    Write-Host "✓ PASS: Exit code is $exitCode (expected non-zero)"
}
```

## Running Tests

```powershell
# Run all exit code tests
Get-ChildItem .\test-scripts\CLI\ExitCodes\*.ps1 | ForEach-Object { & $_.FullName }

# Run specific test
.\test-scripts\CLI\ExitCodes\test-ms-22611.ps1
```

## Adding New Tests

Place tests here for:
- Exit code validation bugs
- Parameter validation issues
- Error handling consistency
- Expected failure scenarios
