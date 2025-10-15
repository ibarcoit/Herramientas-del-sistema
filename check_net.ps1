<#
.SYNOPSIS
    Muestra usuarios conectados al sistema (locales y remotos) y unidades de red mapeadas.
.DESCRIPTION
    Este script muestra:
    1. Usuarios conectados localmente
    2. Usuarios conectados remotamente (por Terminal Services/RDP)
    3. Unidades de red mapeadas en el sistema
#>

function Get-ConnectedUsers {
    # Obtener usuarios conectados localmente
    $localUsers = query user 2>$null | Select-Object -Skip 1
    
    # Obtener sesiones RDP remotas (si hay acceso)
    $remoteUsers = $null
    try {
        $remoteUsers = qwinsta /server:$env:COMPUTERNAME 2>$null | Where-Object { $_ -match 'rdp' }
    } catch {
        Write-Warning "No se pudieron obtener sesiones remotas. Puede que no tengas permisos."
    }

    # Mostrar usuarios locales
    Write-Host "`n=== USUARIOS CONECTADOS LOCALMENTE ===" -ForegroundColor Green
    if ($localUsers) {
        $localUsers | ForEach-Object {
            $userInfo = ($_ -split '\s+').Where({$_ -ne ''})
            [PSCustomObject]@{
                Usuario = $userInfo[0]
                ID_Sesion = $userInfo[1]
                Estado = $userInfo[2]
                TiempoInactivo = $userInfo[3]
                FechaHoraConexion = if ($userInfo.Count -ge 5) { $userInfo[4..($userInfo.Count-1)] -join ' ' } else { 'N/A' }
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No hay usuarios conectados localmente." -ForegroundColor Yellow
    }

    # Mostrar usuarios remotos
    Write-Host "`n=== USUARIOS CONECTADOS REMOTAMENTE (RDP) ===" -ForegroundColor Green
    if ($remoteUsers) {
        $remoteUsers | ForEach-Object {
            $userInfo = ($_ -split '\s+').Where({$_ -ne ''})
            [PSCustomObject]@{
                NombreSesion = $userInfo[0]
                Usuario = $userInfo[1]
                ID_Sesion = $userInfo[2]
                Estado = $userInfo[3]
                Tipo = $userInfo[4]
                Dispositivo = $userInfo[5]
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No hay usuarios conectados remotamente." -ForegroundColor Yellow
    }
}

function Get-NetworkDrives {
    # Obtener unidades de red mapeadas
    Write-Host "`n=== UNIDADES DE RED MAPEADAS ===" -ForegroundColor Green
    
    $networkDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like '\\*' }
    
    if ($networkDrives) {
        $networkDrives | ForEach-Object {
            [PSCustomObject]@{
                LetraUnidad = $_.Name + ":"
                RutaRemota = $_.DisplayRoot
                Proveedor = $_.CurrentLocation
                EspacioLibre = if ($_.Free) { "{0:N2} GB" -f ($_.Free / 1GB) } else { "N/A" }
                EspacioTotal = if ($_.Used + $_.Free) { "{0:N2} GB" -f (($_.Used + $_.Free) / 1GB) } else { "N/A" }
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No hay unidades de red mapeadas." -ForegroundColor Yellow
    }
}

# Ejecutar las funciones
Get-ConnectedUsers
Get-NetworkDrives

Write-Host "`nScript completado." -ForegroundColor Cyan