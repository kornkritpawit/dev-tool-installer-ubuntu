#!/usr/bin/env bash
# ==============================================================================
# lib/registry.sh — Tool Registry
# ==============================================================================
# Manages categories and tools metadata using arrays.
# Each installer module registers itself by defining functions following
# the naming convention: {category}__{tool}__{function}
#
# Interface Pattern — every tool must implement:
#   {category}__{tool}__description()    → echo description string
#   {category}__{tool}__is_installed()   → return 0 if installed, 1 if not
#   {category}__{tool}__install()        → perform installation, return exit code
# ==============================================================================

# ------------------------------------------------------------------------------
# Category Definitions
# ------------------------------------------------------------------------------
# Format: "category_id:Display Name:Description"

# Note: Do NOT use "declare -a" here — when this file is sourced inside a
# function (e.g. source_libraries()), "declare" creates a LOCAL variable
# that is destroyed when the function returns, causing "unbound variable"
# errors under set -u.  Plain assignment creates a GLOBAL variable.
CATEGORIES=(
    "system_essentials:System Essentials:Essential build tools and utilities"
    "python:Python Development:Python runtime and package managers"
    "nodejs:Node.js Development:Node.js runtime and JavaScript tools"
    "dotnet:.NET Development:.NET SDK for C# development"
    "devops:DevOps Tools:Container and orchestration tools"
    "editors:Editors and IDEs:Code editors with extensions"
    "terminal_shell:Terminal and Shell:Shell customization and fonts"
    "applications:Applications:Developer applications and browsers"
    "desktop_settings:Desktop Settings:GNOME desktop preferences"
)

# ------------------------------------------------------------------------------
# Tool Definitions
# ------------------------------------------------------------------------------
# Format: "category_id:tool_id:Display Name:always_run"
# - always_run: "true" = always execute install even if "installed"
#               "false" = skip if already installed

TOOLS=()

# Installation status cache — avoids calling __is_installed() multiple times
# per tool.  Must use "declare -gA" (not plain assignment) because:
#   1. Associative arrays require "declare -A"
#   2. This file may be sourced inside a function, so "-g" ensures GLOBAL scope
# Requires bash 4.2+ (Ubuntu 22.04 ships bash 5.1)
declare -gA _INSTALL_CACHE=()

# Tools will be populated when installer modules are sourced.
# Each installer file (installers/*.sh) should call register_tool() to add
# its tools to the TOOLS array.
#
# Example (in installers/python.sh):
#   register_tool "python" "python3" "Python 3" "false"
#   register_tool "python" "poetry" "Poetry" "false"

# ------------------------------------------------------------------------------
# Selected Tools (populated by TUI)
# ------------------------------------------------------------------------------

SELECTED_TOOLS=()

# ------------------------------------------------------------------------------
# Registration Functions
# ------------------------------------------------------------------------------

# Register a tool in the TOOLS array
# Usage: register_tool <category_id> <tool_id> <display_name> <always_run>
register_tool() {
    local category="$1"
    local tool_id="$2"
    local display_name="$3"
    local always_run="${4:-false}"

    TOOLS+=("${category}:${tool_id}:${display_name}:${always_run}")
    log_debug "Registered tool: ${category}::${tool_id} (${display_name})"
}

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

