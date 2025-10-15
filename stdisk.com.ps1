function Get-DiskInfoServer2008 {
    # Obtener información básica de discos
    $disks = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.MediaType -eq "Fixed hard disk media" }

    if (-not $disks) {
        Write-Output "No se encontraron discos duros físicos."
        return
    }

    Write-Output "`n=== INFORMACIÓN DE DISCOS (Windows Server 2008) ===`n"

    foreach ($disk in $disks) {
        # Obtener letras de unidad asociadas
        $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
        $driveLetters = @()
        
        foreach ($partition in $partitions) {
            $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
            foreach ($logicalDisk in $logicalDisks) {
                if ($logicalDisk.DeviceID) {
                    $driveLetters += $logicalDisk.DeviceID
                }
            }
        }

        # Mostrar información del disco
        Write-Output "Disco Físico #$($disk.Index)"
        Write-Output "  Modelo: $($disk.Model.Trim())"
        Write-Output ("  Tamaño: {0:n1} GB" -f ($disk.Size/1GB))
        Write-Output "  Interfaz: $($disk.InterfaceType)"
        Write-Output "  Estado: $($disk.Status)"
        Write-Output "  Unidades asignadas: $($driveLetters -join ', ')`n"
    }

    # Información adicional de particiones
    Write-Output "`n=== INFORMACIÓN DETALLADA DE PARTICIONES ==="
    $partitions = Get-WmiObject -Class Win32_DiskPartition | Where-Object { $_.Type -notmatch "reservada" }
    
    foreach ($partition in $partitions) {
        $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        $driveLetters = $logicalDisks | ForEach-Object { $_.DeviceID } | Where-Object { $_ }
        
        Write-Output "`nPartición: $($partition.Name)"
        Write-Output "  Disco: $($partition.DiskIndex)"
        Write-Output ("  Tamaño: {0:n1} GB" -f ($partition.Size/1GB))
        Write-Output "  Unidades: $($driveLetters -join ', ')`n"
    }
}

# Ejecutar la función
Get-DiskInfoServer2008 | Out-Host