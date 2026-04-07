# IaaS Multiempresa ASIR - TFC

**Proyecto de Fin de Ciclo (TFC)** para módulo de ASIR.

Sistema de despliegue automatizado de servicios Docker para múltiples empresas con gestión robusta de puertos, credenciales seguras, backups automáticos y validación de dependencias.

---

## Inicio rápido

```bash
# 1. Desplegar WordPress (instala MariaDB automáticamente)
cd scripts
./deploy.sh miempresa wordpress

# 2. Ver servicios desplegados
./list.sh miempresa

# 3. Obtener credenciales
./get-credentials.sh miempresa wordpress

# 4. Eliminar (con backup)
./destroy.sh miempresa wordpress
```

---

## Estructura

```
IaaS-multiempresa-ASIR/
├── scripts/                 # Orquestación y deploy
│   ├── deploy.sh            # Desplegar servicios
│   ├── destroy.sh           # Eliminar servicios
│   ├── list.sh              # Listar servicios
│   ├── get-credentials.sh   # Ver credenciales
│   ├── test.sh              # Suite de tests
│   └── funciones/           # Módulos reutilizables
│       ├── logging.sh       # Sistema de logs
│       ├── db.sh            # Gestión de BD
│       ├── puertos.sh       # Asignación de puertos
│       ├── utils.sh         # Utilidades
│       └── validaciones.sh  # Validaciones
├── catalogo/                 # 14 servicios disponibles
│   ├── wordpress/
│   ├── mariadb/
│   ├── grafana/
│   └── ...
└── infra/                   # Servicios globales
    ├── docker-compose.yml
    └── deploy-infra.sh
```

---

## Características principales

### Despliegue automático con dependencias

WordPress necesita MariaDB? El sistema lo instala automáticamente.

```bash
./deploy.sh acme wordpress

# Resultado:
# [WARN] Dependencia FALTA: acme/mariadb
# [OK] Instalando dependencia: mariadb...
# [OK] Desplegando wordpress...
```

### Multi-empresa con aislamiento

- Servicios independientes por empresa
- Red Docker aislada
- Puertos sin colisiones
- Credenciales propias

### Gestión segura

- Credenciales con permisos 600
- Backups automáticos antes de eliminar
- Base de datos de estado
- Logs de todas las operaciones

---

## Comandos principales

| Comando | Descripción |
|---------|-------------|
| `./deploy.sh <empresa> <servicio>` | Desplegar un servicio |
| `./list.sh [empresa] [formato]` | Ver servicios (tabla/json/csv) |
| `./get-credentials.sh <empresa> <servicio>` | Mostrar credenciales |
| `./destroy.sh <empresa> <servicio>` | Eliminar servicio (con backup) |
| `./test.sh` | Ejecutar suite de tests |

---

## Servicios disponibles (14)

WordPress, MariaDB, Nginx, Grafana, Prometheus, Node-exporter, Portainer, Uptime-Kuma, Vaultwarden, Redis, PhpMyAdmin, Zabbix, Nextcloud, VPN

---

## Infraestructura global

Servicios siempre activos:
- **Portainer** - Gestor Docker (puerto 9000)
- **Grafana** - Dashboards (puerto 3000)
- **Prometheus** - Métricas (puerto 9090)
- **Nginx Proxy Manager** - Proxy inverso (puerto 81)

```bash
cd infra
./deploy-infra.sh start
```

---

## Testing

```bash
cd scripts
./test.sh

# Resultado esperado: 8 PASS, 0 FAIL
```

---

## Requisitos

- Docker (versión 20+)
- Docker Compose (versión 2+)
- Bash 4.0+
- Linux (Ubuntu 20+, Debian 11+)

---

## Status

**LISTO PARA DEFENSA ASIR** ✓

- Fase P0 (base): 100%
- Fase P1 (herramientas): 100%
- Tests: 8/8 PASS
