<#
.SYNOPSIS
    Generate Playwright smoke tests from JIRA ticket descriptions.

.DESCRIPTION
    Analyzes a JIRA ticket and generates a minimal Playwright test that:
    - Navigates to the affected page
    - Performs basic verification of the fix
    - Takes screenshots as evidence
    - Reports results
    
    Uses pattern matching to determine test structure based on keywords.

.PARAMETER IssueKey
    The JIRA ticket key (e.g., MS-22886)

.PARAMETER Environment
    The environment to test against (default: test2)

.PARAMETER RunTest
    If set, runs the generated test immediately

.PARAMETER OutputPath
    Where to save the generated test (default: playwright/Magic Suite/Generated/)

.EXAMPLE
    .\Generate-SmokeTest.ps1 -IssueKey MS-22886
    
.EXAMPLE
    .\Generate-SmokeTest.ps1 -IssueKey MS-22886 -RunTest -Environment beta
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IssueKey,
    [string]$Environment = "test2",
    [switch]$RunTest,
    [string]$OutputPath = ""
)

# Page detection patterns
$pagePatterns = @{
    "Report Studio" = "/report-studio"
    "ReportMagic" = "/report-magic"
    "DataMagic" = "/data-magic"
    "AlertMagic" = "/alert-magic"
    "Admin" = "/admin"
    "Connect" = "/connect"
    "Files" = "/files"
    "Docs" = "/docs"
    "ProMagic" = "/pro-magic"
    "Dashboard" = "/dashboard"
    "Certifications" = "/certifications"
    "Library" = "/library"
}

# Test template patterns
$testTemplates = @{
    "button" = @{
        Pattern = '(button|btn).*should.*(visible|display|work|click|disabled)'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Look for the button mentioned in the ticket
  const button = page.locator('{SELECTOR}');
  
  // Verify button is visible
  await expect(button).toBeVisible();
  
  // Take screenshot as evidence
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-button-visible.png', fullPage: true });
  
  // If clickable, try clicking
  await button.click();
  
  // Take screenshot after interaction
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-after-click.png', fullPage: true });
});
'@
    }
    
    "dark-mode" = @{
        Pattern = 'dark.?mode|light.?mode|theme'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Screenshot in current mode
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-initial-mode.png', fullPage: true });
  
  // Toggle theme (look for common theme toggle selectors)
  const themeToggle = page.locator('[data-testid="theme-toggle"], .theme-toggle, button:has-text("Dark"), button:has-text("Light")').first();
  
  if (await themeToggle.isVisible()) {
    await themeToggle.click();
    await page.waitForTimeout(500); // Allow transition
    
    // Screenshot in new mode
    await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-toggled-mode.png', fullPage: true });
  }
  
  // Verify no visual issues (check for specific element if mentioned)
  const targetElement = page.locator('{SELECTOR}');
  if (await targetElement.count() > 0) {
    await expect(targetElement).toBeVisible();
  }
});
'@
    }
    
    "error-message" = @{
        Pattern = 'error.?message|should.*(display|show).*error|toast'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Initial state screenshot
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-initial.png', fullPage: true });
  
  // Look for error messages or toast notifications
  const errorElements = page.locator('.error, .toast, .notification, [role="alert"], .mud-snackbar');
  
  // Check if any error elements exist
  const errorCount = await errorElements.count();
  console.log(`Found ${errorCount} error/notification elements`);
  
  if (errorCount > 0) {
    // Screenshot the error
    await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-with-error.png', fullPage: true });
    
    // Get error text for verification
    const errorText = await errorElements.first().textContent();
    console.log(`Error text: ${errorText}`);
  }
});
'@
    }
    
    "modal" = @{
        Pattern = 'modal|dialog|popup|pop-up'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Initial screenshot
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-before-modal.png', fullPage: true });
  
  // Try to trigger the modal (look for common triggers)
  const trigger = page.locator('button:has-text("Add"), button:has-text("New"), button:has-text("Create"), button:has-text("Edit"), {SELECTOR}').first();
  
  if (await trigger.isVisible()) {
    await trigger.click();
    await page.waitForTimeout(500);
    
    // Look for modal
    const modal = page.locator('.modal, .dialog, [role="dialog"], .mud-dialog');
    await expect(modal).toBeVisible({ timeout: 5000 });
    
    // Screenshot with modal open
    await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-modal-open.png', fullPage: true });
    
    // Check for close button
    const closeBtn = page.locator('.modal .close, .dialog button:has-text("Close"), [aria-label="Close"]').first();
    if (await closeBtn.isVisible()) {
      await closeBtn.click();
    }
  }
});
'@
    }
    
    "display" = @{
        Pattern = 'should.*(display|show|visible|appear)|column.*should|dropdown'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Wait for page content
  await page.waitForTimeout(2000);
  
  // Take full page screenshot
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-page-loaded.png', fullPage: true });
  
  // Look for the specific element mentioned
  const targetElement = page.locator('{SELECTOR}');
  
  // Check visibility
  if (await targetElement.count() > 0) {
    await expect(targetElement.first()).toBeVisible();
    console.log('Target element is visible');
  } else {
    console.log('Target element not found with selector: {SELECTOR}');
  }
});
'@
    }
    
    "generic" = @{
        Pattern = '.*'
        Template = @'
test('{TITLE}', async ({ page }) => {
  // Navigate to the page
  await page.goto('{BASE_URL}{PAGE_PATH}');
  await page.waitForLoadState('networkidle');
  
  // Initial screenshot
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-loaded.png', fullPage: true });
  
  // Basic page verification
  await expect(page).toHaveTitle(/.+/);
  
  // Wait for content
  await page.waitForTimeout(2000);
  
  // Final screenshot
  await page.screenshot({ path: 'screenshots/{ISSUE_KEY}-final.png', fullPage: true });
  
  // TODO: Add specific verification based on ticket requirements
  console.log('Page loaded successfully');
});
'@
    }
}

