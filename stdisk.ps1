<#
.SYNOPSIS
    Muestra información de discos con letras de unidad asignadas
.DESCRIPTION
    Versión corregida que evita los errores de interpretación
#>

function Format-DiskSize {
    param([uint64]$bytes)
    if ($bytes -ge 1TB) { return "{0:n1} TB" -f ($bytes / 1TB) }
    else { return "{0:n0} GB" -f ($bytes / 1GB) }
}

function Get-DiskInfoWithLetters {
    [CmdletBinding()]
    param()

    # Obtener discos físicos
    $physicalDisks = @{}
    
    # Método moderno (Windows 8/Server 2012+)
    try {
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($disks) {
            foreach ($disk in $disks) {
                $physicalDisks[$disk.DeviceID] = [PSCustomObject]@{
                    Model = $disk.FriendlyName
                    Size = Format-DiskSize $disk.Size
                    Health = switch ($disk.HealthStatus) {
                        0 { "Desconocido"; break }
                        1 { "OK"; break }
                        2 { "Advertencia"; break }
                        3 { "Error"; break }
                        default { "No disponible" }
                    }
                    MediaType = $disk.MediaType
                    Letters = @()
                }
            }
        }
    } catch {}

    # Método WMI para compatibilidad con versiones anteriores
    if ($physicalDisks.Count -eq 0) {
        try {
            $disks = Get-WmiObject -Class Win32_DiskDrive -ErrorAction SilentlyContinue
            foreach ($disk in $disks) {
                $physicalDisks[$disk.Index] = [PSCustomObject]@{
                    Model = $disk.Model.Trim()
                    Size = Format-DiskSize $disk.Size
                    Health = $disk.Status
                    MediaType = $disk.InterfaceType
                    Letters = @()
                }
            }
        } catch {}
    }

    # Obtener letras de unidad asignadas
    try {
        $partitions = Get-WmiObject -Class Win32_DiskPartition -ErrorAction SilentlyContinue
        foreach ($partition in $partitions) {
            $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition" -ErrorAction SilentlyContinue
            foreach ($logicalDisk in $logicalDisks) {
                if ($logicalDisk.DeviceID -and $physicalDisks.ContainsKey($partition.DiskIndex)) {
                    $physicalDisks[$partition.DiskIndex].Letters += $logicalDisk.DeviceID
                }
            }
        }
    } catch {}

    # Mostrar información
    Write-Output "`n=== INFORMACIÓN COMPLETA DE DISCOS ==="

    foreach ($diskId in $physicalDisks.Keys) {
        $diskInfo = $physicalDisks[$diskId]
        
        $output = @"
`nDisco Físico #$diskId
  Modelo: $($diskInfo.Model)
  Tamaño: $($diskInfo.Size)
  Salud: $($diskInfo.Health)
  Tipo: $($diskInfo.MediaType)
  Unidades asignadas: $($diskInfo.Letters -join ', ')
"@
        Write-Output $output
    }

    # Mostrar alertas SMART si existen
    try {
        $smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
        if ($smartData -and ($smartData | Where-Object { $_.PredictFailure })) {
            Write-Output "`n=== ALERTAS SMART ==="
            foreach ($smart in $smartData) {
                if ($smart.PredictFailure) {
                    $diskNumber = $smart.InstanceName.Split('\')[1]
                    Write-Output "  ¡ATENCIÓN! Disco $diskNumber podría fallar (Razón: $($smart.Reason))"
                }
            }
        }
    } catch {}
}

# Ejecutar el script
Get-DiskInfoWithLetters