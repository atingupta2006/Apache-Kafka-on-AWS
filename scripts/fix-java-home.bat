@echo off
REM Windows 10 CMD — fix JAVA_HOME + PATH for Kafka .bat scripts.
REM Use if you see: The syntax of the command is incorrect.
REM Copy-paste:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\fix-java-home.bat

call "%~dp0lab-defaults.bat"
set "JAVA_HOME=%DEF_JAVA_HOME%"
set "KAFKA_BIN=%DEF_KAFKA_BIN%"

if not exist "%JAVA_HOME%\bin\java.exe" (
  echo ERROR: JDK not found at %JAVA_HOME%
  echo Install to C:\Java\jdk-21 or create junction — day-01\commands.md Setup 0.1
  exit /b 1
)

REM Use course kafka-bin wrappers first (bypass broken kafka-run-class.bat on Windows).
set "LAB_KAFKA_BIN=%~dp0kafka-bin"
set "PATH=%LAB_KAFKA_BIN%;%JAVA_HOME%/bin;%KAFKA_BIN%;%PATH%"

echo JAVA_HOME=%JAVA_HOME%
if exist "%JAVA_HOME%\bin\java.exe" (
  echo Java OK. You can run kafka-topics.bat in this window.
) else (
  echo ERROR: java.exe not found.
  echo Install JDK 21 to C:\Java\jdk-21 — see day-01\commands.md Setup 0.1
  echo Or create a junction:
  echo   mkdir C:\Java
  echo   mklink /J C:\Java\jdk-21 "C:\Program Files\Java\jdk-21"
)
