#!/usr/bin/env bash
# ==============================================================================
# lib/core.sh — Core Utilities
# ==============================================================================
# Color constants, logging functions, OS detection, path helpers,
# and common utility functions used throughout the installer.
# ==============================================================================

# ------------------------------------------------------------------------------
# Path Constants
# ------------------------------------------------------------------------------

# Resolve the root directory of the project (where install.sh lives)
# Only set if not already defined (install.sh sets this first)
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Temporary directory for downloads and intermediate files
TEMP_DIR="/tmp/dev-tool-installer-tmp"
mkdir -p "$TEMP_DIR"

# ------------------------------------------------------------------------------
# Log File
# ------------------------------------------------------------------------------

LOG_FILE="/tmp/dev-tool-installer-$(date +%Y%m%d-%H%M%S).log"

# ------------------------------------------------------------------------------
# Color Constants
# ------------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------------------------------------------------------
# APT Update Flag
# ------------------------------------------------------------------------------

APT_UPDATED=false

# ------------------------------------------------------------------------------
# Counters for installation summary
# ------------------------------------------------------------------------------

INSTALL_SUCCESS=0
INSTALL_FAILED=0
INSTALL_SKIPPED=0
INSTALL_TOTAL=0

# Arrays to track results
# Note: Do NOT use "declare -a" here — when this file is sourced inside a
# function (e.g. source_libraries()), "declare" creates a LOCAL variable
# that is destroyed when the function returns, causing "unbound variable"
# errors under set -u.  Plain assignment creates a GLOBAL variable.
FAILED_TOOLS=()
SUCCESS_TOOLS=()
SKIPPED_TOOLS=()

# ------------------------------------------------------------------------------
# Real User Detection (for sudo context)
# ------------------------------------------------------------------------------

# When running with sudo, $USER becomes root but we need the real user
# for user-space operations (VS Code, fonts, dotfiles, etc.)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~${REAL_USER}")

# ------------------------------------------------------------------------------
# Logging Functions
# ------------------------------------------------------------------------------

