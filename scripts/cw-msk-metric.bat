@echo off
REM CloudWatch MSK metrics with CMD-safe dimension quoting.
REM Requires: REGION, CLUSTER_NAME from set-kafka-lab.bat
REM Optional: METRICS_START, METRICS_END (defaults: Day 2 sample window)
REM Optional: GROUP, TOPIC (for SumOffsetLag)
REM
REM Usage:
REM   cw-msk-metric.bat CpuIdle Average 2          REM per-broker (broker id = 2)
REM   cw-msk-metric.bat BytesInPerSec Average      REM cluster-wide
REM   cw-msk-metric.bat SumOffsetLag Maximum lag   REM consumer lag dimensions

if "%REGION%"=="" (
  echo ERROR: REGION not set. Run set-kafka-lab.bat first.
  exit /b 1
)
if "%CLUSTER_NAME%"=="" (
  echo ERROR: CLUSTER_NAME not set. Run start-lab.bat / set-kafka-lab.bat first.
  exit /b 1
)
if "%~1"=="" (
  echo Usage: cw-msk-metric.bat MetricName Statistic [broker-id ^| lag]
  exit /b 1
)

set "METRIC=%~1"
set "STAT=%~2"
if "%METRICS_START%"=="" set "METRICS_START=2026-08-20T10:15:00Z"
if "%METRICS_END%"=="" set "METRICS_END=2026-08-20T10:30:00Z"

if /i "%~3"=="lag" (
  if "%GROUP%"=="" (
    echo ERROR: GROUP not set for SumOffsetLag
    exit /b 1
  )
  if "%TOPIC%"=="" (
    echo ERROR: TOPIC not set for SumOffsetLag
    exit /b 1
  )
  aws cloudwatch get-metric-statistics --region %REGION% --namespace AWS/Kafka --metric-name %METRIC% --dimensions "Name=Cluster Name,Value=%CLUSTER_NAME%" "Name=Consumer Group,Value=%GROUP%" "Name=Topic,Value=%TOPIC%" --start-time %METRICS_START% --end-time %METRICS_END% --period 300 --statistics %STAT%
  exit /b %ERRORLEVEL%
)

if not "%~3"=="" (
  aws cloudwatch get-metric-statistics --region %REGION% --namespace AWS/Kafka --metric-name %METRIC% --dimensions "Name=Cluster Name,Value=%CLUSTER_NAME%" "Name=Broker ID,Value=%~3" --start-time %METRICS_START% --end-time %METRICS_END% --period 300 --statistics %STAT%
  exit /b %ERRORLEVEL%
)

aws cloudwatch get-metric-statistics --region %REGION% --namespace AWS/Kafka --metric-name %METRIC% --dimensions "Name=Cluster Name,Value=%CLUSTER_NAME%" --start-time %METRICS_START% --end-time %METRICS_END% --period 300 --statistics %STAT%
exit /b %ERRORLEVEL%
