#!/usr/bin/env bash
# ==============================================================================
# installers/system-essentials.sh — System Essentials Category
# ==============================================================================
# Essential build tools and utilities for Ubuntu development environment.
#
# Category: system_essentials
# Display:  🔧 System Essentials
#
# Tools (9):
#   build_essential     — build-essential (gcc, g++, make, etc.)
#   curl                — curl (URL data transfer)
#   wget                — wget (file downloader)
#   git                 — Git (version control)
#   unzip               — unzip (ZIP extraction)
#   zip                 — zip (ZIP creation)
#   software_properties — software-properties-common (add-apt-repository)
#   apt_transport       — apt-transport-https (HTTPS for APT)
#   ca_certificates     — ca-certificates (SSL/TLS certificates)
# ==============================================================================

# ==============================================================================
# Tool: build_essential
# ==============================================================================

# Description for build-essential package
system_essentials__build_essential__description() {
    echo "Essential compilation tools (gcc, g++, make, etc.)"
}

# Check if build-essential is installed via dpkg
system_essentials__build_essential__is_installed() {
    is_package_installed "build-essential"
}

# Install build-essential via apt
system_essentials__build_essential__install() {
    log_info "Installing build-essential..."
    ensure_apt_updated
    run_sudo apt-get install -y build-essential
    return $?
}

# ==============================================================================
# Tool: curl
# ==============================================================================

# Description for curl
system_essentials__curl__description() {
    echo "Command-line tool for transferring data with URLs"
}

# Check if curl is available in PATH
system_essentials__curl__is_installed() {
    is_command_available "curl"
}

# Install curl via apt
system_essentials__curl__install() {
    log_info "Installing curl..."
    ensure_apt_updated
    run_sudo apt-get install -y curl
    return $?
}

# ==============================================================================
# Tool: wget
# ==============================================================================

# Description for wget
system_essentials__wget__description() {
    echo "Network file downloader"
}

# Check if wget is available in PATH
system_essentials__wget__is_installed() {
    is_command_available "wget"
}

# Install wget via apt
system_essentials__wget__install() {
    log_info "Installing wget..."
    ensure_apt_updated
    run_sudo apt-get install -y wget
    return $?
}

# ==============================================================================
# Tool: git
# ==============================================================================

# Description for Git
system_essentials__git__description() {
    echo "Distributed version control system"
}

# Check if git is available in PATH
system_essentials__git__is_installed() {
    is_command_available "git"
}

# Install git via apt (no user config prompt — kept simple)
system_essentials__git__install() {
    log_info "Installing Git..."
    ensure_apt_updated
    run_sudo apt-get install -y git
    return $?
}

# ==============================================================================
# Tool: unzip
# ==============================================================================

# Description for unzip
system_essentials__unzip__description() {
    echo "ZIP archive extraction utility"
}

# Check if unzip is available in PATH
system_essentials__unzip__is_installed() {
    is_command_available "unzip"
}

# Install unzip via apt
system_essentials__unzip__install() {
    log_info "Installing unzip..."
    ensure_apt_updated
    run_sudo apt-get install -y unzip
    return $?
}

# ==============================================================================
# Tool: zip
# ==============================================================================

# Description for zip
system_essentials__zip__description() {
    echo "ZIP archive creation utility"
}

# Check if zip is available in PATH
system_essentials__zip__is_installed() {
    is_command_available "zip"
}

# Install zip via apt
system_essentials__zip__install() {
    log_info "Installing zip..."
    ensure_apt_updated
    run_sudo apt-get install -y zip
    return $?
}

# ==============================================================================
# Tool: software_properties
# ==============================================================================

# Description for software-properties-common
system_essentials__software_properties__description() {
    echo "Manage APT repositories (add-apt-repository support)"
}

# Check if software-properties-common is installed via dpkg
system_essentials__software_properties__is_installed() {
    is_package_installed "software-properties-common"
}

# Install software-properties-common via apt
system_essentials__software_properties__install() {
    log_info "Installing software-properties-common..."
    ensure_apt_updated
    run_sudo apt-get install -y software-properties-common
    return $?
}

# ==============================================================================
# Tool: apt_transport
# ==============================================================================

# Description for apt-transport-https
system_essentials__apt_transport__description() {
    echo "HTTPS transport for APT package manager"
}

# Check if apt-transport-https is installed via dpkg
system_essentials__apt_transport__is_installed() {
    is_package_installed "apt-transport-https"
}

# Install apt-transport-https via apt
system_essentials__apt_transport__install() {
    log_info "Installing apt-transport-https..."
    ensure_apt_updated
    run_sudo apt-get install -y apt-transport-https
    return $?
}

# ==============================================================================
# Tool: ca_certificates
# ==============================================================================

# Description for ca-certificates
system_essentials__ca_certificates__description() {
    echo "Common SSL/TLS CA certificates"
}

# Check if ca-certificates is installed via dpkg
system_essentials__ca_certificates__is_installed() {
    is_package_installed "ca-certificates"
}

# Install ca-certificates via apt
system_essentials__ca_certificates__install() {
    log_info "Installing ca-certificates..."
    ensure_apt_updated
    run_sudo apt-get install -y ca-certificates
    return $?
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "system_essentials" "build_essential" "Build Essential"
register_tool "system_essentials" "curl" "curl"
register_tool "system_essentials" "wget" "wget"
register_tool "system_essentials" "git" "Git"
register_tool "system_essentials" "unzip" "unzip"
register_tool "system_essentials" "zip" "zip"
register_tool "system_essentials" "software_properties" "software-properties-common"
register_tool "system_essentials" "apt_transport" "apt-transport-https"
register_tool "system_essentials" "ca_certificates" "ca-certificates"