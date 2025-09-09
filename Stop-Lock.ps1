param(
    [string]$sink,
    [int]$duration = 60,
    [switch]$Help,
    [switch]$Usage
)

function Stop-Lock-Usage {
    Write-Host ""
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host "#                        Stop-Lock - Usage Guide                          #" -ForegroundColor Cyan
    Write-Host "###########################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Prevents the system from locking or going idle by simulating key presses."
    Write-Host "  Useful for maintaining active sessions during long tasks."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -duration       Duration in minutes to keep the system active. Default: 60"
    Write-Host ""
    Write-Host "USAGE EXAMPLE:" -ForegroundColor Yellow
    Write-Host "  .\Stop-Lock.ps1 -duration 120"
    Write-Host ""
}

function Stop-Lock {
    param (
        [int] $duration
    )
    
    $myShell = New-Object -ComObject "WScript.Shell"
    $interval = 180 # Interval in seconds to reset the idle timer, set to 3 minutes
    $loopCounter = [math]::Ceiling($duration * 60 / $interval)

    Write-Host "Start time - $(get-date -DisplayHint time)"

    Write-Progress -PercentComplete (0) -Activity "Timer started for $duration minutes" -Status "0% complete"

    $keys = @('{NUMLOCK}', '{CAPSLOCK}', '{SCROLLLOCK}')

    for ($i = 0; $i -lt $loopCounter; $i++) {
        <# Action that will repeat until the condition is met #>
        $key = Get-Random -InputObject $keys
        $myShell.SendKeys($key)
        start-sleep -Milliseconds 500
        $myShell.SendKeys($key)
        Start-Sleep -Seconds $(interval + $(-10..10 | Get-Random))

        $percentage = [math]::Ceiling(((i+1) / $loopCounter) * 100)
        Write-Progress -PercentComplete $percentage -Status "$percentage% complete"
    }
    Write-Host "End time - $(Get-Date -DisplayHint Time)"
}

# Reassign if $sink is numeric and $duration was not explicitly set
if ($sink -match '^\d+$' -and $null -eq $PSBoundParameters['duration'] ) {
    $duration = [int]$sink
    $sink = $null
}

if (($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Stop-Lock-Usage
    exit 0
}

Stop-Lock -duration $duration