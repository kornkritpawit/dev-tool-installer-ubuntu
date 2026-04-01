#!/usr/bin/env bash
# ==============================================================================
# installers/devops.sh — DevOps Tools Category
# ==============================================================================
# Container and orchestration tools for development environment.
#
# Category: devops
# Display:  🐳 DevOps Tools
#
# Tools (3):
#   docker          — Docker Engine (docker-ce + cli + containerd + buildx + compose plugin)
#   docker_compose  — Docker Compose (v2 plugin, fallback v1 standalone)
#   docker_config   — Docker Configuration (daemon.json log rotation + address pool)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ==============================================================================
# Tool: docker
# ==============================================================================

# Description for Docker Engine
devops__docker__description() {
    echo "Docker Engine — container runtime (docker-ce, cli, containerd, buildx, compose plugin)"
}

# Check if Docker Engine is installed
devops__docker__is_installed() {
    is_command_available "docker"
}

# Install Docker Engine from official APT repository
devops__docker__install() {
    log_info "Installing Docker Engine..."

    # ---- Step 1: Remove old/conflicting packages ----
    log_info "Removing old Docker packages (if any)..."
    local old_pkgs=(
        docker.io
        docker-doc
        docker-compose
        docker-compose-v2
        podman-docker
        containerd
        runc
    )
    for pkg in "${old_pkgs[@]}"; do
        sudo apt-get remove -y "$pkg" >> "$LOG_FILE" 2>&1 || true
    done

    # ---- Step 2: Install prerequisites ----
    ensure_apt_updated
    run_sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release || {
        log_error "Failed to install Docker prerequisites"
        return 1
    }

    # ---- Step 3: Add Docker's official GPG key ----
    log_info "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings >> "$LOG_FILE" 2>&1

    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>> "$LOG_FILE" || {
            log_error "Failed to add Docker GPG key"
            return 1
        }
        sudo chmod a+r /etc/apt/keyrings/docker.gpg >> "$LOG_FILE" 2>&1
    else
        log_debug "Docker GPG key already exists, skipping"
    fi

    # ---- Step 4: Add Docker APT repository ----
    local arch
    arch="$(dpkg --print-architecture)"
    local codename
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

    local repo_file="/etc/apt/sources.list.d/docker.list"
    if [ ! -f "$repo_file" ]; then
        log_info "Adding Docker APT repository..."
        echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
            | sudo tee "$repo_file" > /dev/null

        # Force apt update for new repo
        APT_UPDATED=false
        ensure_apt_updated
    else
        log_debug "Docker APT repository already configured"
        ensure_apt_updated
    fi

    # ---- Step 5: Install Docker packages ----
    log_info "Installing Docker CE packages..."
    run_sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin || {
        log_error "Failed to install Docker CE packages"
        return 1
    }

    # ---- Step 6: Add user to docker group ----
    log_info "Adding user '${REAL_USER}' to docker group..."
    run_sudo usermod -aG docker "$REAL_USER" || {
        log_warning "Failed to add user to docker group (may need manual intervention)"
    }

    # ---- Step 7: Enable and start Docker service ----
    log_info "Enabling Docker service..."
    run_sudo systemctl enable docker >> "$LOG_FILE" 2>&1 || true
    run_sudo systemctl start docker >> "$LOG_FILE" 2>&1 || true

    log_success "Docker Engine installed successfully"
    log_warning "You may need to log out and back in for docker group membership to take effect"
    return 0
}

# ==============================================================================
# Tool: docker_compose
# ==============================================================================

# Description for Docker Compose
devops__docker_compose__description() {
    echo "Docker Compose — multi-container orchestration (v2 plugin)"
}

# Check if Docker Compose is available (v2 plugin or v1 standalone)
devops__docker_compose__is_installed() {
    # Check v2 plugin first
    if docker compose version &>/dev/null; then
        return 0
    fi
    # Fallback: check v1 standalone
    if command -v docker-compose &>/dev/null; then
        return 0
    fi
    return 1
}

