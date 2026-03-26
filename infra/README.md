# Infraestructura
Esta carpeta contiene los **servicios globales** de la plataforma. Son componentes que se despliegan una sola vez en el servidor y dan soporte a todas las empresas, pero no pertenecen a ninguna en concreto.

## Servicios Implementados

### Servicios de Red y Proxy
- **Nginx Proxy Manager**: Gestión de dominios, SSL y proxy reverso
  - URL: http://servidor:81 (admin)
  - Credenciales iniciales: admin@example.com / changeme

### Monitorización Global
- **Prometheus**: Recolección de métricas
  - URL: http://servidor:9090
- **Grafana**: Dashboards y visualización
  - URL: http://servidor:3000
  - Credenciales: admin / admin123
- **Node Exporter**: Métricas del sistema host
  - Puerto: 9100 (interno)

### Herramientas de Administración
- **Portainer**: Interfaz web para Docker
  - URL: http://servidor:9000

### Automatización y Mantenimiento
- **Watchtower**: Auto-actualización de contenedores
  - Se ejecuta automáticamente cada hora

### Sistemas de Seguridad
- **Fail2ban**: Protección contra ataques de fuerza bruta
  - Monitorea SSH, Nginx y otros servicios

### Backups
- **Sistema de Backup Automático**: Backups diarios de bases de datos y volúmenes
  - Se ejecuta diariamente a las 2:00 AM
  - Mantiene backups de los últimos 7 días

## Despliegue Rápido

Para desplegar toda la infraestructura de una vez:

```bash
cd infra
./deploy-infra.sh start    # Iniciar todos los servicios
./deploy-infra.sh stop     # Detener todos los servicios
./deploy-infra.sh restart  # Reiniciar todos los servicios
```

## Despliegue Manual

Cada servicio se levanta de forma independiente:

```bash
# Proxy y balanceo
cd infra/proxy && docker compose up -d

# Monitorización completa
cd infra/monitorizacion/prometheus && docker compose up -d
cd infra/monitorizacion/grafana && docker compose up -d
cd infra/monitorizacion/node-exporter && docker compose up -d

# Administración
cd infra/portainer && docker compose up -d

# Mantenimiento
cd infra/watchtower && docker compose up -d

# Seguridad
cd infra/seguridad/fail2ban && docker compose up -d

# Backups
cd infra/backups && docker compose up -d
```

## Configuración Inicial

### Nginx Proxy Manager
1. Accede a http://servidor:81
2. Cambia la contraseña por defecto
3. Configura dominios y SSL para los servicios de empresas

### Grafana
1. Accede a http://servidor:3000
2. Usuario: admin, Contraseña: admin123
3. Agrega Prometheus como fuente de datos: http://prometheus_global:9090
4. Importa dashboards preconfigurados (Docker, Node Exporter)

### Portainer
1. Accede a http://servidor:9000
2. Configura el endpoint local de Docker
3. Gestiona contenedores, imágenes y volúmenes

## Red de Infraestructura

Todos los servicios comparten la red `infra_net` para comunicarse entre sí de forma segura y aislada de las redes de empresas.

## Logs y Monitoreo

- Logs de contenedores: `docker logs <container_name>`
- Métricas del sistema: Prometheus + Grafana
- Logs de backup: `/var/log/backup.log`
- Logs de seguridad: `docker logs fail2ban_global`
