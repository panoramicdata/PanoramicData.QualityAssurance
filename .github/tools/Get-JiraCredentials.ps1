<#
.SYNOPSIS
    Retrieves JIRA credentials from Windows Credential Manager.

.DESCRIPTION
    This helper script retrieves JIRA credentials from Windows Credential Manager.
    If not found, prompts the user and offers to store them.
    
    Credentials are stored under the target name "PanoramicData.JIRA"

.EXAMPLE
    $creds = & "$PSScriptRoot\Get-JiraCredentials.ps1"
    $username = $creds.Username
    $password = $creds.Password
#>

$CredentialTarget = "PanoramicData.JIRA"

# Try to get credentials from Windows Credential Manager
function Get-StoredJiraCredential {
    try {
        # Use cmdkey to check if credential exists
        $cmdkeyOutput = cmdkey /list:$CredentialTarget 2>&1
        if ($cmdkeyOutput -match "Target: $CredentialTarget") {
            # Credential exists, use .NET to retrieve it
            Add-Type -AssemblyName System.Security
            
            # Use PowerShell's built-in Get-Credential with stored credential
            # Unfortunately, cmdkey doesn't expose password, so we need to use CredRead API
            $sig = @"
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool CredFree(IntPtr cred);

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct CREDENTIAL {
    public int Flags;
    public int Type;
    public string TargetName;
    public string Comment;
    public long LastWritten;
    public int CredentialBlobSize;
    public IntPtr CredentialBlob;
    public int Persist;
    public int AttributeCount;
    public IntPtr Attributes;
    public string TargetAlias;
    public string UserName;
}
"@
            Add-Type -MemberDefinition $sig -Namespace "CredManager" -Name "Api" -ErrorAction SilentlyContinue
            
            $credPtr = [IntPtr]::Zero
            $success = [CredManager.Api]::CredRead($CredentialTarget, 1, 0, [ref]$credPtr)
            
            if ($success) {
                $cred = [System.Runtime.InteropServices.Marshal]::PtrToStructure($credPtr, [Type][CredManager.Api+CREDENTIAL])
                $password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($cred.CredentialBlob, $cred.CredentialBlobSize / 2)
                [CredManager.Api]::CredFree($credPtr) | Out-Null
                
                return @{
                    Username = $cred.UserName
                    Password = $password
                    Source = "WindowsCredentialManager"
                }
            }
        }
    }
    catch {
        Write-Verbose "Could not retrieve credential from Windows Credential Manager: $_"
    }
    return $null
}

function Set-StoredJiraCredential {
    param(
        [string]$Username,
        [string]$Password
    )
    
    # Store using cmdkey
    $result = cmdkey /generic:$CredentialTarget /user:$Username /pass:$Password 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Credentials stored in Windows Credential Manager under '$CredentialTarget'" -ForegroundColor Green
        return $true
    }
    else {
        Write-Warning "Failed to store credentials: $result"
        return $false
    }
}

# Main logic
$credentials = Get-StoredJiraCredential

if ($credentials) {
    Write-Verbose "Retrieved JIRA credentials from Windows Credential Manager"
    return $credentials
}

# No stored credentials - check environment variables as fallback (for migration)
$envUsername = [Environment]::GetEnvironmentVariable('JIRA_USERNAME', 'User')
$envPassword = [Environment]::GetEnvironmentVariable('JIRA_PASSWORD', 'User')

if ($envUsername -and $envPassword) {
    Write-Host "Found JIRA credentials in environment variables." -ForegroundColor Yellow
    Write-Host "Migrating to Windows Credential Manager..." -ForegroundColor Yellow
    
    $stored = Set-StoredJiraCredential -Username $envUsername -Password $envPassword
    if ($stored) {
        Write-Host "Credentials migrated successfully." -ForegroundColor Green
        
        # Remove the environment variables since we've migrated to Credential Manager
        Write-Host "Removing environment variables..." -ForegroundColor Cyan
        [Environment]::SetEnvironmentVariable('JIRA_USERNAME', $null, 'User')
        [Environment]::SetEnvironmentVariable('JIRA_PASSWORD', $null, 'User')
        # Also clear from current session
        $env:JIRA_USERNAME = $null
        $env:JIRA_PASSWORD = $null
        Write-Host "Environment variables removed." -ForegroundColor Green
    }
    
    return @{
        Username = $envUsername
        Password = $envPassword
        Source = "EnvironmentVariables_Migrated"
    }
}

# No credentials found - prompt user
Write-Host "JIRA credentials not found in Windows Credential Manager." -ForegroundColor Yellow
Write-Host "JIRA URL: https://jira.panoramicdata.com" -ForegroundColor Cyan
Write-Host ""

$username = Read-Host "Enter your JIRA username"
if (-not $username) {
    Write-Error "Username is required to access JIRA"
    exit 1
}

Write-Host "Enter your JIRA password or API token (input will be hidden)" -ForegroundColor Cyan
$securePassword = Read-Host -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

if (-not $password) {
    Write-Error "Password/API token is required to access JIRA"
    exit 1
}

# Offer to store credentials
$store = Read-Host "Store credentials in Windows Credential Manager for future use? (Y/n)"
if ($store -ne 'n' -and $store -ne 'N') {
    Set-StoredJiraCredential -Username $username -Password $password
}

return @{
    Username = $username
    Password = $password
    Source = "UserPrompt"
}
