#!/bin/bash

# =========================================
# ASIGNACIÓN SIMPLE DE PUERTOS
# =========================================

# Asignar puerto libre (búsqueda simple)
asignar_puerto() {
    local empresa="$1"
    local servicio="$2"
    
    # Buscar puerto libre en rango (8000-8999)
    for puerto in $(seq "$PUERTO_MIN" "$PUERTO_MAX"); do
        
        # ¿Está en uso en el sistema? (con lsof)
        if lsof -i ":$puerto" >/dev/null 2>&1; then
            continue  # Ocupado, siguiente
        fi
        
        # ¿Está registrado en DB?
        if grep -q ":$puerto:" "$DB_DIR/servicios.txt" 2>/dev/null; then
            continue  # Asignado, siguiente
        fi
        
        # Puerto libre!
        echo "$puerto"
        return 0
    done
    
    echo "ERROR: No hay puertos libres en rango $PUERTO_MIN-$PUERTO_MAX" >&2
    return 1
}

export -f asignar_puerto
