#!/bin/bash

# =========================================
# CLEANUP.SH - Limpiar backups antiguos
# =========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

cleanup_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$BACKUP_LOG"
}

echo "[INFO] Limpiando backups más antiguos de $RETENTION_DAYS días..."

if [ ! -d "$BACKUP_BASE_DIR" ]; then
    echo "[WARN] No hay directorio de backups"
    exit 0
fi

# Contador
DELETED=0
FREED_SIZE=0

# Encontrar y eliminar backups antiguos
find "$BACKUP_BASE_DIR" -name "backup_*.tar.gz" -type f | while read backup_file; do
    # Obtener fecha del archivo
    FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "$backup_file")) / 86400 ))
    
    if [ "$FILE_AGE" -gt "$RETENTION_DAYS" ]; then
        SIZE=$(stat -c %s "$backup_file")
        echo "  Eliminando: $(basename $backup_file) ($FILE_AGE días)"
        rm -f "$backup_file"
        ((DELETED++))
        ((FREED_SIZE += SIZE))
    fi
done

# Convertir bytes a MB
FREED_MB=$((FREED_SIZE / 1024 / 1024))

echo "[OK] Limpieza completada"
echo "  Archivos eliminados: $DELETED"
echo "  Espacio liberado: ${FREED_MB}MB"

cleanup_log "Cleanup: eliminados $DELETED backups, liberados ${FREED_MB}MB"
