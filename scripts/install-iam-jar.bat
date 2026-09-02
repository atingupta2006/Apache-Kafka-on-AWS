@echo off
REM Windows 10 CMD — download AWS MSK IAM auth jar (needed Day 4+).
REM Copy-paste:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\install-iam-jar.bat

set "KAFKA_HOME=C:\kafka\kafka_2.13-3.8.1"
set "JAR=%KAFKA_HOME%\libs\aws-msk-iam-auth.jar"
set "URL=https://repo1.maven.org/maven2/software/amazon/msk/aws-msk-iam-auth/2.3.2/aws-msk-iam-auth-2.3.2-all.jar"

if not exist "%KAFKA_HOME%\bin\windows\kafka-topics.bat" (
  echo ERROR: Kafka not found at %KAFKA_HOME%
  echo Install Kafka first — see day-01\commands.md Setup 0.5
  exit /b 1
)

if exist "%JAR%" (
  echo IAM jar already present: %JAR%
  exit /b 0
)

echo Downloading aws-msk-iam-auth.jar ...
curl -L -o "%JAR%" "%URL%"
if errorlevel 1 (
  echo curl failed. Open this URL in a browser and save the file as:
  echo   %JAR%
  echo %URL%
  exit /b 1
)

if exist "%JAR%" (
  echo OK: %JAR%
) else (
  echo ERROR: download did not create the jar file.
  exit /b 1
)
