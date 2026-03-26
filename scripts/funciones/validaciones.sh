#!/bin/bash

# =========================================
# VALIDACIONES BÁSICAS
# =========================================

# Validar servicio en catálogo
validar_servicio() {
    local servicio="$1"
    
    if [ ! -d "$CATALOGO_DIR/$servicio" ]; then
        echo_error "Servicio no existe: $servicio"
        echo_info "Disponibles: $(ls $CATALOGO_DIR)"
        return 1
    fi
    
    if [ ! -f "$CATALOGO_DIR/$servicio/config.yml" ]; then
        echo_error "Falta config.yml en $servicio"
        return 1
    fi
    
    return 0
}

