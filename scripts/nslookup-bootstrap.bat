@echo off
REM Resolve MSK public bootstrap hostname (strip :9196). Requires BOOTSTRAP from set-kafka-lab.bat.
if "%BOOTSTRAP%"=="" (
  echo ERROR: BOOTSTRAP is empty. Run set-kafka-lab.bat first.
  exit /b 1
)
for /f "tokens=1 delims=:" %%a in ("%BOOTSTRAP%") do (
  echo Resolving bootstrap host: %%a
  nslookup %%a
  exit /b %ERRORLEVEL%
)
echo ERROR: Could not parse BOOTSTRAP=%BOOTSTRAP%
exit /b 1
