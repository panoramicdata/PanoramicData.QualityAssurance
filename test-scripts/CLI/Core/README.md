# CLI Core Tests

Tests for core MagicSuite CLI functionality including authentication, configuration, profiles, and basic CLI behavior.

## Test Files

### MagicSuite-CLI.Tests.ps1
General CLI command execution and validation tests.

### test-ms-22523.ps1
**Bug**: Profile list shows ? instead of checkmark for active profile
- Tests profile display in terminal
- Validates Unicode character rendering
- Checks auth status consistency

### test-ms-22558.ps1
**Bug**: MagicSuite CLI NuGet package missing DotnetToolSettings.xml
- Tests NuGet package integrity
- Validates .NET tool installation

## Test Categories

- ✅ Profile management
- ✅ Authentication status
- ✅ Configuration commands
- ✅ Package integrity

## Running Tests

```powershell
# Run all core tests
Get-ChildItem .\test-scripts\CLI\Core\*.ps1 | ForEach-Object { & $_.FullName }

# Run specific test
.\test-scripts\CLI\Core\test-ms-22523.ps1
```

## Adding New Tests

Place tests here for:
- Authentication and profile operations
- CLI configuration commands
- Version management
- Basic CLI infrastructure issues
