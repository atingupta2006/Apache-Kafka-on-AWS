@echo off
REM Read sample log files (CMD only — no PowerShell).
REM Usage:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\read-sample-log.bat producer
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\read-sample-log.bat consumer
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\read-sample-log.bat scenario5

set "ROOT=%USERPROFILE%\Apache-Kafka-on-AWS"
if not exist "%ROOT%\day-02\samples\producer-error.log" set "ROOT=%~dp0.."
if /i "%~1"=="producer" (
  type "%ROOT%\day-02\samples\producer-error.log"
  exit /b 0
)
if /i "%~1"=="consumer" (
  type "%ROOT%\day-02\samples\consumer-error.log"
  exit /b 0
)
if /i "%~1"=="scenario5" (
  type "%ROOT%\day-05\samples\scenario-5-app.log"
  exit /b 0
)
echo Usage: read-sample-log.bat producer ^| consumer ^| scenario5
exit /b 1
