<#
.SYNOPSIS
    Script para obtener información del sistema (ejecutar como Administrador)
.DESCRIPTION
    Versión optimizada para evitar errores de memoria y bloqueo de archivos
#>

$output = "$env:USERPROFILE\Desktop\reporte_sistema.txt"

# Eliminar archivo existente si hay
if (Test-Path $output) {
    Remove-Item $output -Force
}

Write-Host "Generando reporte... Espere por favor."

# Crear contenido en memoria primero
$reportContent = @()
$reportContent += "=============================================="
$reportContent += "INFORMACION DEL SISTEMA - REPORTE COMPLETO"
$reportContent += "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$reportContent += "=============================================="
$reportContent += ""

# Función segura para obtener datos WMI
function Get-SafeWmiData {
    param($ClassName, $Properties)
    try {
        $data = Get-CimInstance -ClassName $ClassName -ErrorAction Stop | 
                Select-Object $Properties | 
                Out-String
        return $data.Trim()
    } catch {
        return "Error al obtener datos: $($_.Exception.Message)"
    }
}

# [PLACA BASE] - Versión optimizada para memoria
$reportContent += "[PLACA BASE]"
$reportContent += "--------------------------------------------------------------"
try {
    $baseboard = Get-CimInstance Win32_BaseBoard -ErrorAction Stop | 
                 Select-Object Manufacturer, Product, Version
    $reportContent += ($baseboard | Format-List | Out-String).Trim()
} catch {
    $reportContent += "No se pudo obtener información de la placa base: $($_.Exception.Message)"
}
$reportContent += ""

# [BIOS]
$reportContent += "[BIOS - NUMERO DE SERIE]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-SafeWmiData -ClassName Win32_BIOS -Properties SerialNumber)
$reportContent += ""

# [EQUIPO PRINCIPAL]
$reportContent += "[EQUIPO PRINCIPAL]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-SafeWmiData -ClassName Win32_ComputerSystemProduct -Properties Vendor, Name, IdentifyingNumber)
$reportContent += ""

# [DISCOS DUROS] - Procesado por separado para evitar memoria
$reportContent += "[DISCOS DUROS]"
$reportContent += "--------------------------------------------------------------"
$reportContent += "Modelo, Serie y Capacidad:"
try {
    Get-CimInstance Win32_DiskDrive | ForEach-Object {
        $sizeGB = if ($_.Size) { [math]::Round($_.Size / 1GB, 2) } else { "Desconocido" }
        $serial = if ($_.SerialNumber) { $_.SerialNumber.Trim() } else { "No disponible" }
        $reportContent += "$($_.Caption) [Serie: $serial] [Capacidad: $sizeGB GB]"
    }
} catch {
    $reportContent += "Error al obtener información de discos: $($_.Exception.Message)"
}
$reportContent += ""

# [MEMORIA RAM]
$reportContent += "[MEMORIA RAM]"
$reportContent += "--------------------------------------------------------------"
try {
    $totalRAM = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    $reportContent += "Capacidad Total: $totalRAM GB"
} catch {
    $reportContent += "Error al obtener información de RAM: $($_.Exception.Message)"
}
$reportContent += ""

# [PROCESADOR]
$reportContent += "[PROCESADOR]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-SafeWmiData -ClassName Win32_Processor -Properties Name)
$reportContent += ""

# [SISTEMA OPERATIVO]
$reportContent += "[SISTEMA OPERATIVO]"
$reportContent += "--------------------------------------------------------------"
$reportContent += (Get-SafeWmiData -ClassName Win32_OperatingSystem -Properties Caption, OSArchitecture)
$reportContent += ""

# [ANTIVIRUS]
$reportContent += "[ANTIVIRUS]"
$reportContent += "--------------------------------------------------------------"
try {
    $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($av) {
        $reportContent += ($av | Select-Object displayName | Out-String).Trim()
    } else {
        $reportContent += "Información no disponible (ejecutar como Administrador)"
    }
} catch {
    $reportContent += "No se pudo obtener información del antivirus: $($_.Exception.Message)"
}

# Fin del reporte
$reportContent += "=============================================="
$reportContent += "FIN DEL REPORTE"
$reportContent += "=============================================="

# Escribir todo el contenido de una sola vez
$reportContent | Out-File -FilePath $output -Encoding utf8

Write-Host "`nReporte generado correctamente en:"
Write-Host $output
Write-Host "`nPresiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
