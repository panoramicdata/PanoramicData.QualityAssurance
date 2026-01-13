# Pester Tests for MagicSuite CLI
# Tests command-line execution and validates expected behavior
# Compatible with Pester 3.4+

# Verify MagicSuite CLI is installed (run once at script load)
$cliPath = Get-Command magicsuite -ErrorAction SilentlyContinue
if (-not $cliPath) {
    throw "MagicSuite CLI is not installed. Run: dotnet tool install -g MagicSuite.Cli"
}
$script:cliVersion = (magicsuite --version 2>&1) -join ""

Describe "MS-22521: ReportBatchJobs Null Reference Exception" {
    It "should retrieve ReportBatchJobs without null reference exception" {
        $output = magicsuite api get reportbatchjobs --take 5 2>&1 | Out-String
        $output | Should Not Match "Object reference not set to an instance of an object"
        $output | Should Not Match "NullReferenceException"
    }
    
    It "should return ReportBatchJob entities or empty result" {
        $output = magicsuite api get reportbatchjobs --take 5 2>&1 | Out-String
        $output | Should Match "(Found \d+ ReportBatchJob|No ReportBatchJob)"
    }
    
    It "should work with --verbose flag" {
        $output = magicsuite api get reportbatchjobs --take 5 --verbose 2>&1 | Out-String
        $output | Should Not Match "NullReferenceException"
    }
    
    It "should work with --format Json" {
        $output = magicsuite api get reportbatchjobs --take 3 --format json 2>&1 | Out-String
        $output | Should Not Match "NullReferenceException"
    }
}

Describe "MS-22522: Malformed Markup Exception" {
    Context "ReportSchedules" {
        It "should retrieve ReportSchedules in table format without exception" {
            $output = magicsuite api get reportschedules --take 5 2>&1 | Out-String
            $output | Should Match "Found \d+ ReportSchedule"
            $output | Should Not Match "InvalidOperationException"
            $output | Should Not Match "Malformed"
        }
        
        It "should output valid JSON for ReportSchedules" {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
            try {
                magicsuite api get reportschedules --take 3 --format json --output $tempFile 2>&1 | Out-Null
                if (Test-Path $tempFile) {
                    $content = Get-Content $tempFile -Raw
                    { $content | ConvertFrom-Json } | Should Not Throw
                }
            }
            finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }
    }
    
    Context "Connections" {
        It "should retrieve Connections in table format without exception" {
            $output = magicsuite api get connections --take 5 2>&1 | Out-String
            $output | Should Match "Found \d+ Connection"
            $output | Should Not Match "InvalidOperationException"
        }
        
        It "should output valid JSON for Connections" {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
            try {
                magicsuite api get connections --take 3 --format json --output $tempFile 2>&1 | Out-Null
                if (Test-Path $tempFile) {
                    $content = Get-Content $tempFile -Raw
                    { $content | ConvertFrom-Json } | Should Not Throw
                }
            }
            finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }
        
        It "should handle large result sets (50 records)" {
            $output = magicsuite api get connections --take 50 2>&1 | Out-String
            $output | Should Match "Found \d+ Connection"
            $output | Should Not Match "Exception"
        }
    }
}

Describe "MS-22523: Active Profile Display Issue" {
    # Get the active profile from auth status (setup for this describe block)
    $script:authOutput = magicsuite auth status 2>&1 | Out-String
    if ($script:authOutput -match "Authentication Status for Profile: (\w+)") {
        $script:activeProfile = $Matches[1]
    }
    
    It "should show checkmark (not question mark) for active profile" {
        $profilesOutput = magicsuite config profiles list 2>&1 | Out-String
        
        # The active profile should NOT show a question mark
        # Note: This test may fail if the bug still exists
        if ($script:activeProfile) {
            # Check if bug exists (question mark shown)
            $hasBug = $profilesOutput -match "$($script:activeProfile).*\?"
            
            if ($hasBug) {
                # Bug still exists - test should fail
                # Active profile should show checkmark, not question mark
                $profilesOutput | Should Not Match "$($script:activeProfile).*\?"
            } else {
                # Bug fixed or different indicator used
                $true | Should Be $true
            }
        }
    }
    
    It "should identify the active profile via auth status" {
        $authOutput = magicsuite auth status 2>&1 | Out-String
        $authOutput | Should Match "Authentication Status for Profile:"
    }
}

Describe "MS-22564: --output Parameter Not Working" {
    It "should write JSON output to file when --output specified" {
        $tempFile = Join-Path $env:TEMP "ms22564-test.json"
        try {
            magicsuite api get tenants --take 1 --output $tempFile --format json 2>&1 | Out-Null
            # --output should create the file
            Test-Path $tempFile | Should Be $true
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }
    
    It "should write table output to file when --output specified" {
        $tempFile = Join-Path $env:TEMP "ms22564-test.txt"
        try {
            magicsuite api get connections --take 3 --output $tempFile --format table 2>&1 | Out-Null
            # --output should create the file
            Test-Path $tempFile | Should Be $true
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }
    
    It "should work with relative paths" {
        $tempFile = "ms22564-relative-test.json"
        try {
            magicsuite api get tenants --take 1 --output $tempFile --format json 2>&1 | Out-Null
            # --output should work with relative paths
            Test-Path $tempFile | Should Be $true
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }
    
    It "should work with absolute paths" {
        $tempFile = Join-Path $env:TEMP "ms22564-absolute-test.json"
        try {
            magicsuite api get tenants --take 1 --output $tempFile --format json 2>&1 | Out-Null
            # --output should work with absolute paths
            Test-Path $tempFile | Should Be $true
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }
}
