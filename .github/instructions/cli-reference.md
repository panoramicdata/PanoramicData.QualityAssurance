# MagicSuite CLI Reference

## Critical Rules
- **Version 4.1.x ONLY** - Never use 4.2.x versions for testing
- **Always verify version** before running tests: `magicsuite --version`
- **Include version in bug reports** - Essential for reproducibility
- **Use --help liberally** - CLI has comprehensive help for every command

## Installation & Version Management

### Check Current Version
```powershell
magicsuite --version
# Expected: 4.1.* (or similar 4.1.x version; use `4.1.*` to install latest 4.1.x)
```

### Install Specific Version
```powershell
# Install latest 4.1.x (stable)
dotnet tool install -g MagicSuite.Cli --version '4.1.*'

# Install specific version
dotnet tool install -g MagicSuite.Cli --version '4.1.546'
```

### Installing Pre-Release Versions
The `--version '4.1.*'` pattern only matches stable releases. For pre-releases:

```powershell
# Step 1: Query NuGet API to find available pre-release versions
Invoke-RestMethod "https://api.nuget.org/v3-flatcontainer/magicsuite.cli/index.json" | 
    Select-Object -ExpandProperty versions | 
    Where-Object { $_ -like '4.1*' }

# Step 2: Install the specific pre-release version found
dotnet tool install -g MagicSuite.Cli --version '4.1.698-g9695777ce6'
```

**Note**: The `--prerelease` flag cannot be combined with `--version`, so you must query NuGet directly to find pre-release version strings.

### Update/Downgrade Version
```powershell
# Uninstall current version
dotnet tool uninstall -g MagicSuite.Cli

# Install desired version
dotnet tool install -g MagicSuite.Cli --version '4.1.*'

# Verify
magicsuite --version
```

### List Available Versions
```powershell
dotnet tool search MagicSuite.Cli --take 50
```

## Global Options

Available for ALL commands:

| Option | Description | Example |
|--------|-------------|---------|
| `--base-url` | MagicSuite instance URL | `--base-url https://test2.magicsuite.net` |
| `--profile` | Named configuration profile | `--profile test2-amy` |
| `--username` | Authentication username | `--username amy.bond` |
| `--password` | Authentication password | `--password P@ssw0rd` |
| `--output` | Output format (json/table/csv) | `--output json` |
| `--output-file` | Save output to file | `--output-file results.json` |
| `--verbose` | Detailed logging | `--verbose` |
| `--debug` | Debug mode logging | `--debug` |
| `--help` | Show help | `--help` |
| `--version` | Show version | `--version` |

## Authentication Methods

### 1. Profile (Recommended)
```powershell
# Create profile
magicsuite configure-profile --name test2-amy --base-url https://test2.magicsuite.net

# Use profile
magicsuite get --entity DataStore --profile test2-amy
```

### 2. Command Line
```powershell
magicsuite get --entity DataStore --base-url https://test2.magicsuite.net --username amy.bond --password P@ssw0rd
```

### 3. Environment Variables
```powershell
$env:MAGICSUITE_BASE_URL = "https://test2.magicsuite.net"
$env:MAGICSUITE_USERNAME = "amy.bond"
$env:MAGICSUITE_PASSWORD = "P@ssw0rd"

magicsuite get --entity DataStore
```

## Main Commands

### Get Entity
Retrieve single or multiple entities.

```powershell
# List all DataStores
magicsuite get --entity DataStore --profile test2-amy

# Get specific DataStore by ID
magicsuite get --entity DataStore --id 12345 --profile test2-amy

# Get with specific fields
magicsuite get --entity DataStore --fields Id,Name,Type --profile test2-amy

# JSON output
magicsuite get --entity DataStore --output json --profile test2-amy

# Save to file
magicsuite get --entity DataStore --output json --output-file datastores.json --profile test2-amy
```

### Query Entity
Advanced filtering and searching.

```powershell
# Query with filter
magicsuite query --entity DataStore --filter "Name eq 'Production'" --profile test2-amy

# Query with select fields
magicsuite query --entity DataStore --select Id,Name --profile test2-amy

# Query with ordering
magicsuite query --entity DataStore --orderby "Name desc" --profile test2-amy

# Complex query
magicsuite query --entity DataStore --filter "Type eq 'SQL' and Enabled eq true" --select Id,Name,Type --orderby Name --profile test2-amy
```

### Create Entity
Create new entities.

```powershell
# From JSON file
magicsuite create --entity DataStore --from-file datastore.json --profile test2-amy

# From inline JSON
$json = '{"Name":"TestStore","Type":"SQL","ConnectionString":"..."}'
magicsuite create --entity DataStore --from-json $json --profile test2-amy
```

