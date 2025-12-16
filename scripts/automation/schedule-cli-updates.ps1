# Schedule Automated CLI Update Checks
# This script creates a Windows Task Scheduler job to automatically check for CLI updates

param(
    [ValidateSet("Hourly", "Every4Hours", "Daily", "TwiceDaily")]
    [string]$Frequency = "Every4Hours",
    
    [switch]$Remove
)

$taskName = "MagicSuite_CLI_Update_Check"
$scriptPath = Join-Path $PSScriptRoot "automated-update-check.ps1"

if ($Remove) {
    Write-Host "Removing scheduled task: $taskName..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Scheduled task removed" -ForegroundColor Green
    exit 0
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "Schedule MagicSuite CLI Update Checker" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

$trigger = switch ($Frequency) {
    "Hourly" {
        Write-Host "Setting up: Check every hour" -ForegroundColor Cyan
        New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([TimeSpan]::MaxValue)
    }
    "Every4Hours" {
        Write-Host "Setting up: Check every 4 hours" -ForegroundColor Cyan
        New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4) -RepetitionDuration ([TimeSpan]::MaxValue)
    }
    "Daily" {
        Write-Host "Setting up: Check once daily at 9 AM" -ForegroundColor Cyan
        New-ScheduledTaskTrigger -Daily -At "9:00AM"
    }
    "TwiceDaily" {
        Write-Host "Setting up: Check twice daily at 9 AM and 3 PM" -ForegroundColor Cyan
        $t1 = New-ScheduledTaskTrigger -Daily -At "9:00AM"
        $t2 = New-ScheduledTaskTrigger -Daily -At "3:00PM"
        @($t1, $t2)
    }
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WorkingDirectory $PSScriptRoot

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

try {
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Principal $principal -Description "Automatically checks for MagicSuite CLI updates and tests for bug fixes" | Out-Null
    
    Write-Host "`nScheduled task created successfully!" -ForegroundColor Green
    Write-Host "`nTask Details:" -ForegroundColor White
    Write-Host "  Name: $taskName" -ForegroundColor Gray
    Write-Host "  Frequency: $Frequency" -ForegroundColor Gray
    Write-Host "  Script: $scriptPath" -ForegroundColor Gray
    Write-Host "  Next Run: $((Get-ScheduledTaskInfo -TaskName $taskName).NextRunTime)" -ForegroundColor Gray
    
    Write-Host "`nTo manage this task:" -ForegroundColor Yellow
    Write-Host "  View: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Run Now: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Remove: .\schedule-cli-updates.ps1 -Remove" -ForegroundColor Gray
    Write-Host "  Or use Task Scheduler GUI: taskschd.msc" -ForegroundColor Gray
    
} catch {
    Write-Host "`nERROR creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
