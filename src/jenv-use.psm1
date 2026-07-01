function Invoke-Use {
    param(
        [Parameter(Mandatory = $true)][object]$config,
        [Parameter(Mandatory = $true)][boolean]$help,
        [Parameter(Mandatory = $true)][boolean]$output,
        [Parameter(Mandatory = $true)][string]$name
    )

    if ($help) {
        Write-Host '"jenv use <name>"'
        Write-Host 'With this command you set your JAVA_HOME and the version of java to be used by your current shell session.'
        Write-Host '<name> is the alias you assigned to the path with "jenv add <name> <path>"'
        Write-Host 'Careful this overwrites "jenv local"'
        return
    }

    # Cache file in JEnv installation directory
    $cacheFile = Join-Path (Split-Path $PSScriptRoot -Parent) "jenv.java.cache"
    $currentPath = (Get-Location).ProviderPath

    # Remove the local JEnv
    if ($name -eq "remove") {
        $Env:JENVUSE = $null # Set for powershell users
        if ($output) {
            Set-Content -path "jenv.use.tmp" -value "remove" # Create temp file so no restart of the active shell is required
        }
        # Remove this directory from cache
        Remove-CacheEntry -cacheFile $cacheFile -directory $currentPath
        Write-Host "Your session JEnv was unset"
        return
    }


    # Check if specified JEnv is avaible
    $jenv = $config.jenvs | Where-Object { $_.name -eq $name }
    if ($null -eq $jenv) {
        Write-Host ('Theres no JEnv with name {0} Consider using "jenv list"' -f $name)
        return
    }
    else {
        $Env:JAVA_HOME = $jenv.path # Set for powershell users
        $Env:JENVUSE = $jenv.path # Set for powershell users
        if ($output) {
            Set-Content -path "jenv.home.tmp" -value $jenv.path # Create temp file so no restart of the active shell is required
            Set-Content -path "jenv.use.tmp" -value $jenv.path # Create temp file so no restart of the active shell is required
        }
        # Update cache for current directory
        Update-Cache -cacheFile $cacheFile -directory $currentPath -path $jenv.path
        Write-Host 'JEnv changed for the current shell session. Careful this overwrites "jenv local"'
    }
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

    # Update entry for this directory
    $cache[$directory] = $path

    # Write back cache
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

    # Read existing cache
    $cache = @{}
    $lines = Get-Content $cacheFile
    foreach ($line in $lines) {
        if ($line -match "^(.+):(.+)$") {
            $cache[$matches[1]] = $matches[2]
        }
    }

    # Remove entry for this directory
    $cache.Remove($directory)

    # Write back cache
    $content = ""
    foreach ($key in $cache.Keys) {
        $content += "$key`:$($cache[$key])`n"
    }
    Set-Content -Path $cacheFile -Value $content.TrimEnd()
}
