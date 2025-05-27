# Scripts de Diagnóstico para Windows

Colección de scripts PowerShell y Batch para monitoreo y diagnóstico de sistemas Windows.

## 📂 Archivos de Scripts

### 1. check_net.ps1
**Descripción**:  
Muestra usuarios conectados (locales/remotos) y unidades de red mapeadas.

**Características**:
- Sesiones de usuarios locales (nombre, ID, estado, tiempo inactivo)
- Conexiones remotas RDP/Terminal Services
- Unidades de red con estadísticas de uso
- Usa comandos nativos: query user, qwinsta, Get-PSDrive

**Uso**:
powershell
.\check_net.ps1


### 2. info.bat
**Descripción**:  
Inventario básico de hardware (versión Batch).

**Características**:
- Información de placa base y BIOS
- Discos (modelo, serial, capacidad)
- Memoria RAM (capacidad total)
- Procesador (modelo)
- Versión del sistema operativo
- Antivirus instalado
- Usa comandos WMIC para máxima compatibilidad

**Uso**:
cmd
info.bat


### 3. info.ps1
**Descripción**:  
Reporte avanzado de sistema y red (versión PowerShell).

**Características mejoradas**:
- Inventario detallado de hardware (incluyendo módulos RAM individuales)
- Configuración completa de red:
  - Adaptadores (MAC, velocidad)
  - Configuración IP (dirección, gateway, DNS)
  - Tabla de rutas
  - Conexiones TCP activas
- Información del sistema operativo
- Formato profesional con manejo de errores
- Guarda resultados en archivo de texto en el escritorio

**Uso**:
powershell
.\info.ps1


## 🔍 Comparativa de Funcionalidades

| Función                | check_net.ps1 | info.bat | info.ps1 |
|------------------------|---------------|----------|----------|
| Sesiones de usuario    | ✅            | ❌       | ❌       |
| Unidades de red        | ✅            | ❌       | ✅       |
| Info básica de hardware | ❌            | ✅       | ✅       |
| Info detallada de hardware | ❌       | ❌       | ✅       |
| Configuración de red   | ❌            | ❌       | ✅       |
| Requiere admin         | Opcional      | Sí       | Sí       |
| Formato de salida      | Consola       | Texto    | Texto    |
| Requiere PowerShell    | ✅            | ❌       | ✅       |

## 🚀 Casos de Uso Recomendados

- Verificación rápida de sesiones: check_net.ps1
- Sistemas legacy (sin PowerShell): info.bat
- Auditoría profesional completa: info.ps1

## ⚠️ Requisitos
- Windows 7 o superior
- PowerShell 5.1+ (para scripts PS)
- Privilegios de administrador (para funcionalidad completa)

## 📝 Notas Adicionales
- Los scripts PowerShell ofrecen información más detallada
- info.ps1 es la versión recomendada para sistemas modernos
- Todos los scripts incluyen manejo básico de errores
- Los resultados se muestran en pantalla y/o guardan en archivo
