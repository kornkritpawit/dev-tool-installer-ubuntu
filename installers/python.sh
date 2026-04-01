#!/usr/bin/env bash
# ==============================================================================
# installers/python.sh — Python Development Category
# ==============================================================================
# Python runtime, package managers, and build dependencies.
#
# Category: python
# Display:  🐍 Python Development
#
# Tools (5):
#   python3    — Python 3 runtime with dev headers and venv
#   pip        — pip package manager for Python 3
#   poetry     — Poetry dependency management tool
#   uv         — uv (fast Python package manager by Astral)
#   build_deps — Python build dependencies (setuptools, wheel)
# ==============================================================================

# ==============================================================================
# Tool: python3
# ==============================================================================

# Description for Python 3
python__python3__description() {
    echo "Python 3 runtime with dev headers and venv support"
}

# Check if python3 is available in PATH
python__python3__is_installed() {
    is_command_available "python3"
}

# Install python3 with dev headers and venv via apt
python__python3__install() {
    log_info "Installing Python 3 with dev headers and venv..."
    ensure_apt_updated
    run_sudo apt-get install -y python3 python3-dev python3-venv
    return $?
}

# ==============================================================================
# Tool: pip
# ==============================================================================

# Description for pip
python__pip__description() {
    echo "Python package installer (pip3)"
}

# Check if pip is available (command or python module)
python__pip__is_installed() {
    # Check for pip3 command first, then try python3 -m pip
    if is_command_available "pip3"; then
        return 0
    fi
    python3 -m pip --version &>/dev/null
    return $?
}

# Install pip via apt, then upgrade via pip itself
python__pip__install() {
    log_info "Installing pip for Python 3..."
    ensure_apt_updated

    # Primary: install via apt
    if run_sudo apt-get install -y python3-pip; then
        log_info "Upgrading pip to latest version..."
        python3 -m pip install --upgrade pip >> "$LOG_FILE" 2>&1 || true
        return 0
    fi

    # Fallback: ensurepip module
    log_warning "apt install failed, trying ensurepip fallback..."
    if python3 -m ensurepip --upgrade >> "$LOG_FILE" 2>&1; then
        python3 -m pip install --upgrade pip >> "$LOG_FILE" 2>&1 || true
        return 0
    fi

    log_error "Failed to install pip"
    return 1
}

# ==============================================================================
# Tool: poetry
# ==============================================================================

# Description for Poetry
python__poetry__description() {
    echo "Python dependency management and packaging tool"
}

# Check if poetry is available in PATH or in ~/.local/bin
python__poetry__is_installed() {
    if is_command_available "poetry"; then
        return 0
    fi
    # Check common install location
    if [ -x "$HOME/.local/bin/poetry" ]; then
        return 0
    fi
    return 1
}

# Install Poetry via official installer script
python__poetry__install() {
    log_info "Installing Poetry via official installer..."

    # Download and run the official installer (timeout: 120s)
    if timeout 120 bash -c 'curl -sSL --connect-timeout 30 --max-time 60 https://install.python-poetry.org | python3 -' >> "$LOG_FILE" 2>&1; then
        log_success "Poetry installed successfully"
    else
        log_error "Poetry installation failed"
        return 1
    fi

    # Ensure ~/.local/bin is in PATH for current session
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "Added \$HOME/.local/bin to PATH for current session"
    fi

    # Add PATH to .bashrc if not already present
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        if ! grep -q 'export PATH="\$HOME/.local/bin:\$PATH"' "$bashrc" 2>/dev/null && \
           ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$bashrc" 2>/dev/null; then
            log_info "Adding \$HOME/.local/bin to PATH in .bashrc..."
            echo '' >> "$bashrc"
            echo '# Added by Dev Tool Installer — Poetry/pip user bin' >> "$bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
        fi
    fi

    # Verify installation
    if "$HOME/.local/bin/poetry" --version >> "$LOG_FILE" 2>&1; then
        return 0
    fi
    if is_command_available "poetry"; then
        return 0
    fi

    log_error "Poetry installed but verification failed"
    return 1
}

# ==============================================================================
# Tool: uv
# ==============================================================================

# Description for uv
python__uv__description() {
    echo "Extremely fast Python package manager (by Astral)"
}

# Check if uv is available in PATH or in ~/.local/bin
python__uv__is_installed() {
    if is_command_available "uv"; then
        return 0
    fi
    # Check common install location
    if [ -x "$HOME/.local/bin/uv" ]; then
        return 0
    fi
    return 1
}

# Install uv via official installer script
python__uv__install() {
    log_info "Installing uv via official installer..."

    # Download and run the official installer (timeout: 120s)
    if timeout 120 bash -c 'curl -LsSf --connect-timeout 30 --max-time 60 https://astral.sh/uv/install.sh | sh' >> "$LOG_FILE" 2>&1; then
        log_success "uv installed successfully"
    else
        log_error "uv installation failed"
        return 1
    fi

    # Ensure ~/.local/bin is in PATH for current session
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "Added \$HOME/.local/bin to PATH for current session"
    fi

    # Verify installation
    if "$HOME/.local/bin/uv" --version >> "$LOG_FILE" 2>&1; then
        return 0
    fi
    if is_command_available "uv"; then
        return 0
    fi

    log_error "uv installed but verification failed"
    return 1
}

# ==============================================================================
# Tool: build_deps
# ==============================================================================

# Description for Python build dependencies
python__build_deps__description() {
    echo "Python build dependencies (setuptools, wheel)"
}

# Check if setuptools is importable in python3
python__build_deps__is_installed() {
    python3 -c "import setuptools" &>/dev/null
}

# Install Python build dependencies via apt
python__build_deps__install() {
    log_info "Installing Python build dependencies..."
    ensure_apt_updated
    run_sudo apt-get install -y python3-setuptools python3-wheel
    return $?
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "python" "python3" "Python 3"
register_tool "python" "pip" "pip"
register_tool "python" "poetry" "Poetry"
register_tool "python" "uv" "uv"
register_tool "python" "build_deps" "Python Build Dependencies"