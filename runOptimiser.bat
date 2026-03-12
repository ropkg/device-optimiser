@echo off
title Device Optimiser

echo Starting Device Optimisation...
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0DeviceOptimiser.ps1"

echo.
echo Optimisation completed.
pause