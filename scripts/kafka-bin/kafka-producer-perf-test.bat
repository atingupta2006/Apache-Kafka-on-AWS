@echo off
REM Bypass kafka-run-class.bat (Windows "syntax of the command is incorrect").
setlocal EnableExtensions
if "%JAVA_HOME%"=="" set "JAVA_HOME=C:\Java\jdk-21"
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo ERROR: java.exe not found at %JAVA_HOME%
  exit /b 1
)
set "KAFKA_LIBS=C:\kafka\kafka_2.13-3.8.1\libs\*"
set "KAFKA_HEAP_OPTS=-Xmx512M"
"%JAVA_HOME%\bin\java.exe" %KAFKA_HEAP_OPTS% -cp "%KAFKA_LIBS%" org.apache.kafka.tools.ProducerPerformance %*
exit /b %ERRORLEVEL%
