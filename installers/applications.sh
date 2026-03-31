#!/usr/bin/env bash
# ==============================================================================
# installers/applications.sh — Applications Category
# ==============================================================================
# Developer applications and browsers.
#
# Category: applications
# Display:  📦 Applications
#
# Tools (7):
#   postman   — Postman (API testing tool via snap)
#   rustdesk  — RustDesk (remote desktop via .deb download)
#   wireguard — WireGuard (VPN via apt)
#   chrome    — Google Chrome (browser via .deb download)
#   firefox   — Mozilla Firefox (browser via apt/snap)
#   brave     — Brave Browser (browser via APT repo)
#   opera     — Opera Browser (browser via APT repo)
# ==============================================================================

# ==============================================================================
# Tool: postman
# ==============================================================================

# Description for Postman
applications__postman__description() {
    echo "Postman — API development and testing platform"
}

# Check if Postman is installed via snap
applications__postman__is_installed() {
    is_snap_installed "postman"
}

# Install Postman via snap
applications__postman__install() {
    log_info "Installing Postman via snap..."

    if is_snap_installed "postman"; then
        log_success "Postman is already installed"
        return 0
    fi

    run_sudo snap install postman || {
        log_error "Failed to install Postman via snap"
        return 1
    }

    # Verify installation
    if is_snap_installed "postman"; then
        log_success "Postman installed successfully"
        return 0
    else
        log_error "Postman installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: rustdesk
# ==============================================================================

# Description for RustDesk
applications__rustdesk__description() {
    echo "RustDesk — open-source remote desktop application"
}

# Check if RustDesk is installed
applications__rustdesk__is_installed() {
    is_command_available "rustdesk" || is_package_installed "rustdesk"
}

# Install RustDesk via .deb download from GitHub releases
applications__rustdesk__install() {
    log_info "Installing RustDesk..."

    if is_command_available "rustdesk"; then
        log_success "RustDesk is already installed"
        return 0
    fi

    local tmp_deb="${TEMP_DIR}/rustdesk.deb"
    local deb_url=""

    # ---- Step 1: Try to get latest .deb URL from GitHub API ----
    log_info "Fetching latest RustDesk release from GitHub API..."
    if is_command_available jq; then
        local api_response
        api_response=$(curl -s "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" 2>> "$LOG_FILE")

        if [ -n "$api_response" ]; then
            # Find amd64.deb asset URL
            deb_url=$(echo "$api_response" | jq -r '.assets[]? | select(.name | test("amd64\\.deb$")) | .browser_download_url' 2>/dev/null | head -1)

            if [ -z "$deb_url" ] || [ "$deb_url" = "null" ]; then
                # Try alternative pattern: x86_64.deb
                deb_url=$(echo "$api_response" | jq -r '.assets[]? | select(.name | test("x86_64\\.deb$")) | .browser_download_url' 2>/dev/null | head -1)
            fi
        fi
    fi

    # ---- Step 2: Fallback to hardcoded version if API fails ----
    if [ -z "$deb_url" ] || [ "$deb_url" = "null" ]; then
        local fallback_version="1.3.9"
        log_warning "GitHub API failed, using fallback version ${fallback_version}"
        deb_url="https://github.com/rustdesk/rustdesk/releases/download/${fallback_version}/rustdesk-${fallback_version}-x86_64.deb"
    fi

    log_info "Downloading RustDesk from: ${deb_url}"

    # ---- Step 3: Download .deb ----
    if ! download_file "$deb_url" "$tmp_deb"; then
        log_error "Failed to download RustDesk .deb"
        return 1
    fi

    # ---- Step 4: Install .deb + fix deps ----
    log_info "Installing RustDesk .deb package..."
    if ! run_sudo dpkg -i "$tmp_deb"; then
        log_info "Fixing broken dependencies..."
        run_sudo apt-get install -f -y || {
            log_error "Failed to install RustDesk"
            rm -f "$tmp_deb"
            return 1
        }
    fi

    # ---- Step 5: Cleanup ----
    rm -f "$tmp_deb"

    # Verify installation
    if is_command_available "rustdesk" || is_package_installed "rustdesk"; then
        log_success "RustDesk installed successfully"
        return 0
    else
        log_error "RustDesk installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: wireguard
# ==============================================================================

# Description for WireGuard
applications__wireguard__description() {
    echo "WireGuard — fast, modern VPN tunnel"
}

# Check if WireGuard is installed
applications__wireguard__is_installed() {
    is_command_available "wg"
}

# Install WireGuard via apt
applications__wireguard__install() {
    log_info "Installing WireGuard..."

    if is_command_available "wg"; then
        log_success "WireGuard is already installed"
        return 0
    fi

    ensure_apt_updated
    run_sudo apt-get install -y wireguard wireguard-tools || {
        log_error "Failed to install WireGuard"
        return 1
    }

    # Verify installation
    if is_command_available "wg"; then
        log_success "WireGuard installed successfully"
        return 0
    else
        log_error "WireGuard installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: chrome
# ==============================================================================

# Description for Google Chrome
applications__chrome__description() {
    echo "Google Chrome — web browser (stable channel)"
}

# Check if Google Chrome is installed
applications__chrome__is_installed() {
    is_command_available "google-chrome-stable" || is_command_available "google-chrome"
}

# Install Google Chrome via .deb download
applications__chrome__install() {
    log_info "Installing Google Chrome..."

    if is_command_available "google-chrome-stable" || is_command_available "google-chrome"; then
        log_success "Google Chrome is already installed"
        return 0
    fi

    local tmp_deb="${TEMP_DIR}/google-chrome-stable.deb"
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

    # ---- Step 1: Download .deb ----
    log_info "Downloading Google Chrome .deb package..."
    if ! download_file "$chrome_url" "$tmp_deb"; then
        log_error "Failed to download Google Chrome .deb"
        return 1
    fi

    # ---- Step 2: Install .deb + fix deps ----
    log_info "Installing Google Chrome .deb package..."
    if ! run_sudo dpkg -i "$tmp_deb"; then
        log_info "Fixing broken dependencies..."
        run_sudo apt-get install -f -y || {
            log_error "Failed to install Google Chrome"
            rm -f "$tmp_deb"
            return 1
        }
    fi

    # ---- Step 3: Cleanup ----
    rm -f "$tmp_deb"

    # Note: Chrome .deb automatically adds its own APT repo for future updates

    # Verify installation
    if is_command_available "google-chrome-stable" || is_command_available "google-chrome"; then
        log_success "Google Chrome installed successfully"
        return 0
    else
        log_error "Google Chrome installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: firefox
# ==============================================================================

# Description for Mozilla Firefox
applications__firefox__description() {
    echo "Mozilla Firefox — open-source web browser"
}

# Check if Firefox is installed
applications__firefox__is_installed() {
    is_command_available "firefox"
}

# Install Firefox via snap (Ubuntu 22.04+ default) or apt fallback
applications__firefox__install() {
    log_info "Installing Mozilla Firefox..."

    if is_command_available "firefox"; then
        log_success "Firefox is already installed"
        return 0
    fi

    # Ubuntu 22.04+ uses snap as default for Firefox
    # Try snap first, fallback to apt
    if is_command_available "snap"; then
        log_info "Installing Firefox via snap..."
        if run_sudo snap install firefox; then
            if is_command_available "firefox"; then
                log_success "Firefox installed successfully via snap"
                return 0
            fi
        fi
        log_warning "Snap install failed, trying apt fallback..."
    fi

    # Fallback: install via apt
    log_info "Installing Firefox via apt..."
    ensure_apt_updated
    run_sudo apt-get install -y firefox || {
        log_error "Failed to install Firefox"
        return 1
    }

    # Verify installation
    if is_command_available "firefox"; then
        log_success "Firefox installed successfully"
        return 0
    else
        log_error "Firefox installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: brave
# ==============================================================================

# Description for Brave Browser
applications__brave__description() {
    echo "Brave Browser — privacy-focused Chromium-based browser"
}

# Check if Brave is installed
applications__brave__is_installed() {
    is_command_available "brave-browser"
}

# Install Brave Browser via official APT repository
applications__brave__install() {
    log_info "Installing Brave Browser..."

    if is_command_available "brave-browser"; then
        log_success "Brave Browser is already installed"
        return 0
    fi

    # ---- Step 1: Add Brave GPG key ----
    local keyring_path="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
    if [ ! -f "$keyring_path" ]; then
        log_info "Adding Brave Browser GPG key..."
        if ! curl -fsSLo "$keyring_path" \
            "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" 2>> "$LOG_FILE"; then
            log_error "Failed to add Brave Browser GPG key"
            return 1
        fi
    else
        log_debug "Brave Browser GPG key already exists"
    fi

    # ---- Step 2: Add Brave APT repository ----
    local repo_file="/etc/apt/sources.list.d/brave-browser-release.list"
    if [ ! -f "$repo_file" ]; then
        log_info "Adding Brave Browser APT repository..."
        echo "deb [signed-by=${keyring_path}] https://brave-browser-apt-release.s3.brave.com/ stable main" \
            | sudo tee "$repo_file" > /dev/null

        # Force apt update for new repo
        APT_UPDATED=false
    fi

    # ---- Step 3: Install Brave Browser ----
    ensure_apt_updated
    run_sudo apt-get install -y brave-browser || {
        log_error "Failed to install Brave Browser"
        return 1
    }

    # Verify installation
    if is_command_available "brave-browser"; then
        log_success "Brave Browser installed successfully"
        return 0
    else
        log_error "Brave Browser installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Tool: opera
# ==============================================================================

# Description for Opera Browser
applications__opera__description() {
    echo "Opera Browser — feature-rich Chromium-based browser"
}

# Check if Opera is installed
applications__opera__is_installed() {
    is_command_available "opera"
}

# Install Opera Browser via official APT repository
applications__opera__install() {
    log_info "Installing Opera Browser..."

    if is_command_available "opera"; then
        log_success "Opera Browser is already installed"
        return 0
    fi

    # ---- Step 1: Add Opera GPG key ----
    local keyring_path="/usr/share/keyrings/opera-archive-keyring.gpg"
    if [ ! -f "$keyring_path" ]; then
        log_info "Adding Opera Browser GPG key..."
        if ! curl -fsSL "https://deb.opera.com/archive.key" \
            | sudo gpg --dearmor -o "$keyring_path" 2>> "$LOG_FILE"; then
            log_error "Failed to add Opera Browser GPG key"
            return 1
        fi
    else
        log_debug "Opera Browser GPG key already exists"
    fi

    # ---- Step 2: Add Opera APT repository ----
    local repo_file="/etc/apt/sources.list.d/opera-stable.list"
    if [ ! -f "$repo_file" ]; then
        log_info "Adding Opera Browser APT repository..."
        echo "deb [signed-by=${keyring_path}] https://deb.opera.com/opera-stable/ stable non-free" \
            | sudo tee "$repo_file" > /dev/null

        # Force apt update for new repo
        APT_UPDATED=false
    fi

    # ---- Step 3: Install Opera Browser ----
    ensure_apt_updated
    run_sudo apt-get install -y opera-stable || {
        log_error "Failed to install Opera Browser"
        return 1
    }

    # Verify installation
    if is_command_available "opera"; then
        log_success "Opera Browser installed successfully"
        return 0
    else
        log_error "Opera Browser installation could not be verified"
        return 1
    fi
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "applications" "postman" "Postman"
register_tool "applications" "rustdesk" "RustDesk"
register_tool "applications" "wireguard" "WireGuard"
register_tool "applications" "chrome" "Google Chrome"
register_tool "applications" "firefox" "Firefox"
register_tool "applications" "brave" "Brave Browser"
register_tool "applications" "opera" "Opera Browser"