@echo off
setlocal enabledelayedexpansion

:: Verificar que se ejecuta como administrador
echo Verificando permisos de administrador...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Necesitas ejecutar este script como Administrador.
    echo.
    echo Por favor, haz clic derecho sobre el archivo y selecciona "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo Permisos de administrador confirmados.
echo.

:: Crear archivo de registro
set log_file=%TEMP%\reparacion_windows_%date:~-4,4%%date:~-10,2%%date:~-7,2%.log
echo [%date% %time%] Inicio de reparacion de Windows > "%log_file%"

:: Menú principal
:menu
cls
echo ========================================
echo      HERRAMIENTA DE REPARACION WINDOWS
echo ========================================
echo.
echo 1. Reparacion completa (recomendado)
echo 2. Reparacion de archivos de sistema
echo 3. Reparacion de disco
echo 4. Limpieza del sistema
echo 5. Limpieza PROFUNDA (incluye actualizaciones Windows)
echo 6. Ver registro de actividades
echo 7. Salir
echo.
set /p opcion="Selecciona una opcion (1-7): "

if "%opcion%"=="1" goto reparacion_completa
if "%opcion%"=="2" goto reparacion_sistema
if "%opcion%"=="3" goto reparacion_disco
if "%opcion%"=="4" goto limpieza_sistema
if "%opcion%"=="5" goto limpieza_profunda
if "%opcion%"=="6" goto ver_registro
if "%opcion%"=="7" exit
echo Opcion no valida. Presiona cualquier tecla para continuar...
pause >nul
goto menu

:: Reparación completa
:reparacion_completa
echo Ejecutando reparacion completa...
echo [%date% %time%] Inicio reparacion completa >> "%log_file%"
call :limpieza_sistema
call :reparacion_sistema
call :reparacion_disco
echo [%date% %time%] Fin reparacion completa >> "%log_file%"
echo Reparacion completa finalizada.
pause
goto menu

:: Reparación de sistema
:reparacion_sistema
echo.
echo = REPARACION DE ARCHIVOS DE SISTEMA =
echo.
echo Ejecutando DISM /CheckHealth...
echo [%date% %time%] DISM CheckHealth >> "%log_file%"
dism /online /cleanup-image /checkhealth
echo %errorlevel% >> "%log_file%"

echo.
echo Ejecutando DISM /ScanHealth...
echo [%date% %time%] DISM ScanHealth >> "%log_file%"
dism /online /cleanup-image /scanhealth
echo %errorlevel% >> "%log_file%"

echo.
echo Ejecutando DISM /RestoreHealth...
echo [%date% %time%] DISM RestoreHealth >> "%log_file%"
dism /online /cleanup-image /restorehealth
echo %errorlevel% >> "%log_file%"

echo.
echo Ejecutando SFC /ScanNow...
echo [%date% %time%] SFC ScanNow >> "%log_file%"
sfc /scannow
echo %errorlevel% >> "%log_file%"

echo.
echo Reparacion de sistema completada.
echo [%date% %time%] Fin reparacion sistema >> "%log_file%"
goto :eof

:: Reparación de disco
:reparacion_disco
echo.
echo = REPARACION DE DISCO =
echo.
echo Comprobando estado del disco...
echo [%date% %time%] Comprobacion estado disco >> "%log_file%"
wmic diskdrive get status
echo %errorlevel% >> "%log_file%"

echo.
echo Ejecutando CHKDSK en modo lectura...
echo [%date% %time%] CHKDSK lectura >> "%log_file%"
chkdsk
echo %errorlevel% >> "%log_file%"

echo.
set /p chkdsk_repair="¿Deseas ejecutar CHKDSK con reparacion? (s/n): "
if /i "!chkdsk_repair!"=="s" (
    echo Programando CHKDSK para el proximo reinicio...
    echo [%date% %time%] CHKDSK programado >> "%log_file%"
    chkdsk C: /f
    echo.
    echo CHKDSK se ejecutara en el proximo reinicio.
    set reboot_needed=1
)

echo.
echo Reparacion de disco completada.
echo [%date% %time%] Fin reparacion disco >> "%log_file%"
goto :eof

:: Limpieza del sistema - VERSIÓN MEJORADA
:limpieza_sistema
echo.
echo = LIMPIEZA DEL SISTEMA =
echo.

