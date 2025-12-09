# Secure Authentication Setup for MagicSuite CLI
# This script helps you set up API token credentials securely

Write-Host "=== MagicSuite CLI Authentication Setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you securely store your MagicSuite API token." -ForegroundColor Yellow
Write-Host "The credentials will be stored in: $env:USERPROFILE\.magicsuite\" -ForegroundColor Gray
Write-Host "Only your Windows user account can access these credentials." -ForegroundColor Gray
Write-Host ""

# Check for existing profiles
Write-Host "Checking for existing profiles..." -ForegroundColor Yellow
$profileList = magicsuite config profiles list 2>&1

if ($profileList -match "Profile Name") {
    Write-Host ""
    Write-Host "Available profiles:" -ForegroundColor Cyan
    Write-Host $profileList
    Write-Host ""
    $profileName = Read-Host "Enter the profile name to configure"
}
else {
    Write-Host ""
    Write-Host "No profiles found. Let's create one." -ForegroundColor Yellow
    $profileName = Read-Host "Enter a profile name (e.g., production, test, local)"
    $apiUrl = Read-Host "Enter API URL (e.g., https://api.test2.magicsuite.net)"
    
    Write-Host "Creating profile..." -ForegroundColor Yellow
    magicsuite config profiles add --name $profileName --api-url $apiUrl
}

Write-Host ""
Write-Host "Configuring authentication for profile: $profileName" -ForegroundColor Cyan
Write-Host ""

# Get token name
Write-Host "Please enter your API Token Name:" -ForegroundColor Yellow
Write-Host "(This is typically a long hexadecimal string)" -ForegroundColor Gray
$tokenName = Read-Host "Token Name"

if ([string]::IsNullOrWhiteSpace($tokenName)) {
    Write-Host "Error: Token name cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get token key securely
Write-Host "Please enter your API Token Key:" -ForegroundColor Yellow
Write-Host "(Your input will be hidden for security)" -ForegroundColor Gray
$tokenKeySecure = Read-Host "Token Key" -AsSecureString
$tokenKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenKeySecure))

if ([string]::IsNullOrWhiteSpace($tokenKey)) {
    Write-Host "Error: Token key cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setting up authentication..." -ForegroundColor Yellow

# Run the magicsuite auth command
try {
    $output = magicsuite --profile $profileName auth token --name $tokenName --key $tokenKey 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Authentication configured successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Testing connection..." -ForegroundColor Yellow
        
        # Test the connection
        $testOutput = magicsuite --profile $profileName api get tenants 2>&1
        
        if ($testOutput -match "401 Unauthorized" -or $testOutput -match "Unauthorized") {
            Write-Host ""
            Write-Host "Warning: Authentication was saved but connection test failed." -ForegroundColor Yellow
            Write-Host "This could mean:" -ForegroundColor Gray
            Write-Host "  - The token may have expired" -ForegroundColor Gray
            Write-Host "  - The token may not have sufficient permissions" -ForegroundColor Gray
            Write-Host "  - The API URL may be incorrect" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Please verify your token in the MagicSuite web interface." -ForegroundColor Yellow
        }
        else {
            Write-Host ""
            Write-Host "Connection test successful!" -ForegroundColor Green
            Write-Host "You can now use MagicSuite CLI commands." -ForegroundColor Green
        }
    }
    else {
        Write-Host ""
        Write-Host "Failed to configure authentication." -ForegroundColor Red
        Write-Host "Output: $output" -ForegroundColor Gray
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Clear sensitive data from memory
    $tokenKey = $null
    $tokenKeySecure = $null
    [System.GC]::Collect()
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Cyan
