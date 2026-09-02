@echo off
REM Shared launcher — bypasses kafka-run-class.bat (fixes "syntax of the command is incorrect").
REM Usage: call "%~dp0_kafka-run.bat" <MainClass> [args...]

setlocal EnableExtensions
set "MAIN_CLASS=%~1"
if "%MAIN_CLASS%"=="" (
  echo Usage: _kafka-run.bat MainClass [args...]
  exit /b 1
)
shift /1

if "%JAVA_HOME%"=="" call "%~dp0fix-java-home.bat"
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo ERROR: java.exe not found at %JAVA_HOME%
  echo Install JDK to C:\Java\jdk-21 — see day-01\commands.md Setup 0.1
  exit /b 1
)

if not "%BOOTSTRAP%"=="" echo %BOOTSTRAP% | findstr /C:"," >nul && (
  echo ERROR: BOOTSTRAP must be ONE host:port — no commas.
  echo Run start-lab.bat again or: set BOOTSTRAP=b-1-public....amazonaws.com:9196
  exit /b 1
)

set "KAFKA_LIBS=C:\kafka\kafka_2.13-3.8.1\libs\*"
set "CP=%KAFKA_LIBS%"
if defined CLASSPATH set "CP=%CLASSPATH%;%CP%"

"%JAVA_HOME%\bin\java.exe" -cp "%CP%" %MAIN_CLASS% %*
exit /b %ERRORLEVEL%
