# Infraestructura
Esta carpeta contiene los **servicios globales** de la plataforma. Son componentes que se despliegan una sola vez en el servidor y dan soporte a todas las empresas, pero no pertenecen a ninguna en concreto.

## Contenido

- Servicios de red y proxy (Traefik, Nginx Proxy Manager).
- Monitorización global (Prometheus, Grafana, Node Exporter).
- Herramientas de administración (Portainer global).
- Sistemas de seguridad (Fail2ban, Crowdsec).
- Automatización y mantenimiento (Watchtower, backups).
- Cualquier servicio compartido por todo el sistema.

## Uso

Cada subcarpeta contiene su propio `docker-compose.yml` y configuración.  
Los servicios se levantan de forma independiente:

```bash
docker compose up -d
```

Estos servicios no dependen de ninguna empresa y permanecen activos aunque no haya despliegues en curso.
