#!/bin/bash

# 1. Recoger parámetros
EMPRESA=$1
SERVICIO=$2

if [ -z "$EMPRESA" ] || [ -z "$SERVICIO" ]; then
    echo "Uso: $0 <empresa> <servicio>"
    exit 1
fi

# 2. Definir rutas (usando rutas absolutas para mayor seguridad)
BASE_DIR="/srv/$EMPRESA"
SERVICIO_DIR="$BASE_DIR/$SERVICIO"
# Asumimos que 'catalogo' está en el mismo nivel que el script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CATALOGO_DIR="$SCRIPT_DIR/catalogo/$SERVICIO"

if [ ! -d "$CATALOGO_DIR" ]; then
    echo "Error: El catálogo para el servicio '$SERVICIO' no existe en $CATALOGO_DIR"
    exit 1
fi

mkdir -p "$SERVICIO_DIR"

# 3. Generar valores dinámicos
PUERTO=$(shuf -i 8000-8999 -n 1)
DB_NAME="${EMPRESA}_db"
DB_USER="${EMPRESA}_user"
DB_PASSWORD=$(openssl rand -hex 8)
ADMIN_USER="admin"
ADMIN_PASSWORD=$(openssl rand -hex 8)

# 4 y 5. Procesar plantillas (Corregido el delimitador y la expansión)
# Usamos '|' como delimitador de sed por si las variables contienen '/'
sed -e "s|{{EMPRESA}}|$EMPRESA|g" \
    -e "s|{{PUERTO}}|$PUERTO|g" \
    -e "s|{{RUTA_DATOS}}|$BASE_DIR|g" \
    -e "s|{{DB_NAME}}|$DB_NAME|g" \
    -e "s|{{DB_USER}}|$DB_USER|g" \
    -e "s|{{DB_PASSWORD}}|$DB_PASSWORD|g" \
    "$CATALOGO_DIR/docker-compose.tpl" > "$SERVICIO_DIR/docker-compose.yml"

sed -e "s|{{DB_NAME}}|$DB_NAME|g" \
    -e "s|{{DB_USER}}|$DB_USER|g" \
    -e "s|{{DB_PASSWORD}}|$DB_PASSWORD|g" \
    -e "s|{{ADMIN_USER}}|$ADMIN_USER|g" \
    -e "s|{{ADMIN_PASSWORD}}|$ADMIN_PASSWORD|g" \
    "$CATALOGO_DIR/env.tpl" > "$SERVICIO_DIR/.env"

# 6. Crear red si no existe
docker network inspect "${EMPRESA}_net" >/dev/null 2>&1 || \
    docker network create "${EMPRESA}_net"

# 7. Levantar el servicio
cd "$SERVICIO_DIR" || exit
docker compose up -d

echo "------------------------------------------------"
echo "Servicio $SERVICIO desplegado con éxito"
echo "Empresa: $EMPRESA"
echo "Puerto: $PUERTO"
echo "Admin User: $ADMIN_USER"
echo "Admin Pass: $ADMIN_PASSWORD"
echo "------------------------------------------------"
