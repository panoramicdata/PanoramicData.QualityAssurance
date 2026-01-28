<#
.SYNOPSIS
    Query Jira for tickets, users, or other entities using JQL or REST API parameters. Create tickets, add/update/delete comments, transition tickets, and set fix versions. Returns results as JSON.

.DESCRIPTION
    This script queries Jira using the REST API. It supports ticket queries (via JQL), user queries, creating new tickets,
    adding/updating/deleting comments on tickets, transitioning tickets through workflow states, and setting fix versions.
    Results are returned as JSON for easy parsing and automation. The script uses Basic Auth with
    username and password (or API token). Environment variables can be used to store credentials.

USAGE
    # Query tickets with common fields
    ./Jira.ps1 -Action query -QueryType tickets -Jql 'project = "Magic Suite" and priority = Trivial order by created desc' -MaxResults 5

    # Query with all fields
    ./Jira.ps1 -Action query -QueryType tickets -Jql 'assignee = currentUser()' -Fields all

    # Query with specific fields
    ./Jira.ps1 -Action query -QueryType tickets -Jql 'project = "Magic Suite"' -Fields custom -CustomFields 'key,summary,assignee,status'

    # List all users (discover accounts)
    ./Jira.ps1 -Action query -QueryType users -MaxResults 100

    # Search for specific users by name/email
    ./Jira.ps1 -Action query -QueryType users -UserSearch "david"

    # Search for users in a specific project
    ./Jira.ps1 -Action query -QueryType users -UserSearch "bond" -ProjectKey MS

    # Get tickets WITH comments (full history)
    ./Jira.ps1 -Action query -QueryType tickets -Jql 'project = "Magic Suite" and key = MS-22023' -IncludeComments

    # Create a new ticket
    ./Jira.ps1 -Action create -ProjectKey MS -Summary "Add Web.Query example for IP address" -Description "Added example to macro help" -IssueType Improvement -Priority Trivial -Component ReportMagic

    # Create an Epic
    ./Jira.ps1 -Action create -ProjectKey MS -Summary "Warning Elimination" -Description "Epic description" -IssueType Epic -Priority Major

    # Create a ticket with assignee and fix version
    ./Jira.ps1 -Action create -ProjectKey MS -Summary "Fix bug in macro" -Description "Description here" -IssueType Bug -Priority Major -Assignee "david.bond" -FixVersion "3.28.vNext"

    # Add comment to a ticket (simple)
    ./Jira.ps1 -Action comment -IssueKey MS-22023 -Comment "Work completed and ready for testing"

    # Update an existing comment
    ./Jira.ps1 -Action update-comment -IssueKey MS-22023 -CommentId 1778653 -Comment "Updated: Work completed and ready for testing"

    # Delete a comment
    ./Jira.ps1 -Action delete-comment -IssueKey MS-22023 -CommentId 1778653

    # Add formatted comment with Jira markup (use PowerShell backtick for newlines)
    # Jira markup reference:
    #   h1., h2., h3. = Headers
    #   *bold* = Bold text
    #   - item = Bullet list
    #   Use actual line breaks (PowerShell backtick-n: `n) for newlines
    ./Jira.ps1 -Action comment -IssueKey MS-22023 -Comment @"
h3. Deployment Complete

Deployed to *alpha3* environment.
- All tests passing
- Performance validated
"@

    # Link two issues together
    ./Jira.ps1 -Action link-issues -InwardIssue MS-22118 -OutwardIssue MS-22117 -LinkType "Relates"

    # List available transitions for a ticket
    ./Jira.ps1 -Action transitions -IssueKey MS-22023

    # Transition a ticket to a new status
    ./Jira.ps1 -Action transition -IssueKey MS-22023 -TransitionName "Ready for Test"

    # Set fix version for a ticket
    ./Jira.ps1 -Action set-fixversion -IssueKey MS-22052 -FixVersion "3.27.vNext"

    # Set sprint for a ticket (moves ticket to specified sprint)
    ./Jira.ps1 -Action set-sprint -IssueKey MS-22690 -Sprint "Magic Suite 4.1"

    # Attach file to a ticket
    ./Jira.ps1 -Action attach-file -IssueKey MS-22023 -FilePath "C:\path\to\file.txt"

    # Download file attachment from a ticket
    ./Jira.ps1 -Action download-attachment -IssueKey MS-22023 -AttachmentId 1778653 -OutputPath "C:\path\to\save\file.txt"

    # Get change history for a ticket
    ./Jira.ps1 -Action get-history -IssueKey MS-22023

    # Get change history filtered to a specific field (e.g., description changes only)
    ./Jira.ps1 -Action get-history -IssueKey MS-22023 -CustomFields "description"

