@echo off
set "javapath="

rem Check JENVUSE first (session override)
if defined JENVUSE (
    set "javapath=%JENVUSE%"
    goto set_maven
)

rem Get current directory
set "currdir=%CD%"

rem Read cache from JEnv directory
if exist "%~dp0jenv.java.cache" (
    for /f "usebackq tokens=1,2 delims=:" %%a in ("%~dp0jenv.java.cache") do (
        if "%%a"=="%currdir%" (
            set "javapath=%%b"
            goto set_maven
        )
    )
)

rem Fall back to jenv getjava
for /f "delims=" %%i in ('jenv getjava') do set "javapath=%%i"

:set_maven
if defined javapath (
    set "JAVA_HOME=%javapath%"
)

rem Maven home
if not defined MAVEN_HOME (
    echo MAVEN_HOME environment variable is not set.
    echo Please set MAVEN_HOME to your Maven installation directory.
    echo Example: set MAVEN_HOME=D:\app\apache-maven-3.9.8
    exit /b 1
)

if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    "%MAVEN_HOME%\bin\mvn.cmd" %*
) else (
    echo Maven not found at %MAVEN_HOME%
    echo Please check your MAVEN_HOME environment variable.
    exit /b 1
)
