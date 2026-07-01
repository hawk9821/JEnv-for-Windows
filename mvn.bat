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

rem Set JAVA_HOME for Maven
if defined javapath (
    set "JAVA_HOME=%javapath%"
)

rem Maven home - customize if your Maven is installed elsewhere
set "MAVEN_HOME=%MAVEN_HOME%"
if not defined MAVEN_HOME (
    set "MAVEN_HOME=E:\app\apache-maven-3.9.8"
)

if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    "%MAVEN_HOME%\bin\mvn.cmd" %*
) else (
    echo Maven not found at %MAVEN_HOME%
    echo Set MAVEN_HOME environment variable or edit %~dp0mvn.bat
)
