# Script para capturar tráfico HTTP (puerto 80)
cd C:\Users\Sat1\Desktop\pktmon
pktmon filter remove
pktmon start -c
pktmon counters
pktmon start -c --comp nics
pktmon list
pktmon stop -c
pktmon counters
pktmon start -c --comp nics
pktmon start -c --pkt-size 0 --comp nics --file-name C:\Users\Sat1\Desktop\pktmon_log.etl
pktmon start help
pktmon start -c --pkt-size 0 --comp nics --file-name C:\Users\Sat1\Desktop\mi_log_de_red.etl
C:\Users\Sat1\Desktop\pktmon