function Invoke-Change {
    param(
        [Parameter(Mandatory = $true)][object]$config,
        [Parameter(Mandatory = $true)][boolean]$help,
        [Parameter(Mandatory = $true)][boolean]$output,
        [Parameter(Mandatory = $true)][string]$name
    )

    if ($help) {
        Write-Host '"jenv change <name>"'
        Write-Host 'With this command you set your JAVA_HOME and the version of java to be used globally. This is overwritten by both "jenv local" and "jenv use"'
        Write-Host '<name> is the alias you assigned to the path with "jenv add <name> <path>"'
        return
    }

    # Cache file in JEnv installation directory
    $cacheFile = Join-Path (Split-Path $PSScriptRoot -Parent) "jenv.java.cache"

    # Check if specified JEnv is avaible
    $jenv = $config.jenvs | Where-Object { $_.name -eq $name }
    if ($null -eq $jenv) {
        Write-Host ('Theres no JEnv with name {0} Consider using "jenv list"' -f $name)
        return
    }
    else {
        Write-Host "Setting JAVA_HOME globally. This could take some time"
        $config.global = $jenv.path
        $Env:JAVA_HOME = $jenv.path # Set for powershell users
        if ($output) {
            Set-Content -path "jenv.home.tmp" -value $jenv.path # Create temp file so no restart of the active shell is required
        }
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $jenv.path, [System.EnvironmentVariableTarget]::User) # Set globally}

        # Update global in cache
        Update-GlobalCache -cacheFile $cacheFile -path $jenv.path

        Write-Host "JEnv changed globally"
    }
}

function Update-GlobalCache {
    param(
        [string]$cacheFile,
        [string]$path
    )

    $cache = @{}
    if (Test-Path $cacheFile) {
        $lines = Get-Content $cacheFile
        foreach ($line in $lines) {
            if ($line -match "^(.+):(.+)$") {
                $cache[$matches[1]] = $matches[2]
            }
        }
    }

    $cache["_global_"] = $path

    $content = ""
    foreach ($key in $cache.Keys) {
        $content += "$key`:$($cache[$key])`n"
    }
    Set-Content -Path $cacheFile -Value $content.TrimEnd()
}