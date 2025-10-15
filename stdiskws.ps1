function Get-FullDiskReport {
    # Obtener información básica de discos
    $disks = Get-Disk | Select-Object Number, FriendlyName, Size, OperationalStatus, HealthStatus, BusType, SerialNumber

    # Procesar cada disco
    $diskReport = foreach ($disk in $disks) {
        # Crear objeto de información del disco
        $diskInfo = [PSCustomObject]@{
            'Disco' = "Físico #$($disk.Number)"
            'Modelo' = $disk.FriendlyName
            'Tamaño' = "{0:n1} GB" -f ($disk.Size/1GB)
            'Interfaz' = switch ($disk.BusType) {
                3 { "ATA"; break }
                7 { "USB"; break }
                11 { "SATA"; break }
                17 { "NVMe"; break }
                default { "Tipo $($disk.BusType)" }
            }
            'Estado' = $disk.OperationalStatus
            'Salud' = switch ($disk.HealthStatus) {
                0 { "Desconocido"; break }
                1 { "OK"; break }
                2 { "Advertencia"; break }
                3 { "Error"; break }
                default { "No evaluado" }
            }
            'Horas Uso' = "N/D"
            'Temp (°C)' = "N/D"
            'Bloques Reasign' = "N/D"
            '% Vida' = "N/D"
            'Particiones' = @()
        }

        # Método 1: SMART estándar (WMI)
        try {
            $smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictData -ErrorAction Stop |
                         Where-Object { $_.InstanceName -match $disk.Number }

            if ($smartData) {
                $vendorSpecific = $smartData.VendorSpecific
                
                # Procesar atributos comunes
                for ($i = 0; $i -lt $vendorSpecific.Length - 11; $i += 12) {
                    $attrId = $vendorSpecific[$i]
                    $value = $vendorSpecific[$i+3]
                    $rawData = $vendorSpecific[($i+6)..($i+11)]

                    switch ($attrId) {
                        0x09 { # Horas de uso
                            $diskInfo.'Horas Uso' = [BitConverter]::ToUInt32($rawData[0..3], 0)
                        }
                        0xC2 { # Temperatura
                            $diskInfo.'Temp (°C)' = $value
                        }
                        0x05 { # Bloques reasignados
                            $diskInfo.'Bloques Reasign' = [BitConverter]::ToUInt32($rawData[0..3], 0)
                        }
                        0xCA { # Porcentaje de vida
                            $diskInfo.'% Vida' = "$value%"
                        }
                    }
                }
            }
        } catch {
            Write-Verbose "No se pudo obtener SMART vía WMI para disco $($disk.Number)"
        }

        # Método 2: StorageReliabilityCounter para discos modernos
        if ($diskInfo.'Horas Uso' -eq "N/D" -and $PSVersionTable.PSVersion.Major -ge 5) {
            try {
                $storageCounter = Get-PhysicalDisk | Where-Object DeviceId -eq $disk.Number | Get-StorageReliabilityCounter -ErrorAction Stop
                
                if ($storageCounter) {
                    $diskInfo.'Horas Uso' = [math]::Round($storageCounter.PowerOnHours, 1)
                    $diskInfo.'Temp (°C)' = $storageCounter.Temperature
                    $diskInfo.'% Vida' = if ($storageCounter.Wear) { "{0:n0}%" -f $storageCounter.Wear } else { "N/D" }
                }
            } catch {
                Write-Verbose "No se pudo obtener contadores de confiabilidad"
            }
        }

        # Obtener información de particiones para este disco
        $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue | 
                      Where-Object { $_.Type -ne "Reserved" -and $_.DriveLetter -ne $null } |
                      Sort-Object -Property DriveLetter
        
        foreach ($partition in $partitions) {
            $partitionInfo = [PSCustomObject]@{
                'Letra' = $partition.DriveLetter + ":"
                'Tamaño' = "{0:n1} GB" -f ($partition.Size/1GB)
                'Tipo' = switch ($partition.Type) {
                    "Basic" { "Básica" }
                    "IFS" { "Sistema" }
                    default { $partition.Type }
                }
                'Sistema Archivos' = (Get-Volume -Partition $partition -ErrorAction SilentlyContinue).FileSystemType
            }
            $diskInfo.Particiones += $partitionInfo
        }

        $diskInfo
    }

    # Mostrar reporte completo
    Write-Host "`n=== REPORTE COMPLETO DE DISCOS ===`n" -ForegroundColor Cyan
    
    foreach ($disk in $diskReport) {
        # Mostrar información del disco
        $disk | Format-Table -AutoSize -Property "Disco", "Modelo", "Tamaño", "Interfaz", "Estado", "Salud", "Horas Uso", "Temp (°C)", "Bloques Reasign", "% Vida"
        
        # Mostrar particiones si existen
        if ($disk.Particiones.Count -gt 0) {
            Write-Host "`nParticiones del disco $($disk.Disco):" -ForegroundColor Yellow
            $disk.Particiones | Format-Table -AutoSize -Property "Letra", "Tamaño", "Tipo", "Sistema Archivos"
        } else {
            Write-Host "`nDisco $($disk.Disco) no tiene particiones visibles" -ForegroundColor DarkYellow
        }
        
        Write-Host "`n" + ("-" * 50) + "`n" -ForegroundColor DarkGray
    }
}

# Ejecutar el reporte completo
Get-FullDiskReport
