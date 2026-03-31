#!/usr/bin/env bash
# ==============================================================================
# Dev Tool Installer — Ubuntu Desktop
# ==============================================================================
# Main entry point for the Dev Tool Installer.
# Sets up a complete development environment on Ubuntu Desktop via whiptail TUI.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# Requirements:
#   - Ubuntu Desktop 22.04+ or 24.04+
#   - bash 4.0+
#   - whiptail (auto-installed if missing)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

readonly INSTALLER_VERSION="1.0.0"
readonly INSTALLER_NAME="Dev Tool Installer"
readonly MIN_BASH_VERSION=4

# ==============================================================================
# Resolve Script Directory
# ==============================================================================

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

# Check bash version (need 4+ for associative arrays)
check_bash_version() {
    if [ "${BASH_VERSINFO[0]}" -lt "$MIN_BASH_VERSION" ]; then
        echo "ERROR: bash ${MIN_BASH_VERSION}+ is required (current: ${BASH_VERSION})"
        exit 1
    fi
}

# Check if running on Ubuntu
check_ubuntu() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        if [ "${ID:-}" != "ubuntu" ]; then
            echo "WARNING: This script is designed for Ubuntu. Detected: ${ID:-unknown}"
            echo "Press Enter to continue anyway, or Ctrl+C to abort..."
            read -r
        fi
    else
        echo "WARNING: Cannot detect OS. /etc/os-release not found."
        echo "Press Enter to continue anyway, or Ctrl+C to abort..."
        read -r
    fi
}

# Ensure whiptail is available (install if missing)
ensure_whiptail() {
    if ! command -v whiptail &>/dev/null; then
        echo "whiptail not found. Installing..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq whiptail
        if ! command -v whiptail &>/dev/null; then
            echo "ERROR: Failed to install whiptail. Cannot proceed."
            exit 1
        fi
        echo "whiptail installed successfully."
    fi
}

# ==============================================================================
# Source Library Files
# ==============================================================================

# Source order matters: core → sudo-helper → registry → tui
source_libraries() {
    local lib_dir="${SCRIPT_DIR}/lib"

    # Core utilities (logging, colors, helpers) — must be first
    # shellcheck source=lib/core.sh
    source "${lib_dir}/core.sh"

    # Privilege management
    # shellcheck source=lib/sudo-helper.sh
    source "${lib_dir}/sudo-helper.sh"

    # Tool registry (categories, tools metadata)
    # shellcheck source=lib/registry.sh
    source "${lib_dir}/registry.sh"

    # TUI functions (whiptail wrappers)
    # shellcheck source=lib/tui.sh
    source "${lib_dir}/tui.sh"
}

# ==============================================================================
# Signal Handlers
# ==============================================================================

# Handle Ctrl+C gracefully
handle_interrupt() {
    echo ""
    echo "Installation interrupted by user (Ctrl+C)."

    # Stop sudo keep-alive if running
    stop_sudo_keeper 2>/dev/null || true

    # Clean up temp files
    cleanup 2>/dev/null || true

    # Reset terminal in case whiptail left it in a bad state
    reset 2>/dev/null || true

    echo "Log file: ${LOG_FILE:-/tmp/dev-tool-installer-*.log}"
    exit 130
}

# Handle script exit (normal or error)
handle_exit() {
    local exit_code=$?

    # Stop sudo keep-alive
    stop_sudo_keeper 2>/dev/null || true

    # Clean up temp files
    cleanup 2>/dev/null || true

    if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
        log_error "Script exited with code: $exit_code" 2>/dev/null || true
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    # Pre-flight checks (before sourcing libs, so no deps on them)
    check_bash_version
    check_ubuntu
    ensure_whiptail

    # Source all library files
    source_libraries

    # Set up signal handlers
    trap handle_interrupt INT
    trap handle_exit EXIT
    trap 'error_handler $LINENO' ERR

    # Initialize logging
    log_info "Starting ${INSTALLER_NAME} v${INSTALLER_VERSION}"
    log_info "OS: Ubuntu $(get_ubuntu_version) ($(get_ubuntu_codename))"
    log_info "User: $(whoami)"
    log_info "Script directory: ${SCRIPT_DIR}"
    log_info "Log file: ${LOG_FILE}"

    # Request sudo access upfront
    ensure_sudo

    # Initialize tool registry (sources all installer modules)
    registry_init

    log_info "Registered ${#TOOLS[@]} tool(s) in ${#CATEGORIES[@]} categories"

    # Run the TUI flow
    tui_main_flow

    # Final log
    log_info "${INSTALLER_NAME} completed"
    log_info "Succeeded: ${INSTALL_SUCCESS} | Failed: ${INSTALL_FAILED} | Skipped: ${INSTALL_SKIPPED}"
}

# Run main
main "$@"