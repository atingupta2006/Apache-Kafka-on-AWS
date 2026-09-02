@echo off
REM Windows 10 CMD — safe console producer.
REM In each CMD window first: call %USERPROFILE%\set-kafka-lab.bat
REM
REM Interactive (type lines, Ctrl+C to stop) on %%TOPIC%%:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat
REM One message on %%TOPIC%%:
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat my-message
REM One message on another topic (e.g. ACL lab):
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\produce.bat acl-lab-user1 acl-ok

if "%JAVA_HOME%"=="" call "%~dp0fix-java-home.bat"
if "%BOOTSTRAP%"=="" (
  echo Run: call %%USERPROFILE%%\set-kafka-lab.bat
  exit /b 1
)
if "%CLIENT%"=="" set "CLIENT=%USERPROFILE%\client-scram.properties"

set "KAFKA_LIBS=C:\kafka\kafka_2.13-3.8.1\libs\*"
set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
set "PRODUCE_TOPIC=%TOPIC%"

if "%~2"=="" (
  if "%TOPIC%"=="" (
    echo TOPIC is empty. Run set-kafka-lab.bat first.
    exit /b 1
  )
  if not "%~1"=="" (
    echo %~1| "%JAVA_EXE%" -cp "%KAFKA_LIBS%" kafka.tools.ConsoleProducer --bootstrap-server %BOOTSTRAP% --producer.config "%CLIENT%" --topic %PRODUCE_TOPIC%
    exit /b %ERRORLEVEL%
  )
  "%JAVA_EXE%" -cp "%KAFKA_LIBS%" kafka.tools.ConsoleProducer --bootstrap-server %BOOTSTRAP% --producer.config "%CLIENT%" --topic %PRODUCE_TOPIC%
  exit /b %ERRORLEVEL%
)

set "PRODUCE_TOPIC=%~1"
echo %~2| "%JAVA_EXE%" -cp "%KAFKA_LIBS%" kafka.tools.ConsoleProducer --bootstrap-server %BOOTSTRAP% --producer.config "%CLIENT%" --topic %PRODUCE_TOPIC%
exit /b %ERRORLEVEL%
