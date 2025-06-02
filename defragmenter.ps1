<#
.SYNOPSIS
    Script de optimización de discos con visualización mejorada
.DESCRIPTION
    Versión que muestra claramente los discos disponibles antes del menú
    y permite seleccionar qué disco analizar/optimizar
#>

function Show-Header {
    param($Title)
    Clear-Host
    Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
    Write-Host " $Title " -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ("=" * 70) + "`n" -ForegroundColor Cyan
}

function Get-DiskInfo {
    try {
        $disks = @()
        $physicalDisks = Get-Disk | Where-Object { $_.HealthStatus -eq 'Healthy' }
        
        foreach ($disk in $physicalDisks) {
            $partitions = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.DriveLetter }
            
            foreach ($partition in $partitions) {
                $volume = Get-Volume -Partition $partition -ErrorAction SilentlyContinue
                if (-not $volume) { continue }
                
                $sizeGB = [math]::Round($volume.Size / 1GB, 2)
                $freeGB = [math]::Round($volume.SizeRemaining / 1GB, 2)
                
                $disks += [PSCustomObject]@{
                    DiskNumber   = $disk.Number
                    DriveLetter  = $partition.DriveLetter
                    MediaType   = $disk.MediaType
                    Model       = $disk.FriendlyName
                    SizeGB      = $sizeGB
                    FreePercent = [math]::Round(($freeGB/$sizeGB)*100)
                    HealthStatus = $disk.HealthStatus
                }
            }
        }
        return $disks
    } catch {
        Write-Host "Error al obtener información de discos: $_" -ForegroundColor Red
        return @()
    }
}

function Show-Disks {
    param($DiskInfo)
    
    Write-Host "`n=== DISCOS DETECTADOS ===" -ForegroundColor Green
    if ($DiskInfo.Count -eq 0) {
        Write-Host "No se encontraron discos válidos" -ForegroundColor Red
        return
    }
    
    $counter = 1
    foreach ($disk in $DiskInfo) {
        Write-Host "$counter. [$($disk.DriveLetter)] $($disk.Model)" -ForegroundColor White
        Write-Host "   Tipo: $($disk.MediaType)" -ForegroundColor $(if ($disk.MediaType -eq 'SSD') { 'Cyan' } else { 'Yellow' })
        Write-Host "   Tamaño: $($disk.SizeGB) GB | Libre: $($disk.FreePercent)%" -ForegroundColor Gray
        Write-Host "   Estado: $($disk.HealthStatus)`n" -ForegroundColor $(if ($disk.HealthStatus -eq 'Healthy') { 'Green' } else { 'Red' })
        $counter++
    }
}

function Show-Menu {
    Write-Host "`n=== MENÚ PRINCIPAL ===" -ForegroundColor Magenta
    Write-Host "1. Analizar fragmentación (HDD)" -ForegroundColor Yellow
    Write-Host "2. Optimizar SSD (TRIM)" -ForegroundColor Cyan
    Write-Host "3. Desfragmentar HDD" -ForegroundColor Yellow
    Write-Host "4. Optimizar todos los discos" -ForegroundColor Green
    Write-Host "R. Refrescar lista de discos" -ForegroundColor Gray
    Write-Host "Q. Salir`n" -ForegroundColor Red
    
    # Leer entrada y validarla
    do {
        $choice = (Read-Host "Seleccione una opción").Trim().ToUpper()
        $validOptions = @('1','2','3','4','R','Q')
        
        if ($choice -in $validOptions) {
            return $choice
        }
        Write-Host "Opción no válida. Por favor seleccione 1-4, R o Q." -ForegroundColor Red
    } while ($true)
}

