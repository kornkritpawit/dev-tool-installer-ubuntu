#!/usr/bin/env bash
# ==============================================================================
# installers/dotnet.sh — .NET Development Category
# ==============================================================================
# .NET SDK for C# development.
#
# Category: dotnet
# Display:  🟣 .NET Development
#
# Tools (1):
#   dotnet_sdk — .NET SDK (latest LTS via official install script)
#
# Install Strategy:
#   Primary:  Microsoft's official dotnet-install.sh script (--channel LTS)
#   Fallback: Add Microsoft APT repository and apt install dotnet-sdk-8.0
#
# Notes:
#   - Script installs to ~/.dotnet by default (no sudo needed)
#   - DOTNET_ROOT and PATH are added to .bashrc for persistence
# ==============================================================================

# ==============================================================================
# Tool: dotnet_sdk
# ==============================================================================

# Description for .NET SDK
dotnet__dotnet_sdk__description() {
    echo ".NET SDK (latest LTS) for C# development"
}

# Check if dotnet is available in PATH or in ~/.dotnet
dotnet__dotnet_sdk__is_installed() {
    # Check standard PATH first
    if is_command_available "dotnet"; then
        return 0
    fi
    # Check common script-install location
    if [ -x "$HOME/.dotnet/dotnet" ]; then
        return 0
    fi
    return 1
}

# Install .NET SDK using official install script, with APT fallback
dotnet__dotnet_sdk__install() {
    log_info "Installing .NET SDK (latest LTS)..."

    # Primary: Microsoft's official dotnet-install.sh script
    if _dotnet_install_via_script; then
        _dotnet_configure_path
        return 0
    fi

    # Fallback: APT repository method
    log_warning "Script install failed, trying APT repository fallback..."
    if _dotnet_install_via_apt; then
        return 0
    fi

    log_error "Failed to install .NET SDK"
    return 1
}

# ------------------------------------------------------------------------------
# Internal: Install .NET SDK via official script
# ------------------------------------------------------------------------------

_dotnet_install_via_script() {
    local install_script="$TEMP_DIR/dotnet-install.sh"

    # Download the official install script
    log_info "Downloading .NET install script..."
    if ! download_file "https://dot.net/v1/dotnet-install.sh" "$install_script"; then
        log_error "Failed to download dotnet-install.sh"
        return 1
    fi

    chmod +x "$install_script"

    # Run the install script for LTS channel (timeout: 300s / 5 minutes)
    log_info "Running dotnet-install.sh --channel LTS (timeout: 300s)..."
    if timeout 300 "$install_script" --channel LTS >> "$LOG_FILE" 2>&1; then
        log_success ".NET SDK installed via official script"

        # Verify installation
        if [ -x "$HOME/.dotnet/dotnet" ]; then
            local sdk_version
            sdk_version=$("$HOME/.dotnet/dotnet" --version 2>/dev/null)
            log_success ".NET SDK version: ${sdk_version}"
            return 0
        fi
    fi

    log_error "dotnet-install.sh script execution failed"
    return 1
}

# ------------------------------------------------------------------------------
# Internal: Install .NET SDK via Microsoft APT repository
# ------------------------------------------------------------------------------

_dotnet_install_via_apt() {
    local codename
    codename="$(get_ubuntu_codename)"

    log_info "Adding Microsoft APT repository for .NET..."

    # Add Microsoft package signing key and repository
    if ! add_apt_repository_key \
        "https://packages.microsoft.com/keys/microsoft.asc" \
        "/usr/share/keyrings/microsoft-prod.gpg" \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${codename}/prod ${codename} main" \
        "/etc/apt/sources.list.d/microsoft-prod.list"; then
        log_error "Failed to add Microsoft APT repository"
        return 1
    fi

    ensure_apt_updated

    # Install .NET SDK 8.0 (current LTS)
    log_info "Installing dotnet-sdk-8.0 via apt..."
    if run_sudo apt-get install -y dotnet-sdk-8.0; then
        log_success ".NET SDK 8.0 installed via APT"
        return 0
    fi

    log_error "Failed to install .NET SDK via APT"
    return 1
}

# ------------------------------------------------------------------------------
# Internal: Configure DOTNET_ROOT and PATH in .bashrc
# ------------------------------------------------------------------------------

_dotnet_configure_path() {
    local dotnet_root="$HOME/.dotnet"
    local bashrc="$HOME/.bashrc"

    # Export for current session
    export DOTNET_ROOT="$dotnet_root"
    if [[ ":$PATH:" != *":$dotnet_root:"* ]]; then
        export PATH="$PATH:$dotnet_root:$dotnet_root/tools"
    fi

    # Add to .bashrc if not already present
    if [ -f "$bashrc" ]; then
        if ! grep -q 'DOTNET_ROOT' "$bashrc" 2>/dev/null; then
            log_info "Adding DOTNET_ROOT and PATH to .bashrc..."
            cat >> "$bashrc" << 'EOF'

# Added by Dev Tool Installer — .NET SDK
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
EOF
            log_info "DOTNET_ROOT configured in .bashrc"
        else
            log_debug "DOTNET_ROOT already configured in .bashrc"
        fi
    fi
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "dotnet" "dotnet_sdk" ".NET SDK (latest LTS)"