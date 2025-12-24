# Check ReportMagic Macro Documentation for Help Examples
# Test Environment: test2.magicsuite.net
# Date: December 18, 2025

Write-Host "Starting Playwright test to check ReportMagic macro documentation..." -ForegroundColor Cyan

cd playwright

# Run Playwright test
npx playwright test --headed --project=chromium
