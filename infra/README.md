# Infraestructura Global

Este directorio contiene la configuración y los scripts para desplegar y gestionar la infraestructura base que soporta la plataforma SaaS Multiempresa.

## Servicios Incluidos
La infraestructura está diseñada como una arquitectura robusta y segura:

- **Authelia:** Servicio de autenticación y 2FA.
- **Nginx Proxy Manager:** Gestión de rutas y certificados.
- **Portainer:** Administración de contenedores.
- **Monitorización:** Prometheus, Grafana, Loki (agregación de logs) y Node Exporter.
- **Seguridad:** Fail2Ban (protección contra fuerza bruta) y Trivy (escaneo de imágenes).
- **API service:** Interfaz para el despliegue automático de servicios.
- **Redis:** Almacenamiento de sesiones.
- **Watchtower:** Actualizaciones automáticas.

## Estructura
```text
infra/
├── .env                  # Variables de entorno
├── docker-compose.yml    # Definición de la infraestructura global
├── deploy-infra.sh       # Script de gestión de la infra
├── api/                  # Servicio FastAPI de orquestación
├── authelia/             # Configuración de Authelia
├── proxy/                # Nginx Proxy Manager y BD
└── ... (Monitorización, seguridad)
```

## Despliegue y Gestión

1. **Configuración Inicial:**
   Copiar y configurar las variables de entorno necesarias:
   ```bash
   cp .env.example .env
   # Asegúrate de configurar contraseñas robustas para:
   # API_TOKEN, GRAFANA_ADMIN_PASSWORD, DB_PASSWORDS
   ```

2. **Ejecución:**
   ```bash
   ./deploy-infra.sh [start|stop|restart]
   ```

## Integraciones Clave

- **API de Despliegue:** Ubicada en `/api`, expone endpoints protegidos por token para automatizar tareas desde el dashboard.
- **Authelia & Proxy:** La infraestructura de proxy está configurada para realizar *Forward Auth* contra Authelia, asegurando el acceso a servicios críticos.
- **Base de Datos:** Se utilizan instancias MariaDB aisladas para el proxy y para la gestión de usuarios (users-db).

## Seguridad
La infraestructura utiliza las mejores prácticas (Hardening) eliminando hardcoded credentials del `docker-compose.yml`, implementando escaneos automáticos de seguridad con Trivy y asegurando el acceso administrativo mediante Authelia.
