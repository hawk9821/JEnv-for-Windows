@echo off
set "javapath="

rem Check JENVUSE first (session override)
if defined JENVUSE (
    set "javapath=%JENVUSE%"
    goto set_mvnd
)

rem Get current directory
set "currdir=%CD%"

rem Read cache from JEnv directory
if exist "%~dp0jenv.java.cache" (
    for /f "usebackq tokens=1,2 delims=:" %%a in ("%~dp0jenv.java.cache") do (
        if "%%a"=="%currdir%" (
            set "javapath=%%b"
            goto set_mvnd
        )
    )
)

rem Fall back to jenv getjava
for /f "delims=" %%i in ('jenv getjava') do set "javapath=%%i"

:set_mvnd
if defined javapath (
    set "JAVA_HOME=%javapath%"
)

rem Maven Daemon home
if not defined MVND_HOME (
    echo MVND_HOME environment variable is not set.
    echo Please set MVND_HOME to your Maven Daemon installation directory.
    echo Example: set MVND_HOME=D:\app\maven-mvnd-1.0.2-windows-amd64
    exit /b 1
)

if exist "%MVND_HOME%\bin\mvnd.cmd" (
    "%MVND_HOME%\bin\mvnd.cmd" %*
) else (
    echo Maven Daemon not found at %MVND_HOME%
    echo Please check your MVND_HOME environment variable.
    exit /b 1
)
