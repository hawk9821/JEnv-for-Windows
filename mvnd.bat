@echo off
set "javapath="

rem Check JENVUSE first (session override)
if defined JENVUSE (
    set "javapath=%JENVUSE%"
) else (
    rem Read from cache file
    if exist "%~dp0jenv.java.cache" (
        set /p javapath=<"%~dp0jenv.java.cache"
    )
)

rem Fall back to jenv getjava if no cache
if not defined javapath (
    for /f "delims=" %%i in ('jenv getjava') do set "javapath=%%i"
)

rem Set JAVA_HOME for mvnd
if defined javapath (
    set "JAVA_HOME=%javapath%"
)

rem Maven Daemon home - customize if your mvnd is installed elsewhere
set "MVND_HOME=%MVND_HOME%"
if not defined MVND_HOME (
    set "MVND_HOME=E:\app\maven-mvnd-1.0.2-windows-amd64"
)

if exist "%MVND_HOME%\bin\mvnd.cmd" (
    "%MVND_HOME%\bin\mvnd.cmd" %*
) else (
    echo Maven Daemon not found at %MVND_HOME%
    echo Set MVND_HOME environment variable or edit %~dp0mvnd.bat
)