echo Limpiando archivos temporales de TEMP...
echo [%date% %time%] Limpieza carpeta TEMP >> "%log_file%"
if exist %TEMP% (
    for /d %%i in ("%TEMP%\*") do (
        echo Eliminando carpeta: %%i
        rmdir /s /q "%%i" 2>nul
    )
    for %%i in ("%TEMP%\*.*") do (
        echo Eliminando archivo: %%i
        del /f /q "%%i" 2>nul
    )
    echo %errorlevel% >> "%log_file%"
) else (
    echo Carpeta TEMP no encontrada.
    echo ERROR: Carpeta TEMP no encontrada >> "%log_file%"
)

echo.
echo Limpiando archivos temporales de Prefetch...
echo [%date% %time%] Limpieza Prefetch >> "%log_file%"
if exist C:\Windows\Prefetch (
    del /f /q C:\Windows\Prefetch\*.* 2>nul
    echo %errorlevel% >> "%log_file%"
) else (
    echo Carpeta Prefetch no encontrada.
    echo ERROR: Carpeta Prefetch no encontrada >> "%log_file%"
)

echo.
echo Limpiando cache DNS...
echo [%date% %time%] Limpieza cache DNS >> "%log_file%"
ipconfig /flushdns
echo %errorlevel% >> "%log_file%"

echo.
echo Ejecutando limpieza de disco basica...
echo [%date% %time%] Limpieza de disco basica >> "%log_file%"
cleanmgr /sagerun:1
echo %errorlevel% >> "%log_file%"

echo.
echo Limpieza del sistema completada.
echo [%date% %time%] Fin limpieza sistema >> "%log_file%"
goto :eof

:: LIMPIEZA PROFUNDA - Incluye actualizaciones de Windows
:limpieza_profunda
echo.
echo = LIMPIEZA PROFUNDA DEL SISTEMA =
echo.
echo Esta opcion eliminara tambien actualizaciones antiguas de Windows.
echo Esto puede liberar MUCHO espacio (varios GB), pero requiere mas tiempo.
echo.
set /p confirmar="¿Continuar con limpieza profunda? (s/n): "
if /i not "!confirmar!"=="s" (
    echo Limpieza profunda cancelada.
    goto :eof
)

echo Configurando limpieza profunda...
echo [%date% %time%] Inicio limpieza profunda >> "%log_file%"

:: Crear configuración personalizada para cleanmgr
echo [Version] > %TEMP%\cleanmgr_profundo.ini
echo Signature=$Chicago$ >> %TEMP%\cleanmgr_profundo.ini
echo AdvancedRun= >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [StateStore] >> %TEMP%\cleanmgr_profundo.ini
echo StateKey=System\CurrentControlSet\Control\Session Manager\ >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [CleanProfiles] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=0 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [Windows Update Cleanup] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [Downloaded Program Files] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [Temporary Internet Files] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [Offline Web Pages] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [GameNewsFiles] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [GameStatisticsFiles] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini
echo. >> %TEMP%\cleanmgr_profundo.ini
echo [Windows Error Reports] >> %TEMP%\cleanmgr_profundo.ini
echo Default=0 >> %TEMP%\cleanmgr_profundo.ini
echo State=2 >> %TEMP%\cleanmgr_profundo.ini

echo Ejecutando limpieza profunda con actualizaciones de Windows...
echo [%date% %time%] Ejecutando limpieza profunda >> "%log_file%"
cleanmgr /sagerun:9

:: Alternativa: Limpieza manual de actualizaciones de Windows
echo.
echo Limpiando manualmente actualizaciones de Windows...
echo [%date% %time%] Limpieza manual actualizaciones >> "%log_file%"
DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
echo %errorlevel% >> "%log_file%"

echo.
echo Limpieza profunda completada.
echo [%date% %time%] Fin limpieza profunda >> "%log_file%"
pause
goto menu

:: Ver registro
:ver_registro
cls
echo = REGISTRO DE ACTIVIDADES =
echo.
if exist "%log_file%" (
    type "%log_file%"
) else (
    echo No hay registro disponible.
)
echo.
pause
goto menu

:: Finalización
:final
echo.
if defined reboot_needed (
    echo ¡ATENCION! Se requiere reinicio para completar las reparaciones.
    echo.
    set /p reinicio="¿Deseas reiniciar ahora? (s/n): "
    if /i "!reinicio!"=="s" (
        shutdown /r /t 30 /c "Reinicio para completar reparacion de Windows"
        echo El equipo se reiniciara en 30 segundos.
    )
)
echo.
echo Reparaciones completadas. Ver detalles en: %log_file%
echo.
pause