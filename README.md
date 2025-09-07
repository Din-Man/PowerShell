# PowerShell Scripts Workspace

This folder contains a collection of useful PowerShell scripts for system administration and automation tasks. Below is a summary of each script:

## Scripts

### New-SelfSignedCertFile.ps1
Generates a self-signed SSL certificate and private key using OpenSSL. 
- Requires OpenSSL to be installed and available in the system PATH.
- Accepts certificate subject, key file name, certificate file name, and validity period as parameters.
- Outputs `.key` and `.crt` files in the user's `SelfSignedCerts` directory.
- Usage example:
  ```powershell
  New-SelfSignedCertFile -certSubject '/CN=www.example.com' -keyFile 'key-file.key' -certFile 'crt-file.crt' -daysValid 365
  ```

### Get-NicSummary.ps1
Summarizes network interface information on the system.
- Useful for quickly viewing NIC status, IP addresses, and other details.

### create-w11-hv.ps1
Automates the creation of a Windows 11 Hyper-V virtual machine.
- Prompts for configuration details and provisions a VM accordingly.

### Get-RandomPassPhrase.ps1
Generates a secure, memorable passphrase using random words, digits, and special characters.
- Highly customizable: choose word count, digit count, special character set, and capitalization.
- Uses a dictionary file for word selection (default: Dictionary.txt).
- Outputs the passphrase, entropy score, and a strength label.
- Example usage:
  ```powershell
  Get-RandomPassPhrase -WordCount 5 -DigitCount 3 -SpecialCount 2 -Capitalize
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
