@echo off
set "var="

rem Check JENVUSE environment variable first (session override from jenv use)
if defined JENVUSE (
    set "var=%JENVUSE%"
) else (
    rem Read from cache file to avoid PowerShell startup
    if exist "%~dp0jenv.java.cache" (
        set /p var=<"%~dp0jenv.java.cache"
    )
)

rem If var is still empty, fall back to calling jenv getjava (requires PowerShell)
if not defined var (
    for /f "delims=" %%i in ('jenv getjava') do set "var=%%i"
)

if exist "%var%/bin/java.exe" (
    "%var%/bin/java.exe" %*
) else (
    echo There was an error:
    echo %var%
)