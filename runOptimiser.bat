@echo off
title Device Optimiser

:: -------------------------------
:: Auto Admin Elevation
:: -------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo Starting Device Optimisation...
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0DeviceOptimiser.ps1"

echo.
echo Done. Click to continue
pause