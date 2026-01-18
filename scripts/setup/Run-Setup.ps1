# Setup Wizard for QA Tools
# Interactive setup script for new users

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Text)
    Write-Host "[$Number] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Success {
    param([string]$Text)
    Write-Host "OK " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor Green
}

function Write-Info {
    param([string]$Text)
    Write-Host "  > " -ForegroundColor Gray -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Write-Error {
    param([string]$Text)
    Write-Host "X " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Navigate to workspace root (go up two levels from scripts/setup)
$WorkspaceRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Push-Location $WorkspaceRoot

# Start the wizard
Clear-Host
Write-Header "QA Tools Setup Wizard"
Write-Host "This wizard will help you set up all the tools you need for QA testing." -ForegroundColor White
Write-Host "Just follow the prompts and we'll get you up and running!" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to begin"

# Step 1: Check PowerShell version
Write-Header "Step 1: Checking PowerShell Version"
$psVersion = $PSVersionTable.PSVersion
Write-Info "Your PowerShell version: $($psVersion.Major).$($psVersion.Minor)"

if ($psVersion.Major -ge 5) {
    Write-Success "PowerShell version is compatible"
}
else {
    Write-Error "PowerShell 5.1 or later is required"
    Write-Host "Please upgrade PowerShell and run this setup again." -ForegroundColor Yellow
    exit 1
}

# Step 2: Set Execution Policy
Write-Header "Step 2: Configuring PowerShell Execution Policy"
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Info "Current policy: $currentPolicy"

if ($currentPolicy -eq "RemoteSigned" -or $currentPolicy -eq "Unrestricted") {
    Write-Success "Execution policy is already configured"
}
else {
    Write-Host "We need to allow local scripts to run." -ForegroundColor Yellow
    $response = Read-Host "Set execution policy to RemoteSigned? (Y/N)"
    
    if ($response -eq "Y" -or $response -eq "y") {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Success "Execution policy updated to RemoteSigned"
        }
        catch {
            Write-Error "Failed to set execution policy: $_"
            Write-Host "You may need to run PowerShell as Administrator." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "WARNING: Skipped - Some scripts may not run without this setting" -ForegroundColor Yellow
    }
}

# Step 3: Check MagicSuite CLI installation
Write-Header "Step 3: Checking MagicSuite CLI Installation"

if (Test-Command "magicsuite") {
    $version = magicsuite --version 2>&1
    Write-Success "MagicSuite CLI is installed"
    Write-Info "Version: $version"
    
    Write-Host ""
    $updateChoice = Read-Host "Would you like to check for updates? (y/N)"
    if ([string]::IsNullOrWhiteSpace($updateChoice)) { $updateChoice = "N" }
    if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
        Write-Host "Checking for updates to latest 4.1.x version..." -ForegroundColor Yellow
        dotnet tool update -g MagicSuite.Cli --version '4.1.*'
    }
}
else {
    Write-Host "MagicSuite CLI is not installed." -ForegroundColor Yellow
    $installChoice = Read-Host "Would you like to install it now? (Y/N)"
    
    if ($installChoice -eq "Y" -or $installChoice -eq "y") {
        Write-Host "Installing MagicSuite CLI..." -ForegroundColor Yellow
        
        if (-not (Test-Command "dotnet")) {
            Write-Error ".NET SDK is not installed"
            Write-Host "Please install .NET SDK from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
            Write-Host "After installing .NET SDK, run this setup again." -ForegroundColor Yellow
            exit 1
        }
        
        try {
            dotnet tool install -g MagicSuite.Cli --version '4.1.*'
            Write-Success "MagicSuite CLI installed successfully"
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            $version = magicsuite --version 2>&1
            Write-Info "Version: $version"
        }
        catch {
            Write-Error "Failed to install MagicSuite CLI: $_"
            exit 1
        }
    }
    else {
        Write-Host "WARNING: Skipped - MagicSuite CLI is required for testing" -ForegroundColor Yellow
    }
}

# Step 4: Configure MagicSuite CLI Authentication
Write-Header "Step 4: Configuring MagicSuite CLI Profile and Authentication"

# Check existing profiles
Write-Host "Checking for existing MagicSuite CLI profiles..." -ForegroundColor Yellow
$profileList = magicsuite config profiles list 2>&1

Write-Host ""
if ($profileList -match "Profile Name") {
    Write-Info "Existing profiles found:"
    Write-Host $profileList
    Write-Host ""
}
else {
    Write-Info "No profiles found yet."
}

$setupAuth = Read-Host "Would you like to configure a MagicSuite CLI profile now? (Y/N)"

if ($setupAuth -eq "Y" -or $setupAuth -eq "y") {
    Write-Host ""
    
    # Ask if they want to use existing or create new
    $useExisting = $false
    $profileName = ""
    $skipProfile = $false
    
    if ($profileList -match "Profile Name") {
        $choice = Read-Host "Use an existing profile (E) or create a new one (N)? (E/N)"
        if ($choice -eq "E" -or $choice -eq "e") {
            $useExisting = $true
            $profileName = Read-Host "Enter the profile name to configure"
        }
    }
    
    if (-not $useExisting) {
        # Create new profile
        Write-Host "Let's create a new profile:" -ForegroundColor Yellow
        $profileName = Read-Host "Enter a profile name (e.g., production, test, local)"
        
        # Validate profile name is not empty
        if ([string]::IsNullOrWhiteSpace($profileName)) {
            Write-Error "Profile name cannot be empty"
            $skipProfile = $true
        }
        else {
            $apiUrl = Read-Host "Enter API URL (e.g., https://api.test2.magicsuite.net)"
            
            # Validate API URL is not empty
            if ([string]::IsNullOrWhiteSpace($apiUrl)) {
                Write-Error "API URL cannot be empty"
                $skipProfile = $true
            }
            else {
                Write-Host "Creating profile..." -ForegroundColor Yellow
                try {
                    magicsuite config profiles add --name $profileName --api-url $apiUrl 2>&1 | Out-Null
                    Write-Success "Profile '$profileName' created"
                }
                catch {
                    Write-Host "  Note: Profile may already exist, continuing..." -ForegroundColor Gray
                }
            }
        }
    }
    
    # Only proceed with authentication if we have a valid profile
    if (-not $skipProfile -and -not [string]::IsNullOrWhiteSpace($profileName)) {
        # Configure authentication
        Write-Host ""
        Write-Host "Now let's configure authentication for profile: $profileName" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "To get your API token:"
    Write-Info "  1. Log in to your MagicSuite instance"
    Write-Info "  2. Go to your user settings/profile"
    Write-Info "  3. Navigate to API Tokens section"
    Write-Info "  4. Create a new token and copy both the token name and key"
    Write-Host ""
    
    $hasToken = Read-Host "Do you have your API token ready? (Y/N)"
    
    if ($hasToken -eq "Y" -or $hasToken -eq "y") {
        Write-Host ""
        Write-Host "Please enter your API token details:" -ForegroundColor Yellow
        $tokenName = Read-Host "API Token Name (long hexadecimal string)"
        $tokenKeySecure = Read-Host "API Token Key" -AsSecureString
        $tokenKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenKeySecure))
        
        Write-Host ""
        Write-Host "Configuring authentication..." -ForegroundColor Yellow
        
        try {
            magicsuite --profile $profileName auth token --name $tokenName --key $tokenKey 2>&1 | Out-Null
            Write-Success "Authentication configured for profile '$profileName'"
            
            # Test connection
            Write-Host ""
            Write-Host "Testing connection..." -ForegroundColor Yellow
            $testOutput = magicsuite --profile $profileName api get tenants 2>&1
            
            if ($testOutput -match "401 Unauthorized" -or $testOutput -match "Unauthorized") {
                Write-Host "WARNING: Authentication saved but connection test failed." -ForegroundColor Yellow
                Write-Info "This could mean the token expired or has insufficient permissions"
                Write-Info "Please verify your token in the MagicSuite web interface"
            }
            else {
                Write-Success "Connection test successful!"
            }
        }
        catch {
            Write-Error "Failed to configure authentication: $_"
        }
        finally {
            # Clear sensitive data from memory
            $tokenKey = $null
            $tokenKeySecure = $null
            [System.GC]::Collect()
        }
    }
    else {
        Write-Host "WARNING: Skipped authentication - You can configure it later by running:" -ForegroundColor Yellow
        Write-Info "magicsuite --profile $profileName auth token --name YOUR_TOKEN --key YOUR_KEY"
    }
}
else {
    Write-Host "WARNING: Skipped profile configuration" -ForegroundColor Yellow
    Write-Info "Run: magicsuite config profiles add --name myprofile --api-url https://your-api-url.com"
}
}
else {
    Write-Host "WARNING: Skipped - You can configure profiles later" -ForegroundColor Yellow
    Write-Info "Run: magicsuite config profiles add --name myprofile --api-url https://your-api-url.com"
}

