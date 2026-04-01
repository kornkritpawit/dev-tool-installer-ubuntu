#!/usr/bin/env bash
# ==============================================================================
# installers/terminal-shell.sh — Terminal & Shell Category
# ==============================================================================
# Terminal configuration.
#
# Category: terminal_shell
# Display:  🖥️ Terminal and Shell
#
# Tools (1):
#   gnome_terminal   — GNOME Terminal configuration (font, colors, scrollback)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

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

register_tool "terminal_shell" "gnome_terminal" "GNOME Terminal Config" "true"