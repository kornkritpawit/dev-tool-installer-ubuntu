#!/usr/bin/env bash
# ==============================================================================
# installers/editors.sh — Editors & IDEs Category
# ==============================================================================
# Code editors with extensions and settings for development.
#
# Category: editors
# Display:  📝 Editors and IDEs
#
# Tools (3):
#   vscode            — Visual Studio Code (.deb download)
#   vscode_extensions — VS Code Extensions (33 extensions)
#   vscode_settings   — VS Code Settings (settings.json deployment)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ==============================================================================
# VS Code Extensions List
# ==============================================================================

VSCODE_EXTENSIONS=(
    # .NET — runtime must be installed first (dependency of csharp & csdevkit)
    "ms-dotnettools.vscode-dotnet-runtime"
    "ms-dotnettools.csharp"
    "ms-dotnettools.csdevkit"
    # Python
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.debugpy"
    "ms-python.black-formatter"
    "ms-python.isort"
    "charliermarsh.ruff"
    "ms-vscode.vscode-typescript-next"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "bradlc.vscode-tailwindcss"
    "formulahendry.auto-rename-tag"
    "christian-kohler.path-intellisense"
    "pkief.material-icon-theme"
    "github.copilot"
    "github.copilot-chat"
    "ModelHarbor.modelharbor-agent"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-azuretools.vscode-docker"
    "humao.rest-client"
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "gruntfuggly.todo-tree"
    "streetsidesoftware.code-spell-checker"
    "yzhang.markdown-all-in-one"
    "redhat.vscode-yaml"
    "tamasfe.even-better-toml"
    "mechatroner.rainbow-csv"
    "ms-vscode.hexeditor"
    "shardulm94.trailing-spaces"
)

# ==============================================================================
# Helper: Build environment prefix for su -c commands
# ==============================================================================
# VS Code (Electron) needs DISPLAY, DBUS, XDG vars to function correctly.
# When using "su - USER -c ..." these vars are lost because it creates a
# fresh login shell. This helper preserves them.

_build_vscode_env_prefix() {
    local prefix=""
    [ -n "${DISPLAY:-}" ] && prefix+="DISPLAY='${DISPLAY}' "
    [ -n "${WAYLAND_DISPLAY:-}" ] && prefix+="WAYLAND_DISPLAY='${WAYLAND_DISPLAY}' "
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && prefix+="DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS}' "
    [ -n "${XDG_RUNTIME_DIR:-}" ] && prefix+="XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR}' "
    echo "$prefix"
}

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
# Tool: vscode_extensions
# ==============================================================================

# Description for VS Code Extensions
editors__vscode_extensions__description() {
    echo "VS Code Extensions — 33 essential development extensions"
}

# Check if VS Code extensions are installed (at least 20 of 33)
editors__vscode_extensions__is_installed() {
    # VS Code must be installed first
    if ! is_command_available "code"; then
        return 1
    fi

    # Build env prefix — su - loses DISPLAY/DBUS/XDG vars needed by Electron
    local env_prefix
    env_prefix=$(_build_vscode_env_prefix)

    # Get installed extensions count (run as real user with env vars)
    local installed_count
    installed_count=$(su - "$REAL_USER" -c "${env_prefix}code --list-extensions" 2>/dev/null | wc -l)

    # Consider "installed" if at least 20 extensions are present
    [ "${installed_count:-0}" -ge 20 ]
}

