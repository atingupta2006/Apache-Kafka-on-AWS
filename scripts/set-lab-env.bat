@echo off
REM Load lab variables with no questions (after start-lab.bat has been run once).
REM Copy-paste:
REM   call %USERPROFILE%\set-kafka-lab.bat
REM
REM If that file is missing, runs full setup once.

if exist "%USERPROFILE%\set-kafka-lab.bat" (
  call "%USERPROFILE%\set-kafka-lab.bat"
  goto :eof
)

echo No saved lab settings yet. Starting one-time setup...
call "%~dp0start-lab.bat"
