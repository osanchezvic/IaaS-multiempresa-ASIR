# Scripts - Motor de Despliegue v2.0

Esta carpeta contiene el **motor de despliegue refactorizado** de la plataforma multiempresa. Gestiona empresas, servicios, asignación de puertos, credenciales y logging estructurado.

## Estructura Nueva

```
scripts/
├── config.env              # Configuración centralizada
├── deploy.sh              # Script principal de despliegue (REFACTORIZADO)
├── destroy.sh             # Destrucción segura de servicios
├── list.sh                # Listar empresas y servicios
├── .gitignore             # Ignora datos sensibles
├── funciones/             # MODULOS REUTILIZABLES
│   ├── logging.sh         # Sistema de logging estructurado
│   ├── db.sh              # Gestión de bases de datos JSON
│   ├── puertos.sh         # Asignación robusta de puertos (sin colisiones)
│   ├── utils.sh           # Utilidades genéricas
│   └── validaciones.sh    # Validaciones de servicios y dependencias
├── databases/             # ALMACENAMIENTO SEGURO
│   ├── empresas.json      # Registro de empresas
│   ├── servicios.json     # Registro de servicios
│   ├── puertos.json       # Registro de puertos asignados
│   └── credentials/       # Credenciales de servicios (permisos 600)
├── logs/                  # AUDITRIA Y DEBUGGING
│   └── *_deploy_*.log     # Logs de cada operación
└── README.md              # (este archivo)
```

## Cambios P0 Implementados

### [OK] 1. Sistema de Logging Estructurado
- **Archivo**: `funciones/logging.sh`
- Logs con timestamp, nivel (DEBUG/INFO/WARN/ERROR) y contexto
- Múltiples salidas: stdout (coloreado) + archivo
- Trazabilidad completa de operaciones

### [OK] 2. Bases de Datos JSON (no colisiones)
- **Archivo**: `funciones/db.sh`
- Registro de empresas, servicios y puertos
- Validación de duplicados
- Export/Import de estado completo
- Bloqueos básicos (sin race conditions)

### [OK] 3. Asignación Robusta de Puertos
- **Archivo**: `funciones/puertos.sh`
- **SIN colisiones**: Busca puerto libre en rango + registra en DB
- Valida puerto = no en uso en sistema + no en DB
- Range por env: dev (8000-8999), prod (9000-9999)
- Recuperación de puertos al destruir

### ✅ 4. Validaciones Completas
- **Archivo**: `funciones/validaciones.sh`
- Pre-deploy: nombres válidos, catalogo, dependencias
- Post-deploy: compose, env, contenedores corriendo
- Resolución automática de dependencias

### ✅ 5. Credenciales Persistidas
- **Almacenamiento**: `databases/credentials/<empresa>.<servicio>.json`
- Formato JSON estructura (db_user, db_password, admin_user, admin_password, jwt_secret)
- Permisos restrictivos (600)
- Recuperables siempre con: `./credentials.sh show <empresa> <servicio>`

### ✅ 6. Deploy.sh Refactorizado
- Carga todos los módulos automáticamente
- Validaciones pre/post automáticas
- Backup previo antes de cambios
- Transaccionalidad: si falla, estado consistente
- Logging detallado en `logs/<empresa>_<servicio>_deploy_YYYYMMDD_HHMMSS.log`

## Uso

### Desplegar servicio (nuevo)
```bash
./deploy.sh <empresa> <servicio>

# Ejemplo
./deploy.sh miempresa wordpress
```

**Resultado:**
- Validaciones automáticas
- Puerto asignado sin colisiones
- Credenciales guardadas en `databases/credentials/miempresa.wordpress.json`
- Log en `logs/miempresa_wordpress_deploy_*.log`
- URL y contraseñas mostradas en stdout

### Ver logs
```bash
tail -f logs/miempresa_wordpress_deploy_*.log
```

### Consultar credenciales (próximamente)
```bash
./credentials.sh show miempresa wordpress
# Output en JSON:
# {
#   "db_user": "miempresa_user",
#   "db_password": "...",
#   "admin_user": "admin",
#   "admin_password": "..."
# }
```

### Listar servicios (próximamente)
```bash
./list.sh --all
./list.sh --empresa miempresa
./list.sh --json
```

### Destruir servicio (seguro, próximamente)
```bash
./destroy.sh <empresa> <servicio> [--force]
# Requiere confirmación (a menos que --force)
# Backup automático previo
# Libera puerto
# Limpia credenciales
```

## Configuración

Editar `config.env` para personalizar:
- Rangos de puertos (dev vs prod)
- Directorios (BASE_DIR, LOGS_DIR, etc)
- Niveles de logging (LOG_LEVEL)
- Retención de backups

```bash
PUERTO_MIN_DEV=8000
PUERTO_MAX_DEV=8999
PUERTO_MIN_PROD=9000
PUERTO_MAX_PROD=9999
LOG_LEVEL=INFO          # DEBUG, INFO, WARN, ERROR
DEBUG=0                 # Set to 1 for verbose output
FORCE_MODE=0            # Set to 1 to skip confirmations
```

## Base de Datos (Formato)

### empresas.json
```json
{
  "miempresa": {
    "created": "2024-03-26T10:00:00Z",
    "metadata": "...",
    "status": "active"
  }
}
```

### servicios.json
```json
{
  "miempresa:wordpress": {
    "empresa": "miempresa",
    "servicio": "wordpress",
    "puerto": 8042,
    "status": "running",
    "credenciales_file": "/path/to/cred.json",
    "created": "2024-03-26T10:00:00Z"
  }
}
```

### puertos.json
```json
{
  "8042": {
    "empresa": "miempresa",
    "servicio": "wordpress",
    "assigned_at": "2024-03-26T10:00:00Z"
  }
}
```

## Seguridad

### Credenciales
- ✅ Guardadas en JSON separado con permisos 600
- ✅ NO versionadas en git (`.gitignore`)
- ✅ Recuperables siempre desde el servidor
- ⚠️ TODO: Encriptación en reposo (v2.1)

### Datos sensibles no comiteados
- `databases/*.json` (ignorado)
- `databases/credentials/*` (ignorado)
- `logs/*` (ignorado)
- `.env.local` (ignorado)

## Troubleshooting

### Colisión de puertos
```bash
# Ver todos los puertos registrados
jq . scripts/databases/puertos.json

# Ver por empresa
jq '.[] | select(.empresa == "miempresa")' scripts/databases/puertos.json
```

### Credenciales perdidas
```bash
# Recuperar desde archivo guardado
cat scripts/databases/credentials/miempresa.wordpress.json

# Reset de contraseña (próximamente)
./credentials.sh reset miempresa wordpress
```

### Logs de error
```bash
# Ver último error
grep ERROR logs/*deploy*.log | tail -5

# Ver contexto completo
tail -50 logs/miempresa_wordpress_deploy_*.log
```

## Próximos Pasos (P1)

- [ ] Refactorizar `destroy.sh` con backup previo y confirmación
- [ ] Crear `rollback.sh` para restaurar desde snapshot
- [ ] Implementar `list.sh` completo con filtros
- [ ] Crear `credentials.sh` para gestión de secretos
- [ ] Agregar encriptación de credenciales en reposo

## Notas de desarrollo

- Todos los scripts cargan `config.env` y módulos automáticamente
- Use `log_info`, `log_error`, etc para consistencia
- Exporte funciones con `export -f` para subshells
- Los logs se escriben simultáneamente a stdout + archivo