NOTES
    - Jira tickets for Magic Suite have key prefix "MS" (e.g. MS-12345)
    - Default fields for tickets: key, summary, description, status, assignee, priority, created, updated
    - Use -Fields 'all' to get all available fields (large output)
    - Use -Fields 'custom' with -CustomFields for specific fields
    - If using Jira Cloud, pass an API token as Password and use your Atlassian account email as Username.
    - The script stores credentials in the current user's environment variables named JIRA_USERNAME and JIRA_PASSWORD.
    - You may set JIRA_BASEURL (user env var) to override the default base URL (https://jira.panoramicdata.com).
    - For multi-line comments, use PowerShell here-strings (@"..."@) to preserve line breaks and Jira markup.
    - To get a comment ID, use the query action with -IncludeComments flag
    - When creating tickets, common issue types are: Bug, Improvement, New Feature, Task, Epic
    - When creating Epics, the Summary is automatically used as the Epic Name field
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('query','create','comment','update-comment','delete-comment','transition','transitions','set-fixversion','set-sprint','update-ticket','link-issues','attach-file','download-attachment','get-history','list-components')]
    [string]$Action = 'query',

    [Parameter(Mandatory=$false)]
    [ValidateSet('tickets','users')]
    [string]$QueryType = 'tickets',
    
    [Parameter(Mandatory=$false)]
    [string]$Jql,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 50,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('default','all','custom')]
    [string]$Fields = 'default',
    
    [Parameter(Mandatory=$false)]
    [string]$CustomFields,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeComments,

    [Parameter(Mandatory=$false)]
    [string]$IssueKey,

    [Parameter(Mandatory=$false)]
    [string]$Comment,

    [Parameter(Mandatory=$false)]
    [string]$CommentId,

    [Parameter(Mandatory=$false)]
    [string]$TransitionName,

    [Parameter(Mandatory=$false)]
    [string]$TransitionId,

    [Parameter(Mandatory=$false)]
    [string]$FixVersion,
    
    # Parameters for create action
    [Parameter(Mandatory=$false)]
    [string]$ProjectKey,

    [Parameter(Mandatory=$false)]
    [string]$Summary,

    [Parameter(Mandatory=$false)]
    [string]$Description,

    [Parameter(Mandatory=$false)]
    [string]$IssueType = 'Task',

    [Parameter(Mandatory=$false)]
    [string]$Priority = 'Major',

    [Parameter(Mandatory=$false)]
    [string]$Assignee,

    [Parameter(Mandatory=$false)]
    [string]$Component,

    # Parameters for link-issues action
    [Parameter(Mandatory=$false)]
    [string]$InwardIssue,
    
    [Parameter(Mandatory=$false)]
    [string]$OutwardIssue,
  
    [Parameter(Mandatory=$false)]
    [string]$LinkType = 'Relates',
    
    # Parameters for attach-file and download-attachment actions
    [Parameter(Mandatory=$false)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$AttachmentId,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath,
    
    # Parameter for sprint management
    [Parameter(Mandatory=$false)]
    [string]$Sprint,
    
    # Parameters for user search
    [Parameter(Mandatory=$false)]
    [string]$UserSearch,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInactive,
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
  
    # Launch browser after ticket creation
    [Parameter(Mandatory=$false)]
    [switch]$OpenBrowser
)

# Helper function to get credentials from Windows Credential Manager
# This delegates to the dedicated Get-JiraCredentials.ps1 helper script
function Get-JiraCredentialsFromCredentialManager {
    $credentialScript = Join-Path $PSScriptRoot "Get-JiraCredentials.ps1"
    if (Test-Path $credentialScript) {
        try {
            $creds = & $credentialScript
            if ($creds -and $creds.Username -and $creds.Password) {
                return $creds
            }
        } catch {
            # Helper script failed - fall through to other methods
            Write-Verbose "Credential Manager helper script failed: $_"
        }
    }
    return $null
}

# Base URL: prefer env var if set (this one can stay as env var)
$BaseUrl = [Environment]::GetEnvironmentVariable('JIRA_BASEURL', 'User')
if (-not $BaseUrl) { $BaseUrl = 'https://jira.panoramicdata.com' }

# Credential priority:
# 1. Command line parameters (for automation/CI)
# 2. Windows Credential Manager (preferred persistent storage)
# 3. Environment variables (legacy - will be migrated and removed)
# 4. Prompt user (stores to Windows Credential Manager)

$JiraUser = $null
$JiraPass = $null

# Check command line first (for automation scenarios)
if ($Username) { $JiraUser = $Username }
if ($Password) { $JiraPass = $Password }

# Then Windows Credential Manager (preferred)
if (-not $JiraUser -or -not $JiraPass) {
    $credManagerCreds = Get-JiraCredentialsFromCredentialManager
    if ($credManagerCreds) {
        # The helper script handles migration from env vars automatically
        if (-not $JiraUser) { $JiraUser = $credManagerCreds.Username }
        if (-not $JiraPass) { $JiraPass = $credManagerCreds.Password }
    }
}

# If still missing, prompt and store in Windows Credential Manager
if (-not $JiraUser -or -not $JiraPass) {
    Write-Host "JIRA credentials required." -ForegroundColor Yellow
    Write-Host "JIRA URL: $BaseUrl" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $JiraUser) {
        $JiraUser = Read-Host "Enter your JIRA username"
    }
    if (-not $JiraPass) {
        Write-Host "Enter your JIRA password or API token (input will be hidden)" -ForegroundColor Cyan
        $securePass = Read-Host -AsSecureString
        $JiraPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
    }
    
    # Store in Windows Credential Manager (not environment variables)
    $CredentialTarget = "PanoramicData.JIRA"
    $result = cmdkey /generic:$CredentialTarget /user:$JiraUser /pass:$JiraPass 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Credentials stored in Windows Credential Manager under '$CredentialTarget'" -ForegroundColor Green
    } else {
        Write-Warning "Could not store credentials in Windows Credential Manager: $result"
    }
}

# Build Authorization header manually
$pair = $JiraUser + ':' + $JiraPass
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$AuthHeader = @{ Authorization = "Basic $base64" }

function Invoke-JiraApi {
    param(
        [string]$Url,
        [string]$Method = 'GET',
        [object]$Body = $null
    )
    try {
        $params = @{
            Uri = $Url
            Headers = $AuthHeader
            Method = $Method
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
            $params['ContentType'] = 'application/json'
        }
        
        return Invoke-RestMethod @params
    } catch {
        $errorMessage = $_.Exception.Message
        
        # Try to get detailed error from response
        if ($_.ErrorDetails.Message) {
            Write-Host "Jira API Error Details:" -ForegroundColor Red
            Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
            $errorMessage = $_.ErrorDetails.Message
        }
        
        Write-Error "Jira API Error: $errorMessage"
        return $null
    }
}

function Get-JiraComments {
    param(
        [string]$IssueKey
    )
    
    $startAt = 0
    $maxResults = 100  # Jira comment pagination limit
    $allComments = @()
    
    while ($true) {
        $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/comment?startAt=$startAt&maxResults=$maxResults"
        $Response = Invoke-JiraApi -Url $Url
        if ($null -eq $Response) { 
            Write-Warning "Failed to retrieve comments for $IssueKey"
            return @()
        }
        
        $allComments += $Response.comments
        $startAt += $maxResults
        
        # Check if we've retrieved all comments
        if ($allComments.Count -ge $Response.total) { break }
    }
    
    # Format comments for better readability
    return $allComments | ForEach-Object {
        [PSCustomObject]@{
            id = $_.id
            author = if($_.author) { $_.author.displayName } else { 'Unknown' }
            authorEmail = if($_.author) { $_.author.emailAddress } else { $null }
            created = $_.created
            updated = $_.updated
            body = $_.body
            # Include visibility if the comment is restricted
            visibility = if($_.visibility) { 
                "$($_.visibility.type): $($_.visibility.value)" 
            } else { 
                'public' 
            }
        }
    }
}

