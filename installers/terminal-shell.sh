#!/usr/bin/env bash
# ==============================================================================
# installers/terminal-shell.sh — Terminal & Shell Category
# ==============================================================================
# Shell customization, fonts, and terminal configuration.
#
# Category: terminal_shell
# Display:  🖥️ Terminal and Shell
#
# Tools (6):
#   oh_my_zsh        — Oh My Zsh framework for managing Zsh configuration
#   powerlevel10k    — Powerlevel10k theme for Oh My Zsh (like Oh My Posh)
#   oh_my_zsh_config — Oh My Zsh configuration (theme + plugins + PATH migration)
#   font_cascadia    — CaskaydiaCove Nerd Font (Cascadia Code patched with icons)
#   font_thsarabun   — TH Sarabun PSK font (bundled)
#   gnome_terminal   — GNOME Terminal configuration (font, colors, scrollback)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ------------------------------------------------------------------------------
# fc-list cache — avoid running fc-list multiple times (expensive syscall)
# ------------------------------------------------------------------------------
_FC_LIST_CACHE=""

_get_fc_list() {
    if [ -z "$_FC_LIST_CACHE" ]; then
        _FC_LIST_CACHE=$(fc-list 2>/dev/null)
    fi
    echo "$_FC_LIST_CACHE"
}

# ==============================================================================
# Tool: oh_my_zsh
# ==============================================================================

# Description for Oh My Zsh
terminal_shell__oh_my_zsh__description() {
    echo "Oh My Zsh — framework for managing Zsh configuration"
}

# Check if Oh My Zsh is installed
terminal_shell__oh_my_zsh__is_installed() {
    [ -d "${REAL_HOME}/.oh-my-zsh" ]
}

# Install Oh My Zsh with popular plugins
terminal_shell__oh_my_zsh__install() {
    log_info "Installing Oh My Zsh..."

    # ---- Step 1: Install zsh if not present ----
    if ! is_command_available "zsh"; then
        log_info "Installing zsh..."
        ensure_apt_updated
        if ! run_sudo apt-get install -y zsh >> "$LOG_FILE" 2>&1; then
            log_error "Failed to install zsh"
            return 1
        fi
        log_success "zsh installed"
    fi

    # ---- Step 2: Install Oh My Zsh via official script ----
    log_info "Running Oh My Zsh install script (timeout: 120s)..."
    if timeout 120 su - "$REAL_USER" -c 'sh -c "$(curl -fsSL --connect-timeout 30 --max-time 60 https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' >> "$LOG_FILE" 2>&1; then
        log_success "Oh My Zsh installed successfully"
    else
        log_error "Oh My Zsh install script failed"
        return 1
    fi

    # ---- Step 3: Set default shell to zsh ----
    log_info "Setting default shell to zsh..."
    if run_sudo chsh -s "$(which zsh)" "$REAL_USER" >> "$LOG_FILE" 2>&1; then
        log_success "Default shell set to zsh for ${REAL_USER}"
    else
        log_warning "Could not change default shell to zsh (may require re-login)"
    fi

    # ---- Step 4: Install popular plugins ----
    local zsh_custom="${REAL_HOME}/.oh-my-zsh/custom"

    log_info "Installing zsh-autosuggestions plugin (timeout: 60s)..."
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        timeout 60 su - "$REAL_USER" -c "git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ${zsh_custom}/plugins/zsh-autosuggestions" >> "$LOG_FILE" 2>&1 || \
            log_warning "Failed to clone zsh-autosuggestions (timeout or network error)"
    else
        log_info "zsh-autosuggestions already installed"
    fi

    log_info "Installing zsh-syntax-highlighting plugin (timeout: 60s)..."
    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        timeout 60 su - "$REAL_USER" -c "git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ${zsh_custom}/plugins/zsh-syntax-highlighting" >> "$LOG_FILE" 2>&1 || \
            log_warning "Failed to clone zsh-syntax-highlighting (timeout or network error)"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi

    # Verify
    if [ -d "${REAL_HOME}/.oh-my-zsh" ]; then
        log_success "Oh My Zsh installed with plugins"
        return 0
    else
        log_error "Oh My Zsh directory not found after installation"
        return 1
    fi
}