# Install VS Code extensions
editors__vscode_extensions__install() {
    local total=${#VSCODE_EXTENSIONS[@]}
    local ext_timeout=180  # 3 minutes per extension (dotnet extensions are large)

    log_info "Installing VS Code extensions (${total} extensions, timeout: ${ext_timeout}s each)..."

    # VS Code must be available
    if ! is_command_available "code"; then
        log_error "VS Code is not installed. Install VS Code first."
        return 1
    fi

    # ---- Build environment prefix for su -c ----
    # su - creates a fresh login shell that loses DISPLAY, DBUS, XDG vars.
    # VS Code (Electron) needs these to function correctly.
    local env_prefix
    env_prefix=$(_build_vscode_env_prefix)

    # ---- Pre-check: VS Code CLI works under su - context ----
    log_info "Verifying VS Code CLI works under user '${REAL_USER}'..."
    if ! su - "$REAL_USER" -c "${env_prefix}timeout 15 code --version" >> "$LOG_FILE" 2>&1; then
        log_error "VS Code CLI not functional under user '${REAL_USER}'."
        log_error "This may be caused by missing environment variables or VS Code not in PATH."
        log_error "Try running: su - ${REAL_USER} -c 'code --version'"
        return 1
    fi

    # ---- Pre-check: VS Code Marketplace reachable ----
    log_info "Checking VS Code Marketplace connectivity..."
    if ! timeout 15 curl -fsSL --head "https://marketplace.visualstudio.com" > /dev/null 2>&1; then
        log_warning "Cannot reach VS Code Marketplace. Extensions may fail to install."
        log_warning "Check network connectivity or proxy settings."
        # Continue anyway — some extensions might be cached or available
    fi

    local success_count=0
    local fail_count=0
    local timeout_count=0
    local current=0
    local failed_extensions=()

    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        current=$((current + 1))
        log_info "[${current}/${total}] Installing ${ext}... (timeout: ${ext_timeout}s)"

        # NOTE: timeout MUST be inside su -c so it directly controls the code
        # process. Wrapping "timeout su -c ..." only kills su, leaving code
        # running indefinitely as an orphan process.
        # env_prefix passes DISPLAY/DBUS/XDG vars that su - would otherwise lose.
        if su - "$REAL_USER" -c "${env_prefix}timeout ${ext_timeout} code --install-extension '${ext}' --force" >> "$LOG_FILE" 2>&1; then
            success_count=$((success_count + 1))
            log_success "[${current}/${total}] ✓ ${ext}"
        else
            local exit_code=$?
            if [ "$exit_code" -eq 124 ]; then
                # timeout command returns 124 when it kills the process
                timeout_count=$((timeout_count + 1))
                log_warning "[${current}/${total}] ⏰ TIMEOUT: ${ext} (exceeded ${ext_timeout}s, skipping)"
            else
                fail_count=$((fail_count + 1))
                log_warning "[${current}/${total}] ✗ Failed: ${ext} (exit code: ${exit_code})"
            fi
            failed_extensions+=("$ext")
        fi
    done

    # ---- Retry failed extensions once ----
    if [ ${#failed_extensions[@]} -gt 0 ]; then
        log_info "Retrying ${#failed_extensions[@]} failed extension(s)..."
        local retry_num=0
        local retry_total=${#failed_extensions[@]}
        for ext in "${failed_extensions[@]}"; do
            retry_num=$((retry_num + 1))
            log_info "[Retry ${retry_num}/${retry_total}] ${ext}..."

            if su - "$REAL_USER" -c "${env_prefix}timeout ${ext_timeout} code --install-extension '${ext}' --force" >> "$LOG_FILE" 2>&1; then
                success_count=$((success_count + 1))
                fail_count=$((fail_count > 0 ? fail_count - 1 : 0))
                log_success "[Retry] ✓ ${ext}"
            else
                log_warning "[Retry] ✗ Still failed: ${ext}"
            fi
        done
    fi

    log_success "VS Code extensions: ${success_count}/${total} installed, ${fail_count} failed, ${timeout_count} timed out"

    # Consider success if majority installed
    if [ "$success_count" -ge 20 ]; then
        return 0
    elif [ "$success_count" -gt 0 ]; then
        log_warning "Only ${success_count} of ${total} extensions installed"
        return 0
    else
        log_error "No extensions were installed"
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
register_tool "editors" "vscode_extensions" "VS Code Extensions" "true"
register_tool "editors" "vscode_settings" "VS Code Settings" "true"