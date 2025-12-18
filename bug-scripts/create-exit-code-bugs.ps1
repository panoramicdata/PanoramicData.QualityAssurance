# Script to create JIRA bugs for CLI exit code issues discovered during testing
# Date: 2024-12-18
# Bugs found: Multiple validation errors return exit code 0 instead of non-zero

$bugs = @(
    @{
        Summary = "MagicSuite CLI: Negative --take parameter returns exit code 0 on validation error"
        Description = @"
h3. Summary
When the CLI encounters a validation error for negative {{--take}} parameter, it displays an error message but returns exit code 0, making the error undetectable by scripts and automation.

h3. Environment
* CLI Version: 4.1.323+b1d2df9293
* Test Environment: test.magicsuite.net
* Test Date: $(Get-Date -Format 'yyyy-MM-dd')

h3. Steps to Reproduce
1. Run: {{magicsuite api get tenants --take -5}}
2. Observe error message: "The 'take' parameter must be greater than or equal to zero. (Parameter 'take') Actual value was -5."
3. Check exit code: {{`$LASTEXITCODE}}

h3. Expected Result
* Error message displayed: ✓
* Exit code should be non-zero (e.g., 1 or 2)

h3. Actual Result
* Error message displayed: ✓
* Exit code: 0 ✗

h3. Impact
* Scripts cannot detect validation errors
* Automation pipelines may continue after errors
* Inconsistent with CLI best practices (errors should return non-zero exit codes)

h3. Related Issues
This is related to MS-22608 (CLI returns exit code 0 on failure) but focuses specifically on parameter validation errors.

h3. Test Command
{code:powershell}
magicsuite api get tenants --take -5
Write-Host "Exit code: `$LASTEXITCODE"
{code}
"@
    },
    @{
        Summary = "MagicSuite CLI: --output to non-existent directory returns exit code 0 on file write error"
        Description = @"
h3. Summary
When the CLI encounters a file write error (non-existent directory for {{--output}} parameter), it displays an error message but returns exit code 0, making the error undetectable by scripts and automation.

h3. Environment
* CLI Version: 4.1.323+b1d2df9293
* Test Environment: test.magicsuite.net
* Test Date: $(Get-Date -Format 'yyyy-MM-dd')

h3. Steps to Reproduce
1. Run: {{magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"}}
2. Observe error message: "Could not find a part of the path 'C:\NonExistentDir\file.txt'."
3. Check exit code: {{`$LASTEXITCODE}}

h3. Expected Result
* Error message displayed: ✓
* Exit code should be non-zero (e.g., 1 or 2)

h3. Actual Result
* Error message displayed: ✓
* Exit code: 0 ✗

h3. Impact
* Scripts cannot detect file I/O errors
* Output may be expected in a file but silently fails
* Automation pipelines may continue after I/O errors
* Data loss risk if output redirection silently fails

h3. Related Issues
This is related to MS-22608 (CLI returns exit code 0 on failure) but focuses specifically on file I/O errors.

h3. Test Command
{code:powershell}
magicsuite api get tenants --take 1 --output "C:\NonExistentDir\file.txt"
Write-Host "Exit code: `$LASTEXITCODE"
{code}

h3. Recommendation
The CLI should create parent directories automatically (like {{mkdir -p}}) OR return a non-zero exit code when the directory doesn't exist.
"@
    }
)

# Create each bug in JIRA
foreach ($bug in $bugs) {
    Write-Host "`nCreating bug: $($bug.Summary)" -ForegroundColor Cyan
    
    try {
        $params = @{
            ProjectKey = "MS"
            IssueType = "Bug"
            Summary = $bug.Summary
            Description = $bug.Description
            customfield_11200 = @("MagicSuite_R&D")
        }
        
        $result = .\.github\tools\JIRA.ps1 -Action create -Parameters $params
        Write-Host "Created: $($result.key)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create bug: $($_.Exception.Message)"
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "`nBug creation complete!" -ForegroundColor Green