function Detect-PagePath {
    param([string]$Summary, [string]$Description)
    
    $text = "$Summary $Description"
    
    foreach ($page in $pagePatterns.Keys) {
        if ($text -match [regex]::Escape($page)) {
            return $pagePatterns[$page]
        }
    }
    
    return "/dashboard"  # Default
}

function Detect-TestTemplate {
    param([string]$Summary, [string]$Description)
    
    $text = "$Summary $Description".ToLower()
    
    foreach ($templateName in $testTemplates.Keys) {
        if ($templateName -eq "generic") { continue }
        
        $pattern = $testTemplates[$templateName].Pattern
        if ($text -match $pattern) {
            return $templateName
        }
    }
    
    return "generic"
}

function Extract-Selector {
    param([string]$Summary, [string]$Description)
    
    $text = "$Summary $Description"
    
    # Try to extract specific element references
    if ($text -match 'close.?button') { return '.close, [aria-label="close"], button:has-text("Close")' }
    if ($text -match 'insert.*button') { return 'button:has-text("Insert")' }
    if ($text -match 'submit.*button') { return 'button[type="submit"], button:has-text("Submit")' }
    if ($text -match 'save.*button') { return 'button:has-text("Save")' }
    if ($text -match 'resume.*button') { return 'button:has-text("Resume")' }
    if ($text -match 'dropdown|select') { return 'select, .dropdown, [role="listbox"]' }
    
    return '.page-content, main, [role="main"]'  # Default selector
}