function Add-JiraComment {
    param(
        [string]$IssueKey,
        [string]$CommentText
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for adding comments.'
        exit 10
    }
    
    if (-not $CommentText) {
        Write-Error 'Comment parameter is required for adding comments.'
        exit 11
    }
    
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/comment"
    $Body = @{
        body = $CommentText
    }
    
    Write-Host "Adding comment to $IssueKey..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url -Method 'POST' -Body $Body
    
    if ($null -eq $Response) { 
        Write-Error "Failed to add comment to $IssueKey"
        exit 12
    }
    
    Write-Host "Comment added successfully to $IssueKey" -ForegroundColor Green
    Write-Host "Comment ID: $($Response.id)" -ForegroundColor Gray
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $Response
}

function Update-JiraComment {
    param(
        [string]$IssueKey,
        [string]$CommentId,
        [string]$CommentText
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for updating comments.'
        exit 50
    }
    
    if (-not $CommentId) {
        Write-Error 'CommentId parameter is required for updating comments.'
        exit 51
    }
    
    if (-not $CommentText) {
        Write-Error 'Comment parameter is required for updating comments.'
        exit 52
    }
    
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/comment/$CommentId"
    $Body = @{
        body = $CommentText
    }
    
    Write-Host "Updating comment $CommentId on $IssueKey..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url -Method 'PUT' -Body $Body
    
    if ($null -eq $Response) { 
        Write-Error "Failed to update comment $CommentId on $IssueKey"
        exit 53
    }
    
    Write-Host "Comment $CommentId updated successfully on $IssueKey" -ForegroundColor Green
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $Response
}

function Remove-JiraComment {
    param(
        [string]$IssueKey,
        [string]$CommentId
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for deleting comments.'
        exit 60
    }
    
    if (-not $CommentId) {
        Write-Error 'CommentId parameter is required for deleting comments.'
        exit 61
    }
    
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/comment/$CommentId"
    
    Write-Host "Deleting comment $CommentId from $IssueKey..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url -Method 'DELETE'
    
    # DELETE returns 204 No Content on success, so null response is expected
    Write-Host "Comment $CommentId deleted successfully from $IssueKey" -ForegroundColor Green
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $true
}

function Get-JiraTransitions {
    param(
        [string]$IssueKey
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for getting transitions.'
        exit 20
    }
    
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/transitions"
    
    Write-Host "Getting available transitions for $IssueKey..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url
    
    if ($null -eq $Response) { 
        Write-Error "Failed to get transitions for $IssueKey"
        exit 21
    }
    
    Write-Host "Found $($Response.transitions.Count) available transition(s)" -ForegroundColor Green
    
    return $Response.transitions | ForEach-Object {
        [PSCustomObject]@{
            id = $_.id
            name = $_.name
            to = $_.to.name
            hasScreen = $_.hasScreen
        }
    }
}

function Invoke-JiraTransition {
    param(
        [string]$IssueKey,
        [string]$TransitionName,
        [string]$TransitionId,
        [string]$FixVersion
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for transitions.'
        exit 30
    }
    
    if (-not $TransitionName -and -not $TransitionId) {
        Write-Error 'Either TransitionName or TransitionId parameter is required.'
        exit 31
    }
    
    # IMPORTANT: When transitioning to "Send to test", FixVersion is REQUIRED
    # Auto-detect from branch if not provided
    $isSendToTest = $TransitionName -eq 'Send to test'
    if ($isSendToTest) {
        if (-not $FixVersion) {
            # Try to auto-detect from current git branch
            try {
                $currentBranch = git branch --show-current 2>$null
                if ($currentBranch -match 'release/(\d+\.\d+)') {
                    $version = $matches[1]
                    $FixVersion = "$version.vNext"
                    Write-Host "Auto-detected fix version from branch '$currentBranch': $FixVersion" -ForegroundColor Yellow
                }
            } catch {
                # Git not available or not in a git repository
            }
        }
        
        if (-not $FixVersion) {
            Write-Error "FixVersion parameter is REQUIRED when transitioning to 'Send to test'. Use -FixVersion parameter (e.g., '4.1.vNext' for release/4.1 branch, '4.2.vNext' for release/4.2 branch)."
            exit 33
        }
        
        Write-Host "Setting fix version to '$FixVersion' for $IssueKey..." -ForegroundColor Cyan
    }
    
    # If TransitionName is provided, look up the ID
    if ($TransitionName -and -not $TransitionId) {
        Write-Host "Looking up transition ID for '$TransitionName'..." -ForegroundColor Cyan
        $transitions = Get-JiraTransitions -IssueKey $IssueKey
        $transition = $transitions | Where-Object { $_.name -eq $TransitionName }
        
        if (-not $transition) {
            Write-Error "Transition '$TransitionName' not found for $IssueKey. Available transitions:"
            $transitions | ForEach-Object { Write-Host "  - $($_.name) (ID: $($_.id)) -> $($_.to)" -ForegroundColor Yellow }
            exit 32
        }
        
        $TransitionId = $transition.id
        Write-Host "Found transition ID: $TransitionId" -ForegroundColor Gray
    }
    
    # Set the fix version BEFORE transitioning (for "Send to test")
    if ($isSendToTest -and $FixVersion) {
        Set-JiraFixVersion -IssueKey $IssueKey -FixVersion $FixVersion
    }
    
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/transitions"
    $Body = @{
        transition = @{
            id = $TransitionId
        }
    }
    
    Write-Host "Transitioning $IssueKey..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url -Method 'POST' -Body $Body
    
    # Transitions return 204 No Content on success, so null response is expected
    Write-Host "Transition completed successfully for $IssueKey" -ForegroundColor Green
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $true
}

