#!/usr/bin/env bash
# ==============================================================================
# lib/sudo-helper.sh — Privilege Management
# ==============================================================================
# Handles sudo credential caching, keep-alive background process,
# and privilege-related helper functions.
# ==============================================================================

# PID of the sudo keep-alive background process
SUDO_KEEPALIVE_PID=""

# ------------------------------------------------------------------------------
# Sudo Management
# ------------------------------------------------------------------------------

# Ensure sudo access is available
# If not root, prompts for password once and starts keep-alive loop
ensure_sudo() {
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root. Recommend running as normal user (sudo will be used when needed)"
        return 0
    fi

    log_info "Requesting sudo access..."

    # Prompt for sudo password once
    if ! sudo -v; then
        log_error "sudo authentication failed. Cannot proceed without sudo access."
        exit 1
    fi

    log_success "sudo access granted"

    # Start background keep-alive process
    keep_sudo_alive
}

# Background loop that renews sudo timestamp every 50 seconds
# This prevents sudo from timing out during long installations
keep_sudo_alive() {
    # Don't start if running as root
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    # Don't start multiple keep-alive processes
    if [ -n "$SUDO_KEEPALIVE_PID" ] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        log_debug "sudo keep-alive already running (PID: $SUDO_KEEPALIVE_PID)"
        return 0
    fi

    (
        while true; do
            sudo -n true 2>/dev/null
            sleep 50
            # Exit if parent process is gone
            kill -0 "$$" 2>/dev/null || exit 0
        done
    ) &
    SUDO_KEEPALIVE_PID=$!

    log_debug "sudo keep-alive started (PID: $SUDO_KEEPALIVE_PID)"
}

# Stop the sudo keep-alive background process
stop_sudo_keeper() {
    if [ -n "$SUDO_KEEPALIVE_PID" ]; then
        if kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
            kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
            wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
            log_debug "sudo keep-alive stopped (PID: $SUDO_KEEPALIVE_PID)"
        fi
        SUDO_KEEPALIVE_PID=""
    fi
}

# Run a command with sudo, with logging
# Usage: run_sudo <command> [args...]
run_sudo() {
    log_debug "Running with sudo: $*"

    if sudo "$@" >> "$LOG_FILE" 2>&1; then
        return 0
    else
        local exit_code=$?
        log_error "sudo command failed (exit $exit_code): $*"
        return $exit_code
    fi
}