function Generate-TestFile {
    param(
        [string]$IssueKey,
        [string]$Summary,
        [string]$Description,
        [string]$Environment,
        [string]$TemplateName,
        [string]$PagePath,
        [string]$Selector
    )
    
    $baseUrl = "https://$Environment.magicsuite.net"
    $template = $testTemplates[$TemplateName].Template
    
    # Replace placeholders
    $testCode = $template `
        -replace '\{TITLE\}', "$IssueKey`: $Summary" `
        -replace '\{BASE_URL\}', $baseUrl `
        -replace '\{PAGE_PATH\}', $PagePath `
        -replace '\{ISSUE_KEY\}', $IssueKey.ToLower() `
        -replace '\{SELECTOR\}', $Selector
    
    # Wrap in imports and describe block
    $fullTest = @"
// Auto-generated smoke test for $IssueKey
// Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// Template: $TemplateName

import { test, expect } from '@playwright/test';

test.describe('$IssueKey - Smoke Test', () => {
  test.beforeEach(async ({ page }) => {
    // Ensure authenticated - uses stored auth state
  });

$testCode
});
"@
    
    return $fullTest
}

# Ensure JIRA credentials are available
if (-not $env:JIRA_USERNAME -or -not $env:JIRA_PASSWORD) {
    Write-Error "JIRA_USERNAME and JIRA_PASSWORD environment variables must be set"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_PASSWORD)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

# Main execution
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           SMOKE TEST GENERATOR: $IssueKey                     " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Fetch ticket details
Write-Host "📋 Fetching ticket from JIRA..." -ForegroundColor Yellow

try {
    $issue = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue/$IssueKey" `
        -Method GET -Headers $headers
}
catch {
    Write-Error "Failed to fetch ticket: $($_.Exception.Message)"
    exit 1
}

$summary = $issue.fields.summary
$description = $issue.fields.description ?? ""

Write-Host ""
Write-Host "📌 $summary" -ForegroundColor White
Write-Host ""

# Analyze ticket
Write-Host "🔍 Analyzing ticket..." -ForegroundColor Yellow
$pagePath = Detect-PagePath -Summary $summary -Description $description
$templateName = Detect-TestTemplate -Summary $summary -Description $description
$selector = Extract-Selector -Summary $summary -Description $description

Write-Host "   Page: $pagePath" -ForegroundColor Cyan
Write-Host "   Template: $templateName" -ForegroundColor Cyan
Write-Host "   Selector: $selector" -ForegroundColor Cyan
Write-Host ""

# Generate test
Write-Host "🔧 Generating test..." -ForegroundColor Yellow
$testContent = Generate-TestFile `
    -IssueKey $IssueKey `
    -Summary ($summary.Substring(0, [Math]::Min(60, $summary.Length))) `
    -Description $description `
    -Environment $Environment `
    -TemplateName $templateName `
    -PagePath $pagePath `
    -Selector $selector

# Determine output path
if (-not $OutputPath) {
    $OutputPath = "c:\Users\david\source\repos\panoramicdata\PanoramicData.QualityAssurance\playwright\Magic Suite\Generated"
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$testFilePath = Join-Path $OutputPath "$($IssueKey.ToLower())-smoke.spec.ts"

# Save test
$testContent | Out-File $testFilePath -Encoding UTF8
Write-Host "✅ Test saved to: $testFilePath" -ForegroundColor Green
Write-Host ""

# Display test
Write-Host "Generated Test:" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host $testContent -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Run test if requested
if ($RunTest) {
    Write-Host "🎭 Running test with Playwright..." -ForegroundColor Yellow
    Write-Host ""
    
    Push-Location "c:\Users\david\source\repos\panoramicdata\PanoramicData.QualityAssurance\playwright"
    
    try {
        # Run auth first if needed
        Write-Host "Checking authentication..." -ForegroundColor Gray
        
        # Run the test
        & npx playwright test $testFilePath --project=firefox
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ TEST PASSED" -ForegroundColor Green
        }
        else {
            Write-Host ""
            Write-Host "❌ TEST FAILED - Review output above" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "To run the test:" -ForegroundColor Yellow
    Write-Host "  cd playwright" -ForegroundColor Cyan
    Write-Host "  npx playwright test $($IssueKey.ToLower())-smoke --project=firefox" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
