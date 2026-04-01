#!/usr/bin/env bash
# ==============================================================================
# installers/editors.sh — Editors & IDEs Category
# ==============================================================================
# Code editors with settings for development.
#
# Category: editors
# Display:  📝 Editors and IDEs
#
# Tools (2):
#   vscode            — Visual Studio Code (.deb download)
#   vscode_settings   — VS Code Settings (settings.json deployment)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ==============================================================================
# Tool: vscode
# ==============================================================================

# Description for Visual Studio Code
editors__vscode__description() {
    echo "Visual Studio Code — lightweight but powerful source code editor"
}

# Check if VS Code is installed
editors__vscode__is_installed() {
    is_command_available "code"
}

# Install VS Code via .deb download (preferred over snap for file access)
editors__vscode__install() {
    log_info "Installing Visual Studio Code..."

    # Check if already installed
    if is_command_available "code"; then
        log_success "VS Code is already installed"
        return 0
    fi

    local tmp_deb="${TEMP_DIR}/vscode.deb"

    # ---- Step 1: Download VS Code .deb ----
    log_info "Downloading VS Code .deb package..."
    if ! download_file \
        "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
        "$tmp_deb"; then
        log_error "Failed to download VS Code .deb"
        return 1
    fi

    # ---- Step 2: Install .deb package ----
    log_info "Installing VS Code .deb package..."
    if ! run_sudo dpkg -i "$tmp_deb"; then
        log_info "Fixing broken dependencies..."
        run_sudo apt-get install -f -y || {
            log_error "Failed to install VS Code"
            rm -f "$tmp_deb"
            return 1
        }
    fi

    # ---- Step 3: Cleanup ----
    rm -f "$tmp_deb"

    # Verify installation
    if is_command_available "code"; then
        log_success "Visual Studio Code installed successfully"
        return 0
    else
        log_error "VS Code installation failed — 'code' command not found"
        return 1
    fi
}

# ==============================================================================
# Tool: vscode_settings
# ==============================================================================

# Description for VS Code Settings
editors__vscode_settings__description() {
    echo "VS Code Settings — editor configuration (fonts, formatting, themes)"
}

# Check if VS Code settings.json exists
editors__vscode_settings__is_installed() {
    [ -f "${REAL_HOME}/.config/Code/User/settings.json" ]
}

# Deploy VS Code settings.json from config template
editors__vscode_settings__install() {
    log_info "Deploying VS Code settings..."

    local settings_dir="${REAL_HOME}/.config/Code/User"
    local settings_file="${settings_dir}/settings.json"
    local template="${SCRIPT_DIR}/config/vscode-settings.json"

    # Verify template exists
    if [ ! -f "$template" ]; then
        log_error "VS Code settings template not found: ${template}"
        return 1
    fi

    # ---- Step 1: Create settings directory ----
    if [ ! -d "$settings_dir" ]; then
        log_info "Creating VS Code settings directory..."
        mkdir -p "$settings_dir"
        chown -R "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/.config/Code" 2>/dev/null || true
    fi

    # ---- Step 2: Merge or copy settings ----
    if [ -f "$settings_file" ]; then
        log_info "Existing settings.json found, merging..."

        if is_command_available jq; then
            # Merge: template values override existing (template wins for conflicts)
            local merged
            merged=$(jq -s '.[0] * .[1]' "$settings_file" "$template" 2>> "$LOG_FILE")
            if [ -n "$merged" ]; then
                echo "$merged" > "${settings_file}.tmp"
                mv "${settings_file}.tmp" "$settings_file"
                log_success "Settings merged successfully"
            else
                log_warning "jq merge failed, overwriting with template"
                cp "$template" "$settings_file"
            fi
        else
            log_warning "jq not available, overwriting settings.json with template"
            cp "$template" "$settings_file"
        fi
    else
        log_info "Copying settings template to ${settings_file}..."
        cp "$template" "$settings_file"
    fi

    # ---- Step 3: Fix ownership ----
    chown "${REAL_USER}:${REAL_USER}" "$settings_file" 2>/dev/null || true

    log_success "VS Code settings deployed successfully"
    return 0
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "editors" "vscode" "Visual Studio Code"
register_tool "editors" "vscode_settings" "VS Code Settings" "true"