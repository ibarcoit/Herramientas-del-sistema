@echo off
title Limpiador Completo de Archivos Basura (FINAL)

echo Iniciando limpieza (Requiere Administrador)...

:: =========================================================
:: 1. LIMPIEZA DE TEMPORALES DE USUARIO
:: =========================================================
echo.
echo Limpiando temporales de todos los perfiles de usuario...

FOR /D %%U IN ("C:\Users\*") DO (
    :: Limpia ARCHIVOS dentro del TEMP de cada usuario
    DEL /F /S /Q "%%U\AppData\Local\Temp\*.*" > nul 2>&1
    
    :: Limpia SUBCARPETAS dentro del TEMP de cada usuario
    RD /S /Q "%%U\AppData\Local\Temp\*" > nul 2>&1
)

:: =========================================================
:: 2. LIMPIEZA DE TEMPORALES DEL SISTEMA
:: =========================================================
echo.
echo Limpiando temporales del Sistema (C:\Windows\Temp)...

DEL /F /S /Q "%SystemRoot%\TEMP\*.*" > nul 2>&1
RD /S /Q "%SystemRoot%\TEMP\*" > nul 2>&1


:: =========================================================
:: 3. VACIADO DE LA PAPELERA DE RECICLAJE
:: =========================================================
echo.
echo Vaciando la Papelera de Reciclaje (%SystemDrive%\$Recycle.Bin)...

:: Elimina la carpeta $Recycle.Bin (vaciando el contenido)
RD /S /Q "%SystemDrive%\$Recycle.Bin" > nul 2>&1

:: Vuelve a crear la carpeta (necesario para el funcionamiento del SO)
MD "%SystemDrive%\$Recycle.Bin" > nul 2>&1


:: =========================================================
:: 4. LIMPIEZA DE ARCHIVOS PREFETCH
:: =========================================================
echo.
::echo Limpiando archivos Prefetch...
:: El comando elimina los archivos, pero deja la carpeta Prefetch intacta.
::DEL /F /S /Q "%SystemRoot%\Prefetch\*" > nul 2>&1


:: =========================================================
:: 5. LIMPIEZA DE LA CACHÉ DE LA TIENDA DE WINDOWS (MS Store)
:: =========================================================
echo.
echo Limpiando cachés de la Tienda de Windows...

FOR /D %%U IN ("C:\Users\*") DO (
    :: La ruta de la Store varía ligeramente (Microsoft.WindowsStore_*)
    RD /S /Q "%%U\AppData\Local\Packages\Microsoft.WindowsStore_*\LocalCache\*" > nul 2>&1
)


echo.
echo =========================================================
echo Limpieza Total Finalizada.
echo =========================================================

pause