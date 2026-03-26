#!/bin/bash

# ============================================
# GESTIÓN DE BASE DE DATOS (JSON-based)
# ============================================

# Inicializar archivos DB si no existen
_init_database_files() {
    if [ ! -f "$EMPRESAS_DB" ]; then
        echo '{}' > "$EMPRESAS_DB"
        chmod "$DB_PERMS" "$EMPRESAS_DB"
        log_debug "Inicializado: $EMPRESAS_DB"
    fi

    if [ ! -f "$SERVICIOS_DB" ]; then
        echo '{}' > "$SERVICIOS_DB"
        chmod "$DB_PERMS" "$SERVICIOS_DB"
        log_debug "Inicializado: $SERVICIOS_DB"
    fi

    if [ ! -f "$PUERTOS_DB" ]; then
        echo '{}' > "$PUERTOS_DB"
        chmod "$DB_PERMS" "$PUERTOS_DB"
        log_debug "Inicializado: $PUERTOS_DB"
    fi
}

# Registrar nueva empresa
db_register_empresa() {
    local empresa="$1"
    local metadata="${2:-}"

    _init_database_files

    if db_empresa_exists "$empresa"; then
        log_warn "Empresa ya existe: $empresa"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local json_data=$(jq --arg empresa "$empresa" \
                        --arg timestamp "$timestamp" \
                        --arg metadata "$metadata" \
                        '.[$empresa] = {
                            "created": $timestamp,
                            "metadata": $metadata,
                            "status": "active"
                        }' "$EMPRESAS_DB")
    
    echo "$json_data" > "$EMPRESAS_DB"
    log_debug "Registrada empresa: $empresa"
    return 0
}

# Verificar si empresa existe
db_empresa_exists() {
    local empresa="$1"
    [ -f "$EMPRESAS_DB" ] && jq -e ".\"$empresa\"" "$EMPRESAS_DB" >/dev/null 2>&1
    return $?
}

# Registrar servicio de empresa
db_register_servicio() {
    local empresa="$1"
    local servicio="$2"
    local puerto="$3"
    local credenciales="${4:-}"

    _init_database_files

    if ! db_empresa_exists "$empresa"; then
        log_error "Empresa no existe: $empresa"
        return 1
    fi

    if db_servicio_exists "$empresa" "$servicio"; then
        log_warn "Servicio ya existe: $empresa/$servicio"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local json_data=$(jq --arg key "${empresa}:${servicio}" \
                        --arg empresa "$empresa" \
                        --arg servicio "$servicio" \
                        --arg puerto "$puerto" \
                        --arg timestamp "$timestamp" \
                        --arg credenciales "$credenciales" \
                        '.[$key] = {
                            "empresa": $empresa,
                            "servicio": $servicio,
                            "puerto": $puerto,
                            "status": "running",
                            "credenciales_file": $credenciales,
                            "created": $timestamp
                        }' "$SERVICIOS_DB")
    
    echo "$json_data" > "$SERVICIOS_DB"
    log_debug "Registrado servicio: $empresa/$servicio en puerto $puerto"
    return 0
}

# Verificar si servicio existe
db_servicio_exists() {
    local empresa="$1"
    local servicio="$2"
    [ -f "$SERVICIOS_DB" ] && jq -e ".\"${empresa}:${servicio}\"" "$SERVICIOS_DB" >/dev/null 2>&1
    return $?
}

# Obtener puerto de un servicio
db_get_puerto() {
    local empresa="$1"
    local servicio="$2"
    
    [ -f "$SERVICIOS_DB" ] || return 1
    jq -r ".\"${empresa}:${servicio}\".puerto // empty" "$SERVICIOS_DB"
}

# Desregistrar servicio
db_unregister_servicio() {
    local empresa="$1"
    local servicio="$2"

    if ! db_servicio_exists "$empresa" "$servicio"; then
        log_warn "Servicio no existe: $empresa/$servicio"
        return 1
    fi

    local json_data=$(jq "del(.\"${empresa}:${servicio}\")" "$SERVICIOS_DB")
    echo "$json_data" > "$SERVICIOS_DB"
    log_debug "Desregistrado servicio: $empresa/$servicio"
    return 0
}

# Listar servicios de empresa
db_list_servicios_by_empresa() {
    local empresa="$1"
    
    [ -f "$SERVICIOS_DB" ] || echo "[]" && return 0
    jq "[.[] | select(.empresa == \"$empresa\")]" "$SERVICIOS_DB"
}

# Listar todas las empresas
db_list_empresas() {
    [ -f "$EMPRESAS_DB" ] || echo "{}" && return 0
    jq 'keys' "$EMPRESAS_DB"
}

# Listar todos los servicios
db_list_all_servicios() {
    [ -f "$SERVICIOS_DB" ] || echo "[]" && return 0
    jq '.[]' "$SERVICIOS_DB"
}

# Obtener credenciales de servicio
db_get_credenciales_file() {
    local empresa="$1"
    local servicio="$2"
    
    [ -f "$SERVICIOS_DB" ] || return 1
    jq -r ".\"${empresa}:${servicio}\".credenciales_file // empty" "$SERVICIOS_DB"
}

# Verificar disponibilidad de puerto en DB
db_puerto_disponible() {
    local puerto="$1"
    
    [ -f "$PUERTOS_DB" ] || return 0
    # Puerto no existe en la DB = disponible
    ! jq -e ".\"$puerto\"" "$PUERTOS_DB" >/dev/null 2>&1
    return $?
}

# Registrar puerto asignado
db_register_puerto() {
    local puerto="$1"
    local empresa="$2"
    local servicio="$3"

    _init_database_files

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local json_data=$(jq --arg puerto "$puerto" \
                        --arg empresa "$empresa" \
                        --arg servicio "$servicio" \
                        --arg timestamp "$timestamp" \
                        ".\"$puerto\" = {
                            \"empresa\": $empresa,
                            \"servicio\": $servicio,
                            \"assigned_at\": $timestamp
                        }" "$PUERTOS_DB")
    
    echo "$json_data" > "$PUERTOS_DB"
    log_debug "Puerto registrado: $puerto para $empresa/$servicio"
    return 0
}

# Liberar puerto
db_liberar_puerto() {
    local puerto="$1"

    [ -f "$PUERTOS_DB" ] || return 0

    local json_data=$(jq "del(.\"$puerto\")" "$PUERTOS_DB")
    echo "$json_data" > "$PUERTOS_DB"
    log_debug "Puerto liberado: $puerto"
    return 0
}

# Exportar datos (como JSON)
db_export() {
    local tipo="${1:-all}"

    case "$tipo" in
        empresas)
            cat "$EMPRESAS_DB"
            ;;
        servicios)
            cat "$SERVICIOS_DB"
            ;;
        puertos)
            cat "$PUERTOS_DB"
            ;;
        all)
            jq -s '.[0] as $empresas | .[1] as $servicios | .[2] as $puertos | 
                    {empresas: $empresas, servicios: $servicios, puertos: $puertos}' \
                    "$EMPRESAS_DB" "$SERVICIOS_DB" "$PUERTOS_DB"
            ;;
        *)
            log_error "Tipo de export desconocido: $tipo"
            return 1
            ;;
    esac
}

_init_database_files

export -f db_register_empresa db_empresa_exists db_register_servicio db_servicio_exists \
         db_get_puerto db_unregister_servicio db_list_servicios_by_empresa db_list_empresas \
         db_list_all_servicios db_get_credenciales_file db_puerto_disponible db_register_puerto \
         db_liberar_puerto db_export
