netstat -ano | Select-String "LISTENING" | ForEach-Object { $line = $_.ToString().Trim(); $processId = ($line -split '\s+')[-1]; $port = ($line -split '\s+')[2]; $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName; Write-Host "Port: $port, PID: $processId, Process: $($processName -replace '.exe$')"
}
netstat -ano