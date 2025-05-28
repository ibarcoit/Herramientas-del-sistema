# Función para calcular tamaño de carpeta (compatible con PS 2.0+)
function Get-FolderSize {
    param ([string]$folder)
    if (Test-Path $folder) {
        $size = (Get-ChildItem $folder -Recurse | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum / 1GB
        return [math]::Round($size, 2)
    }
    return 0
}

# Carpetas temporales a limpiar (rutas universales)
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

# Limpiar archivos temporales (método compatible)
foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Get-ChildItem $folder -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Vaciar papelera (método universal para todas las versiones)
try {
    $recycleBin = (New-Object -ComObject Shell.Application).Namespace(0xA).Items()
    $recycleBin | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
} catch {
    Write-Host "No se pudo vaciar la papelera (método alternativo falló)." -ForegroundColor Yellow
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

# Pausa
Read-Host "`nPresiona Enter para salir" 