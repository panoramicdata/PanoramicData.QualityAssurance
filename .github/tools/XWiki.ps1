# General XWiki Access Script
# Fetches, creates, updates, and deletes XWiki pages
# Uses Windows Credential Manager to securely store credentials
#
# IMPORTANT: Copilot/AI assistants should ALWAYS use this script to interact with XWiki.
# NEVER access the XWiki REST API directly. If new functionality is needed, enhance this script.
#
# Usage Examples:
#   # Read a page (default action) - parses HTML tables
#   .\XWiki.ps1 -Url "https://wiki.panoramicdata.com/bin/view/Sandbox/TestPage"
#
#   # Get page metadata and content as JSON via REST API
#   .\XWiki.ps1 -Action Get -Space "Sandbox" -PageName "TestPage"
#
#   # Get ONLY the page content (useful for reading/editing)
#   .\XWiki.ps1 -Action GetContent -Space "QA Home" -PageName "WebHome"
#
#   # Get content from nested spaces (use dots to separate nested spaces)
#   .\XWiki.ps1 -Action GetContent -Space "QA Home.QA's AI hopes, dreams and plans" -PageName "WebHome"
#
#   # Create a new page
#   .\XWiki.ps1 -Action Create -Space "Sandbox" -PageName "NewPage" -Title "My New Page" -Content "# Hello World"
#
#   # Update an existing page (provide new content)
#   .\XWiki.ps1 -Action Update -Space "Sandbox" -PageName "TestPage" -Title "Updated Title" -Content "# Updated content"
#
#   # Update page using Find/Replace (useful for fixing typos)
#   .\XWiki.ps1 -Action Replace -Space "QA Home.SubPage" -PageName "WebHome" -Find "typo" -Replace "correction"
#
#   # Delete a page
#   .\XWiki.ps1 -Action Delete -Space "Sandbox" -PageName "TestPage"
#
#   # Search for pages
#   .\XWiki.ps1 -Action Search -Query "regression test"
#
#   # List all spaces
#   .\XWiki.ps1 -Action ListSpaces

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Read", "Get", "GetContent", "Create", "Update", "Replace", "Delete", "Search", "ListSpaces")]
    [string]$Action = "Read",
    
    [Parameter(Mandatory=$false)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [string]$Space,
    
    [Parameter(Mandatory=$false)]
    [string]$PageName = "WebHome",
    
    [Parameter(Mandatory=$false)]
    [string]$Title,
    
    [Parameter(Mandatory=$false)]
    [string]$Content,
    
    [Parameter(Mandatory=$false)]
    [string]$Query,
    
    [Parameter(Mandatory=$false)]
    [string]$Find,
    
    [Parameter(Mandatory=$false)]
    [string]$Replace,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "https://wiki.panoramicdata.com",
    
    [Parameter(Mandatory=$false)]
    [string]$CredentialTarget = "LogicMonitor:XWiki"
)

# Function to get credentials from Windows Credential Manager using native .NET
function Get-StoredCredential {
    param([string]$Target)
    
    try {
        # Add the CredentialManagement type if not already added
        if (-not ([System.Management.Automation.PSTypeName]'CredentialManagement.Credential').Type) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace CredentialManagement
{
    public class Credential
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct CREDENTIAL
        {
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

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

        [DllImport("advapi32.dll")]
        private static extern void CredFree(IntPtr cred);

        public static bool Get(string target, out string username, out string password)
        {
            IntPtr credPtr;
            username = null;
            password = null;

            if (CredRead(target, 1, 0, out credPtr))
            {
                CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
                username = cred.UserName;
                
                if (cred.CredentialBlobSize > 0)
                {
                    password = Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
                }
                
                CredFree(credPtr);
                return true;
            }
            
            return false;
        }
    }
}
"@
        }
        
        $username = $null
        $password = $null
        
        if ([CredentialManagement.Credential]::Get($Target, [ref]$username, [ref]$password)) {
            return @{
                Username = $username
                Password = $password
            }
        }
    } catch {
        # Silently fail if credential not found
    }
    
    return $null
}

