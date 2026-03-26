#!/bin/bash

# ============================================
# UTILIDADES GENÉRICAS
# ============================================

# Validar nombre válido (empresa, servicio)
validar_nombre() {
    local nombre="$1"
    local tipo="${2:-generic}"  # generic, empresa, servicio
    
    # No vacío
    if [ -z "$nombre" ]; then
        log_error "Nombre no puede estar vacío"
        return 1
    fi
    
    # Solo alfanuméricos y guiones (sin espacios, sin caracteres especiales)
    if ! [[ "$nombre" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Nombre inválido: '$nombre'. Solo alfanuméricos, guiones y guiones bajos permitidos"
        return 1
    fi
    
    # Longitud
    if [ ${#nombre} -lt 2 ] || [ ${#nombre} -gt 30 ]; then
        log_error "Nombre debe tener entre 2 y 30 caracteres"
        return 1
    fi
    
    return 0
}

# Confirmar acción (interactive)
confirmar() {
    local prompt="$1"
    local default="${2:-n}"  # y o n
    
    if [ "$FORCE_MODE" -eq 1 ]; then
        return 0  # Si FORCE_MODE, no pedir confirmación
    fi
    
    local response
    if [ "$default" = "y" ]; then
        read -p "$prompt (Y/n): " response
        [ -z "$response" ] && response="y"
    else
        read -p "$prompt (y/N): " response
        [ -z "$response" ] && response="n"
    fi
    
    case "$response" in
        [yY]) return 0 ;;
        [nN]) return 1 ;;
        *) confirmar "$prompt" "$default" ;;
    esac
}

# Esperar a que contenedor esté healthy
wait_container_healthy() {
    local container_name="$1"
    local timeout="${2:-60}"
    local start_time=$(date +%s)
    
    log_info "Esperando a que $container_name esté healthy..."
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            log_error "Timeout esperando a $container_name (${timeout}s)"
            return 1
        fi
        
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
        
        case "$health" in
            healthy)
                log_success "$container_name está healthy"
                return 0
                ;;
            unhealthy)
                log_error "$container_name está unhealthy"
                return 1
                ;;
            starting)
                log_debug "$container_name iniciando..."
                sleep 2
                ;;
            "")
                # Sin healthcheck, asumir está listo después de 5s
                if [ $elapsed -gt 5 ]; then
                    log_info "$container_name no tiene healthcheck, dando por iniciado"
                    return 0
                fi
                sleep 2
                ;;
        esac
    done
}

# Crear backup antes de operación
crear_backup() {
    local empresa="$1"
    local servicio="$2"
    local source_dir="$3"
    
    if [ "$BACKUP_ENABLED" -ne 1 ]; then
        log_debug "Backups deshabilitados"
        return 0
    fi
    
    local backup_dir="/srv/backups/${empresa}/${servicio}"
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/snapshot_$timestamp.tar.gz"
    
    log_info "Creando backup: $backup_file"
    
    if tar -czf "$backup_file" -C "$source_dir" . 2>/dev/null; then
        log_success "Backup creado: $backup_file"
        echo "$backup_file"
        return 0
    else
        log_error "Error creando backup"
        return 1
    fi
}

# Generar contraseña aleatoria
generar_password() {
    local length="${1:-16}"
    openssl rand -hex "$((length / 2))" | cut -c1-$length
}

# Generar token único
generar_token() {
    local length="${1:-32}"
    openssl rand -hex $((length / 2))
}

# Guardar credenciales de forma segura
guardar_credenciales() {
    local empresa="$1"
    local servicio="$2"
    local credenciales_json="$3"  # JSON string
    
    local cred_file="$CREDENTIALS_DIR/${empresa}.${servicio}.json"
    mkdir -p "$CREDENTIALS_DIR"
    
    # Guardar y permisos restrictivos
    echo "$credenciales_json" > "$cred_file"
    chmod "$CREDENTIAL_PERMS" "$cred_file"
    
    log_debug "Credenciales guardadas: $cred_file"
    echo "$cred_file"
}

# Leer credenciales de forma segura
leer_credenciales() {
    local empresa="$1"
    local servicio="$2"
    
    local cred_file="$CREDENTIALS_DIR/${empresa}.${servicio}.json"
    
    if [ ! -f "$cred_file" ]; then
        log_error "Archivo de credenciales no encontrado: $cred_file"
        return 1
    fi
    
    cat "$cred_file"
}

# Extraer valor de credenciales
extraer_credencial() {
    local empresa="$1"
    local servicio="$2"
    local clave="$3"
    
    local cred=$(leer_credenciales "$empresa" "$servicio" 2>/dev/null)
    [ $? -ne 0 ] && return 1
    
    echo "$cred" | jq -r ".\"$clave\" // empty"
}

# Spinner animado
spinner() {
    local message="$1"
    local pid=$!
    local delay=0.1
    local spinner=('|' '/' '-' '\')
    
    while kill -0 $pid 2>/dev/null; do
        for i in "${spinner[@]}"; do
            echo -ne "\r$i $message"
            sleep $delay
        done
    done
    
    echo -ne "\r✓ $message\n"
}

# Hacer spinnerconfiable con job control
run_with_spinner() {
    local message="$1"
    shift
    
    ("$@") &
    local pid=$!
    
    local spinner=('|' '/' '-' '\')
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${spinner[$((i % 4))]} $message"
        ((i++))
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -ne "\r✓ $message\n"
    else
        echo -ne "\r✗ $message\n"
    fi
    
    return $exit_code
}

export -f validar_nombre confirmar wait_container_healthy crear_backup \
         generar_password generar_token guardar_credenciales leer_credenciales \
         extraer_credencial run_with_spinner
