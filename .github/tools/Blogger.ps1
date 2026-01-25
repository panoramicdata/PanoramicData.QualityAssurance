<#
.SYNOPSIS
    Manage Blogger pages and posts using the Blogger API v3.

.DESCRIPTION
    This script interacts with the Blogger API to list, get, create, and update pages and posts.
    For read-only operations (list-pages, get-page), uses public Atom feed (no authentication required).
    For write operations, uses OAuth2 user authentication flow with automatic token refresh.
    Credentials are stored securely in Windows Credential Manager.

.PARAMETER Action
    The action to perform: list-pages, get-page, update-page, create-page, login, logout

.PARAMETER BlogId
    The Blogger blog ID. Default: 289149861252142016 (MagicSuite docs)

.PARAMETER PageId
    The page ID for get-page or update-page actions

.PARAMETER Title
    The page title for create-page or update-page

.PARAMETER Content
    The HTML content for create-page or update-page

.PARAMETER ContentFile
    Path to a file containing HTML content

.PARAMETER AsJson
    Return output as JSON instead of formatted text (useful for scripting)

.EXAMPLE
    # List all pages (no authentication required - uses public Atom feed)
    ./Blogger.ps1 -Action list-pages

    # Get a specific page as JSON (no authentication required)
    ./Blogger.ps1 -Action get-page -PageId 4521542993645694799 -AsJson

    # First-time login (required for write operations)
    ./Blogger.ps1 -Action login

    # Update a page with content from file (requires authentication)
    ./Blogger.ps1 -Action update-page -PageId 4521542993645694799 -Title "Connections" -ContentFile "path/to/content.html"

    # Logout (clear stored credentials)
    ./Blogger.ps1 -Action logout

.NOTES
    Read-only operations (list-pages, get-page) use the public Atom feed - no authentication needed!
    Write operations require OAuth login first.
    
    Credentials are stored in Windows Credential Manager:
    - MagicSuite:Blogger:AccessToken
    - MagicSuite:Blogger:RefreshToken
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("list-pages", "get-page", "update-page", "create-page", "append-page", "login", "logout")]
    [string]$Action,

    [string]$BlogId,

    [string]$PageId,

    [string]$Title,

    [string]$Content,

    [string]$ContentFile,

    [switch]$AsJson
)

# Define which actions are read-only (don't require authentication)
$script:ReadOnlyActions = @("list-pages", "get-page")

# Windows Credential Manager targets for Blogger credentials
$script:ClientIdTarget = "MagicSuite:Blogger:ClientId"
$script:ClientSecretTarget = "MagicSuite:Blogger:ClientSecret"
$script:ApiKeyTarget = "MagicSuite:Blogger:ApiKey"
$script:AccessTokenTarget = "MagicSuite:Blogger:AccessToken"
$script:RefreshTokenTarget = "MagicSuite:Blogger:RefreshToken"

# OAuth2 Configuration - Using Google's "Desktop app" flow with localhost redirect
$script:RedirectUri = "http://localhost:8642/oauth2callback"
$script:Scope = "https://www.googleapis.com/auth/blogger"
$script:AuthEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
$script:TokenEndpoint = "https://oauth2.googleapis.com/token"

# Default blog ID for MagicSuite docs
if (-not $BlogId) {
    $BlogId = "289149861252142016"
}

$BaseUrl = "https://www.googleapis.com/blogger/v3"

# Check if this is a read-only action
$script:IsReadOnlyAction = $Action -in $script:ReadOnlyActions

#region Credential Management Functions

