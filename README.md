# PowerShell Scripts Workspace

This folder contains a collection of useful PowerShell scripts for system administration and automation tasks. Below is a summary of each script:

## Scripts

### Compare-Folders.ps1
Compares the contents of two folders (including subfolders) and logs differences in file and folder counts, as well as missing items.
- Parameters: `-folder1`, `-folder2`, (output log files)
- Usage: Useful for folder synchronization, backup verification, or migration checks.
- Example usage:
  ```powershell
  Compare-Folders -folder1 'C:\Path\To\FolderA' -folder2 'C:\Path\To\FolderB'
  ```

### create-w11-hv.ps1
Automates the creation of a Windows 11 Hyper-V virtual machine.
- Prompts for configuration details and provisions a VM accordingly.

### Get-NicSummary.ps1
Summarizes network interface information on the system.
- Useful for quickly viewing NIC status, IP addresses, and other details.

### Format-Prompt.ps1
Dynamically formats the PowerShell prompt based on the current working directory,
using environment variable mappings to shorten paths for readability.
- Suggested usage - call from `~\Documents\WindowsPowerShell\profile.ps1`
- Example usage -
  ```
  if ($(Get-Location).Path -eq $env:UserProfile) {
      Set-Location $env:MyWorkSpace
  }
  function prompt { Format-Prompt }
  ```

### Get-RandomPassPhrase.ps1
Generates a secure, memorable passphrase using random words, digits, and special characters.
- Highly customizable: choose word count, digit count, special character set, and capitalization.
- Uses a dictionary file for word selection (default: Dictionary.txt).
- Outputs the passphrase, entropy score, and a strength label.
- Example usage:
  ```powershell
  Get-RandomPassPhrase -WordCount 5 -DigitCount 3 -SpecialCount 2 -Capitalize
  ```

### Grant-CertPrivateKeyReadAccess.ps1
- Grants read access to the private key of a specified certificate from specified store to requested user or group.
- Accepts certificate friendly name, identity, key store and switch to indicate Azure AD or local / domain identity.
- Example usage:
  ```powershell
  Grant-CertPrivateKeyReadAccess -certFriendlyName 'MyCert' -identity 'DOMAIN\User' -storeLocation 'CurrentUser'
  
  Grant-CertPrivateKeyReadAccess -certFriendlyName 'MyCert' -identity 'Group' -storeLocation 'LocalMachine' -UseAzureAD
  ```

### New-SelfSignedCertFile.ps1
Generates a self-signed SSL certificate and private key using OpenSSL. 
- Requires OpenSSL to be installed and available in the system PATH.
- Accepts certificate subject, key file name, certificate file name, and validity period as parameters.
- Outputs `.key` and `.crt` files in the user's `SelfSignedCerts` directory.
- Usage example:
  ```powershell
  New-SelfSignedCertFile -certSubject '/CN=www.example.com' -keyFile 'key-file.key' -certFile 'crt-file.crt' -daysValid 365
  ```

### Resolve-DNSNamesBulk.ps1
Resolves multiple DNS names to their corresponding records (A, AAAA, CNAME, SOA).
- Accepts input as a file path or a comma/space-separated list of DNS names.
- Outputs formatted tables of resolved DNS records and failed DNS records.
- Usage example:
  ```powershell
  Resolve-DNSNames-Bulk -DNSNamesInput '.\dnsnames.txt'
  
  Resolve-DNSNames-Bulk -DNSNamesInput 'example.com, example.org, sub.domain.com'
  ```

### Stop-Lock.ps1
Prevents the system from locking or going idle by simulating key presses for a specified duration.
- Parameters: `-duration` (minutes, default 60)
- Usage example:
  ```powershell
  Stop-Lock 60

  Stop-Lock -duration 100
  ```


### PowerShell.code-workspace
VS Code workspace settings for this folder.

## Requirements
- Windows PowerShell
- Some scripts may require additional tools (e.g., OpenSSL)

## Usage

Open this folder in VS Code or a PowerShell terminal. Run scripts as needed, following the usage instructions in each script or above.

### Add This Folder to Your PATH
To run these scripts from any directory, add this folder to your PATH environment variable.

---
Feel free to modify or extend these scripts for your own needs!
