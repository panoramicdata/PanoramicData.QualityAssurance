# Check ReportMagic Macro Documentation Pages
# Environment: test2
# Date: December 18, 2025

Write-Host "`n=== Checking ReportMagic Macro Documentation ===" -ForegroundColor Cyan

$baseUrl = "https://docs.test2.magicsuite.net"

Write-Host "`nBase URL: $baseUrl" -ForegroundColor Yellow
Write-Host "`nChecking for ReportMagic macro documentation pages..." -ForegroundColor Yellow

# Try to access the docs site
try {
    $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
    Write-Host "Success: Docs site is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    
    # Check if there's a macro reference or similar page
    $content = $response.Content
    
    # Look for links that might lead to macro documentation
    if ($content -match "macro|Macro|report|Report") {
        Write-Host "Success: Found references to macros/reports in home page" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error accessing docs site: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nAttempting to find macro documentation pages..." -ForegroundColor Yellow

# Try common documentation patterns
$patterns = @(
    "/macros/reportmagic",
    "/reportmagic/macros",
    "/reference/macros",
    "/macros",
    "/report/macros"
)

foreach ($pattern in $patterns) {
    $url = "$baseUrl$pattern"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        Write-Host "Found page at: $url (Status: $($response.StatusCode))" -ForegroundColor Green
        
        # Check if page contains help examples
        if ($response.Content -match "example|Example|help|Help") {
            Write-Host "  Success: Page contains help/example content" -ForegroundColor Green
        }
        else {
            Write-Host "  Warning: No help/example content found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Not found: $url" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan
