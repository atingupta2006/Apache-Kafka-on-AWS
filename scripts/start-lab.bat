@echo off
REM Windows 10 CMD — first-time lab setup for this VM.
REM Copy-paste:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\start-lab.bat
REM
REM Asks: login + password (required).
REM Region / ARN / bootstrap: shows class defaults — press Enter to accept.
REM
REM Writes:
REM   %USERPROFILE%\client-scram.properties
REM   %USERPROFILE%\set-kafka-lab.bat

set CLIENT=%USERPROFILE%\client-scram.properties
set SESSION=%USERPROFILE%\set-kafka-lab.bat
set COURSE=%USERPROFILE%\Apache-Kafka-on-AWS

call "%~dp0lab-defaults.bat"

set "JAVA_HOME=%DEF_JAVA_HOME%"
set "KAFKA_BIN=%DEF_KAFKA_BIN%"

REM kafka-run-class.bat on Windows requires JAVA_HOME without spaces.
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo.
  echo ERROR: JDK not found at %JAVA_HOME%
  echo Install JDK 21 to C:\Java\jdk-21 — see day-01\commands.md Setup 0.1
  echo Or create a junction from Program Files:
  echo   mkdir C:\Java 2^>nul
  echo   mklink /J C:\Java\jdk-21 "C:\Program Files\Java\jdk-21"
  echo.
  exit /b 1
)

REM Forward slash avoids CMD turning "\b" into a backspace when writing set-kafka-lab.bat
set "LAB_KAFKA_BIN=%COURSE%/scripts/kafka-bin"
set "PATH=%LAB_KAFKA_BIN%;%JAVA_HOME%/bin;%KAFKA_BIN%;%PATH%"

echo.
echo === Kafka lab setup (once) ===
echo.

set /p LOGIN=Your login id (example: user3): 
if "%LOGIN%"=="" (
  echo Login id is required.
  goto :eof
)

set /p PASS=SCRAM password from your trainer: 
if "%PASS%"=="" (
  echo Password is required.
  goto :eof
)

echo.
echo Board values are the same for everyone.
echo Press Enter to keep the default shown in [brackets].
echo.

set "REGION="
set /p REGION=Region [%DEF_REGION%]: 
if "%REGION%"=="" set "REGION=%DEF_REGION%"

set "CLUSTER_ARN="
set /p CLUSTER_ARN=Cluster ARN [%DEF_CLUSTER_ARN%]: 
if "%CLUSTER_ARN%"=="" set "CLUSTER_ARN=%DEF_CLUSTER_ARN%"

set "BOOTSTRAP="
set /p BOOTSTRAP=Bootstrap [%DEF_BOOTSTRAP%]: 
if "%BOOTSTRAP%"=="" set "BOOTSTRAP=%DEF_BOOTSTRAP%"
REM Comma-separated broker lists break kafka tools on Windows CMD.
echo %BOOTSTRAP% | findstr /C:"," >nul && for /f "tokens=1 delims=," %%a in ("%BOOTSTRAP%") do set "BOOTSTRAP=%%a"

set "BOOTSTRAP_IAM=%DEF_BOOTSTRAP_IAM%"
set CLUSTER_NAME=%DEF_CLUSTER_NAME%
set TOPIC=orders-%LOGIN%
set GROUP=cg-%LOGIN%-support
set ACL_TOPIC=acl-lab-%LOGIN%

(
  echo security.protocol=SASL_SSL
  echo sasl.mechanism=SCRAM-SHA-512
  echo sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="%LOGIN%" password="%PASS%";
) > "%CLIENT%"

(
  echo @echo off
  echo REM JAVA_HOME must have no spaces — required for kafka-*.bat on Windows
  echo set JAVA_HOME=%JAVA_HOME%
  echo set KAFKA_BIN=%KAFKA_BIN%
  echo set PATH=%COURSE%/scripts/kafka-bin;%%JAVA_HOME%%/bin;%%KAFKA_BIN%%;%%PATH%%
  echo set CLIENT=%CLIENT%
  echo set CLIENT_IAM=%USERPROFILE%\client-iam.properties
  echo set LOGIN=%LOGIN%
  echo set TOPIC=%TOPIC%
  echo set GROUP=%GROUP%
  echo set ACL_TOPIC=%ACL_TOPIC%
  echo set REGION=%REGION%
  echo set CLUSTER_ARN=%CLUSTER_ARN%
  echo set CLUSTER_NAME=%CLUSTER_NAME%
  echo set BOOTSTRAP=%BOOTSTRAP%
  echo set BOOTSTRAP_IAM=%BOOTSTRAP_IAM%
  echo echo Kafka lab ready: LOGIN=%%LOGIN%% TOPIC=%%TOPIC%% GROUP=%%GROUP%%
  echo echo JAVA_HOME=%%JAVA_HOME%%
) > "%SESSION%"

REM Safety: refuse to leave a session file without JAVA_HOME
findstr /b /c:"set JAVA_HOME=" "%SESSION%" >nul
if errorlevel 1 (
  echo ERROR: set-kafka-lab.bat was written without JAVA_HOME. Tell the trainer.
  goto :eof
)

echo.
echo Wrote %CLIENT%
echo Wrote %SESSION%
echo.
echo LOGIN=%LOGIN%
echo TOPIC=%TOPIC%
echo GROUP=%GROUP%
echo REGION=%REGION%
echo JAVA_HOME=%JAVA_HOME%
echo.

if not exist "%JAVA_HOME%\bin\java.exe" (
  echo WARNING: java.exe not found at %JAVA_HOME%\bin
  echo Install JDK 21 or ask the trainer to update lab-defaults.bat
) else (
  echo Java path looks OK.
)

if not exist "%KAFKA_BIN%\kafka-topics.bat" (
  echo WARNING: kafka-topics.bat not found at %KAFKA_BIN%
) else (
  echo Kafka tools path looks OK.
)

if not exist "%COURSE%\day-01\commands.md" (
  echo WARNING: Clone the course to %COURSE% first.
) else (
  echo Course folder found.
)

echo.
echo Keep this window open for lab commands.
echo New Command Prompt? Paste only:
echo   call %%USERPROFILE%%\set-kafka-lab.bat
echo.