### Update Entity
Modify existing entities.

```powershell
# Update from file
magicsuite update --entity DataStore --id 12345 --from-file updated-datastore.json --profile test2-amy

# Update specific fields
$json = '{"Name":"Updated Name","Enabled":true}'
magicsuite update --entity DataStore --id 12345 --from-json $json --profile test2-amy
```

### Delete Entity
Remove entities (use with caution!).

```powershell
# Delete by ID
magicsuite delete --entity DataStore --id 12345 --profile test2-amy

# Force delete (skip confirmation)
magicsuite delete --entity DataStore --id 12345 --force --profile test2-amy
```

### Execute
Execute DataStore queries or actions.

```powershell
# Execute query
magicsuite execute --entity DataStore --id 12345 --query "SELECT * FROM table" --profile test2-amy

# Execute with timeout
magicsuite execute --entity DataStore --id 12345 --query "SELECT * FROM table" --timeout 300 --profile test2-amy
```

## Entity Types

Common entities in MagicSuite:

| Entity | Purpose | Common Operations |
|--------|---------|-------------------|
| DataStore | Data connections | Get, Query, Execute |
| Report | Scheduled reports | Get, Query, Create, Update |
| Alert | Alert definitions | Get, Query, Create, Update |
| Schedule | Report schedules | Get, Query, Create, Update |
| User | User accounts | Get, Query |
| UserGroup | User groups | Get, Query |
| Portal | Portal instances | Get, Query |
| Dashboard | Dashboards | Get, Query, Create |
| DataMagicQuery | Saved queries | Get, Query, Create, Update |

### Get All Available Entities
```powershell
magicsuite get --help
# Look for "Available Entities" section
```

## Output Formats

### Table (Default)
Human-readable table format.
```powershell
magicsuite get --entity DataStore --output table --profile test2-amy
```

### JSON
Machine-readable JSON.
```powershell
magicsuite get --entity DataStore --output json --profile test2-amy
```

### CSV
Comma-separated values.
```powershell
magicsuite get --entity DataStore --output csv --profile test2-amy
```

## Exit Codes

CLI uses standard exit codes:

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 0 | Success | Command completed successfully |
| 1 | General error | Invalid arguments, unknown command |
| 2 | Authentication error | Invalid credentials, expired token |
| 3 | Not found | Entity doesn't exist |
| 4 | Validation error | Invalid input data |
| 5 | Permission denied | User lacks required permissions |
| 6 | Timeout | Operation took too long |
| 7 | Network error | Connection failed |

### Capture Exit Code
```powershell
magicsuite get --entity DataStore --profile test2-amy
$exitCode = $LASTEXITCODE
Write-Host "Exit code: $exitCode"

if ($exitCode -eq 0) {
    Write-Host "✓ Success"
} else {
    Write-Host "✗ Failed with code $exitCode"
}
```

## Common Patterns

### Testing API Endpoints
```powershell
# Test connection
magicsuite get --entity DataStore --profile test2-amy
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ API accessible"
}

# Test authentication
magicsuite get --entity User --profile test2-amy
if ($LASTEXITCODE -eq 2) {
    Write-Host "✗ Authentication failed"
}

# Test entity existence
magicsuite get --entity DataStore --id 12345 --profile test2-amy
if ($LASTEXITCODE -eq 3) {
    Write-Host "✗ DataStore not found"
}
```

### Bulk Operations
```powershell
# Export all DataStores
magicsuite get --entity DataStore --output json --output-file datastores-backup.json --profile test2-amy

# Process each DataStore
$datastores = Get-Content datastores-backup.json | ConvertFrom-Json
foreach ($ds in $datastores) {
    Write-Host "Processing: $($ds.Name)"
    # Do something with each DataStore
}
```

### Pipeline Integration
```powershell
# Get data and pipe to processing
magicsuite get --entity DataStore --output json --profile test2-amy | 
    ConvertFrom-Json | 
    Where-Object { $_.Type -eq 'SQL' } |
    ForEach-Object { Write-Host "SQL DataStore: $($_.Name)" }
```

## Running Report Schedules (Batch Jobs)

**Important**: To run a report schedule, you must create a ReportBatchJob. The CLI does not have a `create` command, so use the REST API directly.

### Understanding the Relationship
- **ReportSchedule** - Defines what reports to run, input/output folders, cron schedule
- **ReportBatchJob** - An execution instance of a schedule (created to trigger a run)
- **ReportJob** - Individual report jobs within a batch

