@echo off
call "%~dp0..\_kafka-run.bat" org.apache.kafka.tools.TopicCommand %*