# Step 5: Configure JIRA Credentials
Write-Header "Step 5: Configuring JIRA Credentials"

# Check if credentials already exist
$hasExistingJiraCreds = $false
$existingJiraUsername = ""

try {
    $credModule = Get-Module -ListAvailable -Name CredentialManager
    if ($credModule) {
        Import-Module CredentialManager -ErrorAction SilentlyContinue
        $cred = Get-StoredCredential -Target "PanoramicData_JIRA" -ErrorAction SilentlyContinue
        if ($cred) {
            $hasExistingJiraCreds = $true
            $existingJiraUsername = $cred.UserName
        }
    }
}
catch { }

if (-not $hasExistingJiraCreds -and $env:JIRA_USERNAME) {
    $hasExistingJiraCreds = $true
    $existingJiraUsername = $env:JIRA_USERNAME
}

if ($hasExistingJiraCreds) {
    Write-Success "JIRA credentials already configured"
    Write-Info "Username: $existingJiraUsername"
    Write-Host ""
    $updateJira = Read-Host "Would you like to update JIRA credentials? (y/N)"
    if ([string]::IsNullOrWhiteSpace($updateJira)) { $updateJira = "N" }
    $setupJira = $updateJira
}
else {
    Write-Host "You'll need your JIRA credentials to create and update tickets." -ForegroundColor White
    Write-Host ""
    Write-Info "JIRA URL: https://jira.panoramicdata.com"
    Write-Info "You can use your JIRA password or an API token (recommended)"
    Write-Host ""
    $setupJira = Read-Host "Would you like to configure JIRA credentials now? (Y/N)"
}