function Set-JiraFixVersion {
    param(
        [string]$IssueKey,
        [string]$FixVersion
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for setting fix version.'
        exit 40
    }
    
    if (-not $FixVersion) {
        Write-Error 'FixVersion parameter is required for setting fix version.'
        exit 41
    }
    
    Write-Host "Setting fix version for $IssueKey to '$FixVersion'..." -ForegroundColor Cyan
    
    # First, check if the version exists in the project
    # Get the project key from the issue key (e.g., "MS" from "MS-22052")
    $projectKey = $IssueKey.Split('-')[0]
    
    # Get all versions for the project
    $versionsUrl = "$BaseUrl/rest/api/2/project/$projectKey/versions"
    $versions = Invoke-JiraApi -Url $versionsUrl
    
    if ($null -eq $versions) {
        Write-Error "Failed to retrieve versions for project $projectKey"
        exit 42
    }
    
    # Find the version by name
    $version = $versions | Where-Object { $_.name -eq $FixVersion }
    
    if (-not $version) {
        Write-Warning "Version '$FixVersion' does not exist in project $projectKey. Creating it..."
        
        # Create the version
        $createVersionUrl = "$BaseUrl/rest/api/2/version"
        $createBody = @{
            name = $FixVersion
            project = $projectKey
            released = $false
        }
        
        $version = Invoke-JiraApi -Url $createVersionUrl -Method 'POST' -Body $createBody
        
        if ($null -eq $version) {
            Write-Error "Failed to create version '$FixVersion' in project $projectKey"
            exit 43
        }
        
        Write-Host "Created version '$FixVersion' (ID: $($version.id))" -ForegroundColor Green
    } else {
        Write-Host "Found existing version '$FixVersion' (ID: $($version.id))" -ForegroundColor Gray
    }
    
    # Update the issue with the fix version
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey"
    $Body = @{
        fields = @{
            fixVersions = @(
                @{
                    name = $FixVersion
                }
            )
        }
    }
    
    $Response = Invoke-JiraApi -Url $Url -Method 'PUT' -Body $Body
    
    # PUT returns 204 No Content on success, so null response is expected
    Write-Host "Fix version set successfully for $IssueKey" -ForegroundColor Green
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $true
}

function Set-JiraSprint {
    param(
        [string]$IssueKey,
        [string]$SprintName
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for setting sprint.'
        exit 110
    }
    
    if (-not $SprintName) {
        Write-Error 'Sprint parameter is required for setting sprint.'
        exit 111
    }
    
    Write-Host "Setting sprint for $IssueKey to '$SprintName'..." -ForegroundColor Cyan
    
    # Get the project key from the issue key (e.g., "MS" from "MS-22052")
    $projectKey = $IssueKey.Split('-')[0]
    
    # First, we need to find the board ID for this project
    # The Agile API uses boards, not projects directly
    $boardsUrl = "$BaseUrl/rest/agile/1.0/board?projectKeyOrId=$projectKey"
    $boards = Invoke-JiraApi -Url $boardsUrl
    
    if ($null -eq $boards -or $null -eq $boards.values -or $boards.values.Count -eq 0) {
        Write-Error "No Scrum/Kanban board found for project $projectKey"
        exit 112
    }
    
    # Use the first board (typically there's only one per project)
    $boardId = $boards.values[0].id
    $boardName = $boards.values[0].name
    Write-Host "Found board: $boardName (ID: $boardId)" -ForegroundColor Gray
    
    # Get all sprints for this board
    $sprintsUrl = "$BaseUrl/rest/agile/1.0/board/$boardId/sprint?state=active,future"
    $sprints = Invoke-JiraApi -Url $sprintsUrl
    
    if ($null -eq $sprints -or $null -eq $sprints.values) {
        Write-Error "Failed to retrieve sprints for board $boardId"
        exit 113
    }
    
    # Find the sprint by name (partial match supported)
    $sprint = $sprints.values | Where-Object { $_.name -like "*$SprintName*" }
    
    if (-not $sprint) {
        Write-Error "Sprint matching '$SprintName' not found. Available sprints:"
        $sprints.values | ForEach-Object { Write-Host "  - $($_.name) (ID: $($_.id), State: $($_.state))" -ForegroundColor Yellow }
        exit 114
    }
    
    # If multiple matches, take the first one
    if ($sprint -is [array]) {
        Write-Host "Multiple sprints match '$SprintName', using: $($sprint[0].name)" -ForegroundColor Yellow
        $sprint = $sprint[0]
    }
    
    Write-Host "Found sprint: $($sprint.name) (ID: $($sprint.id), State: $($sprint.state))" -ForegroundColor Gray
    
    # Move the issue to the sprint using the Agile API
    $moveUrl = "$BaseUrl/rest/agile/1.0/sprint/$($sprint.id)/issue"
    $Body = @{
        issues = @($IssueKey)
    }
    
    $Response = Invoke-JiraApi -Url $moveUrl -Method 'POST' -Body $Body
    
    # POST returns 204 No Content on success, so null response is expected
    Write-Host "Sprint set successfully for $IssueKey" -ForegroundColor Green
    Write-Host "Sprint: $($sprint.name)" -ForegroundColor Gray
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
    return $true
}

