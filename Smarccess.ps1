# Intentar acceso directo a SMART (puede fallar en algunos SSD)
$smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictData -ErrorAction SilentlyContinue
$smartData | ForEach-Object { 
    Write-Host "Disco $($_.InstanceName.Split('\')[1]):"
    Write-Host "  Atributos SMART crudos: $([BitConverter]::ToString($_.VendorSpecific))"
}