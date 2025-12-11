<#
.SYNOPSIS
    Runs Playwright regression tests against Magic Suite environments.

.DESCRIPTION
    This script runs Playwright tests for Magic Suite applications across different
    environments. It supports filtering by application and running in headed/headless mode.

.PARAMETER Environment
    The target environment to test against.
    Valid values: alpha, alpha2, test, test2, beta, staging, ps, production
    Default: alpha

.PARAMETER Apps
    Optional array of applications to test.
    Valid values: Www, Docs, DataMagic, AlertMagic, Admin, Connect, ReportMagic
    Default: All applications

.PARAMETER Headed
    Run tests with a visible browser window. Default is headless.

.PARAMETER Browser
    Browser to use for testing.
    Valid values: chromium, firefox, webkit
    Default: chromium

.PARAMETER Workers
    Number of parallel workers. Default: 1

.PARAMETER UpdateSnapshots
    Update baseline snapshots for visual comparisons.

.EXAMPLE
    .\RunRegressionTests.ps1 -Environment alpha
    Runs all tests against the alpha environment.

.EXAMPLE
    .\RunRegressionTests.ps1 -Environment staging -Apps AlertMagic,DataMagic
    Runs only AlertMagic and DataMagic tests against staging.

.EXAMPLE
    .\RunRegressionTests.ps1 -Environment test -Headed
    Runs all tests with a visible browser.

.EXAMPLE
    .\RunRegressionTests.ps1 -Environment production -Apps Www
    Runs only Www tests against production.

.NOTES
    Author: Panoramic Data QA Team
    Date: December 2025
    Requires: Node.js, Playwright
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('alpha', 'alpha2', 'test', 'test2', 'beta', 'staging', 'ps', 'production')]
    [string]$Environment = 'alpha',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Www', 'Docs', 'DataMagic', 'AlertMagic', 'Admin', 'Connect', 'ReportMagic')]
    [string[]]$Apps,

    [Parameter(Mandatory = $false)]
    [switch]$Headed,

    [Parameter(Mandatory = $false)]
    [ValidateSet('chromium', 'firefox', 'webkit')]
    [string]$Browser = 'chromium',

    [Parameter(Mandatory = $false)]
    [int]$Workers = 1,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateSnapshots
)

# Get the repository root directory
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$playwrightDir = Join-Path $repoRoot "playwright"
$testDir = Join-Path $playwrightDir "Magic Suite"

# Validate Playwright is available
Write-Host "Checking Playwright installation..." -ForegroundColor Cyan
try {
    $null = npx playwright --version 2>&1
    Write-Host "  Playwright is available" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: Playwright not found. Installing..." -ForegroundColor Yellow
    npx playwright install
}

# Build the URL mapping for the environment
$urlMappings = @{
    'www'     = if ($Environment -eq 'production') { 'https://www.magicsuite.net' } else { "https://www.$Environment.magicsuite.net" }
    'docs'    = if ($Environment -eq 'production') { 'https://docs.magicsuite.net' } else { "https://docs.$Environment.magicsuite.net" }
    'data'    = if ($Environment -eq 'production') { 'https://data.magicsuite.net' } else { "https://data.$Environment.magicsuite.net" }
    'alert'   = if ($Environment -eq 'production') { 'https://alert.magicsuite.net' } else { "https://alert.$Environment.magicsuite.net" }
    'admin'   = if ($Environment -eq 'production') { 'https://admin.magicsuite.net' } else { "https://admin.$Environment.magicsuite.net" }
    'connect' = if ($Environment -eq 'production') { 'https://connect.magicsuite.net' } else { "https://connect.$Environment.magicsuite.net" }
    'report'  = if ($Environment -eq 'production') { 'https://report.magicsuite.net' } else { "https://report.$Environment.magicsuite.net" }
}

Write-Host ""
Write-Host "=== Magic Suite Regression Tests ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Browser: $Browser" -ForegroundColor Yellow
Write-Host "Headed Mode: $($Headed.IsPresent)" -ForegroundColor Yellow
Write-Host "Workers: $Workers" -ForegroundColor Yellow
Write-Host ""

# Display URLs being tested
Write-Host "Target URLs:" -ForegroundColor Cyan
foreach ($key in $urlMappings.Keys | Sort-Object) {
    Write-Host "  $($key): $($urlMappings[$key])" -ForegroundColor Gray
}
Write-Host ""

# Set environment variable for tests to use
$env:MS_ENV = $Environment

# Build test file pattern based on selected apps
$testPattern = @()
if ($Apps -and $Apps.Count -gt 0) {
    foreach ($app in $Apps) {
        $appDir = Join-Path $testDir $app
        if (Test-Path $appDir) {
            $testPattern += Join-Path $appDir "*.spec.ts"
            Write-Host "Including tests from: $app" -ForegroundColor Green
        }
        else {
            Write-Host "WARNING: Test directory not found for $app at $appDir" -ForegroundColor Yellow
        }
    }
}
else {
    # Run all tests
    $testPattern += Join-Path $testDir "*/*.spec.ts"
    Write-Host "Running all application tests" -ForegroundColor Green
}

Write-Host ""

# Build Playwright command arguments
$playwrightArgs = @('playwright', 'test')

# Add test files/patterns
foreach ($pattern in $testPattern) {
    $playwrightArgs += $pattern
}

# Add browser
$playwrightArgs += '--project=' + $Browser

# Add headed mode if specified
if ($Headed) {
    $playwrightArgs += '--headed'
}

# Add workers
$playwrightArgs += "--workers=$Workers"

# Add update snapshots if specified
if ($UpdateSnapshots) {
    $playwrightArgs += '--update-snapshots'
}

# Add reporter
$playwrightArgs += '--reporter=list'

Write-Host "Running: npx $($playwrightArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

# Change to playwright directory and run tests
Push-Location $playwrightDir
try {
    $startTime = Get-Date
    
    # Run Playwright tests
    & npx @playwrightArgs
    
    $exitCode = $LASTEXITCODE
    $duration = (Get-Date) - $startTime
    
    Write-Host ""
    Write-Host "=== Test Run Complete ===" -ForegroundColor Cyan
    Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Yellow
    
    if ($exitCode -eq 0) {
        Write-Host "Status: PASSED" -ForegroundColor Green
    }
    else {
        Write-Host "Status: FAILED (Exit Code: $exitCode)" -ForegroundColor Red
    }
    
    exit $exitCode
}
finally {
    Pop-Location
    # Clean up environment variable
    Remove-Item Env:\MS_ENV -ErrorAction SilentlyContinue
}