function Update-JiraTicket {
 param(
   [string]$IssueKey,
        [string]$Summary,
        [string]$Description,
     [string]$Assignee,
        [string]$Priority
    )
    
 if (-not $IssueKey) {
      Write-Error 'IssueKey parameter is required for updating tickets.'
        exit 45
    }
    
  Write-Host "Updating ticket $IssueKey..." -ForegroundColor Cyan
    
    # Build the update payload with only the fields that were provided
    $fields = @{}
    
    if ($Summary) {
  $fields['summary'] = $Summary
 Write-Host "  Setting summary: $Summary" -ForegroundColor Gray
    }
    
  if ($Description) {
      $fields['description'] = $Description
    Write-Host "  Setting description" -ForegroundColor Gray
    }
    
    if ($Assignee) {
        $fields['assignee'] = @{ name = $Assignee }
        Write-Host "  Setting assignee: $Assignee" -ForegroundColor Gray
    }
    
    if ($Priority) {
        $fields['priority'] = @{ name = $Priority }
        Write-Host "  Setting priority: $Priority" -ForegroundColor Gray
    }

    if ($fields.Count -eq 0) {
        Write-Warning "No fields specified to update for $IssueKey"
        return $false
    }
    
  $Url = "$BaseUrl/rest/api/2/issue/$IssueKey"
    $Body = @{ fields = $fields }
    
  $Response = Invoke-JiraApi -Url $Url -Method 'PUT' -Body $Body
    
    # PUT returns 204 No Content on success, so null response is expected
    Write-Host "Ticket updated successfully: $IssueKey" -ForegroundColor Green
    Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
    
  return $true
}

function Get-AutoFixVersion {
    param(
        [string]$ProjectKey,
        [string]$ProvidedFixVersion
    )
    
    # If a fix version was explicitly provided, use it
    if ($ProvidedFixVersion) {
        return $ProvidedFixVersion
    }
    
    # Try to detect from current git branch
    try {
        $currentBranch = git branch --show-current 2>$null
        if ($currentBranch -match 'release/(\d+\.\d+)') {
            $version = $matches[1]
            $autoFixVersion = "$version.vNext"
            Write-Host "Auto-detected fix version from branch '$currentBranch': $autoFixVersion" -ForegroundColor Gray
            return $autoFixVersion
        }
    } catch {
        # Git not available or not in a git repository
    }
    
    return $null
}

function New-JiraIssue {
    param(
        [string]$ProjectKey,
        [string]$Summary,
        [string]$Description,
        [string]$IssueType,
        [string]$Priority,
        [string]$Assignee,
        [string]$Component,
        [string]$FixVersion
    )
    
    if (-not $ProjectKey) {
        Write-Error 'ProjectKey parameter is required for creating tickets.'
        exit 70
    }
    
    if (-not $Summary) {
        Write-Error 'Summary parameter is required for creating tickets.'
        exit 71
    }
    
    # NOTE: Fix versions should ONLY be set when work is complete and merged
    # DO NOT auto-detect fix version during ticket creation
    
    Write-Host "Creating new $IssueType in project $ProjectKey..." -ForegroundColor Cyan
  
    # Build the issue fields
    $fields = @{
      project = @{
         key = $ProjectKey
     }
        summary = $Summary
      issuetype = @{
         name = $IssueType
        }
    }
 
    # Add description if provided
    if ($Description) {
        $fields['description'] = $Description
    }
    
    # Add priority if provided
    if ($Priority) {
        $fields['priority'] = @{
            name = $Priority
        }
    }
    
    # Add assignee if provided
    if ($Assignee) {
        $fields['assignee'] = @{
        name = $Assignee
        }
    }
    
    # Add component if provided
    if ($Component) {
        $fields['components'] = @(
       @{
       name = $Component
 }
)
    }
    
    # Add Toggl Project custom field (REQUIRED field - must be on create screen)
    if ($ProjectKey -eq 'MS') {
		$fields['customfield_11200'] = @('MagicSuite_R&D')
    }
    elseif ($ProjectKey -eq 'BC') {
		$fields['customfield_11200'] = @('Blazor_Components_R&D')
    }
    
  # Add Epic Name field if creating an Epic (customfield_10304 is the Epic Name field)
if ($IssueType -eq 'Epic') {
        $fields['customfield_10304'] = $Summary
    }
    
    $Url = "$BaseUrl/rest/api/2/issue"
    $Body = @{
        fields = $fields
 }
    
    $Response = Invoke-JiraApi -Url $Url -Method 'POST' -Body $Body
    
 if ($null -eq $Response) {
        Write-Error "Failed to create ticket in project $ProjectKey"
        exit 72
    }
    
    Write-Host "Ticket created successfully: $($Response.key)" -ForegroundColor Green
  Write-Host "View ticket: $BaseUrl/browse/$($Response.key)" -ForegroundColor Gray
    
  # Set fix version ONLY if explicitly provided via parameter
    # Fix versions should be set when work is complete, not during ticket creation
    if ($FixVersion -and $Response.key) {
        Write-Host "Setting fix version to $FixVersion on $($Response.key)..." -ForegroundColor Cyan
        Set-JiraFixVersion -IssueKey $Response.key -FixVersion $FixVersion
 }
    
    return $Response
}

function New-JiraIssueLink {
    param(
        [string]$InwardIssue,
        [string]$OutwardIssue,
        [string]$LinkType
    )
    
    if (-not $InwardIssue) {
        Write-Error 'InwardIssue parameter is required for linking issues.'
        exit 80
    }
    
    if (-not $OutwardIssue) {
        Write-Error 'OutwardIssue parameter is required for linking issues.'
        exit 81
    }
    
  Write-Host "Creating '$LinkType' link from $OutwardIssue to $InwardIssue..." -ForegroundColor Cyan
    
 $Url = "$BaseUrl/rest/api/2/issueLink"
    $Body = @{
        type = @{
   name = $LinkType
        }
   inwardIssue = @{
      key = $InwardIssue
        }
      outwardIssue = @{
      key = $OutwardIssue
        }
    }
    
    $Response = Invoke-JiraApi -Url $Url -Method 'POST' -Body $Body
  
    if ($null -eq $Response) {
  Write-Error "Failed to link issues"
        exit 82
    }
    
    Write-Host "Issues linked successfully: $OutwardIssue $LinkType $InwardIssue" -ForegroundColor Green
    Write-Host "View inward issue: $BaseUrl/browse/$InwardIssue" -ForegroundColor Gray
Write-Host "View outward issue: $BaseUrl/browse/$OutwardIssue" -ForegroundColor Gray
    
    return $true
}

