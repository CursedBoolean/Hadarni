@echo off
:: ============================================================
:: Hadarni — Whisper ASR Server Launcher (Windows)
:: ============================================================
:: Run this script from the project root before launching the app.
::
:: Usage:
::   tools\start_whisper.bat
:: ============================================================

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║   Hadarni Whisper ASR Server                         ║
echo  ║   Model: final_model/final_model                     ║
echo  ╠══════════════════════════════════════════════════════╣
echo  ║  [1] LAN mode      — phone on the same Wi-Fi         ║
echo  ║  [2] Remote mode   — phone on mobile data (ngrok)    ║
echo  ║  [3] Exit                                            ║
echo  ╚══════════════════════════════════════════════════════╝
echo.

set /p CHOICE="  Enter choice (1/2/3): "

if "%CHOICE%"=="1" goto LAN
if "%CHOICE%"=="2" goto NGROK
if "%CHOICE%"=="3" goto END

echo [ERROR] Invalid choice. Please enter 1, 2, or 3.
pause
exit /b 1

:: ── Shared pre-flight checks ──────────────────────────────────────────────────

:PREFLIGHT
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.10+ and add it to PATH.
    pause
    exit /b 1
)

python -c "import uvicorn" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Installing uvicorn...
    pip install "uvicorn[standard]"
)

if not exist "final_model\final_model\model.safetensors" (
    echo [ERROR] Model not found at final_model\final_model\model.safetensors
    echo         Please ensure the final_model folder is at the project root.
    pause
    exit /b 1
)
goto %_NEXT%

:: ── LAN mode ─────────────────────────────────────────────────────────────────

:LAN
cd /d "%~dp0.."
set _NEXT=LAN_START
goto PREFLIGHT

:LAN_START
echo.
echo  [LAN Mode] Starting server — phone must be on the same Wi-Fi.
echo.
python tools/run_server.py
goto END

:: ── Remote / ngrok mode ───────────────────────────────────────────────────────

:NGROK
cd /d "%~dp0.."
set _NEXT=NGROK_CHECK
goto PREFLIGHT

:NGROK_CHECK
where ngrok >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] ngrok not found on PATH.
    echo.
    echo  To install ngrok:
    echo    1. Go to https://ngrok.com/download and download the Windows zip.
    echo    2. Extract ngrok.exe to a folder on your PATH  (e.g. C:\Windows\System32).
    echo    3. Run:  ngrok config add-authtoken ^<YOUR_TOKEN^>
    echo       Get a free token at: https://dashboard.ngrok.com/get-started/your-authtoken
    echo.
    pause
    exit /b 1
)

echo.
echo  [Remote Mode] Starting server + ngrok tunnel.
echo  The Dart service files will be updated automatically with the public URL.
echo  Keep this window open while using the app remotely.
echo.
python tools/run_server.py --ngrok
goto END

:END
pause