if ($setupJira -eq "Y" -or $setupJira -eq "y") {
    Write-Host ""
    Write-Host "Please enter your JIRA credentials:" -ForegroundColor Yellow
    
    $jiraUsername = Read-Host "JIRA Username (e.g. firstname.lastname)"
    $jiraPassword = Read-Host "JIRA Password or API Token" -AsSecureString
    
    try {
        # Store in Windows Credential Manager using CredentialManager module if available
        $credModule = Get-Module -ListAvailable -Name CredentialManager
        
        if ($credModule) {
            Import-Module CredentialManager
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($jiraPassword))
            
            # Remove existing credential if present (idempotent)
            $existingCred = Get-StoredCredential -Target "PanoramicData_JIRA" -ErrorAction SilentlyContinue
            if ($existingCred) {
                Remove-StoredCredential -Target "PanoramicData_JIRA" -ErrorAction SilentlyContinue | Out-Null
            }
            
            New-StoredCredential -Target "PanoramicData_JIRA" -UserName $jiraUsername -Password $plainPassword -Type Generic -Persist LocalMachine | Out-Null
            Write-Success "JIRA credentials saved to Windows Credential Manager"
            # Clear sensitive data from memory immediately
            $plainPassword = $null
            [System.GC]::Collect()
        }
        else {
            # Fallback to environment variables
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($jiraPassword))
            [System.Environment]::SetEnvironmentVariable('JIRA_USERNAME', $jiraUsername, 'User')
            [System.Environment]::SetEnvironmentVariable('JIRA_PASSWORD', $plainPassword, 'User')
            $env:JIRA_USERNAME = $jiraUsername
            $env:JIRA_PASSWORD = $plainPassword
            Write-Success "JIRA credentials saved to environment variables"
            Write-Info "Note: Install CredentialManager module for more secure storage:"
            Write-Info "Install-Module -Name CredentialManager -Force"
            # Clear sensitive data from memory immediately
            $plainPassword = $null
            [System.GC]::Collect()
        }
        
        # Test JIRA connection
        Write-Host ""
        Write-Host "Testing JIRA connection..." -ForegroundColor Yellow
        if (Test-Path ".\.github\tools\JIRA.ps1") {
            $testResult = .\.github\tools\JIRA.ps1 get MS-1 2>&1
            if ($testResult -notmatch "error" -and $testResult -notmatch "failed") {
                Write-Success "JIRA connection successful"
            }
            else {
                Write-Host "WARNING: JIRA connection test inconclusive - verify credentials later" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Error "Failed to save JIRA credentials: $_"
        Write-Info "You can configure this later using environment variables or the JIRA tool"
    }
    finally {
        # Ensure sensitive data is cleared even if there's an error
        $jiraPassword = $null
        $plainPassword = $null
        [System.GC]::Collect()
    }
}
else {
    Write-Host "WARNING: Skipped - You can configure JIRA credentials later" -ForegroundColor Yellow
    Write-Info "Run: .\.github\tools\JIRA.ps1"
}

# Step 6: Configure XWiki Credentials
Write-Header "Step 6: Configuring XWiki Credentials"

# Check if credentials already exist
$hasExistingXWikiCreds = $false
$existingXWikiUsername = ""

try {
    $credModule = Get-Module -ListAvailable -Name CredentialManager
    if ($credModule) {
        Import-Module CredentialManager -ErrorAction SilentlyContinue
        $cred = Get-StoredCredential -Target "LogicMonitor:XWiki" -ErrorAction SilentlyContinue
        if ($cred) {
            $hasExistingXWikiCreds = $true
            $existingXWikiUsername = $cred.UserName
        }
    }
}
catch { }

# Also check native cmdkey for credential
if (-not $hasExistingXWikiCreds) {
    $cmdkeyOutput = cmdkey /list 2>&1 | Out-String
    if ($cmdkeyOutput -match 'LogicMonitor:XWiki') {
        $hasExistingXWikiCreds = $true
        $existingXWikiUsername = "stored in Credential Manager"
    }
}

if ($hasExistingXWikiCreds) {
    Write-Success "XWiki credentials already configured"
    Write-Info "Username: $existingXWikiUsername"
    Write-Host ""
    $updateXWiki = Read-Host "Would you like to update XWiki credentials? (y/N)"
    if ([string]::IsNullOrWhiteSpace($updateXWiki)) { $updateXWiki = "N" }
    $setupXWiki = $updateXWiki
}
else {
    Write-Host "XWiki credentials allow you to read and update wiki documentation." -ForegroundColor White
    Write-Host ""
    Write-Info "XWiki URL: https://wiki.panoramicdata.com"
    Write-Info "You can use your XWiki password"
    Write-Host ""
    $setupXWiki = Read-Host "Would you like to configure XWiki credentials now? (Y/N)"
}