# ==============================================================================
# Tool: powerlevel10k
# ==============================================================================

# Description for Powerlevel10k
terminal_shell__powerlevel10k__description() {
    echo "Powerlevel10k — fast, flexible Zsh theme (similar to Oh My Posh)"
}

# Check if Powerlevel10k is installed
terminal_shell__powerlevel10k__is_installed() {
    [ -d "${REAL_HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]
}

# Install Powerlevel10k theme for Oh My Zsh
terminal_shell__powerlevel10k__install() {
    log_info "Installing Powerlevel10k theme..."

    local zsh_custom="${REAL_HOME}/.oh-my-zsh/custom"
    local p10k_dir="${zsh_custom}/themes/powerlevel10k"

    # ---- Pre-check: Oh My Zsh must be installed ----
    if [ ! -d "${REAL_HOME}/.oh-my-zsh" ]; then
        log_error "Oh My Zsh not found. Install Oh My Zsh first."
        return 1
    fi

    # ---- Clone or update Powerlevel10k ----
    if [ -d "$p10k_dir" ]; then
        log_info "Powerlevel10k already cloned, pulling latest..."
        timeout 60 su - "$REAL_USER" -c "cd '${p10k_dir}' && git pull --depth 1" >> "$LOG_FILE" 2>&1 || \
            log_warning "Failed to update Powerlevel10k (continuing with existing)"
    else
        log_info "Cloning Powerlevel10k (timeout: 120s)..."
        if ! timeout 120 su - "$REAL_USER" -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '${p10k_dir}'" >> "$LOG_FILE" 2>&1; then
            log_error "Failed to clone Powerlevel10k"
            return 1
        fi
    fi

    # Verify
    if [ -d "$p10k_dir" ]; then
        log_success "Powerlevel10k theme installed"
        return 0
    else
        log_error "Powerlevel10k directory not found after installation"
        return 1
    fi
}

# ==============================================================================
# Tool: oh_my_zsh_config
# ==============================================================================

# Description for Oh My Zsh Config
terminal_shell__oh_my_zsh_config__description() {
    echo "Oh My Zsh Configuration — Powerlevel10k theme + plugins + PATH migration"
}

# Check if Oh My Zsh config is in place (theme configured in .zshrc)
terminal_shell__oh_my_zsh_config__is_installed() {
    grep -q 'ZSH_THEME=.*powerlevel10k' "${REAL_HOME}/.zshrc" 2>/dev/null
}

# Configure Oh My Zsh theme and plugins in .zshrc
terminal_shell__oh_my_zsh_config__install() {
    log_info "Configuring Oh My Zsh theme and plugins..."

    local zshrc="${REAL_HOME}/.zshrc"

    # ---- Backup .zshrc before making changes ----
    if [ -f "$zshrc" ]; then
        cp "$zshrc" "${zshrc}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
        log_info "Backed up .zshrc"
    fi

    # ---- Step 1: Verify .zshrc exists (created by Oh My Zsh installer) ----
    if [ ! -f "$zshrc" ]; then
        log_error ".zshrc not found — install Oh My Zsh first"
        return 1
    fi

    # ---- Step 2: Set theme to Powerlevel10k ----
    log_info "Setting ZSH_THEME to powerlevel10k/powerlevel10k..."
    if grep -q '^ZSH_THEME=' "$zshrc" 2>/dev/null; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
    fi
    log_success "Theme set to Powerlevel10k"

    # ---- Step 3: Configure plugins (additive — preserves user-added plugins) ----
    log_info "Configuring plugins..."
    local required_plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose kubectl)

    if grep -q '^plugins=' "$zshrc" 2>/dev/null; then
        # Read current plugins from .zshrc
        local current_plugins
        current_plugins=$(grep '^plugins=' "$zshrc" | sed 's/plugins=(\(.*\))/\1/' | xargs)

        # Add only missing plugins
        local updated_plugins="$current_plugins"
        for plugin in "${required_plugins[@]}"; do
            if ! echo " $current_plugins " | grep -qw "$plugin"; then
                updated_plugins="$updated_plugins $plugin"
            fi
        done

        # Clean up whitespace and update
        updated_plugins=$(echo "$updated_plugins" | xargs)
        sed -i "s/^plugins=.*/plugins=(${updated_plugins})/" "$zshrc"
    else
        # No plugins= line exists — add one with required plugins
        echo "plugins=(${required_plugins[*]})" >> "$zshrc"
    fi
    log_success "Plugins configured (additive — existing plugins preserved)"

    # ---- Step 4: PATH migration — add essential PATHs to .zshrc ----
    log_info "Migrating essential PATH entries to .zshrc..."

    # 4a: ~/.local/bin (Poetry, pip user installs)
    if ! grep -q '\$HOME/.local/bin' "$zshrc" 2>/dev/null; then
        log_info "Adding ~/.local/bin to .zshrc PATH..."
        cat >> "$zshrc" << 'EOF'

# Added by Dev Tool Installer — User local bin (pip, poetry)
export PATH="$HOME/.local/bin:$PATH"
EOF
        log_success "~/.local/bin added to .zshrc"
    else
        log_debug "~/.local/bin already in .zshrc"
    fi

    # 4b: NVM (Node Version Manager)
    if [ -d "${REAL_HOME}/.nvm" ] || [ -s "${REAL_HOME}/.nvm/nvm.sh" ]; then
        if ! grep -q 'NVM_DIR' "$zshrc" 2>/dev/null; then
            log_info "Adding NVM initialization to .zshrc..."
            cat >> "$zshrc" << 'EOF'

# Added by Dev Tool Installer — NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
            log_success "NVM added to .zshrc"
        else
            log_debug "NVM already in .zshrc"
        fi
    fi

    # 4c: .NET SDK (DOTNET_ROOT)
    if [ -d "${REAL_HOME}/.dotnet" ]; then
        if ! grep -q 'DOTNET_ROOT' "$zshrc" 2>/dev/null; then
            log_info "Adding DOTNET_ROOT to .zshrc..."
            cat >> "$zshrc" << 'EOF'

# Added by Dev Tool Installer — .NET SDK
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
EOF
            log_success "DOTNET_ROOT added to .zshrc"
        else
            log_debug "DOTNET_ROOT already in .zshrc"
        fi
    fi

    # ---- Step 5: Hint about bashrc migration ----
    if [ -f "${REAL_HOME}/.bashrc" ]; then
        log_info "Note: Essential PATHs have been migrated. Check .bashrc for any custom aliases you may want to copy."
    fi

    chown "${REAL_USER}:${REAL_USER}" "$zshrc" 2>/dev/null || true

    log_success "Oh My Zsh configured in .zshrc (Powerlevel10k + plugins + PATH)"
    return 0
}