function Add-JiraAttachment {
    param(
  [string]$IssueKey,
        [string]$FilePath
  )
    
  if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for attaching files.'
        exit 90
    }
    
  if (-not $FilePath) {
        Write-Error 'FilePath parameter is required for attaching files.'
        exit 91
    }
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        exit 92
    }
    
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    Write-Host "Attaching file '$fileName' to $IssueKey..." -ForegroundColor Cyan
    
    # Jira attachments require multipart/form-data and special X-Atlassian-Token header
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey/attachments"
    
    try {
        # Build headers with X-Atlassian-Token for XSRF protection
        $attachHeaders = $AuthHeader.Clone()
        $attachHeaders['X-Atlassian-Token'] = 'no-check'
      
        # Use Invoke-WebRequest for multipart file upload
   $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
     $fileContent = [System.Net.Http.ByteArrayContent]::new($fileBytes)
        $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('application/octet-stream')
        
    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
   $multipartContent.Add($fileContent, 'file', $fileName)
        
        $httpClient = [System.Net.Http.HttpClient]::new()
        foreach ($header in $attachHeaders.GetEnumerator()) {
            $httpClient.DefaultRequestHeaders.Add($header.Key, $header.Value)
        }
     
  $response = $httpClient.PostAsync($Url, $multipartContent).Result
        
 if ($response.IsSuccessStatusCode) {
            $responseContent = $response.Content.ReadAsStringAsync().Result
            $attachmentInfo = $responseContent | ConvertFrom-Json
            
      Write-Host "File attached successfully: $fileName" -ForegroundColor Green
        Write-Host "Attachment ID: $($attachmentInfo[0].id)" -ForegroundColor Gray
            Write-Host "Attachment Size: $($attachmentInfo[0].size) bytes" -ForegroundColor Gray
       Write-Host "View ticket: $BaseUrl/browse/$IssueKey" -ForegroundColor Gray
   
            return $attachmentInfo[0]
        } else {
         $errorContent = $response.Content.ReadAsStringAsync().Result
            Write-Error "Failed to attach file: HTTP $($response.StatusCode) - $errorContent"
       exit 93
        }
    } catch {
      Write-Error "Failed to attach file to ${IssueKey}: $_"
        exit 94
    } finally {
        if ($httpClient) { $httpClient.Dispose() }
        if ($multipartContent) { $multipartContent.Dispose() }
    if ($fileContent) { $fileContent.Dispose() }
    }
}

function Get-JiraAttachment {
    param(
        [string]$IssueKey,
        [string]$AttachmentId,
        [string]$OutputPath
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for downloading attachments.'
        exit 95
    }
    
    Write-Host "Retrieving attachments for $IssueKey..." -ForegroundColor Cyan
    
    # Get the issue to retrieve attachment information
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey"
    $issue = Invoke-JiraApi -Url $Url
    
    if ($null -eq $issue -or $null -eq $issue.fields.attachment) {
        Write-Error "No attachments found for $IssueKey"
        exit 96
    }
    
    $attachments = $issue.fields.attachment
    
    if ($attachments.Count -eq 0) {
        Write-Warning "No attachments found on $IssueKey"
        return $null
    }
    
    Write-Host "Found $($attachments.Count) attachment(s)" -ForegroundColor Green
    
    # If AttachmentId is specified, download that specific attachment
    if ($AttachmentId) {
        $attachment = $attachments | Where-Object { $_.id -eq $AttachmentId }
        
        if (-not $attachment) {
            Write-Error "Attachment ID $AttachmentId not found on $IssueKey"
            Write-Host "Available attachments:" -ForegroundColor Yellow
            $attachments | ForEach-Object { Write-Host "  ID: $($_.id) - $($_.filename) ($($_.size) bytes)" -ForegroundColor Gray }
            exit 97
        }
        
        $attachmentsToDownload = @($attachment)
    } else {
        # Download all attachments
        $attachmentsToDownload = $attachments
    }
    
    # Download attachments
    foreach ($att in $attachmentsToDownload) {
        $filename = $att.filename
        $downloadUrl = $att.content
        
        # Determine output file path
        if ($OutputPath) {
            if (Test-Path $OutputPath -PathType Container) {
                # OutputPath is a directory
                $outFile = Join-Path $OutputPath $filename
            } else {
                # OutputPath is a file path
                $outFile = $OutputPath
            }
        } else {
            # Default to current directory
            $outFile = Join-Path (Get-Location) $filename
        }
        
        Write-Host "Downloading $filename to $outFile..." -ForegroundColor Cyan
        
        try {
            # Download the file using Invoke-WebRequest with authentication
            Invoke-WebRequest -Uri $downloadUrl -Headers $AuthHeader -OutFile $outFile -ErrorAction Stop
            
            Write-Host "Downloaded successfully: $outFile" -ForegroundColor Green
            Write-Host "  Size: $($att.size) bytes" -ForegroundColor Gray
            Write-Host "  Type: $($att.mimeType)" -ForegroundColor Gray
            
            # Return attachment info
            [PSCustomObject]@{
                id = $att.id
                filename = $filename
                size = $att.size
                mimeType = $att.mimeType
                created = $att.created
                author = $att.author.displayName
                localPath = $outFile
            }
        } catch {
            Write-Error "Failed to download $filename from $IssueKey}: $_"
            exit 98
        }
    }
}

function Get-JiraHistory {
    param(
        [string]$IssueKey,
        [string]$FieldFilter
    )
    
    if (-not $IssueKey) {
        Write-Error 'IssueKey parameter is required for getting history.'
        exit 100
    }
    
    Write-Host "Retrieving change history for $IssueKey..." -ForegroundColor Cyan
    
    # Get the issue with changelog expanded
    $Url = "$BaseUrl/rest/api/2/issue/$IssueKey`?expand=changelog"
    $Response = Invoke-JiraApi -Url $Url
    
    if ($null -eq $Response) {
        Write-Error "Failed to retrieve history for $IssueKey"
        exit 101
    }
    
    if ($null -eq $Response.changelog -or $null -eq $Response.changelog.histories) {
        Write-Warning "No change history found for $IssueKey"
        return @()
    }
    
    $histories = $Response.changelog.histories
    Write-Host "Found $($histories.Count) history entries" -ForegroundColor Green
    
    # Format and optionally filter the history
    $result = @()
    foreach ($history in $histories) {
        foreach ($item in $history.items) {
            # Apply field filter if specified
            if ($FieldFilter -and $item.field -notlike "*$FieldFilter*") {
                continue
            }
            
            $result += [PSCustomObject]@{
                created = $history.created
                author = if ($history.author) { $history.author.displayName } else { 'Unknown' }
                authorEmail = if ($history.author) { $history.author.emailAddress } else { $null }
                field = $item.field
                fieldtype = $item.fieldtype
                from = $item.from
                fromString = $item.fromString
                to = $item.to
                toString = $item.toString
            }
        }
    }
    
    return $result
}

