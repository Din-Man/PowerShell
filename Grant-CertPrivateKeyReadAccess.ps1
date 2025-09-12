param(
    [string]$sink,
    [string]$certFriendlyName,
    [string]$storeLocation = "LocalMachine",
    [string]$identity,
    [switch]$UseAzureAD,
    [switch]$Help,
    [switch]$Usage
)
function Grant-CertPrivateKeyReadAccess {
    param(
        [string]$certFriendlyName,
        [string]$storeLocation,
        [string]$identity,
        [switch]$UseAzureAD
    )
    # Find the certificate in the specified store by its friendly name
    $certObj = Get-ChildItem -Path "Cert:\$storeLocation\My" | Where-Object { $_.FriendlyName -eq $certFriendlyName }
    if ($null -eq $certObj) {
        Write-Host "Certificate with Friendly Name '$certFriendlyName' not found in Local Machine store." -ForegroundColor Red
        return
    }

    # Get the private key associated with the certificate
    $privateKey = $certObj.PrivateKey
    if ($null -eq $privateKey) {
        Write-Host "No private key found for the certificate '$certFriendlyName'." -ForegroundColor Red
        return
    }

    # Get the file path of the private key
    $keyFilePath = $privateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $keyFileFullPath = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\Crypto\RSA\MachineKeys\$keyFilePath"
    if (-not (Test-Path -Path $keyFileFullPath)) {
        Write-Host "Private key file not found at path '$keyFileFullPath'." -ForegroundColor Red
        return
    }

    # If identity provider is AzureAD, resolve to SID
    if ($UseAzureAD) {
        $identity = Get-AzureIdentity-SecureId -identity $identity
        if ($null -eq $identity) {
            Write-Host "Failed to resolve Azure AD identity '$identity'." -ForegroundColor Red
            return
        }
    }

    # Get the current ACL of the private key file
    $acl = Get-Acl -Path $keyFileFullPath
    # Create a new access rule for the specified identity
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "Read", "Allow")
    # Add the access rule to the ACL
    $acl.AddAccessRule($accessRule)
    # Set the updated ACL back to the private key file
    Set-Acl -Path $keyFileFullPath -AclObject $acl
    Write-Host "Granted Read access to '$identity' for the private key of certificate '$certFriendlyName'." -ForegroundColor Green
}

function Get-AzureIdentity-SecureId {
    param (
        [string]$identity
    )
    
    #check and install AzureAD module if not present
    if (-not (Get-Module -ListAvailable -Name AzureAD)) {
        Write-Host "AzureAD module not found. Installing..." -ForegroundColor Yellow
        # Check current PSGallery installation policy
        $currPolicy = (Get-PSRepository -Name "PSGallery").InstallationPolicy
        # Set to Trusted if not already
        if ($currPolicy -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }
        Install-Module -Name AzureAD -Force -Scope CurrentUser
        if (-not (Get-Module -ListAvailable -Name AzureAD)) {
            Write-Host "Failed to install AzureAD module. Please install it manually and try again." -ForegroundColor Red
            exit 1
        }
        # Revert PSGallery installation policy if it was changed
        if ($currPolicy -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy $currPolicy
        }
    }
    Import-Module AzureAD -Force
    # Login to Azure AD if not already connected
    if (-not (Get-AzureADContext)) {
        Write-Host "Connecting to Azure AD..." -ForegroundColor Yellow
        Connect-AzureAD
    }
    # Try to find the user or group in Azure AD
    $idObj = Get-AzureADUser -Filter "userPrincipalName eq '$identity'"
    if ($null -eq $user) {
        # identity is not user, try group next
        $idObj = Get-AzureADGroup -Filter "displayName eq '$identity'"
        if ($null -eq $idObj) {
            Write-Host "Identity '$identity' not found in Azure AD." -ForegroundColor Red
            exit 1
        }
    }
    $secureId = (New-Object System.Security.Principal.NTAccount($idObj.UserPrincipalName)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    return $secureId   
}

function Grant-CertPrivateKeyReadAccess-Usage {
    Write-Host ""
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host "#               Grant-CertPrivateKeyReadAccess - Usage Guide              #" -ForegroundColor Cyan
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Grants read access to the private key of a specified certificate"
    Write-Host "  in the specified certificate store to a specified user or group."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -certFriendlyName   The friendly name of the certificate."
    Write-Host "  -identity          The user or group to grant read access to."
    Write-Host "                     Format: 'DOMAIN\User' or 'User' for local accounts."
    Write-Host "  -storeLocation     Optional. Certificate store location. "
    Write-Host "                     Valid values: 'LocalMachine' or 'CurrentUser'"
    Write-Host "                     Default: 'LocalMachine'"
    Write-Host "  -UseAzureAD        Switch. Indicates that the identity is an Azure AD user or group."
    Write-Host "                     Requires AzureAD PowerShell module and interactive user login."
    write-host ""
    Write-Host "OUTPUT:" -ForegroundColor Yellow
    Write-Host "  - Success or error message indicating the result of the operation."
    Write-Host ""
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  Grant-CertPrivateKeyReadAccess -certFriendlyName 'MyCert' ` "
    Write-Host "    -identity 'DOMAIN\User' -storeLocation 'CurrentUser'"
    Write-Host ""
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Grant-CertPrivateKeyReadAccess-Usage
    exit 0
}

# validate parameters
if ($certFriendlyName.Trim() -eq "") {
    Write-Host "Parameter -certFriendlyName cannot be empty." -ForegroundColor Red
    exit 
}
if ($identity.Trim() -eq "") {
    Write-Host "Parameter -identity cannot be empty." -ForegroundColor Red
    exit 1
}
if ($identity -notmatch '^(?:[a-zA-Z0-9_-]+\\)?[a-zA-Z0-9_-]+$') {
    Write-Host "Parameter -identity must be in the format 'DOMAIN\User' or 'User'." -ForegroundColor Red
    exit 1
}

Grant-CertPrivateKeyReadAccess -certFriendlyName $certFriendlyName -identity $identity -storeLocation $storeLocation -UseAzureAD:$UseAzureAD