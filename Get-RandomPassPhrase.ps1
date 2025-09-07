param (
    [string]$sink,
    [int]$WordCount = 4,
    [int]$DigitCount = 2,
    [int]$SpecialCount = 2,
    [string]$SpecialSet = 'basic', # 'basic', 'extended', 'custom'
    [string]$CustomSpecials = '',
    [string]$WordListPath = ".\Dictionary.txt",
    [switch]$Capitalize,
    [switch]$Usage,
    [switch]$Help
)

function Get-RandomPassphrase-Usage {
    Write-Host ""
    Write-Host "#################################################################################" -ForegroundColor Cyan
    Write-Host "#                        Get-RandomPassphrase - Usage Guide                     #" -ForegroundColor Cyan
    Write-Host "#################################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Generates a secure passphrase composed of random words, digits, and" 
    Write-Host "  special characters. Anchors the passphrase with a word at both ends."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -WordCount       Number of words to include in the passphrase. Minimum: 3; Default: 4"
    Write-Host "  -DigitCount      Number of digits to include. Default: 2"
    Write-Host "  -SpecialCount    Number of special characters to include. Default: 2"
    Write-Host "  -WordListPath    Path to the word list file. Default: .\Dictionary.txt"
    Write-Host "  -Capitalize      Optional switch. Capitalizes the first letter of each word."
    Write-Host "  -SpecialSet      Character set to use: basic, extended, or custom. Default: basic"
    Write-Host "  -CustomSpecials  Custom special characters (used only if -SpecialSet is 'custom')"
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
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  Get-RandomPassphrase -WordCount 5 -DigitCount 3 -SpecialCount 2 -Capitalize"
    Write-Host ""
    Write-Host "#################################################################################" -ForegroundColor Cyan
}
function Get-RandomWords {
    param (
        [int]$Count,
        [string]$Path,
        [switch]$Capitalize
    )

    $words = Get-Random -InputObject (Get-Content $Path) -Count $Count

    if ($Capitalize) {
        $words = $words | ForEach-Object {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }
    }

    return $words
}

function Get-RandomDigits {
    param ([int]$Count)
    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $digit = Get-Random -Minimum 0 -Maximum 10
        $result += $digit
    }
    return $result
}

function Get-SpecialCharacters {
    param (
        [string]$Set,
        [string]$Custom = ''
    )

    switch ($Set.ToLower()) {
        'basic' { return '!@#$%^&*()'.ToCharArray() }
        'extended' { return '!@#$%^&*()-_=+[]{}<>?'.ToCharArray() }
        'custom' { return $Custom.ToCharArray() | Where-Object { $_ -match '.' } }
        default {
            Write-Warning "Unknown set: $Set"
            return @()
        }
    }
}

function Get-RandomSpecials {
    param (
        [int]$Count,
        [string]$Set,
        [string]$Custom
    )

    $specials = Get-SpecialCharacters -Set $Set -Custom $Custom
    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $index = Get-Random -Minimum 0 -Maximum $specials.Length
        $result += $specials[$index]
    }
    return $result
}
function Get-EntropyBits {
    param (
        [int]$PhraseLength,
        [string]$SpecialSet,
        [string]$CustomSpecials,
        [switch]$Capitalize
    )

    $charset = @()

    # Word characters
    if ($Capitalize) {
        $charset += [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    }
    else {
        $charset += [char[]]'abcdefghijklmnopqrstuvwxyz'
    }

    # Digits
    if ($DigitCount -gt 0) {
        $charset += 0..9
    }

    # Specials
    if ($SpecialCount -gt 0) {
        $charset += Get-SpecialCharacters -Set $SpecialSet -Custom $CustomSpecials
    }

    $poolSize = $charset.Count

    return [math]::Round([math]::Log([math]::Pow($poolSize, $PhraseLength), 2), 2)
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
        [int]$WordCount,
        [int]$DigitCount,
        [int]$SpecialCount,
        [string]$SpecialSet,
        [string]$CustomSpecials,
        [string]$WordListPath,
        [switch]$Capitalize
    )

    if ($WordCount -lt 3) {
        Write-Host "WordCount must be at least 3 for anchored passphrases." -ForegroundColor Red
        exit 1
    }

    if (-not (Test-Path $WordListPath)) {
        Write-Host "Word list not found at: $WordListPath" -ForegroundColor Red
        exit 1
    }

    $words = Get-RandomWords -Count $WordCount -Path $WordListPath -Capitalize:$Capitalize
    $digits = Get-RandomDigits -Count $DigitCount
    $specials = Get-RandomSpecials -Count $SpecialCount -Set $SpecialSet -Custom $CustomSpecials

    $firstWord = $words[0]
    $lastWord = $words[-1]
    $middle = ($words[1..($words.Count - 2)] + $digits + $specials) | Get-Random -Count ($words.Count - 2 + $digits.Count + $specials.Count)

    $passphrase = @($firstWord) + $middle + @($lastWord)
    $passphraseString = $passphrase -join ''

    $entropy = Get-EntropyBits $passphraseString.Length -SpecialSet $SpecialSet -CustomSpecials $CustomSpecials -Capitalize:$Capitalize
    
    $strengthInfo = Get-StrengthLabel -Entropy $entropy
    Write-Host "Generated Passphrase:" -ForegroundColor Cyan
    Write-Host $passphraseString -ForegroundColor Green
    Write-Host ""
    Write-Host "Entropy Score: $entropy bits ($($strengthInfo.Label))" -ForegroundColor $strengthInfo.Color
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Get-RandomPassphrase-Usage
    exit 0
}

Get-RandomPassPhrase -WordCount $WordCount -DigitCount $DigitCount -SpecialCount $SpecialCount -WordListPath $WordListPath -Capitalize:$Capitalize -SpecialSet $SpecialSet -CustomSpecials $CustomSpecials