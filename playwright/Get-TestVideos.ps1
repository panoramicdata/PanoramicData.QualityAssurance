# Quick Video Access Script
# Finds and opens test videos from the most recent Playwright test run

param(
    [Parameter(HelpMessage="Action to perform: list, list-runs, open-run, open-latest, open-failed, open-all, or open-report")]
    [ValidateSet("list", "list-runs", "open-run", "open-latest", "open-failed", "open-all", "open-report")]
    [string]$Action = "list",
    
    [Parameter(HelpMessage="Maximum number of videos to show")]
    [int]$Limit = 10,
    
    [Parameter(HelpMessage="Specific run ID to open (for open-run action)")]
    [string]$RunId = ""
)

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Get-VideoInfo {
    param([System.IO.FileInfo]$Video)
    
    # Parse the test name from the directory structure
    $testName = $Video.Directory.Name
    $status = if ($testName -match "failed") { "❌ FAILED" } 
              elseif ($testName -match "flaky") { "⚠️  FLAKY" }
              else { "✅ PASSED" }
    
    [PSCustomObject]@{
        TestName = $testName
        Status = $status
        Created = $Video.CreationTime
        Size = [Math]::Round($Video.Length / 1MB, 2)
        Path = $Video.FullName
        RelativePath = $Video.FullName -replace [regex]::Escape($PWD.Path), '.'
    }
}

# Change to playwright directory if not already there
if (Test-Path ".\playwright") {
    Push-Location ".\playwright"
    $shouldPop = $true
} else {
    $shouldPop = $false
}

