#!/bin/bash

# =========================================
# RESTORE.SH - Restaurar desde backup
# =========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

# Validar parámetros
if [ $# -lt 2 ]; then
    echo "Uso: $0 <empresa> <servicio> [fecha]"
    echo "Ej:  $0 acme wordpress                    (último backup)"
    echo "Ej:  $0 acme wordpress 20260326_120000    (backup específico)"
    exit 1
fi

EMPRESA="$1"
SERVICIO="$2"
FECHA="${3:-}"
CONTAINER="${EMPRESA}_${SERVICIO}_1"

# Buscar backup
if [ -n "$FECHA" ]; then
    # Backup específico por fecha
    BACKUP_FILE="$BACKUP_BASE_DIR/$EMPRESA/$SERVICIO/backup_${FECHA}.tar.gz"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "[ERROR] Backup no encontrado: $BACKUP_FILE"
        exit 1
    fi
else
    # Último backup (más reciente)
    BACKUP_FILE=$(ls -t "$BACKUP_BASE_DIR/$EMPRESA/$SERVICIO"/backup_*.tar.gz 2>/dev/null | head -1)
    if [ -z "$BACKUP_FILE" ]; then
        echo "[ERROR] Sin backups disponibles para $EMPRESA/$SERVICIO"
        exit 1
    fi
fi

echo "[INFO] Restaurando desde: $(basename $BACKUP_FILE)"

# Verificar contenedor
if ! docker ps -a | grep -q "$CONTAINER"; then
    echo "[ERROR] Contenedor no encontrado: $CONTAINER"
    exit 1
fi

# Detener contenedor
echo "[INFO] Deteniendo contenedor..."
docker stop "$CONTAINER" 2>/dev/null || true
sleep 2

# Extraer backup a volúmenes
TEMP_DIR="/tmp/restore_${EMPRESA}_${SERVICIO}"
mkdir -p "$TEMP_DIR"

echo "[INFO] Extrayendo datos..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" || true

# Restaurar a volúmenes (requiere permisos)
if docker inspect "$CONTAINER" >/dev/null 2>&1; then
    # Usar docker cp para restaurar seguro
    for item in "$TEMP_DIR"/*; do
        if [ -d "$item" ]; then
            docker cp "$item/." "$CONTAINER:/tmp/restore/" 2>/dev/null || true
        fi
    done
fi

# Limpiar temp
rm -rf "$TEMP_DIR"

# Reiniciar contenedor
echo "[INFO] Reiniciando contenedor..."
docker start "$CONTAINER" 2>/dev/null || true
sleep 5

# Verificar estado
if docker ps | grep -q "$CONTAINER"; then
    echo "[OK] Restauracion completada y contenedor activo"
else
    echo "[WARN] Restauracion completada pero contenedor no esta activo"
fi