# Log informational message to stdout and log file
log_info() {
    local msg="[INFO]    $(date +%H:%M:%S) $*"
    echo -e "${BLUE}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

# Log success message to stdout and log file
log_success() {
    local msg="[SUCCESS] $(date +%H:%M:%S) $*"
    echo -e "${GREEN}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

# Log warning message to stdout and log file
log_warning() {
    local msg="[WARN]    $(date +%H:%M:%S) $*"
    echo -e "${YELLOW}${msg}${RESET}"
    echo "$msg" >> "$LOG_FILE"
}

# Log error message to stderr and log file
log_error() {
    local msg="[ERROR]   $(date +%H:%M:%S) $*"
    echo -e "${RED}${msg}${RESET}" >&2
    echo "$msg" >> "$LOG_FILE"
}

# Log debug message to log file only (not shown on screen)
log_debug() {
    local msg="[DEBUG]   $(date +%H:%M:%S) $*"
    echo "$msg" >> "$LOG_FILE"
}

# ------------------------------------------------------------------------------
# Command Execution
# ------------------------------------------------------------------------------

# Run a command with logging; output goes to log file
# Usage: run_cmd <description> <command> [args...]
run_cmd() {
    local description="$1"
    shift

    log_debug "Running: $*"
    log_info "$description"

    if "$@" >> "$LOG_FILE" 2>&1; then
        log_debug "Command succeeded: $*"
        return 0
    else
        local exit_code=$?
        log_error "Command failed (exit $exit_code): $*"
        return $exit_code
    fi
}

# ------------------------------------------------------------------------------
# Detection Helpers
# ------------------------------------------------------------------------------

# Check if a command is available in PATH
# Usage: is_command_available <command_name>
is_command_available() {
    command -v "$1" &>/dev/null
}

# Check if a package is installed via dpkg
# Usage: is_package_installed <package_name>
is_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Check if a snap package is installed
# Usage: is_snap_installed <snap_name>
is_snap_installed() {
    local snap_name="$1"
    # Fast path: check snap binary directly (avoids slow "snap list" query)
    if [ -x "/snap/bin/${snap_name}" ]; then
        return 0
    fi
    # Fallback: binary name may differ from snap name
    snap list "$snap_name" &>/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# OS Detection
# ------------------------------------------------------------------------------

# Get Ubuntu version number (e.g., "24.04")
get_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Get Ubuntu codename (e.g., "noble", "jammy")
get_ubuntu_codename() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "${VERSION_CODENAME:-unknown}"
    else
        echo "unknown"
    fi
}

# Get distro ID (e.g., "ubuntu", "debian")
get_distro_id() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Check if running on Ubuntu
is_ubuntu() {
    [ "$(get_distro_id)" = "ubuntu" ]
}

# ------------------------------------------------------------------------------
# APT Helpers
# ------------------------------------------------------------------------------

# Run apt update if not already done in this session
# Uses APT_UPDATED flag to avoid redundant updates
ensure_apt_updated() {
    if [ "$APT_UPDATED" = false ]; then
        log_info "Updating apt package lists..."
        if sudo apt-get update >> "$LOG_FILE" 2>&1; then
            APT_UPDATED=true
            log_success "apt package lists updated"
        else
            log_warning "apt update had warnings (continuing anyway)"
            APT_UPDATED=true
        fi
    else
        log_debug "apt already updated in this session, skipping"
    fi
}

# ------------------------------------------------------------------------------
# Download Helpers
# ------------------------------------------------------------------------------

# Download a file with retry support and timeout
# Usage: download_file <url> <destination> [max_retries] [timeout_secs]
download_file() {
    local url="$1"
    local dest="$2"
    local max_retries="${3:-3}"
    local dl_timeout="${4:-300}"  # 5 minutes default timeout per attempt
    local attempt=1

    while [ "$attempt" -le "$max_retries" ]; do
        log_debug "Download attempt $attempt/$max_retries (timeout: ${dl_timeout}s): $url"

        if is_command_available curl; then
            if curl -fsSL --connect-timeout 30 --max-time "$dl_timeout" -o "$dest" "$url" 2>> "$LOG_FILE"; then
                log_debug "Download succeeded: $url"
                return 0
            fi
        elif is_command_available wget; then
            if wget -q --connect-timeout=30 --timeout="$dl_timeout" -O "$dest" "$url" 2>> "$LOG_FILE"; then
                log_debug "Download succeeded: $url"
                return 0
            fi
        else
            log_error "Neither curl nor wget is available for download"
            return 1
        fi

        log_warning "Download failed (attempt $attempt/$max_retries): $url"
        attempt=$((attempt + 1))
        sleep 2
    done

    log_error "Download failed after $max_retries attempts: $url"
    return 1
}

# ------------------------------------------------------------------------------
# APT Repository Helpers
# ------------------------------------------------------------------------------

# Add a GPG key and APT repository
# Usage: add_apt_repository_key <key_url> <keyring_path> <repo_line> <list_file>
# Example:
#   add_apt_repository_key \
#       "https://packages.microsoft.com/keys/microsoft.asc" \
#       "/usr/share/keyrings/microsoft.gpg" \
#       "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
#       "/etc/apt/sources.list.d/vscode.list"
add_apt_repository_key() {
    local key_url="$1"
    local keyring_path="$2"
    local repo_line="$3"
    local list_file="$4"

    # Skip if repository already configured
    if [ -f "$list_file" ]; then
        log_debug "APT repository already exists: $list_file"
        return 0
    fi

    log_info "Adding APT repository key from: $key_url"

    # Download and dearmor GPG key
    if ! curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring_path" 2>> "$LOG_FILE"; then
        log_error "Failed to add GPG key: $key_url"
        return 1
    fi

    # Add repository
    echo "$repo_line" | sudo tee "$list_file" > /dev/null

    # Force apt update since we added a new repo
    APT_UPDATED=false
    ensure_apt_updated

    return 0
}

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------

# Clean up temporary files and resources
cleanup() {
    log_debug "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Error handler for trap
error_handler() {
    local line="$1"
    log_error "Unexpected error on line $line"
}