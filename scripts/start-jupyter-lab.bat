@echo off
REM Start JupyterLab from repo venv (local laptop — no global pip install).
REM Usage:
REM   call scripts\start-jupyter-lab.bat
REM Trainer (user15 / new cluster):
REM   set LAB_SESSION_BAT=%~dp0..\internal\tools\_trainer-user15-session.bat
REM   call scripts\start-jupyter-lab.bat

set "ROOT=%~dp0.."
set "VENV=%ROOT%\.venv-lab\Scripts"
set "JUPYTER=%VENV%\jupyter.exe"

if not exist "%JUPYTER%" (
  echo.
  echo ERROR: venv not found at %ROOT%\.venv-lab
  echo One-time setup:
  echo   cd %ROOT%
  echo   python -m venv .venv-lab
  echo   .venv-lab\Scripts\pip install jupyter jupyterlab
  echo.
  exit /b 1
)

if "%LAB_SESSION_BAT%"=="" set "LAB_SESSION_BAT=%USERPROFILE%\set-kafka-lab.bat"
if not exist "%LAB_SESSION_BAT%" (
  echo WARNING: %LAB_SESSION_BAT% not found — run start-lab.bat first or set LAB_SESSION_BAT
)

set "PYTHONPATH=%ROOT%\scripts;%PYTHONPATH%"
set "PATH=%VENV%;%PATH%"
if not defined LAB_SESSION_BAT if exist "%ROOT%\internal\tools\_trainer-user15-session.bat" (
  set "LAB_SESSION_BAT=%ROOT%\internal\tools\_trainer-user15-session.bat"
)

cd /d "%ROOT%"
echo.
echo === Kafka lab JupyterLab (local venv) ===
echo Session file: %LAB_SESSION_BAT%
echo Open: http://localhost:8888/lab
echo Notebooks: day-01\lab.ipynb  day-02\lab.ipynb  ...
echo.
"%JUPYTER%" lab --notebook-dir="%ROOT%" --port=8888 --no-browser --IdentityProvider.token=
