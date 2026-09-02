@echo off
setlocal EnableDelayedExpansion
REM Windows 10 CMD — preflight check before lab (run after Setup 0.x).
REM Copy-paste:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\validate-lab.bat

set "ERR=0"
set "COURSE=%USERPROFILE%\Apache-Kafka-on-AWS"
set "KAFKA_HOME=C:\kafka\kafka_2.13-3.8.1"

echo.
echo === Kafka lab preflight (Windows CMD) ===
echo.

call "%~dp0lab-defaults.bat"
set "JAVA_HOME=%DEF_JAVA_HOME%"

if exist "%JAVA_HOME%\bin\java.exe" (
  echo [OK] Java: %JAVA_HOME%
) else (
  echo [FAIL] Java not found at %JAVA_HOME% — install JDK 21 there or create junction
  echo        See day-01\commands.md Setup 0.1
  set ERR=1
)

where aws >nul 2>&1
if errorlevel 1 (
  echo [FAIL] aws CLI not in PATH
  set ERR=1
) else (
  echo [OK] aws CLI found
)

where git >nul 2>&1
if errorlevel 1 (
  echo [FAIL] git not in PATH
  set ERR=1
) else (
  echo [OK] git found
)

if exist "C:\Program Files\7-Zip\7z.exe" (
  echo [OK] 7-Zip found
) else (
  echo [WARN] 7-Zip not at default path — needed to extract Kafka .tgz
)

if exist "%KAFKA_HOME%\bin\windows\kafka-topics.bat" (
  echo [OK] Kafka tools: %KAFKA_HOME%
) else (
  echo [FAIL] kafka-topics.bat missing — see day-01 Setup 0.5
  set ERR=1
)

if exist "%KAFKA_HOME%\libs\aws-msk-iam-auth.jar" (
  echo [OK] IAM auth jar present
) else (
  echo [WARN] IAM jar missing — run scripts\install-iam-jar.bat before Day 4
)

if exist "%COURSE%\day-01\commands.md" (
  echo [OK] Course clone: %COURSE%
) else (
  echo [FAIL] Clone course to %COURSE%
  set ERR=1
)

if exist "%USERPROFILE%\set-kafka-lab.bat" (
  call "%USERPROFILE%\set-kafka-lab.bat" >nul 2>&1
  if "!BOOTSTRAP!"=="" (
    echo [FAIL] set-kafka-lab.bat has empty BOOTSTRAP — run start-lab.bat
    set ERR=1
  ) else (
    echo [OK] set-kafka-lab.bat: BOOTSTRAP=!BOOTSTRAP!
  )
  if "!CLUSTER_NAME!"=="" echo [WARN] CLUSTER_NAME empty — re-run start-lab.bat
  if "!ACL_TOPIC!"=="" echo [WARN] ACL_TOPIC empty — re-run start-lab.bat
  if "!BOOTSTRAP_IAM!"=="" echo [WARN] BOOTSTRAP_IAM empty — re-run start-lab.bat
) else (
  echo [FAIL] Run start-lab.bat once
  set ERR=1
)

if exist "%USERPROFILE%\client-scram.properties" (
  echo [OK] client-scram.properties
) else (
  echo [FAIL] Run start-lab.bat to create client-scram.properties
  set ERR=1
)

call "%~dp0fix-java-home.bat" >nul 2>&1
where kafka-topics.bat >nul 2>&1
if errorlevel 1 (
  echo [FAIL] kafka-topics.bat not in PATH — run fix-java-home.bat and set-kafka-lab.bat
  set ERR=1
) else (
  kafka-topics.bat 2>nul | findstr /i "bootstrap-server" >nul
  if errorlevel 1 (
    echo [FAIL] kafka-topics.bat broken — git pull, fix-java-home.bat, JDK at C:\Java\jdk-21
    set ERR=1
  ) else (
    echo [OK] kafka-topics.bat launches
  )
)

echo.
if "%ERR%"=="0" (
  echo Result: READY for Day 1-2. Install IAM jar before Day 4 if still [WARN].
) else (
  echo Result: FIX the [FAIL] items above, then run this script again.
)
echo.
exit /b %ERR%
