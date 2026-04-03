@echo off
setlocal

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "RUN_DIR=%ROOT_DIR%\.codex_run"
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "APP_DIR=%ROOT_DIR%\apps\admin_windows"
set "BACKEND_LOG=%RUN_DIR%\backend.out.log"
set "BACKEND_ERR=%RUN_DIR%\backend.err.log"

where dart >nul 2>nul
if errorlevel 1 (
  echo [ERROR] dart was not found in PATH.
  echo Install Flutter or Dart SDK and open a new terminal window.
  pause
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] flutter was not found in PATH.
  echo Install Flutter SDK and open a new terminal window.
  pause
  exit /b 1
)

if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

echo Starting backend...
start "PDO Lite Next Backend" cmd.exe /k "cd /d \"%BACKEND_DIR%\" && dart run bin/backend.dart 1>>\"%BACKEND_LOG%\" 2>>\"%BACKEND_ERR%\""

echo Waiting for backend startup...
timeout /t 4 /nobreak >nul

echo Starting Windows app...
start "PDO Lite Next Admin Windows" cmd.exe /k "cd /d \"%APP_DIR%\" && flutter run -d windows"

echo.
echo Backend and app were started.
echo Backend log: %BACKEND_LOG%
echo Backend error log: %BACKEND_ERR%
echo.
pause
