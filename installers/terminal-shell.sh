#!/usr/bin/env bash
# ==============================================================================
# installers/terminal-shell.sh — Terminal & Shell Category
# ==============================================================================
# Shell customization, fonts, and terminal configuration.
#
# Category: terminal_shell
# Display:  🖥️ Terminal and Shell
#
# Tools (5):
#   oh_my_zsh        — Oh My Zsh framework for managing Zsh configuration
#   oh_my_zsh_config — Oh My Zsh configuration (theme + plugins)
#   font_cascadia    — CaskaydiaMono Nerd Font
#   font_thsarabun   — TH Sarabun PSK font (bundled)
#   gnome_terminal   — GNOME Terminal configuration (font, colors, scrollback)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

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
    log_info "Running Oh My Zsh install script..."
    if su - "$REAL_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' >> "$LOG_FILE" 2>&1; then
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

    log_info "Installing zsh-autosuggestions plugin..."
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        su - "$REAL_USER" -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${zsh_custom}/plugins/zsh-autosuggestions" >> "$LOG_FILE" 2>&1 || \
            log_warning "Failed to clone zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed"
    fi

    log_info "Installing zsh-syntax-highlighting plugin..."
    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        su - "$REAL_USER" -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting ${zsh_custom}/plugins/zsh-syntax-highlighting" >> "$LOG_FILE" 2>&1 || \
            log_warning "Failed to clone zsh-syntax-highlighting"
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
# Tool: oh_my_zsh_config
# ==============================================================================

# Description for Oh My Zsh Config
terminal_shell__oh_my_zsh_config__description() {
    echo "Oh My Zsh Configuration — theme + plugins setup"
}

# Check if Oh My Zsh config is in place (theme configured in .zshrc)
terminal_shell__oh_my_zsh_config__is_installed() {
    grep -q 'ZSH_THEME=' "${REAL_HOME}/.zshrc" 2>/dev/null
}

# Configure Oh My Zsh theme and plugins in .zshrc
terminal_shell__oh_my_zsh_config__install() {
    log_info "Configuring Oh My Zsh theme and plugins..."

    local zshrc="${REAL_HOME}/.zshrc"

    # ---- Step 1: Verify .zshrc exists (created by Oh My Zsh installer) ----
    if [ ! -f "$zshrc" ]; then
        log_error ".zshrc not found — install Oh My Zsh first"
        return 1
    fi

    # ---- Step 2: Set theme to agnoster ----
    log_info "Setting ZSH_THEME to agnoster..."
    if grep -q '^ZSH_THEME=' "$zshrc" 2>/dev/null; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$zshrc"
    else
        echo 'ZSH_THEME="agnoster"' >> "$zshrc"
    fi
    log_success "Theme set to agnoster"

    # ---- Step 3: Configure plugins ----
    log_info "Configuring plugins..."
    if grep -q '^plugins=' "$zshrc" 2>/dev/null; then
        sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose kubectl)/' "$zshrc"
    else
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose kubectl)' >> "$zshrc"
    fi
    log_success "Plugins configured"

    # ---- Step 4: Hint about bashrc migration ----
    if [ -f "${REAL_HOME}/.bashrc" ]; then
        log_info "Note: You may want to migrate custom aliases/PATH from .bashrc to .zshrc"
    fi

    chown "${REAL_USER}:${REAL_USER}" "$zshrc" 2>/dev/null || true

    log_success "Oh My Zsh configured in .zshrc"
    return 0
}

# ==============================================================================
# Tool: font_cascadia
# ==============================================================================

# Description for CaskaydiaMono Nerd Font
terminal_shell__font_cascadia__description() {
    echo "CaskaydiaMono Nerd Font — patched font with icons for terminal"
}

# Check if CaskaydiaMono Nerd Font is installed
terminal_shell__font_cascadia__is_installed() {
    fc-list 2>/dev/null | grep -qi "CaskaydiaMono"
}

# Download and install CaskaydiaMono Nerd Font from GitHub releases
terminal_shell__font_cascadia__install() {
    log_info "Installing CaskaydiaMono Nerd Font..."

    local font_dir="${REAL_HOME}/.local/share/fonts"
    local font_zip="${TEMP_DIR}/CascadiaMono.zip"
    local font_extract_dir="${TEMP_DIR}/CascadiaMono"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"

    # ---- Step 1: Download font zip ----
    log_info "Downloading CascadiaMono Nerd Font..."
    if ! download_file "$download_url" "$font_zip"; then
        log_error "Failed to download CaskaydiaMono Nerd Font"
        return 1
    fi

    # ---- Step 2: Extract fonts ----
    log_info "Extracting fonts..."
    mkdir -p "$font_extract_dir"
    if ! unzip -o "$font_zip" -d "$font_extract_dir" >> "$LOG_FILE" 2>&1; then
        log_error "Failed to extract CascadiaMono.zip"
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
    if fc-list 2>/dev/null | grep -qi "CaskaydiaMono"; then
        log_success "CaskaydiaMono Nerd Font installed successfully"
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
    fc-list 2>/dev/null | grep -qi "Sarabun"
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

    # ---- Set custom font ----
    log_info "Setting terminal font to CaskaydiaMono Nerd Font 12..."
    dconf write "${profile_path}use-system-font" "false" 2>> "$LOG_FILE"
    dconf write "${profile_path}font" "'CaskaydiaMono Nerd Font 12'" 2>> "$LOG_FILE"

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
register_tool "terminal_shell" "oh_my_zsh_config" "Oh My Zsh Config" "true"
register_tool "terminal_shell" "font_cascadia" "CaskaydiaMono Nerd Font" "true"
register_tool "terminal_shell" "font_thsarabun" "TH Sarabun PSK" "true"
register_tool "terminal_shell" "gnome_terminal" "GNOME Terminal Config" "true"