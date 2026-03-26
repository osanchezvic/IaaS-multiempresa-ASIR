#!/bin/bash

# =========================================
# LOGGING SIMPLE (COLOREADO)
# =========================================

echo_info() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
}

echo_error() {
    echo -e "${COLOR_RED}✗ ERROR:${COLOR_RESET} $*" >&2
}

echo_warn() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"
}

echo_debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        echo "[DEBUG] $*"
    fi
}

export -f echo_info echo_error echo_warn echo_debug
