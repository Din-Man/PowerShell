param (
    [string] $sink,
    [string] $InventoryInput,
    [string] $OutputPath,
    [switch] $Usage,
    [switch] $Help
)
function Test-AppInfrastructureHealth-Usage {
    Write-Host ""
    Write-Host "#############################################################################" -ForegroundColor Cyan
    Write-Host "#                Test-AppInfrastructureHealth - Usage Guide                 #" -ForegroundColor Cyan
    Write-Host "#############################################################################" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Validates application infrastructure health by testing server connectivity,"
    Write-Host "  RDP access, and application port availability. Generates a color-coded HTML"
    Write-Host "  report summarizing application and server-level health."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -InventoryInput    JSON input containing application and server details."
    Write-Host "                     Can be a file path or a raw JSON string."
    Write-Host ""
    Write-Host "  -OutputPath        Directory path where the HTML report will be saved."
    Write-Host "                     defaults to '$env:USERPROFILE\Server-Health-Report'."
    Write-Host ""
    Write-Host "OUTPUT:" -ForegroundColor Yellow
    Write-Host "  - A color-coded HTML report showing:"
    Write-Host "       Application health status summary"
    Write-Host "       Server connectivity test results (Ping, RDP, App Ports)"
    Write-Host "  - Report is automatically opened in the default browser."
    Write-Host ""
    Write-Host "USAGE EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  Test-AppInfrastructureHealth -InventoryInput '.\\inventory.json'"
    Write-Host "  Test-AppInfrastructureHealth -InventoryInput '{\"Name\":\"App1\",\"Servers\":[{\"Name\":\"srv1\",\"Type\":\"Web\",\"ports\":[80,443]}]}'"
    Write-Host ""
}

if (($null -eq $sink) -or ($sink -in @('/?', '/h', '/help', '--help')) -or $Usage -or $Help) {
    Test-AppInfrastructureHealth-Usage
    exit 0
}
function BoolToString {
    param (
        [bool] $inputValue
    )
    if ($inputValue) { return "Success" } else { return "Failed" }
}

function BoolToColor {
    param (
        [bool] $inputValue
    )
    if ($inputValue) { return "green" } else { return "red" }
}

function Test-AppInfrastructureHealth {
    param (
        [string] $inventoryInput
    )
    if (Test-Path -Path $inventoryInput -PathType Leaf) {
        $inventoryInput = Get-Content $inventoryInput -Raw
    }
    try {
        $inventory = $inventoryInput | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Host "Provided input is not in valid json format. Please check and rerun" -ForegroundColor Red
        exit 1
    }
    $output = @()
    foreach ($app in $inventory) {
        $oApp = [PSCustomObject]@{
            Application_name = $app.Name
            isHealthy        = $true
            Status           = ""
            Servers          = @()
        }
        foreach ($server in $app.Servers) {
            $oServer = [PSCustomObject]@{
                Server_Name      = $server.name
                IPAddress        = ""
                Type             = $server.type
                PingSucceeded    = $false
                Ping_Test        = ""
                RDPSucceeded     = $false
                RDP_Test         = ""
                AppPortSucceeded = $true
                Port_Test        = ""
            }
            $test = tnc $server.name
            $oServer.IPAddress = $test.RemoteAddress
            $oServer.PingSucceeded = $test.PingSucceeded
            $oApp.isHealthy = $oApp.isHealthy -and $test.PingSucceeded
            $oServer.Ping_Test = BoolToString $test.PingSucceeded
            if ($test.PingSucceeded) {
                $test = tnc $server.name -CommonTCPPort RDP
                $oServer.RDPSucceeded = $test.TCPTestSucceeded
                $oApp.isHealthy = $oApp.isHealthy -and $test.TCPTestSucceeded
                $oServer.RDP_Test = BoolToString $test.TCPTestSucceeded
                foreach ($port in $server.ports) {
                    $test = tnc $server.name -port $port
                    $oServer.AppPortSucceeded = $oServer.AppPortSucceeded -and $test.TCPTestSucceeded
                    $oApp.isHealthy = $oApp.isHealthy -and $test.TCPTestSucceeded
                    $oServer.Port_Test += "$port - $(BoolToString $test.TCPTestSucceeded) `t"
                }
            }
            $oApp.Servers += $oServer
        }
        $oApp.Status = $(if ($oApp.isHealthy) { "Healthy" } else { "UnHealthy" })
    }
    $output += $oApp
    return $output
}
# Decode encoded span tags
function Format-SpanTags {
    param ([string]$html)
    $html -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&amp;', '&'
}
function Publish-HealthReport {
    param(
        [object] $HealthData,
        [string] $OutputPath,
        [switch] $WriteToConsole
    )

    $dt = get-date -Format "yyyyMMdd-hhmm"
    $newOuputFile = New-Item (Join-Path -Path $OutputPath -ChildPath "HealthReport-$dt.HTML")

    $mainTable = ""
    $HealthData | ForEach-Object {
        $_.Status = "<span class=`"$(BoolToColor $($_.isHealthy))`"> $($_.Status) </span>"        
        $_.Servers | ForEach-Object {
            $_.Ping_Test = "<span class=`"$(BoolToColor $($_.PingSucceeded))`"> $($_.Ping_Test) </span>"
            $_.RDP_Test = "<span class=`"$(BoolToColor $($_.RDPSucceeded))`"> $($_.RDP_Test) </span>"
            $_.Port_Test = "<span class=`"$(BoolToColor $($_.AppPortSucceeded))`"> $($_.Port_Test) </span>"
        }
    }

    $mainTable = $HealthData | ConvertTo-Html -Fragment -Property Application_Name, Status 
    $mainTable = Format-SpanTags $mainTable
    $appsTable = ""
    $HealthData | ForEach-Object {
        $appsTable += "<h4>$($_.Application_Name) ===> $($_.Status)</h4>"
        $appsTable += $_.Servers | ConvertTo-Html -Fragment -property Server_Name, IPAddress, Type, Ping_Test, RDP_Test, Port_Test
        $appsTable += "<br/>"
    }
    $appsTable = Format-SpanTags $appsTable

    $html = @"
    <html>
        <head>
            <Title>Health Report - $dt</title>
            <style>
                body { font-family: Consolas, monospace; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ccc; padding: 6px; }
                th { background-color: #f2f2f2; }

                .Red { color: red; }
                .green { color: green; }
            </style>
        </head>
        <Body>
            <center><H2>Application Health Report</h2></center>
            <center><H3>Generated on $(Get-Date -UFormat "%A %m/%d/%Y %R %Z")</center>
            <br>
            $mainTable
            $appsTable
        </Body>
    </html>
"@
    $html | Out-File $newOuputFile
    Start-Process $newOuputFile
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "$env:USERPROFILE\Server-Health-Report\"
    if (-not (Test-Path $OutputPath -PathType Container)) { New-Item $OutputPath -ItemType Directory }
}
if (-not (Test-Path $OutputPath -PathType Container)) {
    Write-Host "Given outputPath is invalid." -ForegroundColor Red
    exit 1
}

$healthData = Test-AppInfrastructureHealth -inventoryInput $InventoryInput
Publish-HealthReport -OutputPath $OutputPath -HealthData $healthData