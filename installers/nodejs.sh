#!/usr/bin/env bash
# ==============================================================================
# installers/nodejs.sh — Node.js Development Category
# ==============================================================================
# Node.js runtime via NVM, npm, and global dev tools.
#
# Category: nodejs
# Display:  📦 Node.js Development
#
# Tools (4):
#   nvm          — NVM (Node Version Manager)
#   nodejs20     — Node.js 20 LTS (via nvm)
#   npm          — npm latest (comes with node, upgraded)
#   nodejs_tools — Node.js Dev Tools (pnpm, nodemon, typescript, ts-node, etc.)
#
# Dependencies:
#   nodejs20     → requires nvm
#   npm          → requires nodejs20
#   nodejs_tools → requires npm
# ==============================================================================

# ==============================================================================
# Helper: Source NVM for current session
# ==============================================================================

# Ensure NVM is loaded in the current shell session
# This is needed because nvm is a shell function, not a binary
_ensure_nvm_loaded() {
    # If nvm function already available, nothing to do
    if type nvm &>/dev/null; then
        return 0
    fi

    # Try to source nvm.sh
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        \. "$NVM_DIR/nvm.sh"
        return 0
    fi

    return 1
}

# ==============================================================================
# Tool: nvm
# ==============================================================================

# Description for NVM
nodejs__nvm__description() {
    echo "Node Version Manager — install and manage multiple Node.js versions"
}

# Check if nvm is installed (directory exists and nvm.sh is present)
nodejs__nvm__is_installed() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [ -d "$nvm_dir" ] && [ -s "$nvm_dir/nvm.sh" ]
}

# Install NVM via official install script
nodejs__nvm__install() {
    log_info "Installing NVM (Node Version Manager)..."

    # Download and run the official NVM install script
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >> "$LOG_FILE" 2>&1; then
        log_success "NVM install script completed"
    else
        log_error "NVM install script failed"
        return 1
    fi

    # Source nvm immediately for current session
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        \. "$NVM_DIR/nvm.sh"
        log_info "NVM sourced for current session"
    else
        log_error "NVM installed but nvm.sh not found"
        return 1
    fi

    # Verify nvm is available
    if type nvm &>/dev/null; then
        local nvm_version
        nvm_version=$(nvm --version 2>/dev/null)
        log_success "NVM v${nvm_version} installed and loaded"
        return 0
    fi

    log_error "NVM installed but not available in current session"
    return 1
}

# ==============================================================================
# Tool: nodejs20
# ==============================================================================

# Description for Node.js 20 LTS
nodejs__nodejs20__description() {
    echo "Node.js 20 LTS runtime (installed via NVM)"
}

# Check if Node.js 20 is installed and active
nodejs__nodejs20__is_installed() {
    # First ensure nvm is loaded
    _ensure_nvm_loaded 2>/dev/null

    # Check if node is available and is version 20.x
    if is_command_available "node"; then
        local node_version
        node_version=$(node --version 2>/dev/null)
        if [[ "$node_version" == v20.* ]]; then
            return 0
        fi
    fi
    return 1
}

# Install Node.js 20 LTS via NVM
nodejs__nodejs20__install() {
    log_info "Installing Node.js 20 LTS via NVM..."

    # Ensure NVM is available
    if ! _ensure_nvm_loaded; then
        log_warning "NVM not loaded. Attempting to install NVM first..."
        nodejs__nvm__install || {
            log_error "Cannot install Node.js 20 without NVM"
            return 1
        }
    fi

    # Install Node.js 20 LTS
    if nvm install 20 >> "$LOG_FILE" 2>&1; then
        log_success "Node.js 20 installed"
    else
        log_error "Failed to install Node.js 20 via NVM"
        return 1
    fi

    # Use Node.js 20 and set as default
    nvm use 20 >> "$LOG_FILE" 2>&1
    nvm alias default 20 >> "$LOG_FILE" 2>&1

    # Verify installation
    local node_version
    node_version=$(node --version 2>/dev/null)
    if [[ "$node_version" == v20.* ]]; then
        log_success "Node.js ${node_version} is active and set as default"
        return 0
    fi

    log_error "Node.js 20 installed but verification failed (got: ${node_version:-none})"
    return 1
}

# ==============================================================================
# Tool: npm
# ==============================================================================

# Description for npm
nodejs__npm__description() {
    echo "npm package manager (latest version)"
}

# Check if npm is available
nodejs__npm__is_installed() {
    _ensure_nvm_loaded 2>/dev/null
    is_command_available "npm"
}

# Upgrade npm to latest version
nodejs__npm__install() {
    log_info "Upgrading npm to latest version..."

    # Ensure NVM and Node are loaded
    _ensure_nvm_loaded 2>/dev/null

    # Check that node is available (npm comes with node)
    if ! is_command_available "node"; then
        log_warning "Node.js not found. Attempting to install Node.js 20 first..."
        nodejs__nodejs20__install || {
            log_error "Cannot upgrade npm without Node.js"
            return 1
        }
    fi

    # Upgrade npm to latest
    if npm install -g npm@latest >> "$LOG_FILE" 2>&1; then
        local npm_version
        npm_version=$(npm --version 2>/dev/null)
        log_success "npm upgraded to v${npm_version}"
        return 0
    fi

    log_error "Failed to upgrade npm"
    return 1
}

# ==============================================================================
# Tool: nodejs_tools
# ==============================================================================

# Description for Node.js Dev Tools
nodejs__nodejs_tools__description() {
    echo "Global Node.js dev tools (pnpm, nodemon, typescript, ts-node, express-generator)"
}

# Check if primary tool (pnpm) is available as indicator
nodejs__nodejs_tools__is_installed() {
    _ensure_nvm_loaded 2>/dev/null
    is_command_available "pnpm"
}

# Install global Node.js development tools via npm
nodejs__nodejs_tools__install() {
    log_info "Installing Node.js global dev tools..."

    # Ensure NVM and Node/npm are loaded
    _ensure_nvm_loaded 2>/dev/null

    # Check that npm is available
    if ! is_command_available "npm"; then
        log_warning "npm not found. Attempting to install Node.js 20 first..."
        nodejs__nodejs20__install || {
            log_error "Cannot install Node.js dev tools without npm"
            return 1
        }
    fi

    # Install global tools
    local tools="pnpm nodemon typescript ts-node express-generator"
    log_info "Installing global packages: ${tools}"

    if npm install -g $tools >> "$LOG_FILE" 2>&1; then
        log_success "Node.js dev tools installed"
        return 0
    fi

    log_error "Failed to install some Node.js dev tools"
    return 1
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "nodejs" "nvm" "NVM (Node Version Manager)"
register_tool "nodejs" "nodejs20" "Node.js 20 LTS"
register_tool "nodejs" "npm" "npm (latest)"
register_tool "nodejs" "nodejs_tools" "Node.js Dev Tools"