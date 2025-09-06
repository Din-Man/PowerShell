<#
	Get-NicSummary.ps1
	------------------
	Summarizes network interface configuration on the system.
	Displays interface index, alias, MAC address, status, profile name, network type, IPv4 address, and default gateway
	in a concise table for all network adapters.
#>
function Get-NicSummary {
	Get-NetIPConfiguration `
	| Select-Object `
	@{n = 'Index'; e = { $_.InterfaceIndex } },
	@{n = 'InterfaceAlias'; e = { if ($_.InterfaceAlias.Length -gt 10) { $_.InterfaceAlias.SubString(0, 10) } else { $_.InterfaceAlias } } },
	@{n = 'MacAddress       ';	e = { $_.NetAdapter.MacAddress } },
	@{n = 'Status      '; e = { $_.NetAdapter.Status } },
	@{n = 'ProfileName     '; e = { $_.NetProfile.Name } },
	@{n = 'NetworkType'; e = { $_.NetProfile.NetworkCategory } },
	@{n = 'IPv4Address '; e = { if ($_.NetAdapter.Status -eq "Up" ) { $_.IPv4Address[0].IPAddress } else { "" } } },
	@{n = 'DefaultGateway'; e = { if ($_.NetAdapter.Status -eq "Up" ) { $_.IPv4DefaultGateway[0].NextHop } else { "" } } } `
	| Sort-Object @{e = 'Status      '; desc = $true }, Index `
	| Format-Table 
}
Get-NicSummary