### Finding Schedules
```powershell
# List all schedules (default limit is 100)
magicsuite api get reportschedules --profile test2 --tenant 1 --take 200

# Search by name
magicsuite api get reportschedules --profile test2 --tenant 1 --filter "Amy"

# Get schedule details
magicsuite api get-by-id reportschedule 27967 --profile test2 --format Json
```

### Creating a Batch Job (Run a Schedule) via REST API
```powershell
# Get profile credentials
$tokenName = "YOUR_TOKEN_NAME"
$tokenKey = "YOUR_TOKEN_KEY"
$apiUrl = "https://api.test2.magicsuite.net"
$scheduleId = 27967  # Amy Test schedule

# Create authorization header
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${tokenName}:${tokenKey}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
    "X-Tenant-Id" = "1"  # Panoramic Data tenant
}

# Create batch job payload
$body = @{
    reportScheduleId = $scheduleId
} | ConvertTo-Json

# POST to create batch job (triggers schedule run)
$result = Invoke-RestMethod -Uri "$apiUrl/api/ReportBatchJobs" `
    -Method POST `
    -Headers $headers `
    -Body $body

Write-Host "Created Batch Job ID: $($result.id)"
```

### Monitoring Batch Job Status
```powershell
# Get batch job status
magicsuite api get-by-id reportbatchjob $batchJobId --profile test2 --format Json

# List recent batch jobs for a schedule
magicsuite api get reportbatchjobs --profile test2 --tenant 1 --take 10 --orderby "-CreatedDateTimeUtc"
```

### Batch Job Execution Results
| Value | Meaning |
|-------|---------|
| 0 | Pending |
| 1 | Success |
| 2 | Partial Success |
| 3 | Failed |
| 4 | Cancelled |
| 5 | Timeout |
| 6 | No Reports |

## Common Pitfalls

### Version Issues
- ❌ **Wrong**: Using 4.2.x versions
- ✅ **Correct**: Always use 4.1.x versions
- **Result**: 4.2.x may have untested features or breaking changes

### Missing Profile
- ❌ **Wrong**: `magicsuite get --entity DataStore`
- ✅ **Correct**: `magicsuite get --entity DataStore --profile test2-amy`
- **Result**: Authentication error without profile or explicit credentials

### Output Confusion
- ❌ **Wrong**: Parsing table output as JSON
- ✅ **Correct**: Use `--output json` for structured data
- **Result**: Unreliable parsing of table-formatted output

### Exit Code Ignored
- ❌ **Wrong**: Not checking `$LASTEXITCODE`
- ✅ **Correct**: Always check exit code for automation
- **Result**: Scripts continue after errors

### File Paths
- ❌ **Wrong**: Relative paths without context
- ✅ **Correct**: Use absolute paths or ensure working directory
- **Result**: Files not found or created in unexpected locations

## Troubleshooting

### Connection Issues
```powershell
# Test connectivity
magicsuite get --entity DataStore --profile test2-amy --verbose

# Check base URL
magicsuite configure-profile --name test2-amy --show
```

### Authentication Problems
```powershell
# Recreate profile
magicsuite configure-profile --name test2-amy --base-url https://test2.magicsuite.net --force

# Test with explicit credentials
magicsuite get --entity DataStore --base-url https://test2.magicsuite.net --username amy.bond --password P@ssw0rd
```

### Debug Mode
```powershell
# Enable debug logging
magicsuite get --entity DataStore --profile test2-amy --debug

# Enable verbose output
magicsuite get --entity DataStore --profile test2-amy --verbose
```

## Help System

### Command Help
```powershell
# General help
magicsuite --help

# Command-specific help
magicsuite get --help
magicsuite query --help
magicsuite create --help

# Show all options
magicsuite get --entity DataStore --help
```

### Version Information
```powershell
# Show version
magicsuite --version

# Show detailed version with commit hash
magicsuite --version --verbose
```

## Test Environments

When testing CLI commands:

| Environment | URL | Profile Name |
|-------------|-----|--------------|
| test2 (default) | test2.magicsuite.net | test2-amy |
| test | test.magicsuite.net | test-amy |
| alpha2 | alpha2.magicsuite.net | alpha2-amy |
| alpha | alpha.magicsuite.net | alpha-amy |

**Create profiles for each environment to speed up testing!**

```powershell
# Create all profiles
magicsuite configure-profile --name test2-amy --base-url https://test2.magicsuite.net
magicsuite configure-profile --name test-amy --base-url https://test.magicsuite.net
magicsuite configure-profile --name alpha2-amy --base-url https://alpha2.magicsuite.net
magicsuite configure-profile --name alpha-amy --base-url https://alpha.magicsuite.net
```
