<#
.SYNOPSIS
    Script para obtener información completa del sistema y red
.DESCRIPTION
    Versión mejorada con:
    - Información del usuario
    - Detalles de hardware y sistema
    - Configuración completa de red
    - Solución al problema de la tecla para salir
.NOTES
    Debe ejecutarse como Administrador para obtener todos los datos
#>

$output = "$env:USERPROFILE\Desktop\reporte_sistema.txt"

# Eliminar archivo existente si existe
if (Test-Path $output) {
    Remove-Item $output -Force
}

Write-Host "Generando reporte completo del sistema y red... Espere por favor."

# Crear contenido en memoria
$reportContent = @()

## ==================== INFORMACIÓN BÁSICA ====================
$reportContent += "=============================================="
$reportContent += "INFORMACION COMPLETA DEL SISTEMA Y RED"
$reportContent += "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$reportContent += "Usuario: $env:USERNAME"
$reportContent += "Equipo: $env:COMPUTERNAME"
$reportContent += "Dominio: $env:USERDOMAIN"
$reportContent += "=============================================="
$reportContent += ""

## ==================== HARDWARE ====================
# [PLACA BASE]
$reportContent += "[PLACA BASE]"
$reportContent += "--------------------------------------------------------------"
try {
    $baseboard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | 
                 Select-Object Manufacturer, Product, Version
    $reportContent += ($baseboard | Format-List | Out-String).Trim()
} catch {
    $reportContent += "Error: $($_.Exception.Message)"
}
$reportContent += ""

# [BIOS]
$reportContent += "[BIOS]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-CimInstance Win32_BIOS | Select-Object SerialNumber, Version, Manufacturer | Format-List | Out-String).Trim()
$reportContent += ""

# [EQUIPO PRINCIPAL]
$reportContent += "[EQUIPO PRINCIPAL]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-CimInstance Win32_ComputerSystemProduct | Select-Object Vendor, Name, IdentifyingNumber, UUID | Format-List | Out-String).Trim()
$reportContent += ""

# [DISCOS DUROS]
$reportContent += "[DISCOS DUROS]"
$reportContent += "--------------------------------------------------------------"
try {
    Get-CimInstance Win32_DiskDrive | ForEach-Object {
        $sizeGB = if ($_.Size) { [math]::Round($_.Size / 1GB, 2) } else { "Desconocido" }
        $serial = if ($_.SerialNumber) { $_.SerialNumber.Trim() } else { "No disponible" }
        $reportContent += "$($_.Caption) [Serie: $serial] [Capacidad: $sizeGB GB] [Interface: $($_.InterfaceType)]"
    }
} catch {
    $reportContent += "Error al obtener información de discos: $($_.Exception.Message)"
}
$reportContent += ""

# [MEMORIA RAM]
$reportContent += "[MEMORIA RAM]"
$reportContent += "--------------------------------------------------------------"
try {
    $ramModules = Get-CimInstance Win32_PhysicalMemory
    $totalRAM = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    $reportContent += "Capacidad Total: $totalRAM GB"
    $reportContent += "Módulos instalados:"
    $ramModules | ForEach-Object {
        $reportContent += "- $([math]::Round($_.Capacity/1GB, 2)) GB ($($_.Speed) MHz) [Serie: $($_.SerialNumber)]"
    }
} catch {
    $reportContent += "Error al obtener información de RAM: $($_.Exception.Message)"
}
$reportContent += ""

# [PROCESADOR]
$reportContent += "[PROCESADOR]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List | Out-String).Trim()
$reportContent += ""

## ==================== SISTEMA ====================
# [SISTEMA OPERATIVO]
$reportContent += "[SISTEMA OPERATIVO]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, InstallDate | Format-List | Out-String).Trim()
$reportContent += ""

# [ANTIVIRUS]
$reportContent += "[ANTIVIRUS]"
$reportContent += "--------------------------------------------------------------"
try {
    $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($av) {
        $reportContent += ($av | Select-Object displayName, productState | Format-List | Out-String).Trim()
    } else {
        $reportContent += "Información no disponible (ejecutar como Administrador)"
    }
} catch {
    $reportContent += "No se pudo obtener información del antivirus: $($_.Exception.Message)"
}
$reportContent += ""

## ==================== INFORMACIÓN DE RED ====================
$reportContent += "=============================================="
$reportContent += "CONFIGURACIÓN DE RED"
$reportContent += "=============================================="
$reportContent += ""

# [TARJETAS DE RED]
$reportContent += "[TARJETAS DE RED]"
$reportContent += "--------------------------------------------------------------"
try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if ($adapters) {
        $adapters | ForEach-Object {
            $reportContent += "Nombre: $($_.Name)"
            $reportContent += "Interfaz: $($_.InterfaceDescription)"
            $reportContent += "Estado: $($_.Status)"
            $reportContent += "Velocidad: $($_.LinkSpeed)"
            $reportContent += "MAC: $($_.MacAddress)"
            $reportContent += ""
            
            # Configuración IP
            $ipConfig = Get-NetIPConfiguration -InterfaceIndex $_.ifIndex -ErrorAction SilentlyContinue
            if ($ipConfig) {
                $reportContent += "Configuración IP:"
                $reportContent += "- IPv4: $($ipConfig.IPv4Address.IPAddress)"
                $reportContent += "- Máscara: $($ipConfig.IPv4Address.PrefixLength)"
                $reportContent += "- Gateway: $($ipConfig.IPv4DefaultGateway.NextHop)"
                $reportContent += "- DNS: $($ipConfig.DNSServer.ServerAddresses -join ', ')"
                $reportContent += ""
            }
        }
    } else {
        $reportContent += "No se encontraron adaptadores de red activos"
    }
} catch {
    $reportContent += "Error al obtener información de red: $($_.Exception.Message)"
}
$reportContent += ""

# [RUTAS DE RED]
$reportContent += "[TABLA DE RUTAS]"
$reportContent += "--------------------------------------------------------------"
try {
    $routes = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.NextHop -ne '0.0.0.0' } | Select-Object DestinationPrefix, NextHop, InterfaceAlias
    if ($routes) {
        $reportContent += ($routes | Format-Table -AutoSize | Out-String).Trim()
    } else {
        $reportContent += "No se encontraron rutas configuradas"
    }
} catch {
    $reportContent += "Error al obtener tabla de rutas: $($_.Exception.Message)"
}
$reportContent += ""

# [CONEXIONES ACTIVAS]
$reportContent += "[CONEXIONES ACTIVAS]"
$reportContent += "--------------------------------------------------------------"
try {
    $connections = Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
    if ($connections) {
        $reportContent += ($connections | Format-Table -AutoSize | Out-String).Trim()
    } else {
        $reportContent += "No se encontraron conexiones activas"
    }
} catch {
    $reportContent += "Error al obtener conexiones: $($_.Exception.Message)"
}

## ==================== FIN ====================
$reportContent += "=============================================="
$reportContent += "FIN DEL REPORTE"
$reportContent += "=============================================="

# Escribir todo el contenido al archivo
$reportContent | Out-File -FilePath $output -Encoding utf8

Write-Host "`nReporte generado correctamente en:"
Write-Host $output
Write-Host ""

# Solución universal para esperar entrada
if ($Host.Name -match 'ISE') {
    # Si se ejecuta en PowerShell ISE
    Write-Host "Script finalizado. Puedes cerrar esta ventana."
    Start-Sleep -Seconds 3
} else {
    # Para PowerShell normal
    Write-Host "Presiona cualquier tecla para continuar..."
    [void][System.Console]::ReadKey($true)
}