
function Get-Java {
    param (
        [object]$config
    )

    $global = $config.global
    $use = $Env:JENVUSE
    $cacheFile = Join-Path $PSScriptRoot "..\jenv.java.cache"

    # Use command overwrites everything
    if ($use) {
        Set-Content -path $cacheFile -value $use
        Write-Output $use
        return
    }

    # Check local setting for current directory first
    $currentPath = (Get-Location).ProviderPath
    $localname = ($config.locals | Where-Object { $_.path -eq $currentPath }).name
    if ($localname) {
        $local = ($config.jenvs | Where-Object { $_.name -eq $localname }).path
        Set-Content -path $cacheFile -value $local
        Write-Output $local
        return
    }

    # No local for current dir - traverse up to find parent with local setting
    # Use ProviderPath + Split-Path because .Parent can return null in some PowerShell contexts
    $currentPath = (Get-Location).ProviderPath
    $parentPath = Split-Path $currentPath -Parent
    while ($parentPath) {
        $parentLocal = $config.locals | Where-Object { $_.path -eq $parentPath }
        if ($parentLocal) {
            $parentJava = $config.jenvs | Where-Object { $_.name -eq $parentLocal.name }
            if ($parentJava) {
                Set-Content -path $cacheFile -value $parentJava.path
                Write-Output $parentJava.path
                return
            }
        }
        $parentPath = if ($parentPath.Length -gt 3) { Split-Path $parentPath -Parent } else { $null }
    }

    # Fall back to global
    if ($global) {
        Set-Content -path $cacheFile -value $global
        Write-Output $global
        return
    }

    # No JEnv set
    Write-Output 'No global java version found. Use jenv change to set one'
}