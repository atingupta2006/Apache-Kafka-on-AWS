@echo off
REM MSK IAM auth JAR for kafka-topics on port 9198. Call after jupyter-lab-session.bat.
set "CLASSPATH=C:\kafka\kafka_2.13-3.8.1\libs\aws-msk-iam-auth.jar;%CLASSPATH%"
