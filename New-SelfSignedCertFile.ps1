
param (
    [string]$sink,
    [string]$certSubject,
    [string]$AlternativeNames,
    [string]$keyFile,
    [string]$certFile,
    [switch]$Usage,
    [switch]$Help,
    [int]$daysValid = 365
)

function New-SelfSignedCertFile-Usage {
    Write-Host ""
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host "#                   New-SelfSignedCertFile - Usage Guide                  #" -ForegroundColor Cyan
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Generates a self-signed SSL certificate and private key using OpenSSL."
    Write-Host "  Requires OpenSSL to be installed and available in the system PATH."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -certSubject        Certificate subject in '/CN=domain.com' format."
    Write-Host "  -keyFile            Output filename or path for the private key (.key)."
    Write-Host "  -certFile           Output filename or path for the certificate (.crt)."
    Write-Host "  -daysValid          Optional. Validity period in days. Default: 365"
    Write-Host "  -AlternativeNames   Optional. Comma-separated DNS names for SAN."
    Write-Host ""
    Write-Host "OUTPUT LOCATION:" -ForegroundColor Yellow
    Write-Host "  If only filenames are provided, outputs to:"
    Write-Host "    $env:USERPROFILE\SelfSignedCerts"
    Write-Host ""
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  .\New-SelfSignedCertFile -certSubject '/CN=www.example.com' ``"
    Write-Host "    -keyFile 'key-file.key' -certFile 'crt-file.crt' -daysValid 365 ``"
    Write-Host "    -AlternativeNames 'www.example.com','example.com'"
    Write-Host ""
}

function Resolve-CertFilePath {
    param (
        $inputName,
        $expectedExtension,
        $defaultDir = "$env:USERPROFILE\SelfSignedCerts"
    )
    # Check if $input is a full path
    if ([System.IO.Path]::IsPathRooted($inputName)) {
        return $inputName
    }
    # if not full path check if it has an extension and append default directory
    elseif ([System.IO.Path]::GetExtension($inputName) -eq $expectedExtension) {
        return Join-Path -Path $defaultDir -ChildPath $inputName
    }
    # If no extension, treat as name only
    else {
        return Join-Path -Path $defaultDir -ChildPath ("$inputName.$expectedExtension")
    }
}
function New-SelfSignedCertFile {
    param (
        $certSubject = "",
        $AlternativeNames = "",
        $keyFile = "",
        $certFile = "",
        $daysValid = 365
    )
    $sanString = ""
    
    if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
        Write-Host "OpenSSL is not installed or not found in system PATH." -ForegroundColor Red
        Write-Host "Please install OpenSSL and try again." -ForegroundColor Red
        Write-Host "TIP: Use `"winget install ShiningLight.OpenSSL.Light`" to install OpenSSL." -ForegroundColor Yellow
        exit 1
    }

    if ($certSubject -eq "" -or $keyFile -eq "" -or $certFile -eq "") {
        New-SelfSignedCertFile-Usage
        exit 1
    }

    # Validate $certSubject format or auto-correct if FQDN
    if ($certSubject -notmatch "^/CN=") {
        # Check if it's a FQDN (simple regex for hostnames)
        if ($certSubject -match '^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$') {
            Write-Host "Detected FQDN. Converting to subject format."
            $certSubject = "/CN=$certSubject"
        }
        else {
            Write-Host "-certSubject must start with  '/CN=' and be a valid FQDN." -ForegroundColor Red
            New-SelfSignedCertFile-Usage
            exit 1
        }
    }

    #checks for alternative names and appends to subject if provided
    if ($AlternativeNames -ne "") {
        $sanString = "subjectAltName=DNS:" + (($AlternativeNames -split "," ) -join ",DNS:")
    }

    # Prepare output directory
    $certPath = "$env:USERPROFILE\SelfSignedCerts"
    if (-not (Test-Path -Path $certPath)) {
        New-Item -ItemType Directory -Path $certPath | Out-Null
    }
    $keyFile = Resolve-CertFilePath -inputName $keyFile -expectedExtension ".key" -defaultDir $certPath
    $certFile = Resolve-CertFilePath -inputName $certFile -expectedExtension ".crt" -defaultDir $certPath
    # Reset warning stack
    if ($null -ne $Warning) { $Warning.Clear() }
    if (Test-Path -Path $keyFile) {
        Write-Warning "Key file '$keyFile' already exists. It will be overwritten."
    }
    if (Test-Path -Path $certFile) {
        Write-Warning "Certificate file '$certFile' already exists. It will be overwritten."
    }
    # Conditionally prompt
    if ($Warning.Count -gt 0) {
        Read-Host -Prompt "Press Enter to continue or Ctrl+C to cancel"
        $Warning.Clear()
    }

    $opensslCmd = @"
openssl req -x509 -newkey rsa:2048 -keyout "$keyFile" -out "$certFile" -days $daysValid -subj "$certSubject"
"@
    if ($sanString -ne "") {
        $opensslCmd += " -addext `"$sanString`""
    }
    Write-Host "Creating cert and key files with the below commmand"
    Write-Host $opensslCmd
    Invoke-Expression $opensslCmd

    Write-Host "Certificate Details:"
    openssl x509 -in $certFile -text -noout
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    New-SelfSignedCertFile-Usage
    exit 0
}
New-SelfSignedCertFile -certSubject $certSubject -keyFile $keyFile -certFile $certFile -daysValid $daysValid -AlternativeNames $AlternativeNames 