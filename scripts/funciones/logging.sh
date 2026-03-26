#!/bin/bash

# ============================================
# SISTEMA DE LOGGING ESTRUCTURADO
# ============================================

# Asegurar directorio de logs existe
mkdir -p "$LOGS_DIR" 2>/dev/null

# Obtener timestamp
_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Obtener nivel de log
_log_level_number() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *)     echo 1 ;;
    esac
}

# Log a archivo
_log_to_file() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(timestamp)] [$level] $message" >> "$LOG_FILE" 2>/dev/null
}

# Log a stdout
_log_to_stdout() {
    local level="$1"
    shift
    local message="$*"
    local color=""
    local reset="\033[0m"

    case "$level" in
        DEBUG) color="\033[0;36m" ;;  # Cyan
        INFO)  color="\033[0;32m" ;;  # Green
        WARN)  color="\033[0;33m" ;;  # Yellow
        ERROR) color="\033[0;31m" ;;  # Red
    esac

    if [ -t 1 ]; then  # Si es terminal
        echo -e "${color}[$(timestamp)] [$level]${reset} $message"
    else
        echo "[$(timestamp)] [$level] $message"
    fi
}

# Función centralizada de log
_log() {
    local level="$1"
    shift
    local message="$*"

    # Parsear LOG_LEVEL configurado
    local configured_level=$(_log_level_number "$LOG_LEVEL")
    local message_level=$(_log_level_number "$level")

    # Solo loguear si el nivel es >= configurado
    if [ "$message_level" -ge "$configured_level" ]; then
        _log_to_stdout "$level" "$message"
        _log_to_file "$level" "$message"
    fi
}

# Alias públicos
log_debug() { _log "DEBUG" "$@"; }
log_info()  { _log "INFO" "$@"; }
log_warn()  { _log "WARN" "$@"; }
log_error() { _log "ERROR" "$@"; }

# Timestamp en formato legible
timestamp() { _timestamp; }

# Log con contexto de empresa/servicio
log_context() {
    local empresa="$1"
    local servicio="$2"
    local level="$3"
    shift 3
    local message="$*"
    _log "$level" "[$empresa:$servicio] $message"
}

# Inicializar log para operación
init_log() {
    local empresa="$1"
    local servicio="$2"
    local operation="$3"
    
    export LOG_FILE="$LOGS_DIR/${empresa}_${servicio}_${operation}_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$(dirname "$LOG_FILE")"
    log_info "=== INICIANDO: $operation para $empresa/$servicio ==="
}

# Banner de éxito
log_success() {
    local message="$1"
    log_info "✓ $message"
}

# Banner de error
log_failed() {
    local message="$1"
    log_error "✗ $message"
    if [ ! -z "$LOG_FILE" ]; then
        log_error "Ver logs en: $LOG_FILE"
    fi
}

export -f log_debug log_info log_warn log_error timestamp init_log log_context log_success log_failed