# ==============================================================================
# Tool: font_cascadia
# ==============================================================================

# Description for CaskaydiaCove Nerd Font
terminal_shell__font_cascadia__description() {
    echo "CaskaydiaCove Nerd Font — Cascadia Code patched with Nerd Font icons + ligatures"
}

# Check if CaskaydiaCove Nerd Font is installed
terminal_shell__font_cascadia__is_installed() {
    _get_fc_list | grep -qi "CaskaydiaCove"
}

# Download and install CaskaydiaCove Nerd Font from GitHub releases
terminal_shell__font_cascadia__install() {
    log_info "Installing CaskaydiaCove Nerd Font..."

    local font_dir="${REAL_HOME}/.local/share/fonts"
    local font_zip="${TEMP_DIR}/CascadiaCode.zip"
    local font_extract_dir="${TEMP_DIR}/CascadiaCode"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"

    # ---- Step 1: Download font zip ----
    log_info "Downloading CascadiaCode Nerd Font (CaskaydiaCove)..."
    if ! download_file "$download_url" "$font_zip"; then
        log_error "Failed to download CaskaydiaCove Nerd Font"
        return 1
    fi

    # ---- Step 2: Extract fonts ----
    log_info "Extracting fonts..."
    mkdir -p "$font_extract_dir"
    if ! unzip -o "$font_zip" -d "$font_extract_dir" >> "$LOG_FILE" 2>&1; then
        log_error "Failed to extract CascadiaCode.zip"
        rm -f "$font_zip"
        return 1
    fi

    # ---- Step 3: Install fonts to user directory ----
    mkdir -p "$font_dir"

    # Copy only font files (ttf/otf)
    local font_count=0
    while IFS= read -r -d '' font_file; do
        cp "$font_file" "$font_dir/"
        font_count=$((font_count + 1))
    done < <(find "$font_extract_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)

    log_info "Copied ${font_count} font files to ${font_dir}"

    # ---- Step 4: Fix ownership ----
    chown -R "${REAL_USER}:${REAL_USER}" "$font_dir" 2>/dev/null || true

    # ---- Step 5: Rebuild font cache ----
    log_info "Rebuilding font cache..."
    if su - "$REAL_USER" -c "fc-cache -fv" >> "$LOG_FILE" 2>&1; then
        log_debug "Font cache rebuilt"
    else
        # Fallback to system fc-cache
        fc-cache -fv >> "$LOG_FILE" 2>&1 || true
    fi

    # ---- Step 6: Cleanup ----
    rm -rf "$font_zip" "$font_extract_dir"

    # Verify
    if fc-list 2>/dev/null | grep -qi "CaskaydiaCove"; then
        log_success "CaskaydiaCove Nerd Font installed successfully"
        return 0
    else
        log_warning "Font files installed but fc-list may need a re-login to detect"
        return 0
    fi
}

# ==============================================================================
# Tool: font_thsarabun
# ==============================================================================

# Description for TH Sarabun PSK
terminal_shell__font_thsarabun__description() {
    echo "TH Sarabun PSK — standard Thai government font"
}

# Check if TH Sarabun PSK is installed
terminal_shell__font_thsarabun__is_installed() {
    _get_fc_list | grep -qi "Sarabun"
}

# Install TH Sarabun PSK from bundled zip
terminal_shell__font_thsarabun__install() {
    log_info "Installing TH Sarabun PSK font..."

    local font_dir="${REAL_HOME}/.local/share/fonts"
    local bundled_zip="${SCRIPT_DIR}/font/THSARABUN_PSK.zip"
    local font_extract_dir="${TEMP_DIR}/THSARABUN_PSK"

    # ---- Step 1: Check bundled font exists ----
    if [ ! -f "$bundled_zip" ]; then
        log_warning "TH Sarabun PSK font not bundled at: ${bundled_zip}"
        log_warning "Please place THSARABUN_PSK.zip in the font/ directory and re-run"
        return 1
    fi

    # ---- Step 2: Extract fonts ----
    log_info "Extracting TH Sarabun PSK fonts..."
    mkdir -p "$font_extract_dir"
    if ! unzip -o "$bundled_zip" -d "$font_extract_dir" >> "$LOG_FILE" 2>&1; then
        log_error "Failed to extract THSARABUN_PSK.zip"
        return 1
    fi

    # ---- Step 3: Install fonts to user directory ----
    mkdir -p "$font_dir"

    local font_count=0
    while IFS= read -r -d '' font_file; do
        cp "$font_file" "$font_dir/"
        font_count=$((font_count + 1))
    done < <(find "$font_extract_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)

    log_info "Copied ${font_count} font files to ${font_dir}"

    # ---- Step 4: Fix ownership ----
    chown -R "${REAL_USER}:${REAL_USER}" "$font_dir" 2>/dev/null || true

    # ---- Step 5: Rebuild font cache ----
    log_info "Rebuilding font cache..."
    if su - "$REAL_USER" -c "fc-cache -fv" >> "$LOG_FILE" 2>&1; then
        log_debug "Font cache rebuilt"
    else
        fc-cache -fv >> "$LOG_FILE" 2>&1 || true
    fi

    # ---- Step 6: Cleanup ----
    rm -rf "$font_extract_dir"

    # Verify
    if fc-list 2>/dev/null | grep -qi "Sarabun"; then
        log_success "TH Sarabun PSK font installed successfully"
        return 0
    else
        log_warning "Font files installed but fc-list may need a re-login to detect"
        return 0
    fi
}

# ==============================================================================
# Tool: gnome_terminal
# ==============================================================================

# Description for GNOME Terminal Config
terminal_shell__gnome_terminal__description() {
    echo "GNOME Terminal configuration — custom font, colors, scrollback"
}

# Check if GNOME Terminal is configured with custom font
terminal_shell__gnome_terminal__is_installed() {
    # Must have GNOME Terminal and dconf available
    if ! is_command_available "gnome-terminal" || ! is_command_available "dconf"; then
        return 1
    fi

    # Get default profile ID
    local profile
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")

    if [ -z "$profile" ]; then
        return 1
    fi

    # Check if custom font is set
    local use_sys_font
    use_sys_font=$(dconf read "/org/gnome/terminal/legacy/profiles:/:${profile}/use-system-font" 2>/dev/null)

    [ "$use_sys_font" = "false" ]
}

# Configure GNOME Terminal with custom font, colors, and scrollback
terminal_shell__gnome_terminal__install() {
    log_info "Configuring GNOME Terminal..."

    # ---- Prerequisite check ----
    if ! is_command_available "gnome-terminal"; then
        log_warning "GNOME Terminal not found, skipping configuration"
        return 0
    fi

    if ! is_command_available "dconf"; then
        log_warning "dconf not found, installing..."
        ensure_apt_updated
        run_sudo apt-get install -y dconf-cli >> "$LOG_FILE" 2>&1 || {
            log_error "Failed to install dconf-cli"
            return 1
        }
    fi

    # ---- Get default profile ID ----
    local profile
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")

    if [ -z "$profile" ]; then
        log_warning "Could not detect GNOME Terminal default profile"
        log_warning "GNOME Terminal may not have been opened yet. Skipping."
        return 0
    fi

    local profile_path="/org/gnome/terminal/legacy/profiles:/:${profile}/"

    log_info "Configuring GNOME Terminal profile: ${profile}"

    # ---- Set custom font (CaskaydiaCove Nerd Font Mono for terminal) ----
    log_info "Setting terminal font to CaskaydiaCove Nerd Font Mono 12..."
    dconf write "${profile_path}use-system-font" "false" 2>> "$LOG_FILE"
    dconf write "${profile_path}font" "'CaskaydiaCove Nerd Font Mono 12'" 2>> "$LOG_FILE"

    # ---- Set color scheme (Solarized Dark-like) ----
    log_info "Setting terminal color scheme..."
    dconf write "${profile_path}use-theme-colors" "false" 2>> "$LOG_FILE"
    dconf write "${profile_path}background-color" "'#002b36'" 2>> "$LOG_FILE"
    dconf write "${profile_path}foreground-color" "'#839496'" 2>> "$LOG_FILE"

    # ---- Scrollback ----
    log_info "Setting scrollback to 10000 lines..."
    dconf write "${profile_path}scrollback-lines" "10000" 2>> "$LOG_FILE"

    # ---- Disable audible bell ----
    dconf write "${profile_path}audible-bell" "false" 2>> "$LOG_FILE"

    log_success "GNOME Terminal configured successfully"
    return 0
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "terminal_shell" "oh_my_zsh" "Oh My Zsh"
register_tool "terminal_shell" "powerlevel10k" "Powerlevel10k Theme" "true"
register_tool "terminal_shell" "oh_my_zsh_config" "Oh My Zsh Config" "true"
register_tool "terminal_shell" "font_cascadia" "CaskaydiaCove Nerd Font" "true"
register_tool "terminal_shell" "font_thsarabun" "TH Sarabun PSK" "true"
register_tool "terminal_shell" "gnome_terminal" "GNOME Terminal Config" "true"