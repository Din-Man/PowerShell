param(
    [string]$sink,
    [string]$DNSNamesInput,
    [switch]$Help,
    [switch]$Usage
)

function Resolve-DNSNamesBulk {
    param (
        [string]$DNSNamesInput
    )
    $dnsNames = @()
    #check if $DNSNamesInput is a file path
    if (Test-Path -Path $DNSNamesInput -PathType Leaf) {
        $dnsNames = Get-Content -Path $DNSNamesInput | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
    }
    else {
        # check if the list is comma separated or space separated
        switch ($DNSNamesInput) {
            { $_ -like "*,*" } { $dnsNames = $DNSNamesInput -split "," | ForEach-Object { $_.Trim() } ; break }
            { $_ -like "* *" } { $dnsNames = $DNSNamesInput -split " " | ForEach-Object { $_.Trim() } ; break }
            default { $dnsNames = @($DNSNamesInput.Trim()) }
        }
    }
    if ($dnsNames.Count -eq 0) {
        Write-Host "No valid DNS names found in input." -ForegroundColor Red
        return
    }
    $results = @()
    $failedDomains = @()
    foreach ($dnsName in $dnsNames) {
        try {
            $prefix = ""
            Resolve-DnsName -Name $dnsName -ErrorAction Stop | ForEach-Object {
                $entry = $_
                $results += [PSCustomObject]@{
                    DNSName = $prefix + $entry.Name
                    Type    = $entry.Type
                    Target  = switch ($entry.Type) {
                        "A" { $entry.IPAddress }
                        "AAAA" { $entry.IPAddress }
                        "CNAME" { $entry.NameHost }
                        "SOA" { $entry.PrimaryServer }
                        default { $null }
                    }
                }
                $prefix += " > "
            }
        }
        catch {
            $failedDomains += [PSCustomObject]@{
                DNSName = $dnsName
                Error   = $_.Exception.Message
            }
        }
    }
    if ($results.Count -gt 0) {
        Write-Host "`nResolved DNS Records:" -ForegroundColor Cyan
        $results | Format-Table -AutoSize
    }
    if ($failedDomains.Count -gt 0) {
        Write-Host "`nFailed to resolve the following DNS names:" -ForegroundColor Yellow
        $failedDomains | Format-Table -AutoSize
    }
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Resolve-DNSNamesBulk-Usage
    exit 0
}

function Resolve-DNSNamesBulk-Usage {
    Write-Host ""
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host "#               Resolve-DNSNames-Bulk - Usage Guide                       #" -ForegroundColor Cyan
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Resolves multiple DNS names to their corresponding records (A, AAAA, CNAME, SOA)."
    Write-Host "  Accepts input as a file path or a comma/space-separated list of DNS names."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -DNSNamesInput    The input containing DNS names to resolve."
    Write-Host "                    Can be a file path (one DNS name per line) or"
    Write-Host "                    a comma/space-separated list of DNS names."
    write-host ""
    Write-Host "OUTPUT:" -ForegroundColor Yellow
    Write-Host "  - A formatted table of resolved DNS records."
    Write-Host "  - A list of DNS names that failed to resolve with error messages."
    Write-Host ""
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  Resolve-DNSNames-Bulk -DNSNamesInput '.\dnsnames.txt'"
    Write-Host "  Resolve-DNSNames-Bulk -DNSNamesInput 'example.com, example.org, sub.domain.com'"
    Write-Host ""    
}

Resolve-DNSNamesBulk -DNSNamesInput $DNSNamesInput