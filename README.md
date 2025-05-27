### 📌 Script: info.ps1

**Descripción**:  
Versión mejorada del script batch, escrito en PowerShell, que recopila información completa del sistema y configuración de red.

**Funcionalidades**:
- **Hardware**:
  - Placa base, BIOS, equipo principal
  - Discos duros (con interfaz de conexión)
  - Memoria RAM (módulos individuales con velocidad)
  - Procesador (núcleos, hilos, velocidad)
  
- **Sistema**:
  - Sistema operativo (versión, arquitectura, fecha instalación)
  - Antivirus (nombre, estado)
  
- **Red**:
  - Tarjetas de red activas (MAC, velocidad)
  - Configuración IP (IPv4, máscara, gateway, DNS)
  - Tabla de rutas
  - Conexiones TCP establecidas

**Mejoras respecto a la versión batch**:
- Información más detallada y mejor formateada
- Manejo robusto de errores
- Información de red completa
- Compatibilidad con PowerShell ISE y consola normal
- Genera el reporte en el escritorio del usuario

**Tecnologías utilizadas**:
- Cmdlets de CIM (Common Information Model)
- Cmdlets de red de PowerShell (`Get-NetAdapter`, `Get-NetIPConfiguration`)
- Formateo profesional de salida
- Manejo avanzado de errores

**Requisitos**:
- PowerShell 5.1 o superior
- Ejecución como Administrador para información completa
- Módulos de red de PowerShell habilitados

**Uso típico**:
- Auditoría completa de sistemas
- Solución de problemas de red
- Documentación técnica detallada
- Inventario de activos TI
