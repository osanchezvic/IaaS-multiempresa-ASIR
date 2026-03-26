#!/bin/bash

# =========================================
# FUNCIONES BÁSICAS DE BASE DE DATOS (TXT)
# =========================================

# Registrar empresa (si no existe)
registro_empresa() {
    local empresa="$1"
    
    mkdir -p "$DB_DIR"
    
    if grep -q "^$empresa$" "$DB_DIR/empresas.txt" 2>/dev/null; then
        return 0
    fi
    
    echo "$empresa" >> "$DB_DIR/empresas.txt"
}

# Registrar servicio
# Formato: empresa:servicio:puerto:status
registro_servicio() {
    local empresa="$1"
    local servicio="$2"
    local puerto="$3"
    
    mkdir -p "$DB_DIR"
    
    if grep -q "^$empresa:$servicio:" "$DB_DIR/servicios.txt" 2>/dev/null; then
        return 0
    fi
    
    echo "$empresa:$servicio:$puerto:running" >> "$DB_DIR/servicios.txt"
}

# Obtener puerto de servicio
obtener_puerto() {
    local empresa="$1"
    local servicio="$2"
    
    grep "^$empresa:$servicio:" "$DB_DIR/servicios.txt" 2>/dev/null | cut -d: -f3
}

# Comprobar si servicio existe
servicio_existe() {
    local empresa="$1"
    local servicio="$2"
    
    grep -q "^$empresa:$servicio:" "$DB_DIR/servicios.txt" 2>/dev/null
}

# Listar servicios
listar_servicios() {
    local empresa="${1:-}"
    
    if [ -z "$empresa" ]; then
        cat "$DB_DIR/servicios.txt" 2>/dev/null | column -t -s:
    else
        grep "^$empresa:" "$DB_DIR/servicios.txt" 2>/dev/null | column -t -s:
    fi
}

export -f registro_empresa registro_servicio obtener_puerto servicio_existe listar_servicios
