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
#   oh_my_posh       — Oh My Posh prompt engine
#   oh_my_posh_config — Oh My Posh theme config + bashrc integration
#   font_cascadia    — CaskaydiaMono Nerd Font
#   font_thsarabun   — TH Sarabun PSK font (bundled)
#   gnome_terminal   — GNOME Terminal configuration (font, colors, scrollback)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ==============================================================================
# Tool: oh_my_posh
# ==============================================================================

# Description for Oh My Posh
terminal_shell__oh_my_posh__description() {
    echo "Oh My Posh — cross-platform prompt theme engine"
}

# Check if Oh My Posh is installed
terminal_shell__oh_my_posh__is_installed() {
    is_command_available "oh-my-posh"
}

# Install Oh My Posh via official install script
terminal_shell__oh_my_posh__install() {
    log_info "Installing Oh My Posh..."

    # Download and run official install script (installs to /usr/local/bin)
    if curl -fsSL https://ohmyposh.dev/install.sh | bash -s >> "$LOG_FILE" 2>&1; then
        # Verify installation
        if is_command_available "oh-my-posh"; then
            log_success "Oh My Posh installed successfully"
            return 0
        else
            log_error "Oh My Posh install script ran but binary not found in PATH"
            return 1
        fi
    else
        log_error "Oh My Posh install script failed"
        return 1
    fi
}

# ==============================================================================
# Tool: oh_my_posh_config
# ==============================================================================

# Description for Oh My Posh Config
terminal_shell__oh_my_posh_config__description() {
    echo "Oh My Posh theme — paradox theme config + bashrc integration"
}

# Check if Oh My Posh config is in place (theme + bashrc eval)
terminal_shell__oh_my_posh_config__is_installed() {
    grep -q "oh-my-posh" "${REAL_HOME}/.bashrc" 2>/dev/null
}

# Deploy Oh My Posh theme and add eval to .bashrc
terminal_shell__oh_my_posh_config__install() {
    log_info "Configuring Oh My Posh theme..."

    local omp_config_dir="${REAL_HOME}/.config/oh-my-posh"
    local omp_theme="${omp_config_dir}/paradox.omp.json"
    local template="${SCRIPT_DIR}/config/paradox.omp.json"
    local bashrc="${REAL_HOME}/.bashrc"

    # ---- Step 1: Verify template exists ----
    if [ ! -f "$template" ]; then
        log_error "Oh My Posh theme template not found: ${template}"
        return 1
    fi

    # ---- Step 2: Create config directory and copy theme ----
    log_info "Deploying paradox theme..."
    mkdir -p "$omp_config_dir"
    cp "$template" "$omp_theme"
    chown -R "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/.config/oh-my-posh" 2>/dev/null || true

    log_success "Theme deployed to ${omp_theme}"

    # ---- Step 3: Add Oh My Posh eval to .bashrc (idempotent) ----
    if grep -q "oh-my-posh" "$bashrc" 2>/dev/null; then
        log_info "Oh My Posh already configured in .bashrc, updating..."
        # Remove old block using marker comments
        sed -i '/# Oh My Posh/,/^fi$/d' "$bashrc" 2>/dev/null || true
        # Also remove standalone eval lines
        sed -i '/oh-my-posh init bash/d' "$bashrc" 2>/dev/null || true
    fi

    log_info "Adding Oh My Posh to .bashrc..."
    cat >> "$bashrc" << 'BASHRC_OMP'

# Oh My Posh
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/paradox.omp.json)"
fi
BASHRC_OMP

    chown "${REAL_USER}:${REAL_USER}" "$bashrc" 2>/dev/null || true

    log_success "Oh My Posh configured in .bashrc"
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

register_tool "terminal_shell" "oh_my_posh" "Oh My Posh"
register_tool "terminal_shell" "oh_my_posh_config" "Oh My Posh Theme" "true"
register_tool "terminal_shell" "font_cascadia" "CaskaydiaMono Nerd Font" "true"
register_tool "terminal_shell" "font_thsarabun" "TH Sarabun PSK" "true"
register_tool "terminal_shell" "gnome_terminal" "GNOME Terminal Config" "true"