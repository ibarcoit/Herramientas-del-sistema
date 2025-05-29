@echo off
:: Script para ejecutar archivos PS1 desde su ubicación actual
:: Versión corregida para Windows 10/11 y sistemas legacy

title Ejecutor de scripts PowerShell
color 0A

:: Verificar si PowerShell está disponible
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: PowerShell no está instalado o no está en el PATH.
    pause
    exit /b
)

:inicio
cls
echo ****************************************
echo * EJECUTOR DE SCRIPTS POWERSHELL *
echo ****************************************
echo.
echo Directorio actual: %CD%
echo.
dir /b *.ps1 2>nul
echo.

:: Pedir nombre del script
set /p script_ps1="Introduce el nombre del script (sin .ps1): "
if "%script_ps1%"=="" goto inicio

:: Verificar existencia del archivo
if not exist "%CD%\%script_ps1%.ps1" (
    echo.
    echo ERROR: No se encontró "%script_ps1%.ps1" en este directorio.
    pause
    goto inicio
)

:: Mostrar información del script
echo.
echo Script seleccionado: %CD%\%script_ps1%.ps1
echo.

:: Confirmar ejecución
choice /c SN /n /m "¿Deseas ejecutar el script? [S/N]"
if errorlevel 2 goto inicio

:: Ejecutar con política bypass
echo.
echo Ejecutando script...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%CD%\%script_ps1%.ps1"

:: Pausa final
echo.
pause
goto inicio