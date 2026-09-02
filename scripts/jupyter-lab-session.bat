@echo off
REM Called at the start of every Jupyter %%cmd cell — loads Kafka lab env.
if defined LAB_SESSION_BAT (
  call "%LAB_SESSION_BAT%"
) else if exist "%USERPROFILE%\set-kafka-lab.bat" (
  call "%USERPROFILE%\set-kafka-lab.bat"
) else (
  echo ERROR: Run start-lab.bat once, or set LAB_SESSION_BAT before starting Jupyter.
  exit /b 1
)