# Initialize the registry by sourcing all installer modules
# This triggers each module's register_tool() calls
registry_init() {
    local installer_dir="${SCRIPT_DIR}/installers"

    log_debug "Initializing tool registry..."

    # Source all installer files if directory exists and has .sh files
    if [ -d "$installer_dir" ]; then
        local count=0
        for f in "$installer_dir"/*.sh; do
            # Skip if no .sh files found (glob didn't match)
            [ -f "$f" ] || continue
            log_debug "Sourcing installer: $f"
            # shellcheck source=/dev/null
            source "$f"
            count=$((count + 1))
        done
        log_debug "Sourced $count installer module(s)"
    else
        log_warning "Installers directory not found: $installer_dir"
    fi

    log_debug "Registry initialized with ${#TOOLS[@]} tool(s) in ${#CATEGORIES[@]} categories"
}

# ------------------------------------------------------------------------------
# Category Query Functions
# ------------------------------------------------------------------------------

# Get list of all category IDs
# Usage: registry_get_categories → prints category IDs, one per line
registry_get_categories() {
    local entry
    for entry in "${CATEGORIES[@]}"; do
        echo "${entry%%:*}"
    done
}

# Get display name of a category
# Usage: registry_get_category_name <category_id>
registry_get_category_name() {
    local target="$1"
    local entry
    for entry in "${CATEGORIES[@]}"; do
        local id="${entry%%:*}"
        if [ "$id" = "$target" ]; then
            local rest="${entry#*:}"
            echo "${rest%%:*}"
            return 0
        fi
    done
    echo "$target"
}

# Get description of a category
# Usage: registry_get_category_description <category_id>
registry_get_category_description() {
    local target="$1"
    local entry
    for entry in "${CATEGORIES[@]}"; do
        local id="${entry%%:*}"
        if [ "$id" = "$target" ]; then
            local rest="${entry#*:}"
            echo "${rest#*:}"
            return 0
        fi
    done
    echo ""
}

# ------------------------------------------------------------------------------
# Tool Query Functions
# ------------------------------------------------------------------------------

# Get all tool IDs for a given category
# Usage: registry_get_tools <category_id> → prints tool IDs, one per line
registry_get_tools() {
    local target_category="$1"
    local entry
    for entry in "${TOOLS[@]}"; do
        local category="${entry%%:*}"
        if [ "$category" = "$target_category" ]; then
            local rest="${entry#*:}"
            echo "${rest%%:*}"
        fi
    done
}

# Get display name of a tool
# Usage: registry_get_tool_name <category_id> <tool_id>
registry_get_tool_name() {
    local target_category="$1"
    local target_tool="$2"
    local entry
    for entry in "${TOOLS[@]}"; do
        local category="${entry%%:*}"
        local rest="${entry#*:}"
        local tool_id="${rest%%:*}"
        if [ "$category" = "$target_category" ] && [ "$tool_id" = "$target_tool" ]; then
            rest="${rest#*:}"
            echo "${rest%%:*}"
            return 0
        fi
    done
    echo "$target_tool"
}

# Get description of a tool (calls the tool's __description function)
# Usage: registry_get_tool_description <category_id> <tool_id>
registry_get_tool_description() {
    local category="$1"
    local tool="$2"
    local func="${category}__${tool}__description"

    if declare -f "$func" &>/dev/null; then
        "$func"
    else
        # Fallback to display name from registry
        registry_get_tool_name "$category" "$tool"
    fi
}

# Check if a tool should always run (even if "installed")
# Usage: registry_is_always_run <category_id> <tool_id>
registry_is_always_run() {
    local target_category="$1"
    local target_tool="$2"
    local entry
    for entry in "${TOOLS[@]}"; do
        local category="${entry%%:*}"
        local rest="${entry#*:}"
        local tool_id="${rest%%:*}"
        if [ "$category" = "$target_category" ] && [ "$tool_id" = "$target_tool" ]; then
            rest="${rest#*:}"
            local always_run="${rest#*:}"
            [ "$always_run" = "true" ]
            return $?
        fi
    done
    return 1
}

# Check if a tool is installed (calls the tool's __is_installed function)
# Results are cached in _INSTALL_CACHE to avoid expensive repeated checks.
# Usage: registry_is_tool_installed <category_id> <tool_id>
registry_is_tool_installed() {
    local category="$1"
    local tool="$2"
    local cache_key="${category}:${tool}"

    # Return cached result if available
    if [[ -v _INSTALL_CACHE["$cache_key"] ]]; then
        return "${_INSTALL_CACHE[$cache_key]}"
    fi

    local func="${category}__${tool}__is_installed"
    local result=1
    if declare -f "$func" &>/dev/null; then
        "$func"
        result=$?
    fi

    _INSTALL_CACHE["$cache_key"]=$result
    return $result
}

# Clear the entire installation status cache
# Usage: registry_clear_cache
registry_clear_cache() {
    _INSTALL_CACHE=()
}

# Clear cache for a specific tool (e.g. after installing it)
# Usage: registry_clear_tool_cache <category_id> <tool_id>
registry_clear_tool_cache() {
    local category="$1"
    local tool="$2"
    unset '_INSTALL_CACHE["${category}:${tool}"]'
}

# Install a tool (calls the tool's __install function)
# Wraps in error isolation to prevent one tool failure from stopping others
# Usage: registry_install_tool <category_id> <tool_id>
registry_install_tool() {
    local category="$1"
    local tool="$2"
    local func="${category}__${tool}__install"

    if declare -f "$func" &>/dev/null; then
        # Run in subshell for error isolation
        (
            set +e
            "$func"
            exit $?
        )
        return $?
    fi

    log_error "Install function not found: $func"
    return 1
}

# ------------------------------------------------------------------------------
# Selection Management
# ------------------------------------------------------------------------------

# Add a tool to the selected list
# Usage: registry_select_tool <category_id> <tool_id>
registry_select_tool() {
    local category="$1"
    local tool="$2"
    SELECTED_TOOLS+=("${category}:${tool}")
}

# Clear all selections
registry_clear_selections() {
    SELECTED_TOOLS=()
}

# Get all selected tools
# Usage: registry_get_all_selected_tools → prints "category:tool" pairs, one per line
registry_get_all_selected_tools() {
    local entry
    for entry in "${SELECTED_TOOLS[@]}"; do
        echo "$entry"
    done
}

# Get count of selected tools
registry_get_selected_count() {
    echo "${#SELECTED_TOOLS[@]}"
}

# ------------------------------------------------------------------------------
# Statistics
# ------------------------------------------------------------------------------

# Get count of tools in a category
# Usage: registry_get_tool_count <category_id>
registry_get_tool_count() {
    local target_category="$1"
    local count=0
    local entry
    for entry in "${TOOLS[@]}"; do
        local category="${entry%%:*}"
        if [ "$category" = "$target_category" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# Get count of not-yet-installed tools in a category
# Usage: registry_get_new_tool_count <category_id>
registry_get_new_tool_count() {
    local target_category="$1"
    local count=0
    local entry
    for entry in "${TOOLS[@]}"; do
        local category="${entry%%:*}"
        if [ "$category" = "$target_category" ]; then
            local rest="${entry#*:}"
            local tool_id="${rest%%:*}"
            if ! registry_is_tool_installed "$target_category" "$tool_id"; then
                count=$((count + 1))
            fi
        fi
    done
    echo "$count"
}