function Analyze-Disk {
    param($DriveLetter, $Model)
    
    try {
        Write-Host "`nAnalizando fragmentación de $DriveLetter ($Model)..."
        $result = Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose 4>&1
        
        # Mostrar resultados del análisis
        $fragPercent = if ($result -match "(\d+)% fragmented") { $matches[1] } else { "0" }
        
        Write-Host "`n=== RESULTADOS DEL ANÁLISIS ===" -ForegroundColor Cyan
        Write-Host "Disco: $DriveLetter ($Model)"
        Write-Host "Fragmentación: $fragPercent%"
        
        if ([int]$fragPercent -gt 10) {
            Write-Host "Recomendación: Necesita desfragmentación" -ForegroundColor Red
        } else {
            Write-Host "Estado: Optimizado" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Host "  [ERROR] Fallo al analizar $DriveLetter : $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-Disk {
    param($DriveLetter, $MediaType, $Model)
    
    try {
        if ($MediaType -eq 'SSD') {
            Write-Host "`nOptimizando SSD $DriveLetter ($Model) con TRIM..." -ForegroundColor Cyan
            Optimize-Volume -DriveLetter $DriveLetter -ReTrim -Verbose
            Write-Host "TRIM completado correctamente" -ForegroundColor Green
        }
        else {
            Write-Host "`nDesfragmentando HDD $DriveLetter ($Model)..." -ForegroundColor Yellow
            Optimize-Volume -DriveLetter $DriveLetter -Defrag -Verbose
            Write-Host "Desfragmentación completada" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "  [ERROR] Fallo en $DriveLetter : $_" -ForegroundColor Red
        return $false
    }
}

function Select-Disk {
    param($DiskInfo, $OperationType)
    
    $validDisks = @()
    $message = ""
    
    switch ($OperationType) {
        "ANALYZE" { 
            $validDisks = $DiskInfo | Where-Object { $_.MediaType -eq 'HDD' }
            $message = "Seleccione HDD para analizar (1-$($validDisks.Count))" 
        }
        "SSD" { 
            $validDisks = $DiskInfo | Where-Object { $_.MediaType -eq 'SSD' }
            $message = "Seleccione SSD para optimizar (1-$($validDisks.Count))" 
        }
        "HDD" { 
            $validDisks = $DiskInfo | Where-Object { $_.MediaType -eq 'HDD' }
            $message = "Seleccione HDD para desfragmentar (1-$($validDisks.Count))" 
        }
    }
    
    if ($validDisks.Count -eq 0) {
        Write-Host "No hay discos disponibles para esta operación" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "`n$message" -ForegroundColor White
    for ($i = 0; $i -lt $validDisks.Count; $i++) {
        Write-Host "$($i+1). $($validDisks[$i].DriveLetter) $($validDisks[$i].Model)"
    }
    
    do {
        $selection = Read-Host "`nSeleccione un disco (1-$($validDisks.Count))"
        if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $validDisks.Count) {
            return $validDisks[[int]$selection-1]
        }
        Write-Host "Selección inválida. Intente nuevamente." -ForegroundColor Red
    } while ($true)
}

# ========= PROGRAMA PRINCIPAL =========
Write-Host "Iniciando optimizador de discos..." -ForegroundColor Magenta

do {
    $diskInfo = Get-DiskInfo
    Show-Disks $diskInfo
    $option = Show-Menu
    
    switch ($option) {
        '1' { 
            $selectedDisk = Select-Disk $diskInfo "ANALYZE"
            if ($selectedDisk) {
                Analyze-Disk $selectedDisk.DriveLetter $selectedDisk.Model
                Read-Host "`nPresione Enter para continuar..."
            }
        }
        '2' { 
            $selectedDisk = Select-Disk $diskInfo "SSD"
            if ($selectedDisk) {
                Optimize-Disk $selectedDisk.DriveLetter $selectedDisk.MediaType $selectedDisk.Model
                Read-Host "`nPresione Enter para continuar..."
            }
        }
        '3' { 
            $selectedDisk = Select-Disk $diskInfo "HDD"
            if ($selectedDisk) {
                Optimize-Disk $selectedDisk.DriveLetter $selectedDisk.MediaType $selectedDisk.Model
                Read-Host "`nPresione Enter para continuar..."
            }
        }
        '4' { 
            Write-Host "`n=== OPTIMIZANDO TODOS LOS DISCOS ===" -ForegroundColor Green
            foreach ($disk in $diskInfo) {
                Optimize-Disk $disk.DriveLetter $disk.MediaType $disk.Model
                Write-Host ""
            }
            Read-Host "`nPresione Enter para continuar..."
        }
        'R' { 
            Write-Host "Actualizando información de discos..." -ForegroundColor Magenta
            Start-Sleep -Seconds 1
        }
        'Q' { 
            Write-Host "Saliendo del programa..." -ForegroundColor Red
            exit
        }
    }
} while ($true)