try {
    # Find all video files
    $testResultsPath = ".\test-results"
    
    if (-not (Test-Path $testResultsPath)) {
        Write-Host "❌ No test results found!" -ForegroundColor Red
        Write-Host "   Run some tests first: npx playwright test" -ForegroundColor Yellow
        return
    }

    $videos = Get-ChildItem -Path $testResultsPath -Filter "video.webm" -Recurse -ErrorAction SilentlyContinue
    
    if ($videos.Count -eq 0) {
        Write-Host "❌ No videos found in test results!" -ForegroundColor Red
        Write-Host "   Videos are recorded automatically when tests run" -ForegroundColor Yellow
        Write-Host "   Check playwright.config.ts to ensure video recording is enabled" -ForegroundColor Yellow
        return
    }

    # Sort by creation time (newest first)
    $videos = $videos | Sort-Object CreationTime -Descending

    switch ($Action) {
        "list" {
            Write-Header "📹 Test Videos Found: $($videos.Count)"
            
            $displayVideos = if ($Limit -gt 0) { $videos | Select-Object -First $Limit } else { $videos }
            
            $videoInfo = $displayVideos | ForEach-Object { Get-VideoInfo $_ }
            
            $videoInfo | Format-Table -AutoSize -Property @(
                @{Label="Status"; Expression={$_.Status}},
                @{Label="Test Name"; Expression={$_.TestName}},
                @{Label="Created"; Expression={$_.Created.ToString("yyyy-MM-dd HH:mm:ss")}},
                @{Label="Size (MB)"; Expression={$_.Size}},
                @{Label="Path"; Expression={$_.RelativePath}}
            )
            
            Write-Host ""
            Write-Host "Quick Actions:" -ForegroundColor Cyan
            Write-Host "  .\Get-TestVideos.ps1 -Action list-runs       # View all test run sessions" -ForegroundColor Gray
            Write-Host "  .\Get-TestVideos.ps1 -Action open-latest    # Open most recent video" -ForegroundColor Gray
            Write-Host "  .\Get-TestVideos.ps1 -Action open-failed    # Open failed test videos" -ForegroundColor Gray
            Write-Host "  .\Get-TestVideos.ps1 -Action open-all       # Open all videos" -ForegroundColor Gray
            Write-Host "  .\Get-TestVideos.ps1 -Action open-report    # Open HTML video report" -ForegroundColor Gray
            Write-Host "  explorer test-results                        # Open folder in Explorer" -ForegroundColor Gray
            Write-Host ""
        }
        
        "list-runs" {
            Write-Header "📚 Test Run History"
            
            $indexFile = ".\test-results\video-reports\runs-index.json"
            
            if (-not (Test-Path $indexFile)) {
                Write-Host "❌ No test run history found!" -ForegroundColor Red
                Write-Host "   Run some tests to create history" -ForegroundColor Yellow
                return
            }
            
            $runs = Get-Content $indexFile | ConvertFrom-Json
            
            if ($runs.Count -eq 0) {
                Write-Host "No test runs recorded yet" -ForegroundColor Yellow
                return
            }
            
            Write-Host "Found $($runs.Count) test run(s)`n" -ForegroundColor White
            
            $runData = $runs | ForEach-Object {
                $startTime = [DateTime]::Parse($_.startTime)
                $endTime = [DateTime]::Parse($_.endTime)
                
                [PSCustomObject]@{
                    "Run #" = $runs.IndexOf($_) + 1
                    "Date" = $startTime.ToString("yyyy-MM-dd")
                    "Time" = $startTime.ToString("HH:mm:ss")
                    "Videos" = $_.videoCount
                    "Duration (s)" = $_.duration
                    "Run ID" = $_.runId
                    "Report Path" = "test-results\$($_.htmlPath)"
                }
            }
            
            $runData | Format-Table -AutoSize
            
            Write-Host ""
            Write-Host "Quick Actions:" -ForegroundColor Cyan
            Write-Host "  .\Get-TestVideos.ps1 -Action open-run -RunId ""<run-id>""  # Open specific run report" -ForegroundColor Gray
            Write-Host "  .\Get-TestVideos.ps1 -Action open-report                  # Open latest run report" -ForegroundColor Gray
            Write-Host "  explorer test-results\video-reports                        # Browse all runs" -ForegroundColor Gray
            Write-Host ""
        }
        
        "open-run" {
            if ([string]::IsNullOrWhiteSpace($RunId)) {
                Write-Host "❌ Please specify a RunId!" -ForegroundColor Red
                Write-Host "   Example: .\Get-TestVideos.ps1 -Action open-run -RunId ""run-2026-01-15T10-30-00""" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Available runs:" -ForegroundColor Cyan
                & $MyInvocation.MyCommand.Path -Action list-runs
                return
            }
            
            $htmlReport = ".\test-results\video-reports\$RunId\test-videos.html"
            
            if (Test-Path $htmlReport) {
                Write-Header "📊 Opening Test Run: $RunId"
                Write-Host "Report: $htmlReport" -ForegroundColor White
                Start-Process $htmlReport
            }
            else {
                Write-Host "❌ Report not found for run ID: $RunId" -ForegroundColor Red
                Write-Host "   Looking for: $htmlReport" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Available runs:" -ForegroundColor Yellow
                & $MyInvocation.MyCommand.Path -Action list-runs
            }
        }
        
        "open-latest" {
            if ($videos.Count -eq 0) { return }
            
            $latest = $videos | Select-Object -First 1
            Write-Header "▶️  Opening Latest Video"
            $info = Get-VideoInfo $latest
            Write-Host "Test: $($info.TestName)" -ForegroundColor White
            Write-Host "Time: $($info.Created)" -ForegroundColor Gray
            Write-Host "Path: $($info.RelativePath)" -ForegroundColor Gray
            Write-Host ""
            
            Start-Process $latest.FullName
        }
        
        "open-failed" {
            $failedVideos = $videos | Where-Object { $_.Directory.Name -match "failed" }
            
            if ($failedVideos.Count -eq 0) {
                Write-Host "✅ No failed test videos found!" -ForegroundColor Green
                return
            }
            
            Write-Header "❌ Opening Failed Test Videos: $($failedVideos.Count)"
            
            foreach ($video in $failedVideos) {
                $info = Get-VideoInfo $video
                Write-Host "▶️  $($info.TestName)" -ForegroundColor Red
                Start-Process $video.FullName
                Start-Sleep -Milliseconds 500  # Small delay between opens
            }
            
            Write-Host ""
            Write-Host "✅ Opened $($failedVideos.Count) failed test video(s)" -ForegroundColor Green
        }
        
        "open-all" {
            Write-Header "▶️  Opening All Videos: $($videos.Count)"
            
            if ($videos.Count -gt 5) {
                Write-Host "⚠️  WARNING: About to open $($videos.Count) videos!" -ForegroundColor Yellow
                $confirm = Read-Host "Continue? (y/N)"
                if ($confirm -ne "y" -and $confirm -ne "Y") {
                    Write-Host "Cancelled" -ForegroundColor Gray
                    return
                }
            }
            
            foreach ($video in $videos) {
                $info = Get-VideoInfo $video
                Write-Host "▶️  $($info.TestName)" -ForegroundColor White
                Start-Process $video.FullName
                Start-Sleep -Milliseconds 300  # Small delay between opens
            }
            
            Write-Host ""
            Write-Host "✅ Opened $($videos.Count) video(s)" -ForegroundColor Green
        }
        
        "open-report" {
            $htmlReport = ".\test-results\test-videos.html"
            
            if (Test-Path $htmlReport) {
                Write-Header "📊 Opening Video Report"
                Write-Host "Report: test-results\test-videos.html" -ForegroundColor White
                Start-Process $htmlReport
            }
            else {
                Write-Host "❌ Video report not found!" -ForegroundColor Red
                Write-Host "   The HTML report is generated automatically after running tests" -ForegroundColor Yellow
                Write-Host "   Run: npx playwright test" -ForegroundColor Gray
            }
        }
    }
}
finally {
    if ($shouldPop) {
        Pop-Location
    }
}
