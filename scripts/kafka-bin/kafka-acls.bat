@echo off
call "%~dp0..\_kafka-run.bat" kafka.admin.AclCommand %*