function Get-StoredCredential {
    param([string]$Target)

    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinCredManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CredReadW(string target, int type, int reserved, out IntPtr credential);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool CredFree(IntPtr credential);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetCredential(string target) {
        IntPtr credPtr;
        if (CredReadW(target, 1, 0, out credPtr)) {
            try {
                CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
                if (cred.CredentialBlobSize > 0) {
                    return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
                }
            }
            finally {
                CredFree(credPtr);
            }
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue

        return [WinCredManager]::GetCredential($Target)
    }
    catch {
        return $null
    }
}

function Set-StoredCredential {
    param(
        [string]$Target,
        [string]$Username,
        [string]$Password
    )

    try {
        $result = cmdkey /generic:$Target /user:$Username /pass:$Password 2>&1
        return $LASTEXITCODE -eq 0 -or $result -match "successfully"
    }
    catch {
        Write-Error "Failed to store credential: $_"
        return $false
    }
}

function Remove-StoredCredential {
    param([string]$Target)

    try {
        cmdkey /delete:$Target 2>&1 | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

#endregion

#region Credential Initialization

# Try to migrate credentials from environment variables to Windows Credential Manager
# This is a one-time migration - after storing, environment variables are removed

function Initialize-BloggerCredentials {
    $migrated = $false
    
    # Check for Client ID in environment variable
    if ($env:BLOGGER_CLIENT_ID) {
        Write-Host "Migrating BLOGGER_CLIENT_ID to Windows Credential Manager..." -ForegroundColor Cyan
        Set-StoredCredential -Target $script:ClientIdTarget -Username "BloggerClientId" -Password $env:BLOGGER_CLIENT_ID
        [System.Environment]::SetEnvironmentVariable("BLOGGER_CLIENT_ID", $null, [System.EnvironmentVariableTarget]::User)
        $migrated = $true
    }
    
    # Check for Client Secret in environment variable
    if ($env:BLOGGER_CLIENT_SECRET) {
        Write-Host "Migrating BLOGGER_CLIENT_SECRET to Windows Credential Manager..." -ForegroundColor Cyan
        Set-StoredCredential -Target $script:ClientSecretTarget -Username "BloggerClientSecret" -Password $env:BLOGGER_CLIENT_SECRET
        [System.Environment]::SetEnvironmentVariable("BLOGGER_CLIENT_SECRET", $null, [System.EnvironmentVariableTarget]::User)
        $migrated = $true
    }
    
    # Check for API Key in environment variable
    if ($env:BLOGGER_API_KEY) {
        Write-Host "Migrating BLOGGER_API_KEY to Windows Credential Manager..." -ForegroundColor Cyan
        Set-StoredCredential -Target $script:ApiKeyTarget -Username "BloggerApiKey" -Password $env:BLOGGER_API_KEY
        [System.Environment]::SetEnvironmentVariable("BLOGGER_API_KEY", $null, [System.EnvironmentVariableTarget]::User)
        $migrated = $true
    }
    
    if ($migrated) {
        Write-Host "Credentials migrated successfully. Environment variables have been removed." -ForegroundColor Green
    }
    
    # Now load credentials from Windows Credential Manager
    $script:ClientId = Get-StoredCredential -Target $script:ClientIdTarget
    $script:ClientSecret = Get-StoredCredential -Target $script:ClientSecretTarget
    $script:ApiKey = Get-StoredCredential -Target $script:ApiKeyTarget
}

# Initialize credentials
Initialize-BloggerCredentials

# Validate credentials are available for non-read-only actions
if (-not ($script:ReadOnlyActions -contains $Action)) {
    if (-not $script:ClientId -or -not $script:ClientSecret) {
        Write-Error @"
Blogger credentials not found. Please set the following environment variables (one-time setup):

  `$env:BLOGGER_CLIENT_ID = 'your-client-id'
  `$env:BLOGGER_CLIENT_SECRET = 'your-client-secret'
  `$env:BLOGGER_API_KEY = 'your-api-key'  # Optional, for read-only access

Then run this script again. The credentials will be stored in Windows Credential Manager
and the environment variables will be automatically removed.
"@
        exit 1
    }
}

#endregion

#region OAuth2 Functions

function Start-OAuthLogin {
    Write-Host "Starting OAuth2 authentication flow..." -ForegroundColor Cyan
    Write-Host ""

    # Generate state for CSRF protection
    $state = [guid]::NewGuid().ToString("N")

    # Build authorization URL
    $authUrl = "$($script:AuthEndpoint)?" +
        "client_id=$([Uri]::EscapeDataString($script:ClientId))" +
        "&redirect_uri=$([Uri]::EscapeDataString($script:RedirectUri))" +
        "&response_type=code" +
        "&scope=$([Uri]::EscapeDataString($script:Scope))" +
        "&state=$state" +
        "&access_type=offline" +
        "&prompt=consent"

    # Start local HTTP listener
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://localhost:8642/")

    try {
        $listener.Start()
        Write-Host "Opening browser for Google sign-in..." -ForegroundColor Yellow
        Write-Host "If the browser doesn't open automatically, go to:" -ForegroundColor Gray
        Write-Host $authUrl -ForegroundColor Cyan
        Write-Host ""

        # Open browser
        Start-Process $authUrl

        Write-Host "Waiting for authorization..." -ForegroundColor Yellow

        # Wait for callback (with timeout)
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Parse the callback
        $queryParams = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)
        $code = $queryParams["code"]
        $returnedState = $queryParams["state"]
        $error = $queryParams["error"]

        # Send response to browser
        $responseHtml = if ($code -and $returnedState -eq $state) {
            @"
<!DOCTYPE html>
<html>
<head><title>Authentication Successful</title></head>
<body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
<h1 style="color: green;">&#10004; Authentication Successful!</h1>
<p>You can close this window and return to PowerShell.</p>
</body>
</html>
"@
        } else {
            @"
<!DOCTYPE html>
<html>
<head><title>Authentication Failed</title></head>
<body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
<h1 style="color: red;">&#10008; Authentication Failed</h1>
<p>Error: $error</p>
<p>Please close this window and try again.</p>
</body>
</html>
"@
        }

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseHtml)
        $response.ContentLength64 = $buffer.Length
        $response.ContentType = "text/html"
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()

        if (-not $code) {
            Write-Error "Authorization failed: $error"
            return $false
        }

        if ($returnedState -ne $state) {
            Write-Error "State mismatch - possible CSRF attack"
            return $false
        }

        Write-Host "Authorization code received. Exchanging for tokens..." -ForegroundColor Yellow

        # Exchange code for tokens
        $tokenBody = @{
            code          = $code
            client_id     = $script:ClientId
            client_secret = $script:ClientSecret
            redirect_uri  = $script:RedirectUri
            grant_type    = "authorization_code"
        }

        $tokenResponse = Invoke-RestMethod -Uri $script:TokenEndpoint -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"

        if ($tokenResponse.access_token) {
            # Store access token
            Set-StoredCredential -Target $script:AccessTokenTarget -Username "blogger" -Password $tokenResponse.access_token | Out-Null

            # Store refresh token if provided
            if ($tokenResponse.refresh_token) {
                Set-StoredCredential -Target $script:RefreshTokenTarget -Username "blogger" -Password $tokenResponse.refresh_token | Out-Null
            }

            Write-Host ""
            Write-Host "[OK] Authentication successful!" -ForegroundColor Green
            Write-Host "Tokens stored in Windows Credential Manager." -ForegroundColor Gray
            Write-Host "Access token expires in: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
            return $true
        }
        else {
            Write-Error "Failed to obtain access token"
            return $false
        }
    }
    catch {
        Write-Error "OAuth login failed: $_"
        return $false
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

function Invoke-TokenRefresh {
    $refreshToken = Get-StoredCredential -Target $script:RefreshTokenTarget

    if (-not $refreshToken) {
        return $null
    }

    Write-Host "Refreshing access token..." -ForegroundColor Yellow

    try {
        $tokenBody = @{
            refresh_token = $refreshToken
            client_id     = $script:ClientId
            client_secret = $script:ClientSecret
            grant_type    = "refresh_token"
        }

        $tokenResponse = Invoke-RestMethod -Uri $script:TokenEndpoint -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"

        if ($tokenResponse.access_token) {
            Set-StoredCredential -Target $script:AccessTokenTarget -Username "blogger" -Password $tokenResponse.access_token | Out-Null
            Write-Host "[OK] Token refreshed successfully" -ForegroundColor Green
            return $tokenResponse.access_token
        }
    }
    catch {
        Write-Warning "Token refresh failed: $_"
    }

    return $null
}

function Get-ValidAccessToken {
    $accessToken = Get-StoredCredential -Target $script:AccessTokenTarget

    if (-not $accessToken) {
        # No access token, try to refresh
        $accessToken = Invoke-TokenRefresh
    }

    if (-not $accessToken) {
        return $null
    }

    # Test if token is valid by making a simple API call
    try {
        $testHeaders = @{ "Authorization" = "Bearer $accessToken" }
        Invoke-RestMethod -Uri "https://www.googleapis.com/blogger/v3/users/self" -Headers $testHeaders -ErrorAction Stop | Out-Null
        return $accessToken
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            # Token expired, try to refresh
            $accessToken = Invoke-TokenRefresh
            return $accessToken
        }
        throw
    }
}

#endregion

# Handle login/logout actions first
if ($Action -eq "login") {
    Add-Type -AssemblyName System.Web
    $result = Start-OAuthLogin
    exit $(if ($result) { 0 } else { 1 })
}

if ($Action -eq "logout") {
    Remove-StoredCredential -Target $script:AccessTokenTarget
    Remove-StoredCredential -Target $script:RefreshTokenTarget
    Write-Host "[OK] Logged out. Credentials removed from Windows Credential Manager." -ForegroundColor Green
    exit 0
}

# For read-only actions, try public access first, fall back to OAuth if available
# For write actions, require OAuth authentication
if ($script:IsReadOnlyAction) {
    # Try to get OAuth token if available (for better access), otherwise use API key
    $AccessToken = Get-ValidAccessToken
    
    if ($AccessToken) {
        # Use OAuth if we have a valid token
        $Headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type"  = "application/json"
        }
        $script:UseApiKey = $false
    }
    else {
        # Fall back to API key for public access
        $Headers = @{
            "Content-Type" = "application/json"
        }
        $script:UseApiKey = $true
    }
}
else {
    # Write access mode - require OAuth
    $AccessToken = Get-ValidAccessToken

    if (-not $AccessToken) {
        Write-Error "Not authenticated. Please run: .\.github\tools\Blogger.ps1 -Action login"
        Write-Host ""
        Write-Host "This will open a browser window for Google sign-in." -ForegroundColor Yellow
        Write-Host "Your credentials will be securely stored in Windows Credential Manager." -ForegroundColor Gray
        exit 1
    }

    $Headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }
    $script:UseApiKey = $false
}

function Invoke-BloggerApi {
    param(
        [string]$Method = "GET",
        [string]$Endpoint,
        [object]$Body
    )

    $Uri = "$BaseUrl$Endpoint"
    
    # Append API key for public access
    if ($script:UseApiKey) {
        if ($Uri -match "\?") {
            $Uri += "&key=$($script:ApiKey)"
        }
        else {
            $Uri += "?key=$($script:ApiKey)"
        }
    }

    $params = @{
        Uri     = $Uri
        Method  = $Method
        Headers = $Headers
    }

    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }

    try {
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        
        # If public access failed, suggest authentication
        if ($script:UseApiKey -and ($statusCode -eq 400 -or $statusCode -eq 401 -or $statusCode -eq 403)) {
            Write-Error "Public API access failed. This blog may require authentication."
            Write-Host ""
            Write-Host "Please run: .\.github\tools\Blogger.ps1 -Action login" -ForegroundColor Yellow
            Write-Host "This will open a browser window for Google sign-in." -ForegroundColor Gray
            exit 1
        }
        
        Write-Error "API call failed: $_"
        throw
    }
}

# Load content from file if specified
if ($ContentFile -and (Test-Path $ContentFile)) {
    $Content = Get-Content -Path $ContentFile -Raw
    # Remove HTML comments at the start (documentation header)
    $Content = $Content -replace "(?s)^\s*<!--.*?-->\s*", ""
}

switch ($Action) {
    "list-pages" {
        if (-not $AsJson) {
            Write-Host "Listing pages for blog $BlogId..." -ForegroundColor Cyan
        }
        
        # Use public Atom feed for read-only access (no authentication required)
        $atomUrl = "https://www.blogger.com/feeds/$BlogId/pages/default"
        try {
            [xml]$feed = (Invoke-WebRequest -Uri $atomUrl -UseBasicParsing).Content
            
            # Convert Atom entries to a consistent format
            $pages = $feed.feed.entry | ForEach-Object {
                # Extract page ID from the id element (format: tag:blogger.com,...page-PAGEID)
                $pageIdMatch = $_.id -match 'page-(\d+)$'
                $extractedId = if ($pageIdMatch) { $matches[1] } else { $_.id }
                [PSCustomObject]@{
                    id        = $extractedId
                    title     = $_.title.'#text'
                    url       = ($_.link | Where-Object { $_.rel -eq 'alternate' }).href
                    published = $_.published
                    updated   = $_.updated
                    content   = $_.content.'#text'
                }
            }
            
            if ($AsJson) {
                # Return as JSON for scripting
                @{ items = $pages } | ConvertTo-Json -Depth 10
            }
            elseif ($pages) {
                $pages | ForEach-Object {
                    Write-Host ""
                    Write-Host "Page ID: $($_.id)" -ForegroundColor Green
                    Write-Host "Title: $($_.title)"
                    Write-Host "URL: $($_.url)"
                    Write-Host "Published: $($_.published)"
                    Write-Host "Updated: $($_.updated)"
                }
                Write-Host ""
                Write-Host "Total: $($pages.Count) pages" -ForegroundColor Yellow
            }
            else {
                Write-Host "No pages found."
            }
        }
        catch {
            Write-Error "Failed to fetch pages: $_"
            exit 1
        }
    }

    "get-page" {
        if (-not $PageId) {
            Write-Error "PageId is required for get-page action"
            exit 1
        }

        if (-not $AsJson) {
            Write-Host "Getting page $PageId from blog $BlogId..." -ForegroundColor Cyan
        }
        
        # Use public Atom feed for read-only access (no authentication required)
        $atomUrl = "https://www.blogger.com/feeds/$BlogId/pages/default"
        try {
            [xml]$feed = (Invoke-WebRequest -Uri $atomUrl -UseBasicParsing).Content
            
            # Find the page by ID (format: tag:blogger.com,...page-PAGEID)
            $entry = $feed.feed.entry | Where-Object { $_.id -match "page-$PageId$" }
            
            if (-not $entry) {
                Write-Error "Page with ID $PageId not found"
                exit 1
            }
            
            $page = [PSCustomObject]@{
                id        = $PageId
                title     = $entry.title.'#text'
                url       = ($entry.link | Where-Object { $_.rel -eq 'alternate' }).href
                published = $entry.published
                updated   = $entry.updated
                content   = $entry.content.'#text'
            }
            
            if ($AsJson) {
                # Return as JSON for scripting
                $page | ConvertTo-Json -Depth 10
            }
            else {
                Write-Host ""
                Write-Host "Page ID: $($page.id)" -ForegroundColor Green
                Write-Host "Title: $($page.title)"
                Write-Host "URL: $($page.url)"
                Write-Host "Published: $($page.published)"
                Write-Host "Updated: $($page.updated)"
                Write-Host ""
                Write-Host "Content preview (first 500 chars):" -ForegroundColor Yellow
                $contentPreview = if ($page.content.Length -gt 500) { $page.content.Substring(0, 500) + "..." } else { $page.content }
                Write-Host $contentPreview
            }
        }
        catch {
            Write-Error "Failed to fetch page: $_"
            exit 1
        }
    }

    "update-page" {
        if (-not $PageId) {
            Write-Error "PageId is required for update-page action"
            exit 1
        }

        if (-not $Content) {
            Write-Error "Content or ContentFile is required for update-page action"
            exit 1
        }

        Write-Host "Updating page $PageId..." -ForegroundColor Cyan

        $body = @{
            content = $Content
        }

        if ($Title) {
            $body.title = $Title
        }

        $result = Invoke-BloggerApi -Method "PATCH" -Endpoint "/blogs/$BlogId/pages/$PageId" -Body $body

        Write-Host "Page updated successfully!" -ForegroundColor Green
        Write-Host "Title: $($result.title)"
        Write-Host "URL: $($result.url)"
        Write-Host "Updated: $($result.updated)"
    }

    "append-page" {
        if (-not $PageId) {
            Write-Error "PageId is required for append-page action"
            exit 1
        }

        if (-not $Content) {
            Write-Error "Content or ContentFile is required for append-page action"
            exit 1
        }

        Write-Host "Fetching existing page $PageId..." -ForegroundColor Cyan
        $existing = Invoke-BloggerApi -Endpoint "/blogs/$BlogId/pages/$PageId"

        Write-Host "Appending new content..." -ForegroundColor Cyan
        $newContent = $existing.content + "`n`n" + $Content

        $body = @{
            content = $newContent
        }

        $result = Invoke-BloggerApi -Method "PATCH" -Endpoint "/blogs/$BlogId/pages/$PageId" -Body $body

        Write-Host "Content appended successfully!" -ForegroundColor Green
        Write-Host "Title: $($result.title)"
        Write-Host "URL: $($result.url)"
        Write-Host "Updated: $($result.updated)"
    }

    "create-page" {
        if (-not $Title) {
            Write-Error "Title is required for create-page action"
            exit 1
        }

        if (-not $Content) {
            Write-Error "Content or ContentFile is required for create-page action"
            exit 1
        }

        Write-Host "Creating new page '$Title'..." -ForegroundColor Cyan

        $body = @{
            title   = $Title
            content = $Content
        }

        $result = Invoke-BloggerApi -Method "POST" -Endpoint "/blogs/$BlogId/pages" -Body $body

        Write-Host "Page created successfully!" -ForegroundColor Green
        Write-Host "Page ID: $($result.id)"
        Write-Host "Title: $($result.title)"
        Write-Host "URL: $($result.url)"
    }
}