if ($setupXWiki -eq "Y" -or $setupXWiki -eq "y") {
    Write-Host ""
    Write-Host "Please enter your XWiki credentials:" -ForegroundColor Yellow
    
    $xwikiUsername = Read-Host "XWiki Username (e.g. firstname_lastname)"
    $xwikiPassword = Read-Host "XWiki Password" -AsSecureString
    
    try {
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($xwikiPassword))
        
        # Store using cmdkey (native Windows credential manager)
        # Remove existing credential if present
        cmdkey /delete:LogicMonitor:XWiki 2>&1 | Out-Null
        
        # Add new credential
        $cmdkeyResult = cmdkey /generic:LogicMonitor:XWiki /user:$xwikiUsername /pass:$plainPassword 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "XWiki credentials saved to Windows Credential Manager"
        }
        else {
            Write-Host "WARNING: Failed to save credentials via cmdkey, trying CredentialManager module..." -ForegroundColor Yellow
            
            # Fallback to CredentialManager module
            $credModule = Get-Module -ListAvailable -Name CredentialManager
            if ($credModule) {
                Import-Module CredentialManager
                
                # Remove existing credential if present
                $existingCred = Get-StoredCredential -Target "LogicMonitor:XWiki" -ErrorAction SilentlyContinue
                if ($existingCred) {
                    Remove-StoredCredential -Target "LogicMonitor:XWiki" -ErrorAction SilentlyContinue | Out-Null
                }
                
                New-StoredCredential -Target "LogicMonitor:XWiki" -UserName $xwikiUsername -Password $plainPassword -Type Generic -Persist LocalMachine | Out-Null
                Write-Success "XWiki credentials saved to Windows Credential Manager"
            }
            else {
                Write-Host "ERROR: Could not save XWiki credentials" -ForegroundColor Red
                Write-Info "Install CredentialManager module: Install-Module -Name CredentialManager -Force"
            }
        }
        
        # Test XWiki connection
        Write-Host ""
        Write-Host "Testing XWiki connection..." -ForegroundColor Yellow
        if (Test-Path ".\.github\tools\XWiki.ps1") {
            $testResult = .\.github\tools\XWiki.ps1 -Action Search -Query "QA" 2>&1
            if ($testResult -notmatch "error" -and $testResult -notmatch "401") {
                Write-Success "XWiki connection successful"
            }
            else {
                Write-Host "WARNING: XWiki connection test inconclusive - verify credentials later" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Error "Failed to save XWiki credentials: $_"
        Write-Info "You can configure this later using the XWiki tool"
    }
    finally {
        # Ensure sensitive data is cleared even if there's an error
        $xwikiPassword = $null
        $plainPassword = $null
        [System.GC]::Collect()
    }
}
else {
    Write-Host "WARNING: Skipped - You can configure XWiki credentials later" -ForegroundColor Yellow
    Write-Info "Run: .\.github\tools\XWiki.ps1 -Action Search -Query 'test'"
}

# Step 7: Check Node.js and Playwright Setup
Write-Header "Step 7: Checking Node.js and Playwright for UI Testing"

Write-Host "Node.js is required for Playwright UI testing tools." -ForegroundColor White
Write-Host ""

# Check if Node.js is installed
if (Test-Command "node") {
    $nodeVersion = node --version 2>&1
    Write-Success "Node.js is installed"
    Write-Info "Version: $nodeVersion"
    
    # Check if npm is available
    if (Test-Command "npm") {
        $npmVersion = npm --version 2>&1
        Write-Success "npm is installed"
        Write-Info "Version: $npmVersion"
        
        # Check if playwright directory exists and has node_modules
        if (Test-Path ".\playwright\package.json") {
            Write-Host ""
            
            # Check if already installed
            $playwrightInstalled = Test-Path ".\playwright\node_modules\@playwright\test"
            
            if ($playwrightInstalled) {
                Write-Success "Playwright dependencies already installed"
                $playwrightSetup = Read-Host "Would you like to update Playwright dependencies? (y/N)"
                if ([string]::IsNullOrWhiteSpace($playwrightSetup)) { $playwrightSetup = "N" }
            }
            else {
                $playwrightSetup = Read-Host "Would you like to install Playwright dependencies? (Y/N)"
            }
            
            if ($playwrightSetup -eq "Y" -or $playwrightSetup -eq "y") {
                Write-Host "Installing Playwright dependencies..." -ForegroundColor Yellow
                Push-Location ".\playwright"
                try {
                    npm install
                    Write-Success "Playwright dependencies installed"
                    
                    Write-Host ""
                    
                    # Check if Chromium browser is already installed
                    $chromiumInstalled = $false
                    $playwrightCachePath = "$env:USERPROFILE\AppData\Local\ms-playwright\chromium-*"
                    if (Test-Path $playwrightCachePath) {
                        $chromiumInstalled = $true
                    }
                    
                    if ($chromiumInstalled) {
                        Write-Success "Playwright Chromium browser already installed"
                        $installBrowsers = Read-Host "Would you like to update Playwright browsers? (y/N)"
                        if ([string]::IsNullOrWhiteSpace($installBrowsers)) { $installBrowsers = "N" }
                    }
                    else {
                        $installBrowsers = Read-Host "Would you like to install Playwright browsers? (Y/N)"
                    }
                    
                    if ($installBrowsers -eq "Y" -or $installBrowsers -eq "y") {
                        Write-Host "Installing Playwright browsers (this may take a few minutes)..." -ForegroundColor Yellow
                        npx playwright install chromium
                        Write-Success "Playwright Chromium browser installed"
                    }
                }
                catch {
                    Write-Error "Failed to install Playwright: $_"
                }
                finally {
                    Pop-Location
                }
            }
        }
        else {
            Write-Info "Playwright configuration not found (playwright/package.json)"
        }
    }
    else {
        Write-Error "npm is not installed (should come with Node.js)"
    }
}
else {
    Write-Host "Node.js is not installed." -ForegroundColor Yellow
    Write-Host ""
    Write-Info "Node.js is required for Playwright UI testing tools"
    Write-Info "Download from: https://nodejs.org/ (LTS version recommended)"
    Write-Host ""
    $installNode = Read-Host "Open download page in browser? (Y/N)"
    
    if ($installNode -eq "Y" -or $installNode -eq "y") {
        Start-Process "https://nodejs.org/"
        Write-Info "After installing Node.js, restart this terminal and run setup again"
    }
}

