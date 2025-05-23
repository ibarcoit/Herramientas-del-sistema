@echo off
setlocal enabledelayedexpansion
:: Script para obtener y guardar información del sistema en reporte_sistema.txt
:: Debe ejecutarse como Administrador

set "output=reporte_sistema.txt"

echo Generando reporte... Espere por favor.

(
echo ==============================================
echo INFORMACION DEL SISTEMA - REPORTE COMPLETO
echo Fecha: %date% %time%
echo ==============================================
echo.

echo [PLACA BASE]
echo --------------------------------------------------------------
wmic baseboard get product,Manufacturer,version
echo.

echo [BIOS - NUMERO DE SERIE]
echo --------------------------------------------------------------
wmic bios get serialnumber
echo.

echo [EQUIPO PRINCIPAL]
echo --------------------------------------------------------------
wmic csproduct get vendor,name,identifyingnumber
echo.

echo [DISCOS DUROS]
echo --------------------------------------------------------------
echo Modelo, Serie y Capacidad:
for /f "skip=2 tokens=2-4 delims=," %%a in ('wmic diskdrive get caption^,serialnumber^,size /format:csv') do (
    if not "%%a"=="" (
        set "size=%%c"
        set "size=!size:~0,-9!"
        echo %%a [Serie: %%b] [Capacidad: !size! GB]
    )
)
echo.

echo [MEMORIA RAM]
echo --------------------------------------------------------------
for /f "skip=1 tokens=*" %%m in ('wmic memorychip get capacity /format:list ^| findstr "Capacity"') do (
    for /f "tokens=2 delims==" %%n in ("%%m") do (
        set "ram=%%n"
        set "ram=!ram:~0,-9!"
        set /a total_ram+=!ram!
    )
)
echo Capacidad Total: !total_ram! GB
echo.

echo [PROCESADOR]
echo --------------------------------------------------------------
wmic cpu get name
echo.

echo [SISTEMA OPERATIVO]
echo --------------------------------------------------------------
wmic os get caption,osarchitecture /value | findstr "="
echo.

echo [ANTIVIRUS]
echo --------------------------------------------------------------
wmic /namespace:\\root\SecurityCenter2 path AntivirusProduct get displayName /value | findstr "="
echo.

echo ==============================================
echo FIN DEL REPORTE
echo ==============================================
) > "%output%"

echo.
echo Reporte generado correctamente en:
echo %cd%\%output%
echo.
pause


