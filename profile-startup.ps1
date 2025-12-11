# Auto-check for MagicSuite CLI updates on startup
$updateCheckFile = Join-Path $env:TEMP "magicsuite-last-check.txt"
$checkIntervalHours = 24

$shouldCheck = $false
if (Test-Path $updateCheckFile) {
    $lastCheck = Get-Content $updateCheckFile -ErrorAction SilentlyContinue
    if ($lastCheck) {
        $lastCheckTime = [DateTime]::Parse($lastCheck)
        $hoursSinceCheck = ((Get-Date) - $lastCheckTime).TotalHours
        if ($hoursSinceCheck -ge $checkIntervalHours) {
            $shouldCheck = $true
        }
    }
} else {
    $shouldCheck = $true
}

if ($shouldCheck) {
    Write-Host "`n[Checking for MagicSuite CLI updates...]" -ForegroundColor Cyan
    
    $currentVersion = magicsuite --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $updateOutput = dotnet tool update MagicSuite.Cli --global 2>&1 | Out-String
        
        if ($updateOutput -match "successfully updated from version") {
            $oldVer = if ($updateOutput -match "from version '([^']+)'") { $matches[1] } else { "unknown" }
            $newVer = if ($updateOutput -match "to version '([^']+)'") { $matches[1] } else { "unknown" }
            Write-Host "CLI UPDATED: $oldVer -> $newVer" -ForegroundColor Green
            
            Write-Host "[Running quick bug verification...]" -ForegroundColor Yellow
            $profileCheck = magicsuite config profiles list 2>&1 | Out-String
            if ($profileCheck -notmatch "\?") {
                Write-Host "  MS-22523 (Profile display): FIXED" -ForegroundColor Green
            }
        } elseif ($updateOutput -match "is up to date") {
            Write-Host "CLI up to date ($currentVersion)" -ForegroundColor Gray
        }
    }
    
    Get-Date | Out-File $updateCheckFile -Encoding UTF8
}