# Function to store credentials in Windows Credential Manager using native .NET
function Set-StoredCredential {
    param(
        [string]$Target,
        [string]$Username,
        [string]$Password
    )
    
    try {
        # Add the CredentialManagement type if not already added
        if (-not ([System.Management.Automation.PSTypeName]'CredentialManagement.CredentialWriter').Type) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace CredentialManagement
{
    public class CredentialWriter
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct CREDENTIAL
        {
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

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredWrite(ref CREDENTIAL credential, int flags);

        public static bool Set(string target, string username, string password)
        {
            CREDENTIAL cred = new CREDENTIAL();
            cred.Type = 1; // CRED_TYPE_GENERIC
            cred.TargetName = target;
            cred.UserName = username;
            cred.Persist = 2; // CRED_PERSIST_LOCAL_MACHINE
            
            byte[] passwordBytes = Encoding.Unicode.GetBytes(password);
            cred.CredentialBlobSize = passwordBytes.Length;
            cred.CredentialBlob = Marshal.AllocHGlobal(passwordBytes.Length);
            Marshal.Copy(passwordBytes, 0, cred.CredentialBlob, passwordBytes.Length);

            bool result = CredWrite(ref cred, 0);
            
            Marshal.FreeHGlobal(cred.CredentialBlob);
            
            return result;
        }
    }
}
"@
        }
        
        if ([CredentialManagement.CredentialWriter]::Set($Target, $Username, $Password)) {
            Write-Host "✓ Credentials saved to Windows Credential Manager" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Error storing credentials" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error storing credentials: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Function to parse HTML table
function Parse-XWikiTable {
    param(
        [string]$TableHtml
    )
    
    # Extract headers - try both thead and direct tr > th pattern
    $headerMatch = [regex]::Match($TableHtml, '<thead[^>]*>(.*?)</thead>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $headerNames = @()
    
    if ($headerMatch.Success) {
        $headers = [regex]::Matches($headerMatch.Value, '<th[^>]*>(.*?)</th>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $headerNames = $headers | ForEach-Object { 
            $text = $_.Groups[1].Value -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' ' -replace '&amp;', '&'
            $text.Trim()
        }
    } else {
        # Try to find th elements anywhere in the table
        $headers = [regex]::Matches($TableHtml, '<th[^>]*>(.*?)</th>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($headers.Count -gt 0) {
            $headerNames = $headers | ForEach-Object { 
                $text = $_.Groups[1].Value -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' ' -replace '&amp;', '&'
                $text.Trim()
            }
        }
    }
    
    # Extract rows - try tbody first, then any tr with td
    $rows = @()
    $tbodyMatch = [regex]::Match($TableHtml, '<tbody[^>]*>(.*?)</tbody>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($tbodyMatch.Success) {
        $rows = [regex]::Matches($tbodyMatch.Value, '<tr[^>]*>(.*?)</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    } else {
        # Find all rows with td elements (skip header rows with th)
        $allRows = [regex]::Matches($TableHtml, '<tr[^>]*>(.*?)</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $rows = $allRows | Where-Object { $_.Value -match '<td' }
    }
    
    # Parse rows into objects
    $tableData = @()
    foreach ($row in $rows) {
        $cells = [regex]::Matches($row.Value, '<td[^>]*>(.*?)</td>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        $rowData = @{}
        for ($i = 0; $i -lt $cells.Count; $i++) {
            $cellHtml = $cells[$i].Groups[1].Value
            
            # Check for hyperlinks
            $hasLink = $cellHtml -match '<a\s+[^>]*href='
            
            # Extract text content and decode HTML entities
            $text = $cellHtml -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' ' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>'
            $text = $text.Trim()
            
            $columnName = if ($i -lt $headerNames.Count) { $headerNames[$i] } else { "Column$($i+1)" }
            
            $rowData[$columnName] = @{
                Text = if ($text) { $text } else { $null }
                HasLink = $hasLink
                Html = $cellHtml
            }
        }
        
        $tableData += [PSCustomObject]$rowData
    }
    
    return @{
        Headers = $headerNames
        Rows = $tableData
    }
}

# Function to build REST API URL for pages (handles nested spaces)
# XWiki REST API requires nested spaces to be formatted as:
#   /spaces/Parent/spaces/Child/spaces/GrandChild/pages/PageName
# Input space can be dot-separated: "QA Home.SubSpace.DeepSpace"
function Build-XWikiPageUrl {
    param(
        [string]$BaseUrl,
        [string]$Space,
        [string]$PageName
    )
    
    # Split space by dots to handle nested spaces
    $spaceParts = $Space -split '\.'
    
    # Build the nested spaces URL path
    $spacePath = ""
    for ($i = 0; $i -lt $spaceParts.Count; $i++) {
        $encodedSpace = [System.Uri]::EscapeDataString($spaceParts[$i])
        if ($i -eq 0) {
            $spacePath = "spaces/$encodedSpace"
        } else {
            $spacePath += "/spaces/$encodedSpace"
        }
    }
    
    $encodedPage = [System.Uri]::EscapeDataString($PageName)
    return "$BaseUrl/rest/wikis/xwiki/$spacePath/pages/$encodedPage"
}

# Try to get stored credentials
$storedCred = Get-StoredCredential -Target $CredentialTarget
$Username = $null
$Password = $null

if ($storedCred) {
    $Username = $storedCred.Username
    $Password = $storedCred.Password
    Write-Host "✓ Using stored credentials for: $Username" -ForegroundColor Green
}

# If no stored credentials retrieved, prompt user
if (-not $Username -or -not $Password) {
    Write-Host "Please enter XWiki credentials:" -ForegroundColor Cyan
    Write-Host ""
    
    $Username = Read-Host "Enter XWiki username"
    $SecurePassword = Read-Host "Enter XWiki password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    if (-not $Username -or -not $Password) {
        Write-Host "Username and password are required." -ForegroundColor Red
        exit 1
    }
    
    # Ask to save credentials (only if we just prompted for them)
    Write-Host ""
    $save = Read-Host "Save credentials to Windows Credential Manager? (Y/N)"
    if ($save -eq 'Y' -or $save -eq 'y') {
        Set-StoredCredential -Target $CredentialTarget -Username $Username -Password $Password
    }
}

# Create Basic Auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))

# Handle different actions
switch ($Action) {
    "Read" {
        # Original behavior - fetch HTML page and parse tables
        if (-not $Url) {
            Write-Host "Error: -Url parameter is required for Read action" -ForegroundColor Red
            exit 1
        }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "text/html"
        }
        
        Write-Host ""
        Write-Host "Fetching XWiki page..." -ForegroundColor Cyan
        Write-Host "URL: $Url" -ForegroundColor Gray
        Write-Host ""
        
        try {
            $response = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing
            
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ Successfully fetched page" -ForegroundColor Green
                
                $html = $response.Content
                $tableMatches = [regex]::Matches($html, '<table[^>]*>(.*?)</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                if ($tableMatches.Count -eq 0) {
                    Write-Host "No tables found on the page." -ForegroundColor Yellow
                    return
                }
                
                Write-Host ""
                Write-Host "Found $($tableMatches.Count) table(s) on the page" -ForegroundColor Cyan
                
                $tables = @()
                for ($i = 0; $i -lt $tableMatches.Count; $i++) {
                    $parsedTable = Parse-XWikiTable -TableHtml $tableMatches[$i].Value
                    $tables += [PSCustomObject]@{
                        Index = $i
                        Headers = $parsedTable.Headers
                        RowCount = $parsedTable.Rows.Count
                        Rows = $parsedTable.Rows
                    }
                }
                
                return $tables
            } else {
                Write-Host "Error: HTTP $($response.StatusCode)" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "Error fetching page: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    "Get" {
        # Get page content via REST API as JSON
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for Get action" -ForegroundColor Red
            exit 1
        }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        Write-Host "Getting page: $Space/$PageName" -ForegroundColor Cyan
        
        try {
            $page = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "✓ Page retrieved successfully" -ForegroundColor Green
            return $page
        } catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                Write-Host "Page not found: $Space/$PageName" -ForegroundColor Yellow
            } else {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            exit 1
        }
    }
    
    "GetContent" {
        # Get ONLY the page content (returns just the markdown/wiki content string)
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for GetContent action" -ForegroundColor Red
            exit 1
        }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        Write-Host "Getting content: $Space/$PageName" -ForegroundColor Cyan
        
        try {
            $page = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            Write-Host "✓ Content retrieved successfully" -ForegroundColor Green
            # Return just the content string
            return $page.content
        } catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                Write-Host "Page not found: $Space/$PageName" -ForegroundColor Yellow
            } else {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            exit 1
        }
    }
    
    "Create" {
        # Create a new page
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for Create action" -ForegroundColor Red
            exit 1
        }
        
        $pageTitle = if ($Title) { $Title } else { $PageName }
        $pageContent = if ($Content) { $Content } else { "# $pageTitle`n`nPage created on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            "Content-Type" = "application/xml"
            Accept = "application/xml"
        }
        
        # Escape XML special characters
        $escapedTitle = $pageTitle -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        $escapedContent = $pageContent -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        
        $xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><page xmlns=`"http://www.xwiki.org`"><title>$escapedTitle</title><syntax>markdown/1.2</syntax><content>$escapedContent</content></page>"
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        Write-Host "Creating page: $Space/$PageName" -ForegroundColor Cyan
        
        try {
            Invoke-RestMethod -Uri $apiUrl -Method PUT -Headers $headers -Body $xml | Out-Null
            Write-Host "✓ Page created successfully!" -ForegroundColor Green
            Write-Host "  View at: $BaseUrl/bin/view/$($Space -replace '\.', '/')/$PageName" -ForegroundColor Gray
            return @{ Success = $true; Space = $Space; PageName = $PageName; Url = "$BaseUrl/bin/view/$($Space -replace '\.', '/')/$PageName" }
        } catch {
            Write-Host "Error creating page: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    "Replace" {
        # Find and replace text in a page (useful for fixing typos without rewriting entire content)
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for Replace action" -ForegroundColor Red
            exit 1
        }
        if (-not $Find) {
            Write-Host "Error: -Find parameter is required for Replace action" -ForegroundColor Red
            exit 1
        }
        if (-not $PSBoundParameters.ContainsKey('Replace')) {
            Write-Host "Error: -Replace parameter is required for Replace action (can be empty string)" -ForegroundColor Red
            exit 1
        }
        
        # First, get the existing page
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        Write-Host "Fetching page for replacement: $Space/$PageName" -ForegroundColor Cyan
        
        try {
            $existingPage = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        } catch {
            Write-Host "Error: Page not found." -ForegroundColor Red
            exit 1
        }
        
        # Perform the replacement
        $oldContent = $existingPage.content
        $newContent = $oldContent -replace [regex]::Escape($Find), $Replace
        
        if ($oldContent -eq $newContent) {
            Write-Host "Warning: No matches found for '$Find' - page not modified" -ForegroundColor Yellow
            return @{ Success = $false; Message = "No matches found"; Find = $Find }
        }
        
        # Count replacements
        $matchCount = ([regex]::Matches($oldContent, [regex]::Escape($Find))).Count
        
        # Update the page
        $headers["Content-Type"] = "application/xml"
        $headers["Accept"] = "application/xml"
        
        $escapedTitle = $existingPage.title -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        $escapedContent = $newContent -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        
        $xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><page xmlns=`"http://www.xwiki.org`"><title>$escapedTitle</title><syntax>markdown/1.2</syntax><content>$escapedContent</content></page>"
        
        Write-Host "Replacing '$Find' with '$Replace' ($matchCount occurrence(s))" -ForegroundColor Cyan
        
        try {
            Invoke-RestMethod -Uri $apiUrl -Method PUT -Headers $headers -Body $xml | Out-Null
            Write-Host "✓ Replacement complete! $matchCount occurrence(s) replaced." -ForegroundColor Green
            return @{ Success = $true; Space = $Space; PageName = $PageName; ReplacementCount = $matchCount; Find = $Find; Replace = $Replace }
        } catch {
            Write-Host "Error updating page: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    "Update" {
        # Update an existing page
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for Update action" -ForegroundColor Red
            exit 1
        }
        
        if (-not $Title -and -not $Content) {
            Write-Host "Error: At least -Title or -Content must be provided for Update action" -ForegroundColor Red
            exit 1
        }
        
        # First, get the existing page to preserve values
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        
        try {
            $existingPage = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            $pageTitle = if ($Title) { $Title } else { $existingPage.title }
            $pageContent = if ($Content) { $Content } else { $existingPage.content }
        } catch {
            Write-Host "Error: Page not found. Use Create action for new pages." -ForegroundColor Red
            exit 1
        }
        
        $headers["Content-Type"] = "application/xml"
        $headers["Accept"] = "application/xml"
        
        # Escape XML special characters
        $escapedTitle = $pageTitle -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        $escapedContent = $pageContent -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
        
        $xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><page xmlns=`"http://www.xwiki.org`"><title>$escapedTitle</title><syntax>markdown/1.2</syntax><content>$escapedContent</content></page>"
        
        Write-Host "Updating page: $Space/$PageName" -ForegroundColor Cyan
        
        try {
            Invoke-RestMethod -Uri $apiUrl -Method PUT -Headers $headers -Body $xml | Out-Null
            Write-Host "✓ Page updated successfully!" -ForegroundColor Green
            return @{ Success = $true; Space = $Space; PageName = $PageName }
        } catch {
            Write-Host "Error updating page: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    "Delete" {
        # Delete a page
        if (-not $Space) {
            Write-Host "Error: -Space parameter is required for Delete action" -ForegroundColor Red
            exit 1
        }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        $apiUrl = Build-XWikiPageUrl -BaseUrl $BaseUrl -Space $Space -PageName $PageName
        Write-Host "Deleting page: $Space/$PageName" -ForegroundColor Yellow
        
        try {
            Invoke-RestMethod -Uri $apiUrl -Method DELETE -Headers $headers | Out-Null
            Write-Host "✓ Page deleted successfully!" -ForegroundColor Green
            return @{ Success = $true; Deleted = "$Space/$PageName" }
        } catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                Write-Host "Page not found (may already be deleted)" -ForegroundColor Yellow
            } else {
                Write-Host "Error deleting page: $($_.Exception.Message)" -ForegroundColor Red
            }
            exit 1
        }
    }
    
    "Search" {
        # Search for pages
        if (-not $Query) {
            Write-Host "Error: -Query parameter is required for Search action" -ForegroundColor Red
            exit 1
        }
        
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $searchUrl = "$BaseUrl/rest/wikis/xwiki/search?q=$([System.Uri]::EscapeDataString($Query))"
        Write-Host "Searching for: $Query" -ForegroundColor Cyan
        
        try {
            $response = Invoke-RestMethod -Uri $searchUrl -Headers $headers
            $results = $response.searchResults
            
            if ($results.Count -eq 0) {
                Write-Host "No results found." -ForegroundColor Yellow
                return @()
            }
            
            Write-Host "✓ Found $($results.Count) result(s)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($result in $results) {
                Write-Host "  $($result.title)" -ForegroundColor Yellow
                Write-Host "    Space: $($result.space)" -ForegroundColor Gray
                Write-Host "    URL: $BaseUrl/bin/view/$($result.space -replace '\.', '/')/$($result.pageName)" -ForegroundColor Gray
            }
            
            return $results
        } catch {
            Write-Host "Error searching: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    "ListSpaces" {
        # List all spaces
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            Accept = "application/json"
        }
        
        $apiUrl = "$BaseUrl/rest/wikis/xwiki/spaces"
        Write-Host "Listing XWiki spaces..." -ForegroundColor Cyan
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
            $spaces = $response.spaces
            
            Write-Host "✓ Found $($spaces.Count) space(s)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($s in $spaces) {
                Write-Host "  $($s.name)" -ForegroundColor Yellow
            }
            
            return $spaces
        } catch {
            Write-Host "Error listing spaces: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
}
