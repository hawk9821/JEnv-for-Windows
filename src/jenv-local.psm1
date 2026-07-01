function Invoke-Local {
    param(
        [Parameter(Mandatory = $true)][object]$config,
        [Parameter(Mandatory = $true)][boolean]$help,
        [Parameter(Mandatory = $true)][string]$name
    )

    if ($help) {
        Write-Host '"jenv local <name>"'
        Write-Host 'This command allows you to specify a java version that will always be used in this folder and all subfolders'
        Write-Host 'This is overwriten by "jenv use"'
        Write-Host '<name> is the alias of the JEnv you want to specify'
        Write-Host "Attention! You might have to call jenv first before it changes your JAVA_HOME to the local environment. The java command will work out of the box"
        return
    }

    # Cache file in JEnv installation directory
    $cacheFile = Join-Path (Split-Path $PSScriptRoot -Parent) "jenv.java.cache"
    $currentPath = (Get-Location).ProviderPath

    # Remove the local JEnv
    if ($name -eq "remove") {
        $config.locals = @($config.locals | Where-Object { $_.path -ne $currentPath })
        # Remove this directory from cache
        Remove-CacheEntry -cacheFile $cacheFile -directory $currentPath
        Write-Output "Your local JEnv was unset"
        return
    }

    # Check if specified JEnv is avaible
    $jenv = $config.jenvs | Where-Object { $_.name -eq $name }
    if ($null -eq $jenv) {
        Write-Output "Theres no JEnv with name $name Consider using `"jenv list`""
        return
    }

    # Check if path is already used
    # Store JDK path before loop as $jenv gets overwritten in foreach
    $jdkPath = $jenv.path
    foreach ($localEntry in $config.locals) {
        if ($localEntry.path -eq $currentPath) {
            # if path is used replace with new version
            $localEntry.name = $name
            # Update cache file with JDK path
            Update-Cache -cacheFile $cacheFile -directory $currentPath -path $jdkPath
            Write-Output ("Your replaced your java version for {0} {1}" -f $currentPath, $name)
            return
        }
    }

    # Add new JEnv
    $config.locals += [PSCustomObject]@{
        path = $currentPath
        name = $name
    }

    # Update cache file
    Update-Cache -cacheFile $cacheFile -directory $currentPath -path $jdkPath

    Write-Output ("{0} is now your local java version for {1}" -f $currentPath, $name)
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
