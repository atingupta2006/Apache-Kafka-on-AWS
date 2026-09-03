@echo off
REM Called at the start of every Jupyter %%cmd cell — loads Kafka lab env.
if defined LAB_SESSION_BAT goto :load

REM Shared class VM: the seat is the students\userN folder the notebook runs from,
REM because one JupyterLab server serves every student.
set "_CD=%CD%"
set "_REST=%_CD:*\students\=%"
set "_SEAT="
if not "%_REST%"=="%_CD%" for /f "tokens=1 delims=\" %%a in ("%_REST%") do set "_SEAT=%%a"

if defined _SEAT if exist "C:\kafka-lab\sessions\%_SEAT%\set-kafka-lab.bat" set "LAB_SESSION_BAT=C:\kafka-lab\sessions\%_SEAT%\set-kafka-lab.bat"
if not defined LAB_SESSION_BAT if defined _SEAT if exist "C:\Users\%_SEAT%\set-kafka-lab.bat" set "LAB_SESSION_BAT=C:\Users\%_SEAT%\set-kafka-lab.bat"
if not defined LAB_SESSION_BAT if exist "%USERPROFILE%\set-kafka-lab.bat" set "LAB_SESSION_BAT=%USERPROFILE%\set-kafka-lab.bat"

if not defined LAB_SESSION_BAT (
  echo ERROR: no lab session found for this folder.
  echo Class VM: open the notebook from your own students\userN folder.
  echo Own laptop: run scripts\start-lab.bat once, or set LAB_SESSION_BAT.
  exit /b 1
)

:load
call "%LAB_SESSION_BAT%"
