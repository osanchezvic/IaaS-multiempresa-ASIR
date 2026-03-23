#!/bin/bash

# Parámetros
EMPRESA=$1
SERVICIO=$2

# Si alguno de los parámetros está vacio, exit
if [ -z "$EMPRESA" ] || [ -z "$SERVICIO" ]; then
    echo "Uso: $0 <empresa> <servicio>"
    exit 1
fi

# Creación de variables
SERVICIO_DIR="/srv/$EMPRESA/$SERVICIO"
COMPOSE_FILE="$SERVICIO_DIR/docker-compose.yml"
RED="${EMPRESA}_net"

# Si el servicio no existe, exit
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "No existe el servicio $SERVICIO para la empresa $EMPRESA"
    exit 1
fi

echo "Parando contenedores."
sleep 0.3
clear
echo "Parando contenedores.."
sleep 0.3
clear
echo "Parando contenedores..."
sleep 0.3
clear

docker compose -f "$COMPOSE_FILE" down > /dev/null

echo "Eliminando carpeta de datos."
sleep 0.3
clear
echo "Eliminando carpeta de datos.."
sleep 0.3
clear
echo "Eliminando carpeta de datos..."
sleep 0.3
clear
rm -rf "$SERVICIO_DIR"

# Comprobar si la red sigue existiendo
if docker network inspect "$RED" >/dev/null 2>&1; then
    # Comprobar si la red está vacía
    NUM_CONT=$(docker network inspect "$RED" -f '{{len .Containers}}')
    if [ "$NUM_CONT" -eq 0 ]; then
        echo "Eliminando red $RED..."
        docker network rm "$RED"
    else
        echo "La red $RED no está vacía, no se elimina."
    fi
fi

echo "El servicio $SERVICIO de la empresa $EMPRESA ha sido eliminado correctamente."