# Execute the requested action
if ($Action -eq 'create') {
    $result = New-JiraIssue -ProjectKey $ProjectKey -Summary $Summary -Description $Description -IssueType $IssueType -Priority $Priority -Assignee $Assignee -Component $Component -FixVersion $FixVersion

    # Auto-launch browser to the new ticket URL if requested
    if ($OpenBrowser) {
        $ticketUrl = "$BaseUrl/browse/$($result.key)"
        Write-Host "Opening browser to new ticket: $ticketUrl" -ForegroundColor Green
        Start-Process $ticketUrl
    }
    
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'attach-file') {
    $result = Add-JiraAttachment -IssueKey $IssueKey -FilePath $FilePath
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'download-attachment') {
    $result = Get-JiraAttachment -IssueKey $IssueKey -AttachmentId $AttachmentId -OutputPath $OutputPath
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'link-issues') {
    New-JiraIssueLink -InwardIssue $InwardIssue -OutwardIssue $OutwardIssue -LinkType $LinkType
}
elseif ($Action -eq 'comment') {
    $result = Add-JiraComment -IssueKey $IssueKey -CommentText $Comment
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'update-comment') {
    $result = Update-JiraComment -IssueKey $IssueKey -CommentId $CommentId -CommentText $Comment
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'delete-comment') {
    Remove-JiraComment -IssueKey $IssueKey -CommentId $CommentId
    Write-Host "Comment deleted successfully" -ForegroundColor Green
}
elseif ($Action -eq 'transitions') {
    $result = Get-JiraTransitions -IssueKey $IssueKey
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'transition') {
    Invoke-JiraTransition -IssueKey $IssueKey -TransitionName $TransitionName -TransitionId $TransitionId -FixVersion $FixVersion
}
elseif ($Action -eq 'set-fixversion') {
    Set-JiraFixVersion -IssueKey $IssueKey -FixVersion $FixVersion
}
elseif ($Action -eq 'set-sprint') {
    Set-JiraSprint -IssueKey $IssueKey -SprintName $Sprint
}
elseif ($Action -eq 'update-ticket') {
    Update-JiraTicket -IssueKey $IssueKey -Summary $Summary -Description $Description -Assignee $Assignee -Priority $Priority
    Write-Host "Ticket updated successfully" -ForegroundColor Green
}
elseif ($Action -eq 'link-issues') {
    if (-not $InwardIssue -or -not $OutwardIssue) {
        Write-Error 'Both InwardIssue and OutwardIssue parameters are required for linking issues.'
        exit 80
    }
    
    # Build the link payload
    $linkPayload = @{
        type = @{
            name = $LinkType
        }
        inwardIssue = $InwardIssue
        outwardIssue = $OutwardIssue
    }
    
    $Url = "$BaseUrl/rest/api/2/issueLink"
    Write-Host "Linking issues $InwardIssue and $OutwardIssue with link type '$LinkType'..." -ForegroundColor Cyan
    $Response = Invoke-JiraApi -Url $Url -Method 'POST' -Body $linkPayload
    
    if ($null -eq $Response) {
        Write-Error "Failed to link issues $InwardIssue and $OutwardIssue"
        exit 81
    }
    
    Write-Host "Issues linked successfully" -ForegroundColor Green
    Write-Host "View link: $BaseUrl/issues/$InwardIssue" -ForegroundColor Gray
    
    return $Response
}
elseif ($Action -eq 'query') {
    if ($QueryType -eq 'tickets') {
        if (-not $Jql) {
            Write-Error 'Jql parameter is required for ticket queries.'
            exit 1
        }
        
        # Build fields parameter for API
        $fieldsParam = ""
        if ($Fields -eq 'default') {
            $fieldsParam = "&fields=key,summary,description,status,assignee,priority,created,updated"
        } elseif ($Fields -eq 'all') {
            # Don't specify fields parameter to get all fields
            $fieldsParam = ""
        } elseif ($Fields -eq 'custom') {
            if (-not $CustomFields) {
                Write-Error 'CustomFields parameter is required when Fields is set to "custom".'
                exit 5
            }
            # Custom field list
            $fieldsParam = "&fields=$CustomFields"
        }
        
        $startAt = 0
        $total = $null
        $allIssues = @()
        
        Write-Host "Querying Jira tickets..." -ForegroundColor Cyan
        
        while ($true) {
            # Calculate how many results we still need (respect MaxResults as total limit)
            $remaining = $MaxResults - $allIssues.Count
            $pageSize = [Math]::Min($remaining, 100)  # Jira max page size is 100
            
            $Url = "$BaseUrl/rest/api/2/search?jql=" + [uri]::EscapeDataString($Jql) + "&startAt=$startAt&maxResults=$pageSize$fieldsParam"
            $Response = Invoke-JiraApi -Url $Url
            if ($null -eq $Response) { exit 2 }
            if ($null -eq $total) { 
                $total = $Response.total 
                Write-Host "Found $total ticket(s)" -ForegroundColor Green
            }
            $allIssues += $Response.issues
            $startAt += $pageSize
            # Stop when we have enough results OR we've fetched all available
            if ($allIssues.Count -ge $MaxResults -or $allIssues.Count -ge $total) { break }
        }
        
        # Retrieve comments if requested
        if ($IncludeComments -and $allIssues.Count -gt 0) {
            Write-Host "Retrieving comments for $($allIssues.Count) ticket(s)..." -ForegroundColor Cyan
            $issueCount = 0
            $allIssues | ForEach-Object {
                $issueCount++
                Write-Progress -Activity "Fetching Comments" -Status "Processing $($_.key) ($issueCount of $($allIssues.Count))" -PercentComplete (($issueCount / $allIssues.Count) * 100)
                
                $comments = Get-JiraComments -IssueKey $_.key
                
                # Add comments to the issue object
                $_ | Add-Member -MemberType NoteProperty -Name 'comments' -Value $comments -Force
            }
            Write-Progress -Activity "Fetching Comments" -Completed
            Write-Host "Comments retrieved successfully" -ForegroundColor Green
        }
        
        # Format output based on field selection
        if ($Fields -eq 'default') {
            $result = $allIssues | Select-Object key,
                @{n='summary';e={$_.fields.summary}},
                @{n='description';e={$_.fields.description}},
                @{n='status';e={$_.fields.status.name}},
                @{n='assignee';e={if($_.fields.assignee){$_.fields.assignee.displayName}else{'Unassigned'}}},
                @{n='priority';e={if($_.fields.priority){$_.fields.priority.name}else{'None'}}},
                @{n='created';e={$_.fields.created}},
                @{n='updated';e={$_.fields.updated}},
                @{n='url';e={"$BaseUrl/browse/$($_.key)"}},
                @{n='commentCount';e={if($_.comments){$_.comments.Count}else{0}}},
                @{n='comments';e={$_.comments}}
        } else {
            # For 'all' or custom fields, return the full structure
            $result = $allIssues | ForEach-Object {
                $issue = $_
                $formatted = [ordered]@{
                    key = $issue.key
                    url = "$BaseUrl/browse/$($issue.key)"
                }
                # Add all fields from the response
                $issue.fields.PSObject.Properties | ForEach-Object {
                    $formatted[$_.Name] = $_.Value
                }
                # Add comments if they were retrieved
                if ($issue.comments) {
                    $formatted['commentCount'] = $issue.comments.Count
                    $formatted['comments'] = $issue.comments
                }
                [PSCustomObject]$formatted
            }
        }
        
        $result | ConvertTo-Json -Depth 10
    }
    elseif ($QueryType -eq 'users') {
        Write-Host "Querying Jira users..." -ForegroundColor Cyan
        
        $allUsers = @()
        
        # Determine the search approach based on parameters
        if ($ProjectKey) {
            # Get users assignable to a specific project
            Write-Host "Searching for users assignable to project $ProjectKey..." -ForegroundColor Gray
            $searchQuery = if ($UserSearch) { [uri]::EscapeDataString($UserSearch) } else { "" }
            $Url = "$BaseUrl/rest/api/2/user/assignable/search?project=$ProjectKey&username=$searchQuery&maxResults=$MaxResults"
            $Response = Invoke-JiraApi -Url $Url
            if ($null -ne $Response) {
                $allUsers = $Response
            }
        } elseif ($UserSearch) {
            # Search users by username/name/email
            Write-Host "Searching for users matching '$UserSearch'..." -ForegroundColor Gray
            $searchQuery = [uri]::EscapeDataString($UserSearch)
            $Url = "$BaseUrl/rest/api/2/user/search?username=$searchQuery&maxResults=$MaxResults&includeInactive=$($IncludeInactive.IsPresent)"
            $Response = Invoke-JiraApi -Url $Url
            if ($null -ne $Response) {
                $allUsers = $Response
            }
        } else {
            # List all users (paginated) - use "." as wildcard search
            Write-Host "Listing all users (use -UserSearch to filter)..." -ForegroundColor Gray
            $startAt = 0
            while ($true) {
                $Url = "$BaseUrl/rest/api/2/user/search?username=.&startAt=$startAt&maxResults=$MaxResults&includeInactive=$($IncludeInactive.IsPresent)"
                $Response = Invoke-JiraApi -Url $Url
                if ($null -eq $Response) { exit 3 }
                if ($Response.Count -eq 0) { break }
                $allUsers += $Response
                $startAt += $MaxResults
                if ($Response.Count -lt $MaxResults) { break }
                # Safety limit to prevent infinite loops
                if ($allUsers.Count -ge 1000) {
                    Write-Warning "Retrieved 1000 users, stopping. Use -UserSearch to filter results."
                    break
                }
            }
        }
        
        Write-Host "Found $($allUsers.Count) user(s)" -ForegroundColor Green
        
        # Format output
        $result = $allUsers | Select-Object `
            @{n='username';e={$_.name}},
            @{n='displayName';e={$_.displayName}},
            @{n='emailAddress';e={$_.emailAddress}},
            @{n='active';e={$_.active}},
            @{n='timeZone';e={$_.timeZone}}
        
        $result | ConvertTo-Json -Depth 6
    }
    else {
        Write-Error "Unsupported QueryType: $QueryType"
        exit 4
    }
}
elseif ($Action -eq 'get-history') {
    # Get ticket change history
    $result = Get-JiraHistory -IssueKey $IssueKey -FieldFilter $CustomFields
    $result | ConvertTo-Json -Depth 6
}
elseif ($Action -eq 'list-components') {
    # List all components for a project
    if (-not $ProjectKey) {
        Write-Error "ProjectKey is required for list-components action"
        exit 1
    }
    
    Write-Host "Getting components for project $ProjectKey..." -ForegroundColor Gray
    $Url = "$BaseUrl/rest/api/2/project/$ProjectKey/components"
    $Response = Invoke-JiraApi -Url $Url
    
    if ($null -eq $Response) {
        Write-Error "Failed to get components for project $ProjectKey"
        exit 1
    }
    
    Write-Host "Found $($Response.Count) component(s)" -ForegroundColor Green
    
    $result = $Response | Select-Object `
        @{n='id';e={$_.id}},
        @{n='name';e={$_.name}},
        @{n='description';e={$_.description}},
        @{n='lead';e={$_.lead.displayName}},
        @{n='assigneeType';e={$_.assigneeType}}
    
    $result | ConvertTo-Json -Depth 6
}
else {
    Write-Error "Unsupported Action: $Action"
    exit 99
}
