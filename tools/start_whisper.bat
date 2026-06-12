@echo off
:: ============================================================
:: Hadarni — Whisper ASR Server Launcher (Windows)
:: ============================================================
:: Starts the FastAPI Whisper server using the final_model.
:: Run this script from the project root before launching the app.
::
:: Usage:
::   tools\start_whisper.bat
:: ============================================================

echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║   Hadarni Whisper ASR Server                 ║
echo  ║   Model: final_model/final_model             ║
echo  ║   Port : 8000                                ║
echo  ╚══════════════════════════════════════════════╝
echo.

cd /d "%~dp0.."

:: Check Python is available
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.10+ and add it to PATH.
    pause
    exit /b 1
)

:: Check uvicorn is installed
python -c "import uvicorn" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Installing uvicorn...
    pip install uvicorn[standard]
)

:: Check the final model directory exists
if not exist "final_model\final_model\model.safetensors" (
    echo [ERROR] Model not found at final_model\final_model\model.safetensors
    echo         Please ensure the final_model folder is at the project root.
    pause
    exit /b 1
)

python tools/run_server.py

pause
