# Plataforma SaaS Multiempresa (ASIR)

Plataforma de gestión SaaS automatizada y segura diseñada para orquestar servicios basados en Docker en entornos multiempresa. El sistema permite el despliegue centralizado, la configuración, y la gestión de acceso basada en roles (RBAC) para múltiples inquilinos.

## Arquitectura y Seguridad
El sistema se ha reforzado para cumplir con estándares profesionales de seguridad y gestión de infraestructuras:

- **RBAC (Control de Acceso basado en Roles):** Integración de base de datos MariaDB para gestionar usuarios, empresas (tenants) y permisos de administrador.
- **Seguridad en Capas:**
  - **Authelia:** Implementación de autenticación de dos factores (2FA) y control de acceso.
  - **Hardening:** Uso de archivos `.env` para secretos, CSRF tokens en el dashboard, y escaneo de vulnerabilidades mediante **Trivy**.
  - **Proxy Inverso:** Nginx Proxy Manager gestionando el tráfico y certificados SSL.
- **API-driven Infrastructure:** Servicio de API (FastAPI) para automatizar el ciclo de vida de despliegue mediante peticiones seguras.
- **Monitorización:** Stack completo con Prometheus, Grafana y Loki.

## Estructura del Proyecto

```text
/
├── catalogo/        # Definiciones de servicios (templates docker-compose)
├── infra/           # Infraestructura global (proxy, api, authelia, monitorización)
├── scripts/         # Lógica central de orquestación
│   ├── funciones/   # Módulos bash reutilizables
│   └── deploy.sh    # Script principal con pre-flight security scan
├── docs/            # Documentación técnica y guía de defensa
└── README.md        # Este archivo
```

## Características Principales

1. **RBAC y Gestión Multiempresa:** Diferenciación entre administradores globales y administradores de empresa (tenants) mediante base de datos relacional.
2. **API de Despliegue:** API segura para disparar el despliegue (`POST /deploy/<company>/<service>`) reemplazando ejecuciones manuales.
3. **Escaneo de Vulnerabilidades (Trivy):** Paso de seguridad obligatorio integrado en `deploy.sh` que aborta despliegues con vulnerabilidades críticas.
4. **Despliegue Automatizado:** Resolución de dependencias entre contenedores, aislamiento de redes y gestión dinámica de puertos.
5. **Backups Automáticos:** Protección de datos integrada antes de operaciones destructivas.

## Uso

### Despliegue de Servicios
El despliegue se puede realizar mediante CLI o a través del nuevo Panel de Administración que interactúa con la API interna.

```bash
./scripts/deploy.sh <empresa> <servicio>
```

### Gestión de Servicios
| Comando | Descripción |
| :--- | :--- |
| `./scripts/deploy.sh` | Despliega servicio (con pre-flight scan de Trivy). |
| `./scripts/list.sh` | Lista servicios desplegados por empresa. |
| `./scripts/get-credentials.sh` | Recupera credenciales seguras (formato JSON). |
| `./scripts/destroy.sh` | Elimina servicios con backup previo. |

## Seguridad
- **Secretos:** Nunca almacenar contraseñas en el código fuente. Utilizar variables de entorno en el archivo `.env`.
- **RBAC:** La base de datos `users_db` controla el acceso. Asegurar que las contraseñas están correctamente hasheadas (bcrypt).
- **API:** El token de la API (`API_TOKEN`) debe mantenerse privado y rotado periódicamente.

## Requisitos
- Docker Engine 20+
- Docker Compose v2
- Trivy (para escaneo de imágenes)
- MariaDB
