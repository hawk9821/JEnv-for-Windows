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

    # Remove the local JEnv
    if ($name -eq "remove") {
        $config.locals = @($config.locals | Where-Object { $_.path -ne (Get-Location) })
        # Clear cache file - next java call will re-resolve via jenv getjava
        $cacheFile = Join-Path $PSScriptRoot "..\jenv.java.cache"
        if (Test-Path $cacheFile) {
            Remove-Item -path $cacheFile
        }
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
        if ($localEntry.path -eq (Get-Location)) {
            # if path is used replace with new version
            $localEntry.name = $name
            # Update cache file with JDK path, not directory path
            $cacheFile = Join-Path $PSScriptRoot "..\jenv.java.cache"
            Set-Content -path $cacheFile -value $jdkPath
            Write-Output ("Your replaced your java version for {0} {1}" -f (Get-Location), $name)
            return
        }
    }

    # Add new JEnv
    $config.locals += [PSCustomObject]@{
        path = (Get-Location).path
        name = $name
    }

    # Update cache file
    $cacheFile = Join-Path $PSScriptRoot "..\jenv.java.cache"
    Set-Content -path $cacheFile -value $jenv.path

    Write-Output ("{0} is now your local java version for {1}" -f (Get-Location), $name)
}