#!/bin/bash

# Script para desplegar toda la infraestructura global
# Uso: ./deploy-infra.sh [start|stop|restart]

ACTION=${1:-start}
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

SERVICES=(
    "portainer"
    "monitorizacion/node-exporter"
    "monitorizacion/prometheus"
    "monitorizacion/grafana"
    "proxy"
    "watchtower"
    "seguridad/fail2ban"
    "backups"
)

echo "=== DESPLIEGUE DE INFRAESTRUCTURA ==="
echo "Acción: $ACTION"
echo "Directorio base: $BASE_DIR"
echo

for service in "${SERVICES[@]}"; do
    service_path="$BASE_DIR/$service"

    if [ -d "$service_path" ] && [ -f "$service_path/docker-compose.yml" ]; then
        echo "Procesando: $service"

        cd "$service_path" || continue

        case $ACTION in
            start)
                docker compose up -d
                ;;
            stop)
                docker compose down
                ;;
            restart)
                docker compose restart
                ;;
            *)
                echo "Acción no válida. Use: start|stop|restart"
                exit 1
                ;;
        esac

        echo "✓ $service completado"
        echo
    else
        echo "⚠ Saltando $service (no existe docker-compose.yml)"
    fi
done

echo "=== INFRAESTRUCTURA $ACTION COMPLETADA ==="
echo
echo "Servicios disponibles:"
echo "- Portainer: http://localhost:9000"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000 (admin/admin123)"
echo "- Nginx Proxy Manager: http://localhost:81 (admin@example.com/changeme)"
echo
echo "Para verificar estado: docker ps | grep global"