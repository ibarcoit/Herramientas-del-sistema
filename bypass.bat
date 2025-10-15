@echo off
:: Obtener la ruta donde está este script batch
set "batch_path=%~dp0"
cd /d "%batch_path%"

:inicio
cls
echo ****************************************
echo * EJECUTOR DE SCRIPTS POWERSHELL *
echo ****************************************
echo.
echo Directorio actual: %CD%
echo.

:: Mostrar scripts en el directorio del batch
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