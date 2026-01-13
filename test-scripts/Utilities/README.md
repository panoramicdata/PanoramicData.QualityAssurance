# Test Utilities

Helper scripts, test data generators, and common test functions that support multiple test areas.

## Test Files

### test-jira-create.ps1
Test script for JIRA issue creation with verbose error handling.
- Validates JIRA API connectivity
- Tests issue creation with various field combinations
- Helps debug JIRA integration issues

## Test Categories

- ✅ JIRA integration testing
- ✅ API connectivity validation
- ✅ Helper functions for test scripts

## Running Tests

```powershell
.\test-scripts\Utilities\test-jira-create.ps1
```

## Adding New Utilities

Place scripts here for:
- Test data generation
- Common test helper functions
- Integration test utilities
- Test environment setup scripts
- Shared test configuration
