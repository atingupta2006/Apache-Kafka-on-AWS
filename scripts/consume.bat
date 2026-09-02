@echo off
REM Windows 10 CMD — safe console consumer (use instead of kafka-console-consumer.bat --group).
REM In each CMD window first: call %USERPROFILE%\set-kafka-lab.bat
REM Usage (after set-kafka-lab.bat):
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat
REM   call %USERPROFILE%\Apache-Kafka-on-AWS\scripts\consume.bat --from-beginning

if "%JAVA_HOME%"=="" call "%~dp0fix-java-home.bat"
if "%BOOTSTRAP%"=="" (
  echo Run: call %%USERPROFILE%%\set-kafka-lab.bat
  exit /b 1
)
if "%CLIENT%"=="" set "CLIENT=%USERPROFILE%\client-scram.properties"
if "%TOPIC%"=="" (
  echo TOPIC is empty. Run set-kafka-lab.bat first.
  exit /b 1
)
if "%GROUP%"=="" (
  echo GROUP is empty. Run set-kafka-lab.bat first.
  exit /b 1
)

set "KAFKA_LIBS=C:\kafka\kafka_2.13-3.8.1\libs\*"
"%JAVA_HOME%\bin\java.exe" -cp "%KAFKA_LIBS%" org.apache.kafka.tools.consumer.ConsoleConsumer --bootstrap-server %BOOTSTRAP% --consumer.config "%CLIENT%" --topic %TOPIC% --group %GROUP% %*
