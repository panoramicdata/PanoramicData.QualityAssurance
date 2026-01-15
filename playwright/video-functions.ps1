# PowerShell Profile Functions for Playwright Test Videos
# Add these to your PowerShell profile for quick access to test videos
# To edit profile: notepad $PROFILE

<#
.SYNOPSIS
    Quick access to Playwright test videos
.DESCRIPTION
    Functions to easily find and open test videos after running Playwright tests.
    Supports multiple test runs with timestamps for easy comparison.
.EXAMPLE
    Get-TestVideos                    # List recent videos
    Get-TestRunHistory                # View all test run sessions
    Open-LatestTestVideo              # Open most recent video
    Open-FailedTestVideos             # Open all failed test videos
    Open-TestVideoReport              # Open HTML video report
    Open-TestRun "run-2026-01-15..."  # Open specific test run
#>

function Get-TestVideos {
    <#
    .SYNOPSIS
        List all test videos from recent Playwright test runs
    #>
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="Maximum number of videos to display")]
        [int]$Limit = 10
    )
    
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action list -Limit $Limit
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action list -Limit $Limit
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action list -Limit $Limit
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
        Write-Host "   Make sure you're in the workspace root or playwright folder" -ForegroundColor Yellow
    }
}

function Get-TestRunHistory {
    <#
    .SYNOPSIS
        View all test run sessions with timestamps
    #>
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action list-runs
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action list-runs
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action list-runs
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
    }
}

function Open-TestRun {
    <#
    .SYNOPSIS
        Open a specific test run report by Run ID
    .PARAMETER RunId
        The Run ID of the test session (e.g., "run-2026-01-15T10-30-00")
    #>
    param(
        [Parameter(Mandatory=$true, HelpMessage="Run ID to open (e.g., run-2026-01-15T10-30-00)")]
        [string]$RunId
    )
    
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action open-run -RunId $RunId
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action open-run -RunId $RunId
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action open-run -RunId $RunId
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
    }
}

function Open-LatestTestVideo {
    <#
    .SYNOPSIS
        Open the most recent test video
    #>
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action open-latest
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action open-latest
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action open-latest
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
    }
}

function Open-FailedTestVideos {
    <#
    .SYNOPSIS
        Open all videos from failed tests
    #>
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action open-failed
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action open-failed
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action open-failed
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
    }
}

function Open-TestVideoReport {
    <#
    .SYNOPSIS
        Open the HTML video report in your browser
    #>
    $scriptPath = ".\playwright\Get-TestVideos.ps1"
    
    if (Test-Path $scriptPath) {
        & $scriptPath -Action open-report
    }
    elseif (Test-Path "..\Get-TestVideos.ps1") {
        & "..\Get-TestVideos.ps1" -Action open-report
    }
    elseif (Test-Path ".\Get-TestVideos.ps1") {
        & ".\Get-TestVideos.ps1" -Action open-report
    }
    else {
        Write-Host "❌ Get-TestVideos.ps1 not found!" -ForegroundColor Red
    }
}

function Open-TestVideosFolder {
    <#
    .SYNOPSIS
        Open the test-results folder in Windows Explorer
    #>
    if (Test-Path ".\playwright\test-results") {
        explorer ".\playwright\test-results"
    }
    elseif (Test-Path ".\test-results") {
        explorer ".\test-results"
    }
    else {
        Write-Host "❌ test-results folder not found!" -ForegroundColor Red
        Write-Host "   Run some Playwright tests first" -ForegroundColor Yellow
    }
}

# Aliases for convenience
Set-Alias -Name gtv -Value Get-TestVideos -Description "Quick alias for Get-TestVideos"
Set-Alias -Name gtrh -Value Get-TestRunHistory -Description "Quick alias for Get-TestRunHistory"
Set-Alias -Name latest-video -Value Open-LatestTestVideo -Description "Quick alias for Open-LatestTestVideo"
Set-Alias -Name failed-videos -Value Open-FailedTestVideos -Description "Quick alias for Open-FailedTestVideos"
Set-Alias -Name open-run -Value Open-TestRun -Description "Quick alias for Open-TestRun"

Write-Host "✅ Playwright video functions loaded!" -ForegroundColor Green
Write-Host "   Commands: Get-TestVideos, Get-TestRunHistory, Open-TestRun, Open-LatestTestVideo, Open-FailedTestVideos" -ForegroundColor Gray
Write-Host "   Aliases: gtv, gtrh, open-run, latest-video, failed-videos" -ForegroundColor Gray