# Install Docker Compose
# Normally comes with docker-compose-plugin from Docker install.
# If not present, install the plugin or fallback to standalone.
devops__docker_compose__install() {
    log_info "Installing Docker Compose..."

    # Check if already available via plugin (installed with docker-ce)
    if docker compose version &>/dev/null; then
        log_success "Docker Compose v2 plugin already available"
        return 0
    fi

    # Try installing the plugin via apt
    ensure_apt_updated
    if run_sudo apt-get install -y docker-compose-plugin; then
        if docker compose version &>/dev/null; then
            log_success "Docker Compose v2 plugin installed successfully"
            return 0
        fi
    fi

    # Fallback: install standalone docker-compose v2
    log_warning "Plugin install failed, trying standalone docker-compose..."
    local compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
    local compose_dest="/usr/local/bin/docker-compose"

    if download_file "$compose_url" "${TEMP_DIR}/docker-compose"; then
        run_sudo install -m 755 "${TEMP_DIR}/docker-compose" "$compose_dest" || {
            log_error "Failed to install standalone docker-compose"
            return 1
        }
        log_success "Docker Compose standalone installed successfully"
        return 0
    fi

    log_error "Failed to install Docker Compose"
    return 1
}

# ==============================================================================
# Tool: docker_config
# ==============================================================================

# Description for Docker Configuration
devops__docker_config__description() {
    echo "Docker daemon configuration (log rotation, address pool)"
}

# Check if Docker is configured (daemon.json exists)
devops__docker_config__is_installed() {
    [ -f /etc/docker/daemon.json ]
}

# Configure Docker daemon
devops__docker_config__install() {
    log_info "Configuring Docker daemon..."

    # ---- Step 1: Create /etc/docker/daemon.json ----
    local daemon_json="/etc/docker/daemon.json"

    if [ -f "$daemon_json" ]; then
        log_info "daemon.json already exists, merging configuration..."
        # Merge using jq if available, otherwise overwrite with warning
        if is_command_available jq; then
            local template_json
            template_json=$(cat << 'DAEMONJSON'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ]
}
DAEMONJSON
)
            local merged
            merged=$(jq -s '.[0] * .[1]' "$daemon_json" <(echo "$template_json") 2>> "$LOG_FILE")
            if [ -n "$merged" ]; then
                echo "$merged" | sudo tee "$daemon_json" > /dev/null
            else
                log_warning "jq merge failed, overwriting daemon.json"
                echo "$template_json" | sudo tee "$daemon_json" > /dev/null
            fi
        else
            log_warning "jq not available, overwriting daemon.json"
            sudo tee "$daemon_json" > /dev/null << 'DAEMONJSON'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ]
}
DAEMONJSON
        fi
    else
        log_info "Creating daemon.json..."
        sudo mkdir -p /etc/docker >> "$LOG_FILE" 2>&1
        sudo tee "$daemon_json" > /dev/null << 'DAEMONJSON'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ]
}
DAEMONJSON
    fi

    # ---- Step 2: Restart Docker to apply daemon.json ----
    log_info "Restarting Docker service to apply daemon.json..."

    if systemctl is-active docker &>/dev/null; then
        # Docker is running — restart with timeout
        if timeout 30 bash -c 'sudo systemctl restart docker' >> "$LOG_FILE" 2>&1; then
            log_success "Docker service restarted successfully"
        else
            local exit_code=$?
            if [ "$exit_code" -eq 124 ]; then
                log_warning "Docker restart timed out after 30s (daemon.json is saved, Docker will apply on next start)"
            else
                log_warning "Docker restart failed (daemon.json is saved, Docker will apply on next start)"
            fi
        fi
    else
        # Docker is not running — just log that config is saved
        log_info "Docker service is not running. daemon.json saved — config will apply when Docker starts."
    fi

    log_success "Docker daemon configured successfully (daemon.json deployed)"
    return 0
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "devops" "docker" "Docker Engine"
register_tool "devops" "docker_compose" "Docker Compose"
register_tool "devops" "docker_config" "Docker Configuration"