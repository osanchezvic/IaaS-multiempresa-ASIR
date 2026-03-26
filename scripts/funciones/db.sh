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

# Crear usuario admin en BD infra (para panel)
crear_usuario_admin() {
    local empresa="$1"
    local admin_user="$2"
    local admin_pass="$3"
    
    # Generar hash bcrypt con php (si disponible) o usar openssl para simple hash
    # Para bcrypt, usar php si está instalado, sino fallback a md5
    local hash_pass
    if command -v php >/dev/null 2>&1; then
        hash_pass=$(php -r "echo password_hash('$admin_pass', PASSWORD_BCRYPT);")
    else
        hash_pass=$(echo -n "$admin_pass" | openssl dgst -md5 | cut -d' ' -f2)
    fi
    
    # Insertar en BD infra_users_db
    mysql -h localhost -P 3307 -u users_user -pusers_pass users_db -e "
        INSERT INTO usuarios (empresa, usuario, hash_password, rol) 
        VALUES ('$empresa', '$admin_user', '$hash_pass', 'admin') 
        ON DUPLICATE KEY UPDATE hash_password='$hash_pass';
    " 2>/dev/null || log_warn "No se pudo insertar usuario admin en BD infra (BD no disponible?)"
}

export -f registro_empresa registro_servicio obtener_puerto servicio_existe listar_servicios crear_usuario_admin
