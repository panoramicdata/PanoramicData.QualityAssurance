# MS-21863 Log Collection Script
# Searches Elastic for SharePoint-related logs and saves them to the MS-21863 folder

Write-Host "Collecting logs for MS-21863 - SharePoint File Copy Regression" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logFolder = "logs\MS-21863"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Ensure folder exists
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

Write-Host "1. Searching for SharePoint-related logs..." -ForegroundColor Yellow

# Simple SharePoint search query
$sharepointQuery = @{
    "bool" = @{
        "must" = @(
            @{ "match" = @{ "message" = "SharePoint" } }
        )
        "filter" = @{
            "range" = @{
                "@timestamp" = @{
                    "gte" = "2025-09-24T00:00:00Z"
                }
            }
        }
    }
}

try {
    $sharepointResult = .\.github\tools\Elastic.ps1 -Action "search" -Index "logs-*" -Parameters @{
        "Query" = $sharepointQuery
        "Size" = 100
    }
    
    $outputFile = "$logFolder\sharepoint-logs-$timestamp.json"
    $sharepointResult | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
    Write-Host "✓ SharePoint logs saved to: $outputFile" -ForegroundColor Green
    
    # Count hits
    if ($sharepointResult.hits -and $sharepointResult.hits.hits) {
        Write-Host "  Found $($sharepointResult.hits.hits.Count) SharePoint log entries" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Error searching SharePoint logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Searching for copy/file operation logs..." -ForegroundColor Yellow

# File copy operations query
$copyQuery = @{
    "bool" = @{
        "should" = @(
            @{ "match" = @{ "message" = "copy" } },
            @{ "match" = @{ "message" = "file not found" } },
            @{ "match" = @{ "message" = "not found" } },
            @{ "match" = @{ "message" = "temp" } }
        )
        "filter" = @{
            "range" = @{
                "@timestamp" = @{
                    "gte" = "2025-09-24T00:00:00Z"
                }
            }
        }
    }
}

try {
    $copyResult = .\.github\tools\Elastic.ps1 -Action "search" -Index "logs-*" -Parameters @{
        "Query" = $copyQuery
        "Size" = 100
    }
    
    $outputFile = "$logFolder\copy-operation-logs-$timestamp.json"
    $copyResult | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
    Write-Host "✓ Copy operation logs saved to: $outputFile" -ForegroundColor Green
    
    # Count hits
    if ($copyResult.hits -and $copyResult.hits.hits) {
        Write-Host "  Found $($copyResult.hits.hits.Count) copy operation log entries" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Error searching copy operation logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. Searching for CAE Portal Agent logs..." -ForegroundColor Yellow

# CAE Portal Agent query
$caeQuery = @{
    "bool" = @{
        "should" = @(
            @{ "match" = @{ "message" = "CAE" } },
            @{ "match" = @{ "message" = "portal" } },
            @{ "match" = @{ "message" = "agent" } }
        )
        "filter" = @{
            "range" = @{
                "@timestamp" = @{
                    "gte" = "2025-09-24T00:00:00Z"
                }
            }
        }
    }
}

try {
    $caeResult = .\.github\tools\Elastic.ps1 -Action "search" -Index "logs-*" -Parameters @{
        "Query" = $caeQuery
        "Size" = 100
    }
    
    $outputFile = "$logFolder\cae-agent-logs-$timestamp.json"
    $caeResult | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
    Write-Host "✓ CAE Portal Agent logs saved to: $outputFile" -ForegroundColor Green
    
    # Count hits
    if ($caeResult.hits -and $caeResult.hits.hits) {
        Write-Host "  Found $($caeResult.hits.hits.Count) CAE agent log entries" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Error searching CAE agent logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. Searching for error logs..." -ForegroundColor Yellow

# Error logs query 
$errorQuery = @{
    "bool" = @{
        "should" = @(
            @{ "match" = @{ "level" = "ERROR" } },
            @{ "match" = @{ "level" = "FATAL" } },
            @{ "match" = @{ "message" = "exception" } },
            @{ "match" = @{ "message" = "error" } }
        )
        "filter" = @{
            "range" = @{
                "@timestamp" = @{
                    "gte" = "2025-09-24T00:00:00Z"
                }
            }
        }
    }
}

try {
    $errorResult = .\.github\tools\Elastic.ps1 -Action "search" -Index "logs-*" -Parameters @{
        "Query" = $errorQuery
        "Size" = 100
    }
    
    $outputFile = "$logFolder\error-logs-$timestamp.json"
    $errorResult | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding UTF8
    Write-Host "✓ Error logs saved to: $outputFile" -ForegroundColor Green
    
    # Count hits
    if ($errorResult.hits -and $errorResult.hits.hits) {
        Write-Host "  Found $($errorResult.hits.hits.Count) error log entries" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Error searching error logs: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Log collection completed for MS-21863" -ForegroundColor Green
Write-Host "Check the logs\MS-21863\ folder for collected log files" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan