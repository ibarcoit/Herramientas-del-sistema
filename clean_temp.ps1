# Función para calcular tamaño de carpeta en GB
function Get-FolderSize {
    param ([string]$folder)
    if (Test-Path $folder) {
        $size = (Get-ChildItem $folder -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
        return [math]::Round($size, 2)
    }
    return 0
}

# Carpetas a limpiar
$tempFolders = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:WINDIR\Temp",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache"
)

# Mostrar espacio ANTES
Write-Host "=== ESPACIO ANTES DE LIMPIAR ===" -ForegroundColor Cyan
$totalBefore = 0
foreach ($folder in $tempFolders) {
    $size = Get-FolderSize $folder
    Write-Host "$folder : $size GB" -ForegroundColor Yellow
    $totalBefore += $size
}
Write-Host "`nTOTAL TEMPORALES ANTES: $totalBefore GB`n" -ForegroundColor Green

# Limpiar archivos temporales
Write-Host "Limpiando archivos temporales..." -ForegroundColor Magenta
foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Remove-Item "$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Vaciar papelera (compatible con TODOS los Windows)
try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item -Path "$env:USERPROFILE\..\$Recycle.Bin\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "No se pudo vaciar la papelera (método no soportado)." -ForegroundColor Yellow
}

# Mostrar espacio DESPUÉS
Write-Host "`n=== ESPACIO DESPUÉS DE LIMPIAR ===" -ForegroundColor Cyan
$totalAfter = 0
foreach ($folder in $tempFolders) {
    $size = Get-FolderSize $folder
    Write-Host "$folder : $size GB" -ForegroundColor Yellow
    $totalAfter += $size
}
Write-Host "`nTOTAL TEMPORALES DESPUÉS: $totalAfter GB" -ForegroundColor Green
$spaceFreed = $totalBefore - $totalAfter
Write-Host "`n✅ ESPACIO LIBERADO: $spaceFreed GB" -ForegroundColor White -BackgroundColor DarkGreen

# Pausa para ver resultados
Read-Host "`nPresiona Enter para salir"