# Step 7b: Configure Playwright Output Location (OneDrive)
Write-Header "Step 7b: Configure Playwright Output Location (OneDrive)"

Write-Host "Playwright test videos and artifacts can be saved to a folder you choose." -ForegroundColor White
Write-Host ""
# Try to detect OneDrive root(s) and find a Panoramic* folder
$oneDriveRoots = @()
if ($env:OneDriveCommercial) { $oneDriveRoots += $env:OneDriveCommercial }
if ($env:OneDrive) { $oneDriveRoots += $env:OneDrive }
if ($env:OneDriveConsumer) { $oneDriveRoots += $env:OneDriveConsumer }

$oneDriveRoots = $oneDriveRoots | Where-Object { $_ } | Get-Unique

$foundDefault = $null
foreach ($root in $oneDriveRoots) {
    try {
        $children = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
        if ($children) {
            # Prefer exact known names, then any folder starting with "Panoramic"
            $preferred = $children | Where-Object { $_.Name -in @('Panoramic Data Limited','Panoramic Data','PanoramicData') } | Select-Object -First 1
            if (-not $preferred) {
                $preferred = $children | Where-Object { $_.Name -match '^Panoramic' } | Select-Object -First 1
            }
            if ($preferred) {
                $foundDefault = Join-Path $preferred.FullName "QA\playwright tests"
                break
            }
        }
    }
    catch { }
}

if (-not $foundDefault -and $oneDriveRoots.Count -gt 0) {
    # Fallback to first OneDrive root with a common folder name
    $foundDefault = Join-Path $oneDriveRoots[0] "Panoramic Data\QA\playwright tests"
}

if ($foundDefault) {
    $defaultPath = $foundDefault
    $defaultLabel = "Detected OneDrive"
}
else {
    $defaultPath = Join-Path $WorkspaceRoot "test-results\playwright"
    $defaultLabel = "Repository fallback"
}

Write-Host "Where should Playwright save videos and artifacts?" -ForegroundColor Cyan
Write-Host "  1) Use default ($defaultLabel): $defaultPath" -ForegroundColor Gray
Write-Host "  2) Enter a custom folder path (full path)" -ForegroundColor Gray
Write-Host "  3) Skip (videos will be disabled to avoid repo storage)" -ForegroundColor Gray
Write-Host ""
$choice = Read-Host "Choose 1, 2 or 3 (press Enter for 1)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

switch ($choice) {
    '1' {
        $targetPath = $defaultPath
    }
    '2' {
        $entered = Read-Host "Enter full folder path for Playwright outputs"
        if ([string]::IsNullOrWhiteSpace($entered)) {
            Write-Host "No path entered - falling back to default." -ForegroundColor Yellow
            $targetPath = $defaultPath
        }
        else { $targetPath = $entered }
    }
    '3' {
        $targetPath = $null
    }
    default {
        Write-Host "Invalid choice - using default." -ForegroundColor Yellow
        $targetPath = $defaultPath
    }
}

if ($targetPath) {
    try {
        if (-not (Test-Path $targetPath)) {
            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
            Write-Success "Created folder: $targetPath"
        }
        else {
            Write-Success "Folder exists: $targetPath"
        }

        # Persist environment variable for the current user and set for this session
        [System.Environment]::SetEnvironmentVariable('MS_VIDEO_DIR', $targetPath, 'User')
        $env:MS_VIDEO_DIR = $targetPath
        Write-Info "Saved MS_VIDEO_DIR to your user environment and set for this session"
        Write-Info 'To change later re-run this setup or remove with: [Environment]::SetEnvironmentVariable("MS_VIDEO_DIR", $null, "User")'
    }
    catch {
        Write-Error "Failed to set MS_VIDEO_DIR: $_"
    }
}
else {
    Write-Host "Skipping OneDrive configuration. Videos will be disabled to avoid storing large files in the repository." -ForegroundColor Gray
}

# Step 8: Configure Playwright Authentication
Write-Header "Step 8: Configuring Playwright Authentication"

