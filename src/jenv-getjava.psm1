
function Get-Java {
    param (
        [object]$config,
        [switch]$SyncCache
    )

    $global = $config.global
    $use = $Env:JENVUSE
    $currentPath = (Get-Location).ProviderPath

    # Cache file in JEnv installation directory
    $cacheFile = Join-Path (Split-Path $PSScriptRoot -Parent) "jenv.java.cache"

    # Check JENVUSE first
    if ($use) {
        Write-Output $use
        return
    }

    # Sync cache from config history when cache file does not exist
    if ($SyncCache -and -not (Test-Path $cacheFile)) {
        $cache = @{}

        # Add global setting (config.global is already a path)
        if ($global) {
            $cache["_global_"] = $global
        }

        # Add local settings
        foreach ($localEntry in $config.locals) {
            $javaEntry = $config.jenvs | Where-Object { $_.name -eq $localEntry.name }
            if ($javaEntry) {
                $cache[$localEntry.path] = $javaEntry.path
            }
        }

        # Write cache file if we have entries
        if ($cache.Count -gt 0) {
            $content = ""
            foreach ($key in $cache.Keys) {
                $content += "$key`:$($cache[$key])`n"
            }
            New-Item -ItemType File -Path $cacheFile -Force | Out-Null
            Set-Content -Path $cacheFile -Value $content.TrimEnd()
        }
    }

    # Try to read from cache first
    if (Test-Path $cacheFile) {
        $cache = @{}
        $lines = Get-Content $cacheFile
        foreach ($line in $lines) {
            if ($line -match "^(.+):(.+)$") {
                $cache[$matches[1]] = $matches[2]
            }
        }

        # Direct match
        if ($cache.ContainsKey($currentPath)) {
            Write-Output $cache[$currentPath]
            return
        }

        # Parent directory match
        $parentPath = Split-Path $currentPath -Parent
        while ($parentPath) {
            if ($cache.ContainsKey($parentPath)) {
                Write-Output $cache[$parentPath]
                return
            }
            $parentPath = if ($parentPath.Length -gt 3) { Split-Path $parentPath -Parent } else { $null }
        }

        # Global match
        if ($cache.ContainsKey("_global_")) {
            Write-Output $cache["_global_"]
            return
        }
    }

    # Cache miss - fall back to config (no cache update)
    # Check local setting for current directory
    $localname = ($config.locals | Where-Object { $_.path -eq $currentPath }).name
    if ($localname) {
        $local = ($config.jenvs | Where-Object { $_.name -eq $localname }).path
        Write-Output $local
        return
    }

    # Traverse up to find parent with local setting
    $parentPath = Split-Path $currentPath -Parent
    while ($parentPath) {
        $parentLocal = $config.locals | Where-Object { $_.path -eq $parentPath }
        if ($parentLocal) {
            $parentJava = $config.jenvs | Where-Object { $_.name -eq $parentLocal.name }
            if ($parentJava) {
                Write-Output $parentJava.path
                return
            }
        }
        $parentPath = if ($parentPath.Length -gt 3) { Split-Path $parentPath -Parent } else { $null }
    }

    # Fall back to global
    if ($global) {
        Write-Output $global
        return
    }

    Write-Output 'No global java version found. Use jenv change to set one'
}

function Update-Cache {
    param(
        [string]$cacheFile,
        [string]$directory,
        [string]$path
    )

    # Read existing cache
    $cache = @{}
    if (Test-Path $cacheFile) {
        $lines = Get-Content $cacheFile
        foreach ($line in $lines) {
            if ($line -match "^(.+):(.+)$") {
                $cache[$matches[1]] = $matches[2]
            }
        }
    }

    # Update entry
    $cache[$directory] = $path

    # Write back
    $content = ""
    foreach ($key in $cache.Keys) {
        $content += "$key`:$($cache[$key])`n"
    }
    Set-Content -Path $cacheFile -Value $content.TrimEnd()
}

function Remove-CacheEntry {
    param(
        [string]$cacheFile,
        [string]$directory
    )

    if (-not (Test-Path $cacheFile)) { return }

    $cache = @{}
    $lines = Get-Content $cacheFile
    foreach ($line in $lines) {
        if ($line -match "^(.+):(.+)$") {
            $cache[$matches[1]] = $matches[2]
        }
    }

    $cache.Remove($directory)

    $content = ""
    foreach ($key in $cache.Keys) {
        $content += "$key`:$($cache[$key])`n"
    }
    Set-Content -Path $cacheFile -Value $content.TrimEnd()
}
