# Helper script to create JIRA feature request for CLI Visual Studio Code integration documentation

# Get credentials
$credTarget = "PanoramicData_JIRA"
$cred = $null

try {
    $credObject = Get-StoredCredential -Target $credTarget -ErrorAction SilentlyContinue
    if ($credObject) {
        $cred = $credObject
    }
} catch {
    if ($env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
        $securePassword = ConvertTo-SecureString $env:JIRA_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($env:JIRA_USERNAME, $securePassword)
    }
}

if (-not $cred) {
    Write-Error "No JIRA credentials found."
    exit 1
}

$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$($cred.GetNetworkCredential().Password)"))
    "Content-Type" = "application/json"
}

$summary = "Add Visual Studio Code integration documentation to CLI help page"

$description = @"
h2. Summary
Add documentation to the MagicSuite CLI help page explaining how to use the CLI effectively within Visual Studio Code, including terminal integration, task configuration, and workflow examples.

h2. Background
Users working in Visual Studio Code can benefit from integrated CLI workflows, but there is currently no documentation explaining best practices or setup steps. This documentation would help users:
* Configure VS Code tasks for common CLI operations
* Set up integrated terminal profiles
* Create snippets for frequently used commands
* Use output redirection effectively
* Debug CLI commands in VS Code environment

h2. Requested Documentation Sections

h3. 1. Terminal Integration
* Using the integrated terminal vs external terminal
* Configuring PowerShell/Bash profiles for the CLI
* Setting up multiple terminal profiles for different environments
* Terminal color scheme considerations

h3. 2. VS Code Tasks Configuration
Example tasks.json for common operations:
* Running API queries
* File operations (upload/download)
* Generating reports
* Running test suites

h3. 3. Output Handling
* Using {{--output}} parameter to save results to workspace files
* Piping CLI output to VS Code's search/replace
* Using JSON output format for further processing
* Viewing output files in VS Code editor

h3. 4. Workspace Integration
* Recommended workspace structure for CLI projects
* Using .vscode folder for shared team configurations
* Environment variable management in launch.json
* Profile switching for multi-environment workflows

h3. 5. Debugging and Troubleshooting
* Viewing verbose output in Output panel
* Using VS Code's problem matcher for CLI errors
* Debugging PowerShell scripts that call the CLI
* Common VS Code-specific issues and solutions

h3. 6. Productivity Tips
* Keyboard shortcuts for running CLI commands
* Creating snippets for common command patterns
* Using VS Code extensions that complement the CLI
* Automating workflows with tasks and keybindings

h2. Example Content Structure
{code:json}
// Example tasks.json for MagicSuite CLI in VS Code
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Get Tenants",
      "type": "shell",
      "command": "magicsuite api get tenants --format json --output tenants.json",
      "problemMatcher": []
    },
    {
      "label": "Check Auth Status", 
      "type": "shell",
      "command": "magicsuite auth status",
      "problemMatcher": []
    }
  ]
}
{code}

h2. Benefits
* Improved user experience for VS Code users (likely a large portion of users)
* Faster onboarding for new CLI users
* Standardized workflows across team members
* Better integration with existing development workflows
* Reduced support requests for VS Code-specific issues

h2. Suggested Location
Add a new section to the CLI help documentation:
* URL: [MagicSuite CLI Documentation]
* New section: "Using with Visual Studio Code"
* Consider adding to README.md in the CLI repository as well

h2. Related Resources
* VS Code Tasks Documentation: https://code.visualstudio.com/docs/editor/tasks
* VS Code Terminal Documentation: https://code.visualstudio.com/docs/terminal/basics
* PowerShell in VS Code: https://code.visualstudio.com/docs/languages/powershell

h2. Acceptance Criteria
* Documentation added to CLI help page with VS Code integration section
* Includes working examples of tasks.json configuration
* Covers terminal setup and profile configuration
* Provides troubleshooting guidance for common VS Code scenarios
* Includes screenshots or animated GIFs demonstrating key workflows
"@

$body = @{
    fields = @{
        project = @{ key = "MS" }
        issuetype = @{ name = "Task" }
        summary = $summary
        description = $description
        customfield_11200 = @("MagicSuite_R&D")
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 10
$utf8Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

try {
    Write-Host "Creating JIRA task for VS Code CLI documentation..."
    $response = Invoke-RestMethod -Uri "https://jira.panoramicdata.com/rest/api/2/issue" `
        -Method POST `
        -Headers $headers `
        -Body $utf8Body
    
    Write-Host "Successfully created issue: $($response.key)" -ForegroundColor Green
    Write-Host "URL: https://jira.panoramicdata.com/browse/$($response.key)" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to create JIRA issue: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}
