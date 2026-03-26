#!/bin/bash

# ============================================
# GESTIÓN ROBUSTA DE PUERTOS
# ============================================

# Validar si puerto está en uso en el sistema
_puerto_en_uso_sistema() {
    local puerto="$1"
    
    # Intentar con lsof primero (más directo)
    if command -v lsof &> /dev/null; then
        lsof -Pi :"$puerto" >/dev/null 2>&1 && return 0
    fi
    
    # Fallback a netstat
    if command -v netstat &> /dev/null; then
        netstat -tuln 2>/dev/null | grep -q ":$puerto " && return 0
    fi
    
    # Sin herramientas, intentar conexión
    timeout 1 bash -c "</dev/tcp/localhost/$puerto" 2>/dev/null && return 0
    
    return 1
}

# Generar puerto aleatorio dentro de rango
_generar_puerto_candidato() {
    local min="$1"
    local max="$2"
    
    local RANDOM=$(($(date +%s) % 32768))
    echo $(( RANDOM % (max - min + 1) + min ))
}

# Buscar puerto disponible
_find_available_port() {
    local min="$1"
    local max="$2"
    local intentos=0
    local max_intentos=50

    while [ $intentos -lt $max_intentos ]; do
        local puerto=$(_generar_puerto_candidato "$min" "$max")
        
        # Verificar que no está en DB
        if ! db_puerto_disponible "$puerto"; then
            log_debug "Puerto $puerto en DB, buscando otro..."
            ((intentos++))
            continue
        fi
        
        # Verificar que no está en uso en sistema
        if _puerto_en_uso_sistema "$puerto"; then
            log_debug "Puerto $puerto en uso en sistema, buscando otro..."
            ((intentos++))
            continue
        fi
        
        # Puerto disponible
        log_debug "Puerto disponible encontrado: $puerto"
        echo "$puerto"
        return 0
    done

    log_error "No se encontró puerto disponible después de $max_intentos intentos"
    return 1
}

# Asignar puerto para empresa/servicio
asignar_puerto() {
    local empresa="$1"
    local servicio="$2"
    local env="${3:-dev}"  # dev o prod
    
    # Obtener rango según entorno
    local puerto_min="$PUERTO_MIN_DEV"
    local puerto_max="$PUERTO_MAX_DEV"
    
    if [ "$env" = "prod" ]; then
        puerto_min="$PUERTO_MIN_PROD"
        puerto_max="$PUERTO_MAX_PROD"
    fi
    
    log_debug "Buscando puerto para $empresa/$servicio en rango $puerto_min-$puerto_max"
    
    # Buscar puerto disponible
    local puerto=$(_find_available_port "$puerto_min" "$puerto_max")
    [ -z "$puerto" ] && return 1
    
    # Registrar en DB
    if db_register_puerto "$puerto" "$empresa" "$servicio"; then
        echo "$puerto"
        log_info "Puerto asignado: $puerto para $empresa/$servicio"
        return 0
    else
        log_error "Error registrando puerto $puerto en DB"
        return 1
    fi
}

# Validar puerto ya asignado
validar_puerto_asignado() {
    local puerto="$1"
    local empresa="$2"
    local servicio="$3"
    
    # Verificar que está en DB asignado a esta empresa/servicio
    local puerto_db=$(jq -r ".\"$puerto\" // empty" "$PUERTOS_DB" 2>/dev/null)
    
    if [ -z "$puerto_db" ]; then
        log_error "Puerto $puerto no está registrado"
        return 1
    fi
    
    local emp_db=$(echo "$puerto_db" | jq -r '.empresa')
    local serv_db=$(echo "$puerto_db" | jq -r '.servicio')
    
    if [ "$emp_db" != "$empresa" ] || [ "$serv_db" != "$servicio" ]; then
        log_error "Puerto $puerto no pertenece a $empresa/$servicio"
        return 1
    fi
    
    return 0
}

# Liberar puerto (al destruir servicio)
liberar_puerto_servicio() {
    local empresa="$1"
    local servicio="$2"
    
    # Obtener puerto de DB
    local puerto=$(db_get_puerto "$empresa" "$servicio")
    
    if [ -z "$puerto" ]; then
        log_warn "Puerto no encontrado para $empresa/$servicio"
        return 1
    fi
    
    # Validar que sigue asignado a este servicio
    if validar_puerto_asignado "$puerto" "$empresa" "$servicio"; then
        db_liberar_puerto "$puerto"
        log_info "Puerto liberado: $puerto"
        return 0
    else
        return 1
    fi
}

# Listar puertos en uso
listar_puertos_en_uso() {
    local empresa="${1:-}"
    
    if [ -z "$empresa" ]; then
        # Todos los puertos
        db_export puertos | jq '.[]'
    else
        # Solo de una empresa
        db_export puertos | jq ".[] | select(.empresa == \"$empresa\")"
    fi
}

# Validar que puerto está libre en DOCKER específicamente
validar_puerto_libre_docker() {
    local puerto="$1"
    
    # Intenta conectar al puerto
    timeout 1 bash -c "</dev/tcp/localhost/$puerto" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_error "Puerto $puerto ocupado en Docker/localhost"
        return 1
    fi
    
    # Verifica también en proceso Docker
    docker ps --format "{{.Ports}}" | grep -q "$puerto" && return 1
    
    return 0
}

export -f asignar_puerto validar_puerto_asignado liberar_puerto_servicio \
         listar_puertos_en_uso validar_puerto_libre_docker
