param (
    [string] $sink,
    [int] $Count = 1,
    [int] $WordCount = 5,
    [switch] $UseExtendedSpecials,
    [switch] $AllLower,
    [switch] $Usage,
    [switch] $Help
)

# Script-safe path resolution
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

function Get-RandomPassphrase-Usage {
    Write-Host ""
    Write-Host "#################################################################################" -ForegroundColor Cyan
    Write-Host "#                        Get-RandomPassphrase - Usage Guide                     #" -ForegroundColor Cyan
    Write-Host "#################################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Generates a secure passphrase composed of random words, digits, and special characters. " 
    Write-Host "  Anchors passphrase with words at both ends and digits or special characters placed randomly between words."
    Write-Host "  Looks for 'Dictionary.txt' on the script path for the dictionary of words to be used. "
    Write-Host "  Recommended to use your own custom word list or Diceware or EFF word list or other public wordlist."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -WordCount            Number of words to include in the passphrase. Default: 5"
    Write-Host "  -Count                Number of passphrases to generate. Default: 1"
    Write-Host "  -UseExtendedSpecials  Switch to select basic vs extended special characters"
    Write-Host "  -AllLower             Switch to indicate if the passphrase should be all lower case"
    Write-Host ""
    Write-Host "OUTPUT:" -ForegroundColor Yellow
    Write-Host "  - Passphrase string with anchored first/last word"
    Write-Host "  - Entropy score in bits"
    Write-Host "  - Strength label with color-coded feedback:"
    Write-Host "      Very Weak" -ForegroundColor DarkRed
    Write-Host "      Weak" -ForegroundColor Red
    Write-Host "      Moderate" -ForegroundColor Yellow
    Write-Host "      Strong" -ForegroundColor Green
    Write-Host "      Very Strong" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "USAGE EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  Get-RandomPassphrase"
    Write-Host "  Get-RandomPassphrase -WordCount 4 -Count 3"
    Write-Host "  Get-RandomPassphrase -UseExtendedSpecials -AllLower"
    Write-Host ""
    Write-Host "#################################################################################" -ForegroundColor Cyan
}
function Get-RandomWords {
    param (
        [int]$Count,
        [string[]]$WordList,
        [switch]$AllLower
    )
    [string[]] $words = @()

    $words += Get-Random -InputObject $WordList -Count $Count

    if ($AllLower) {
        $words = $words | ForEach-Object {
            $_.ToLower()
        }
    }
    return $words
}

function Get-RandomDigit {
    return (Get-Random -Minimum 0 -Maximum 10).ToString()
}

function Get-SpecialCharacters {
    param (
        [switch] $UseExtendedSpecials
    )

    if ($UseExtendedSpecials) {
        return '!@#$%^&*()-_=+[]{}<>?'.ToCharArray()
    }
    else {
        return '!@#$%^&*()'.ToCharArray() 
    }
}

function Get-RandomSpecial {
    param (
        [switch] $UseExtendedSpecials
    )
    $specials = Get-SpecialCharacters -UseExtendedSpecials:$UseExtendedSpecials
    $index = Get-Random -Minimum 0 -Maximum $specials.Length
    return $specials[$index]
}

function Get-EntropyBits {
    param (
        [int]$WordCount,
        [int]$WordListCount,
        [switch]$UseExtendedSpecials,
        [switch]$AllLower
    )

    # Per-word entropy from dictionary size
    $wordEntropy = $WordCount * [Math]::Log($WordListCount, 2)
    # Seperator entropy from the slots
    $slots = $WordCount - 1
    $slotsCharsCount = 10 + (Get-SpecialCharacters -UseExtendedSpecials:$UseExtendedSpecials).Count
    $slotsEntropy = $slots * [Math]::Log($slotsCharsCount, 2)

    return [math]::Round($wordEntropy + $slotsEntropy, 2)
}

function Get-StrengthLabel {
    param ([double]$Entropy)

    switch ($Entropy) {
        { $_ -lt 28 } { return @{ Label = "Very Weak"; Color = "DarkRed" } }
        { $_ -lt 36 } { return @{ Label = "Weak"; Color = "Red" } }
        { $_ -lt 60 } { return @{ Label = "Moderate"; Color = "Yellow" } }
        { $_ -lt 80 } { return @{ Label = "Strong"; Color = "Green" } }
        default { return @{ Label = "Very Strong"; Color = "DarkGreen" } }
    }
}

function Get-RandomPassPhrase {
    param (
        [int] $WordCount,
        [switch] $UseExtendedSpecials,
        [switch] $AllLower,
        [double] $MinEntropy
    )
    
    [int] $MaxAttempts = 3
    [int] $Slots = 0
    [string[]] $WordList, $RandomWords, $Tail
    [string] $Head = ""
    [string] $PassphraseString = ""
    [float] $Entropy = 0

    $Slots = $WordCount - 1

    $WordListPath = Join-Path $ScriptDir 'Dictionary.txt'
    if (-not (Test-Path $WordListPath)) {
        Write-Host "Word list not found at: $WordListPath" -ForegroundColor Red
        exit 1
    }

    $WordList = Get-Content $WordListPath
    if ($WordList.Count -lt $WordCount) { 
        Write-Host "Word list contains $($WordList.Count) entries; need at least $WordCount." -ForegroundColor Red
        exit 1
    }

    $RandomWords = @()
    $RandomWords += Get-RandomWords -Count $WordCount -WordList $WordList -AllLower:$AllLower
    $Head = $RandomWords[0]
    $Tail = @()
    for ($i = 0; $i -lt $Slots; $i++) {
        if (Get-Random -Minimum 0 -Maximum 2) {
            $Tail += Get-RandomSpecial
        }
        else {
            $Tail += Get-RandomDigit
        }
        $Tail += $RandomWords[$i + 1]
    }
    $PassphraseString = $Head + ($Tail -join '')
    $Entropy = Get-EntropyBits -WordCount $WordCount -WordListCount $WordList.Count -UseExtendedSpecials:$UseExtendedSpecials -AllLower:$AllLower
    

    $strengthInfo = Get-StrengthLabel -Entropy $Entropy
    Write-Host "Generated Passphrase:" -ForegroundColor Cyan
    Write-Host $PassphraseString -ForegroundColor Green
    Write-Host ""
    Write-Host "Entropy Score: $Entropy bits ($($strengthInfo.Label))" -ForegroundColor $strengthInfo.Color
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Get-RandomPassphrase-Usage
    exit 0
}

if ($WordCount -lt 1) {
    Write-host "Word count must be at least 1" -ForegroundColor Red
    exit 1
}

for ($i = 1; $i -le $Count; $i++) {
    if ($Count -gt 1) { Write-Host "Passphrase #$i" -ForegroundColor Cyan }
    Get-RandomPassPhrase -WordCount $WordCount -AllLower:$AllLower -UseExtendedSpecials:$UseExtendedSpecials 
    if ($i -lt $Count) { Write-Host "" }
}