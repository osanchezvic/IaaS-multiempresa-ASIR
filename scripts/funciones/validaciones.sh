#!/bin/bash

# ============================================
# VALIDACIONES DE SERVICIOS Y DEPENDENCIAS
# ============================================

# Validar que servicio existe en catálogo
validar_servicio_existe() {
    local servicio="$1"
    
    local servicio_dir="$CATALOGO_DIR/$servicio"
    
    if [ ! -d "$servicio_dir" ]; then
        log_error "Servicio no existe en catálogo: $servicio"
        log_info "Servicios disponibles:"
        ls -1 "$CATALOGO_DIR" | sed 's/^/  - /'
        return 1
    fi
    
    # Validar que tiene config.yml
    if [ ! -f "$servicio_dir/config.yml" ]; then
        log_error "Falta config.yml en $servicio_dir"
        return 1
    fi
    
    return 0
}

# Obtener dependencias de servicio
obtener_dependencias() {
    local servicio="$1"
    
    local config="$CATALOGO_DIR/$servicio/config.yml"
    
    if [ ! -f "$config" ]; then
        log_error "Config no encontrada: $config"
        return 1
    fi
    
    # Parsear YAML simple (línea "dependencias:")
    grep -A 10 "^dependencias:" "$config" | grep "^  - " | sed 's/^  - //' | tr -d '\r'
}

# Validar que todas las dependencias están disponibles
validar_dependencias() {
    local servicio="$1"
    
    local deps=$(obtener_dependencias "$servicio")
    
    if [ -z "$deps" ]; then
        log_debug "No hay dependencias para $servicio"
        return 0
    fi
    
    local missing=0
    while IFS= read -r dep; do
        if [ -n "$dep" ]; then
            if ! validar_servicio_existe "$dep"; then
                log_error "Dependencia no disponible: $dep"
                ((missing++))
            fi
        fi
    done <<< "$deps"
    
    if [ $missing -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# Validar compose template
validar_compose_template() {
    local empresa="$1"
    local servicio="$2"
    local servicio_dir="/srv/$empresa/$servicio"
    
    if [ ! -f "$servicio_dir/docker-compose.yml" ]; then
        log_error "docker-compose.yml no encontrado en $servicio_dir"
        return 1
    fi
    
    # Validar con docker compose
    if ! docker compose -f "$servicio_dir/docker-compose.yml" config >/dev/null 2>&1; then
        log_error "docker-compose.yml inválido en $servicio_dir"
        docker compose -f "$servicio_dir/docker-compose.yml" config 2>&1 | grep -i error | head -5
        return 1
    fi
    
    log_debug "docker-compose.yml válido"
    return 0
}

# Validar .env template
validar_env_template() {
    local empresa="$1"
    local servicio="$2"
    local servicio_dir="/srv/$empresa/$servicio"
    
    if [ ! -f "$servicio_dir/.env" ]; then
        log_warn ".env no encontrado en $servicio_dir"
        return 0
    fi
    
    # Validar que no haya variables sin reemplazar ({{VAR}})
    if grep -q "{{" "$servicio_dir/.env"; then
        log_error ".env contiene variables sin reemplazar"
        grep "{{" "$servicio_dir/.env" | head -5 | sed 's/^/  /'
        return 1
    fi
    
    log_debug ".env válido"
    return 0
}

# Validar que empresa está en directorio correcto
validar_estructura_empresa() {
    local empresa="$1"
    local empresa_dir="/srv/$empresa"
    
    if [ ! -d "$empresa_dir" ]; then
        log_error "Directorio de empresa no existe: $empresa_dir"
        return 1
    fi
    
    # Directorio debe tener permisos adecuados
    if [ ! -w "$empresa_dir" ]; then
        log_error "Sin permisos de escritura en $empresa_dir"
        return 1
    fi
    
    return 0
}

# Validar redes Docker
validar_red_docker() {
    local empresa="$1"
    local red="${empresa}_net"
    
    if ! docker network inspect "$red" >/dev/null 2>&1; then
        log_warn "Red Docker no existe: $red"
        return 1
    fi
    
    log_debug "Red Docker válida: $red"
    return 0
}

# Validar que compose con nombre especificado está corriendo
validar_servicio_corriendo() {
    local empresa="$1"
    local servicio="$2"
    local container_name="${empresa}_${servicio}"
    
    if ! docker ps -a --filter "name=$container_name" --format '{{.Names}}' | grep -q "$container_name"; then
        log_warn "Contenedor no encontrado: $container_name"
        return 1
    fi
    
    if ! docker ps --filter "name=$container_name" --format '{{.Names}}' | grep -q "$container_name"; then
        log_warn "Contenedor no está corriendo: $container_name"
        return 1
    fi
    
    log_debug "Servicio corriendo: $container_name"
    return 0
}

# Validar permisos de archivo critico
validar_permisos() {
    local archivo="$1"
    local expected_perms="$2"  # e.g., "600"
    
    if [ ! -f "$archivo" ]; then
        log_error "Archivo no existe: $archivo"
        return 1
    fi
    
    local current_perms=$(stat -f "%OLp" "$archivo" 2>/dev/null || stat -c "%a" "$archivo" 2>/dev/null)
    
    if [ "$current_perms" != "$expected_perms" ]; then
        log_warn "Permisos incorrectos en $archivo: $current_perms (esperado $expected_perms)"
        chmod "$expected_perms" "$archivo"
        log_info "Permisos corregidos"
    fi
    
    return 0
}

# Validación completa antes de deploy
validar_pre_deploy() {
    local empresa="$1"
    local servicio="$2"
    
    log_info "Ejecutando validaciones pre-deploy..."
    
    # Validar nombres
    validar_nombre "$empresa" "empresa" || return 1
    validar_nombre "$servicio" "servicio" || return 1
    
    # Validar catalogo
    validar_servicio_existe "$servicio" || return 1
    validar_dependencias "$servicio" || return 1
    
    # Validar estructura
    validar_estructura_empresa "$empresa" || return 1
    
    log_success "Validaciones pre-deploy completadas"
    return 0
}

# Validación post-deploy
validar_post_deploy() {
    local empresa="$1"
    local servicio="$2"
    
    log_info "Ejecutando validaciones post-deploy..."
    
    validar_compose_template "$empresa" "$servicio" || return 1
    validar_env_template "$empresa" "$servicio" || return 1
    
    sleep 2  # Esperar a que contenedor inicie
    
    validar_servicio_corriendo "$empresa" "$servicio" || return 1
    
    log_success "Validaciones post-deploy completadas"
    return 0
}

export -f validar_servicio_existe obtener_dependencias validar_dependencias \
         validar_compose_template validar_env_template validar_estructura_empresa \
         validar_red_docker validar_servicio_corriendo validar_permisos \
         validar_pre_deploy validar_post_deploy
