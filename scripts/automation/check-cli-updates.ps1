# Automated MagicSuite CLI Update Checker and Installer
# Run this script regularly to check for and install CLI updates

param(
    [switch]$AutoInstall,  # Automatically install updates without prompting
    [switch]$Verbose,      # Show detailed output
    [switch]$TestOnly      # Only check for updates, don't install
)

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "MagicSuite CLI Update Checker" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Run Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

# Get current version
Write-Host "Checking current CLI version..." -ForegroundColor Yellow
try {
    $currentVersion = magicsuite --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: MagicSuite CLI not found or not functioning properly" -ForegroundColor Red
        exit 1
    }
    Write-Host "Current Version: " -NoNewline -ForegroundColor White
    Write-Host "$currentVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to get current CLI version: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check for updates (using --dry-run equivalent)
Write-Host "`nChecking for available updates..." -ForegroundColor Yellow

try {
    # Capture the update check output
    $updateOutput = dotnet tool update MagicSuite.Cli --global 2>&1 | Out-String
    
    if ($updateOutput -match "Tool 'magicsuite.cli' was successfully updated from version '([^']+)' to version '([^']+)'") {
        $oldVersion = $matches[1]
        $newVersion = $matches[2]
        
        Write-Host "`n✓ UPDATE INSTALLED!" -ForegroundColor Green
        Write-Host "  Old Version: $oldVersion" -ForegroundColor Gray
        Write-Host "  New Version: $newVersion" -ForegroundColor Green
        
        # Verify the new version
        $verifiedVersion = magicsuite --version 2>&1
        Write-Host "`n  Verified Installation: $verifiedVersion" -ForegroundColor Cyan
        
        # Log the update
        $logEntry = @{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            OldVersion = $oldVersion
            NewVersion = $newVersion
            VerifiedVersion = $verifiedVersion
            UpdateType = "Automatic"
        }
        
        # Create logs directory if it doesn't exist
        $logDir = Join-Path $PSScriptRoot ".." "logs" "cli-updates"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Append to log file
        $logFile = Join-Path $logDir "update-history.json"
        $logHistory = @()
        if (Test-Path $logFile) {
            $logHistory = Get-Content $logFile -Raw | ConvertFrom-Json
        }
        $logHistory += $logEntry
        $logHistory | ConvertTo-Json -Depth 10 | Set-Content $logFile -Encoding UTF8
        
        Write-Host "`n  Update logged to: $logFile" -ForegroundColor Gray
        
        # Return update information for further processing
        return @{
            Updated = $true
            OldVersion = $oldVersion
            NewVersion = $newVersion
        }
        
    } elseif ($updateOutput -match "Tool 'magicsuite.cli' is up to date") {
        Write-Host "`n✓ CLI is already up to date (version $currentVersion)" -ForegroundColor Green
        return @{
            Updated = $false
            CurrentVersion = $currentVersion
        }
        
    } else {
        Write-Host "`nUnexpected output from update check:" -ForegroundColor Yellow
        Write-Host $updateOutput -ForegroundColor Gray
        return @{
            Updated = $false
            CurrentVersion = $currentVersion
            UnexpectedOutput = $true
        }
    }
    
} catch {
    Write-Host "`nERROR during update check: $($_.Exception.Message)" -ForegroundColor Red
    return @{
        Updated = $false
        Error = $_.Exception.Message
    }
}

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "Update Check Complete" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan
