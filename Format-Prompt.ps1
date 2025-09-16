<#
.SYNOPSIS
    Dynamically formats the PowerShell prompt based on the current working directory,
    using environment variable mappings to shorten paths for readability.

.DESCRIPTION
    This script computes a shortened prompt string by matching the current path against 
    valid environment variable values. It excludes noisy or multi-valued variables, 
    caches valid paths for the session, and selects the longest matching segment for clarity.

    Format-Prompt       - Generates the prompt string based on current location and env match.
    Get-ValidEnvPaths   - Returns a session-cached list of valid, single-valued env paths.
    Get-BestEnvMatch    - Finds the longest matching env path segment for the current location.

.EXAMPLE
    Call the Format-Prompt function from ~\Documents\WindowsPowerShell\profile.ps1 like below.
    Below code also updates the default startup location for PowerShell to custom WorkSpace folder.
    ```
    if ($(Get-Location).Path -eq $env:UserProfile) {
        Set-Location $env:MyWorkSpace
    }
    function prompt { Format-Prompt }
    ```
#>
param(
    [string] $prefix = "PS"
)
function Format-Prompt {
    param(
        [string] $prefix
    )
    [string]$loc = Get-Location
    $q = Split-Path -Qualifier -path $loc
    $p = Split-Path -Parent -path $loc
    $l = Split-Path -Leaf -path $loc
    
    $bestMatch = Get-BestEnvMatch -currentPath $loc
    $prompt = $loc

    switch ($p) {
        "" { $prompt = "$prefix $loc> "; break }
        "$q\" { $prompt = "$prefix $loc> "; break }
        default {
            if ($bestMatch) {
                switch ($bestMatch.Value) {
                    $loc { $prompt = "$prefix Env:$($bestMatch.Name)> "; break }
                    $p { $prompt = "$prefix Env:$($bestMatch.Name)\$l> "; break }
                    Default { $prompt = "$prefix Env:$($bestMatch.Name)\...\$l> "; break }
                } 
            }
            else { $prompt = "$prefix $q\...\$l> " }
        }
    }
    return $prompt
}

function Get-ValidEnvPaths {
    if (-not $Global:ValidEnvPathsCache) {
        $excludedVars = @{
            Path         = $true
            PSModulePath = $true
            PATHEXT      = $true
            TEMP         = $true
            TMP          = $true
        }
        $envVars = [System.Environment]::GetEnvironmentVariables().GetEnumerator()
        $Global:ValidEnvPathsCache = @()
        foreach ($envVar in $envVars) {
            $name = $envVar.Key
            $value = $envVar.Value

            if (-not $value) { continue }
            if ($value.IndexOf(';') -ge 0) { continue }
            if ($excludedVars[$name]) { continue }

            # Only include actual filesystem paths
            if (Test-Path $value) {
                $Global:ValidEnvPathsCache += [PSCustomObject]@{
                    Name  = $name
                    Value = $value
                }
            }
        }
    }
    return $Global:ValidEnvPathsCache
}

function Get-BestEnvMatch {
    param (
        [string] $currentPath
    )
    $bestMatch = $null
    $longestLength = 0

    $validEnvVars = Get-ValidEnvPaths
    foreach ($envVar in $validEnvVars) {
        $value = $envVar.Value
        if ($currentPath.IndexOf($value, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $len = $value.Length
            if ($len -gt $longestLength) {
                $longestLength = $len
                $bestMatch = $envVar
            }
        }
    }
    return $bestMatch
}

Format-Prompt -prefix $prefix