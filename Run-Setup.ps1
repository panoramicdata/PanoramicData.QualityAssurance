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
    $updateChoice = Read-Host "Would you like to check for updates? (Y/N)"
    if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
        Write-Host "Checking for updates..." -ForegroundColor Yellow
        dotnet tool update -g MagicSuite.Cli
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
            dotnet tool install -g MagicSuite.Cli
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
Write-Host "You'll need your JIRA credentials to create and update tickets." -ForegroundColor White
Write-Host ""
Write-Info "JIRA URL: https://jira.panoramicdata.com"
Write-Info "You can use your JIRA password or an API token (recommended)"
Write-Host ""

$setupJira = Read-Host "Would you like to configure JIRA credentials now? (Y/N)"

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

# Step 6: Final verification
Write-Header "Step 6: Verifying Setup"
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

# Check MagicSuite auth
Write-Step "4" "MagicSuite CLI Authentication"
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
Write-Host "  - View all profiles:    magicsuite config profiles list" -ForegroundColor Gray
Write-Host ""
Write-Host "Need help? Check SETUP-INSTRUCTIONS.md or ask the team!" -ForegroundColor Yellow
Write-Host ""
