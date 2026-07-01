@echo off
set "var="

rem Check JENVUSE environment variable first (session override from jenv use)
if defined JENVUSE (
    set "var=%JENVUSE%"
    goto run_java
)

rem Get current directory for cache lookup
set "currdir=%CD%"

rem Read cache from JEnv installation directory
if exist "%~dp0jenv.java.cache" (
    for /f "usebackq tokens=1,2 delims=:" %%a in ("%~dp0jenv.java.cache") do (
        if "%%a"=="%currdir%" (
            set "var=%%b"
            goto run_java
        )
    )
)

rem If not in cache, call jenv getjava
for /f "delims=" %%i in ('jenv getjava') do set "var=%%i"

:run_java
if exist "%var%/bin/java.exe" (
    "%var%/bin/java.exe" %*
) else (
    echo There was an error:
    echo %var%
)