if (Test-Command "node") {
    # Check if authentication already exists
    $authExists = Test-Path ".\playwright\.auth\user.json"
    
    if ($authExists) {
        Write-Success "Playwright authentication already configured"
        Write-Info "Authentication state file exists: .\playwright\.auth\user.json"
        Write-Host ""
        $setupPlaywrightAuth = Read-Host "Would you like to update/refresh authentication? (y/N)"
        if ([string]::IsNullOrWhiteSpace($setupPlaywrightAuth)) { $setupPlaywrightAuth = "N" }
    }
    else {
        Write-Host "Playwright tests can save your login session for faster testing." -ForegroundColor White
        Write-Host ""
        Write-Info "This will:"
        Write-Info "  1. Open a browser window"
        Write-Info "  2. Let you log in to Magic Suite manually"
        Write-Info "  3. Save your login cookies for all future tests"
        Write-Host ""
        
        $setupPlaywrightAuth = Read-Host "Would you like to set up Playwright authentication now? (Y/N)"
    }
    
    if ($setupPlaywrightAuth -eq "Y" -or $setupPlaywrightAuth -eq "y") {
        Write-Host ""
        Write-Host "Which environment would you like to log in to?" -ForegroundColor Yellow
        Write-Host "  1. alpha"
        Write-Host "  2. alpha2"
        Write-Host "  3. test"
        Write-Host "  4. test2"
        Write-Host "  5. beta"
        Write-Host "  6. staging"
        Write-Host "  7. production"
        Write-Host ""
        
        $envChoice = Read-Host "Enter choice (1-7)"
        
        $envMap = @{
            "1" = "alpha"
            "2" = "alpha2"
            "3" = "test"
            "4" = "test2"
            "5" = "beta"
            "6" = "staging"
            "7" = "production"
        }
        
        $selectedEnv = $envMap[$envChoice]
        
        if ($selectedEnv) {
            Write-Host ""
            Write-Host "Setting up authentication for $selectedEnv environment..." -ForegroundColor Yellow
            Write-Host ""
            Write-Info "The Playwright Inspector will open with a browser window"
            Write-Info "Steps to complete authentication:"
            Write-Info "  1. Log in to Magic Suite in the browser window"
            Write-Info "  2. Wait for the page to fully load after login"
            Write-Info "  3. Click the 'Resume' button in the Playwright Inspector window"
            Write-Info "  4. Your login session will be saved to .auth/user.json"
            Write-Host ""
            Write-Host "NOTE: The browser will pause and wait for you - take your time!" -ForegroundColor Cyan
            Write-Host ""
            Read-Host "Press Enter when ready to continue"
            
            Push-Location ".\playwright"
            try {
                $env:MS_ENV = $selectedEnv
                
                # Try Firefox first
                Write-Host "Opening Firefox browser..." -ForegroundColor Yellow
                
                # First ensure Firefox is installed
                npx playwright install firefox 2>&1 | Out-Null
                
                $firefoxResult = npx playwright test auth.setup --headed --project=firefox 2>&1
                
                # Check if auth file was created
                if (Test-Path ".\.auth\user.json") {
                    Write-Success "Authentication state saved successfully!"
                    Write-Info "Session cookies saved for environment: $selectedEnv"
                    Write-Info "All tests will now use this logged-in session"
                    Write-Info "Cookie details: .AspNetCore.MagicSuite$($selectedEnv.Substring(0,1).ToUpper())$($selectedEnv.Substring(1))"
                }
                else {
                    # Firefox failed, try Chrome
                    Write-Host "Firefox didn't work, trying Chrome..." -ForegroundColor Yellow
                    
                    $chromeResult = npx playwright test auth.setup --headed --project=chromium 2>&1
                    
                    if (Test-Path ".\.auth\user.json") {
                        Write-Success "Authentication state saved successfully!"
                        Write-Info "Session cookies saved for environment: $selectedEnv"
                        Write-Info "All tests will now use this logged-in session"
                        Write-Info "Cookie details: .AspNetCore.MagicSuite$($selectedEnv.Substring(0,1).ToUpper())$($selectedEnv.Substring(1))"
                    }
                    else {
                        Write-Host "WARNING: Authentication file not found - you may need to try again" -ForegroundColor Yellow
                        Write-Info "Make sure to click 'Resume' in the Playwright Inspector after logging in"
                        Write-Info "Output: $firefoxResult"
                    }
                }
            }
            catch {
                Write-Error "Failed to set up authentication: $_"
                Write-Info "You can try again later by running:"
                Write-Info "  cd playwright; `$env:MS_ENV='$selectedEnv'; npx playwright test auth.setup --headed --project=firefox"
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "Invalid choice - skipping authentication setup" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Skipped - You can set up authentication later by running:" -ForegroundColor Yellow
        Write-Info "cd playwright; `$env:MS_ENV='test2'; npx playwright test auth.setup --headed --project=firefox"
        Write-Info "Remember: Log in, then click 'Resume' in the Playwright Inspector to save the session"
    }
}
else {
    Write-Host "Skipped - Node.js must be installed first" -ForegroundColor Yellow
}

# Step 8b: Configure Additional User Roles (Optional)
Write-Header "Step 8b: Configuring Additional User Roles (Optional)"

if (Test-Command "node") {
    Write-Host "Some tests require different user permission levels:" -ForegroundColor White
    Write-Host ""
    Write-Info "  • Super Admin - For tenant management, all-tenants queries"
    Write-Info "  • Uber Admin  - Highest level admin access"
    Write-Info "  • Regular User - Standard user permissions (non-admin)"
    Write-Host ""
    Write-Host "Your default authentication (Step 8) is used for most tests." -ForegroundColor Gray
    Write-Host "Additional roles are only needed when testing specific permissions." -ForegroundColor Gray
    Write-Host ""
    
    $setupRoles = Read-Host "Would you like to set up additional user roles now? (y/N)"
    if ([string]::IsNullOrWhiteSpace($setupRoles)) { $setupRoles = "N" }
    
    if ($setupRoles -eq "Y" -or $setupRoles -eq "y") {
        Write-Host ""
        Write-Host "Which user roles would you like to configure?" -ForegroundColor Yellow
        Write-Host "  1. Super Admin"
        Write-Host "  2. Uber Admin"
        Write-Host "  3. Regular User"
        Write-Host "  4. All of the above"
        Write-Host "  5. Skip"
        Write-Host ""
        
        $roleChoice = Read-Host "Enter choice (1-5)"
        
        $rolesToSetup = @()
        switch ($roleChoice) {
            "1" { $rolesToSetup = @("super-admin") }
            "2" { $rolesToSetup = @("uber-admin") }
            "3" { $rolesToSetup = @("regular-user") }
            "4" { $rolesToSetup = @("super-admin", "uber-admin", "regular-user") }
            default { Write-Host "Skipping additional user roles" -ForegroundColor Gray }
        }
        
        if ($rolesToSetup.Count -gt 0) {
            # Use the same environment as the main auth setup
            $envForRoles = if ($selectedEnv) { $selectedEnv } else { "alpha2" }
            
            Write-Host ""
            Write-Host "Setting up roles for environment: $envForRoles" -ForegroundColor Cyan
            Write-Host ""
            
            foreach ($role in $rolesToSetup) {
                $roleName = switch ($role) {
                    "super-admin" { "Super Admin" }
                    "uber-admin" { "Uber Admin" }
                    "regular-user" { "Regular User" }
                }
                
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
                Write-Host "Configuring: $roleName" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
                Write-Host ""
                Write-Info "⚠️  IMPORTANT: Log in with $roleName credentials"
                Write-Info "   This is a DIFFERENT account than your default login"
                Write-Host ""
                Write-Host "Steps:" -ForegroundColor Cyan
                Write-Info "  1. Browser will open and pause at Playwright Inspector"
                Write-Info "  2. Log in with $roleName account in the browser"
                Write-Info "  3. After login completes, click 'Resume' in Inspector"
                Write-Info "  4. Session will be saved to .auth/$role.json"
                Write-Host ""
                Read-Host "Press Enter when ready to proceed with $roleName login"
                
                Push-Location ".\playwright"
                try {
                    $env:MS_ENV = $envForRoles
                    
                    # Install Firefox if not already installed
                    npx playwright install firefox 2>&1 | Out-Null
                    
                    Write-Host "Opening browser for $roleName authentication..." -ForegroundColor Yellow
                    $authResult = npx playwright test "auth.setup.$role" --headed --project=firefox 2>&1
                    
                    if (Test-Path ".\.auth\$role.json") {
                        Write-Success "$roleName authentication saved successfully!"
                        Write-Info "File: .auth\$role.json"
                        Write-Info "Usage: npx playwright test --project=$role"
                    }
                    else {
                        Write-Host "WARNING: $roleName authentication file not created" -ForegroundColor Yellow
                        Write-Info "Make sure to click 'Resume' in Playwright Inspector after logging in"
                        Write-Info "You can retry later with: npx playwright test auth.setup.$role --headed"
                    }
                }
                catch {
                    Write-Error "Failed to set up $roleName authentication: $_"
                    Write-Info "You can try again later by running:"
                    Write-Info "  cd playwright; npx playwright test auth.setup.$role --headed"
                }
                finally {
                    Pop-Location
                }
                
                Write-Host ""
            }
            
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Success "User role setup complete!"
            Write-Host ""
            Write-Host "To use different roles in tests:" -ForegroundColor Cyan
            Write-Info "  Default user:   npx playwright test"
            if ($rolesToSetup -contains "super-admin") {
                Write-Info "  Super Admin:    npx playwright test --project=super-admin"
            }
            if ($rolesToSetup -contains "uber-admin") {
                Write-Info "  Uber Admin:     npx playwright test --project=uber-admin"
            }
            if ($rolesToSetup -contains "regular-user") {
                Write-Info "  Regular User:   npx playwright test --project=regular-user"
            }
            Write-Host ""
            Write-Host "See .\playwright\.auth\README.md for more details" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "Skipped - You can set up additional roles later by running:" -ForegroundColor Yellow
        Write-Info "cd playwright; npx playwright test auth.setup.super-admin --headed"
        Write-Info "cd playwright; npx playwright test auth.setup.uber-admin --headed"
        Write-Info "cd playwright; npx playwright test auth.setup.regular-user --headed"
    }
}
else {
    Write-Host "Skipped - Node.js must be installed first" -ForegroundColor Yellow
}

# Step 9: Final verification
Write-Header "Step 9: Verifying Setup"
Write-Host "Running final checks..." -ForegroundColor Yellow
Write-Host ""

$allGood = $true

# Check MagicSuite CLI
Write-Step "1" "MagicSuite CLI"
if (Test-Command "magicsuite") {
    Write-Success "  Installed and accessible"
}
else {
    Write-Error "  Not found"
    $allGood = $false
}

# Check execution policy
Write-Step "2" "PowerShell Execution Policy"
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "RemoteSigned" -or $policy -eq "Unrestricted") {
    Write-Success "  Configured: $policy"
}
else {
    Write-Host "  WARNING: Current: $policy (may block scripts)" -ForegroundColor Yellow
}

# Check JIRA credentials
Write-Step "3" "JIRA Credentials"
$hasJiraCreds = $false
try {
    $credModule = Get-Module -ListAvailable -Name CredentialManager
    if ($credModule) {
        Import-Module CredentialManager
        $cred = Get-StoredCredential -Target "PanoramicData_JIRA" -ErrorAction SilentlyContinue
        if ($cred) {
            $hasJiraCreds = $true
        }
    }
}
catch { }

if (-not $hasJiraCreds -and $env:JIRA_USERNAME -and $env:JIRA_PASSWORD) {
    $hasJiraCreds = $true
}

if ($hasJiraCreds) {
    Write-Success "  Configured"
}
else {
    Write-Host "  WARNING: Not configured yet" -ForegroundColor Yellow
    Write-Info "  Run: .\.github\tools\JIRA.ps1"
}

# Check XWiki credentials
Write-Step "4" "XWiki Credentials"
$hasXWikiCreds = $false
$cmdkeyOutput = cmdkey /list 2>&1 | Out-String
if ($cmdkeyOutput -match 'LogicMonitor:XWiki') {
    $hasXWikiCreds = $true
}

if ($hasXWikiCreds) {
    Write-Success "  Configured"
}
else {
    Write-Host "  WARNING: Not configured yet" -ForegroundColor Yellow
    Write-Info "  Run: .\.github\tools\XWiki.ps1"
}

# Check Node.js
Write-Step "5" "Node.js for Playwright"
if (Test-Command "node") {
    $nodeVersion = node --version 2>&1
    Write-Success "  Installed: $nodeVersion"
}
else {
    Write-Host "  WARNING: Not installed - required for Playwright UI testing" -ForegroundColor Yellow
    Write-Info "  Download from: https://nodejs.org/"
}

# Check Playwright setup
Write-Step "6" "Playwright Dependencies"
if ((Test-Path ".\playwright\node_modules") -and (Test-Path ".\playwright\.auth")) {
    Write-Success "  Installed and configured"
    
    # Check if auth file exists
    if (Test-Path ".\playwright\.auth\user.json") {
        Write-Info "  Authentication state saved"
    }
    else {
        Write-Host "  INFO: No saved authentication (tests may require login)" -ForegroundColor Gray
    }
}
elseif (Test-Path ".\playwright\node_modules") {
    Write-Success "  Dependencies installed"
    Write-Host "  INFO: No authentication state saved yet" -ForegroundColor Gray
}
else {
    Write-Host "  WARNING: Not installed yet" -ForegroundColor Yellow
    Write-Info "  Run: cd playwright; npm install"
}

# Check MagicSuite auth
Write-Step "7" "MagicSuite CLI Authentication"
$configPath = "$env:USERPROFILE\.magicsuite"
$hasConfig = $false

if (Test-Path $configPath) {
    # Check if there are any config files in the directory
    $configFiles = Get-ChildItem $configPath -File -ErrorAction SilentlyContinue
    if ($configFiles -and $configFiles.Count -gt 0) {
        $hasConfig = $true
    }
}

if ($hasConfig) {
    Write-Success "  Configuration found"
}
else {
    Write-Host "  WARNING: Not configured yet" -ForegroundColor Yellow
    Write-Info "  Run this wizard again and configure a profile, or run:"
    Write-Info "  magicsuite auth token --profile PROFILE_NAME --name TOKEN_NAME --key TOKEN_KEY"
}

# Summary
Write-Header "Setup Complete!"

if ($allGood) {
    Write-Host "SUCCESS! Congratulations! Your QA tools are ready to use." -ForegroundColor Green
}
else {
    Write-Host "WARNING: Setup complete with some items requiring attention." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review SETUP-INSTRUCTIONS.md for detailed documentation" -ForegroundColor White
Write-Host "  2. Check out Testing-Ideas.md for testing strategies" -ForegroundColor White
Write-Host "  3. Try running: magicsuite --help" -ForegroundColor White
Write-Host "  4. Explore the test-plans directory for examples" -ForegroundColor White
Write-Host ""
Write-Host "Quick Commands:" -ForegroundColor Cyan
Write-Host "  - Test MagicSuite CLI:  magicsuite --version" -ForegroundColor Gray
Write-Host "  - Test JIRA:            .\.github\tools\JIRA.ps1 get MS-1" -ForegroundColor Gray
Write-Host "  - Test XWiki:           .\.github\tools\XWiki.ps1 -Action Search -Query 'QA'" -ForegroundColor Gray
Write-Host "  - View all profiles:    magicsuite config profiles list" -ForegroundColor Gray
Write-Host ""
Write-Host "Need help? Check SETUP-INSTRUCTIONS.md or ask the team!" -ForegroundColor Yellow

# Return to original directory
Pop-Location
Write-Host ""
