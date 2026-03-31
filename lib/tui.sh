#!/usr/bin/env bash
# ==============================================================================
# lib/tui.sh — TUI Functions (whiptail)
# ==============================================================================
# Wrapper functions for whiptail dialogs: checklist, gauge, msgbox, yesno.
# Implements the two-level TUI flow: category → tool → confirm → install → summary
# ==============================================================================

# ------------------------------------------------------------------------------
# Terminal Size Detection
# ------------------------------------------------------------------------------

# Detect terminal dimensions and set dialog sizes
tui_detect_size() {
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

    # Dialog dimensions with sensible limits
    DIALOG_HEIGHT=$((TERM_HEIGHT - 4))
    DIALOG_WIDTH=$((TERM_WIDTH - 10))

    # Clamp to reasonable range
    [ "$DIALOG_HEIGHT" -lt 15 ] && DIALOG_HEIGHT=15
    [ "$DIALOG_HEIGHT" -gt 40 ] && DIALOG_HEIGHT=40
    [ "$DIALOG_WIDTH" -lt 50 ] && DIALOG_WIDTH=50
    [ "$DIALOG_WIDTH" -gt 90 ] && DIALOG_WIDTH=90

    # List height for checklist/menu items
    LIST_HEIGHT=$((DIALOG_HEIGHT - 8))
    [ "$LIST_HEIGHT" -lt 5 ] && LIST_HEIGHT=5
}

# Initialize TUI sizes on source
tui_detect_size

# ------------------------------------------------------------------------------
# Basic whiptail Helpers
# ------------------------------------------------------------------------------

# Display a message box
# Usage: tui_msgbox <title> <message>
tui_msgbox() {
    local title="$1"
    local message="$2"

    whiptail \
        --title "$title" \
        --msgbox "$message" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

# Display a yes/no dialog
# Usage: tui_yesno <title> <message> → returns 0 for Yes, 1 for No
tui_yesno() {
    local title="$1"
    local message="$2"

    whiptail \
        --title "$title" \
        --yesno "$message" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

# Display a progress gauge
# Usage: echo <percent> | tui_gauge <title> <message>
# Or pipe a sequence of percentages for animated progress
tui_gauge() {
    local title="$1"
    local message="$2"

    whiptail \
        --title "$title" \
        --gauge "$message" \
        8 "$DIALOG_WIDTH" 0
}

# Display an info box (non-blocking, disappears immediately)
# Usage: tui_infobox <title> <message>
tui_infobox() {
    local title="$1"
    local message="$2"

    whiptail \
        --title "$title" \
        --infobox "$message" \
        8 "$DIALOG_WIDTH"
}

# ------------------------------------------------------------------------------
# Welcome Screen
# ------------------------------------------------------------------------------

# Display welcome message with project info
tui_welcome() {
    local version="1.0.0"
    local ubuntu_ver
    ubuntu_ver="$(get_ubuntu_version)"
    local codename
    codename="$(get_ubuntu_codename)"

    whiptail \
        --title "Dev Tool Installer v${version}" \
        --msgbox "\
Welcome to Dev Tool Installer for Ubuntu!

This script will help you set up a complete development
environment on your Ubuntu desktop.

System Info:
  OS:       Ubuntu ${ubuntu_ver} (${codename})
  User:     $(whoami)
  Log file: ${LOG_FILE}

Press OK to continue." \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

# ------------------------------------------------------------------------------
# Category Selection
# ------------------------------------------------------------------------------

# Display category checklist
# User selects which categories they want to install/configure
# Returns selected category IDs via stdout
tui_category_checklist() {
    tui_detect_size

    local -a checklist_args=()
    local entry

    for entry in "${CATEGORIES[@]}"; do
        local category_id="${entry%%:*}"
        local rest="${entry#*:}"
        local display_name="${rest%%:*}"
        local description="${rest#*:}"

        # Count tools and new (not installed) tools
        local total_count
        total_count=$(registry_get_tool_count "$category_id")
        local new_count
        new_count=$(registry_get_new_tool_count "$category_id")

        # Build display string
        local label="${display_name} (${total_count} tools, ${new_count} new)"

        # Default: check if category has new tools
        local checked="OFF"
        if [ "$new_count" -gt 0 ]; then
            checked="ON"
        fi

        checklist_args+=("$category_id" "$label" "$checked")
    done

    # Show nothing if no categories
    if [ ${#checklist_args[@]} -eq 0 ]; then
        tui_msgbox "No Categories" "No tool categories found. Please add installer modules to the installers/ directory."
        return 1
    fi

    local result
    result=$(whiptail \
        --title "Dev Tool Installer v1.0" \
        --checklist "Select categories to install:" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$LIST_HEIGHT" \
        "${checklist_args[@]}" \
        3>&1 1>&2 2>&3) || return 1

    # Parse whiptail output: remove quotes and output one per line
    echo "$result" | tr -d '"' | tr ' ' '\n'
}

# ------------------------------------------------------------------------------
# Tool Selection (Per-Category)
# ------------------------------------------------------------------------------

# Display tool checklist for a specific category
# Shows installed status next to each tool
# Usage: tui_tool_checklist <category_id> → prints selected tool IDs
tui_tool_checklist() {
    local category_id="$1"
    local category_name
    category_name=$(registry_get_category_name "$category_id")

    tui_detect_size

    local -a checklist_args=()
    local tools
    tools=$(registry_get_tools "$category_id")

    # Return early if no tools in this category
    if [ -z "$tools" ]; then
        log_debug "No tools registered for category: $category_id"
        return 0
    fi

    local tool_id
    while IFS= read -r tool_id; do
        [ -z "$tool_id" ] && continue

        local display_name
        display_name=$(registry_get_tool_name "$category_id" "$tool_id")

        # Check installed status
        local status_icon="✗ not installed"
        local checked="ON"
        if registry_is_tool_installed "$category_id" "$tool_id"; then
            status_icon="✓ installed"
            # Still check always_run tools by default
            if registry_is_always_run "$category_id" "$tool_id"; then
                checked="ON"
            else
                checked="OFF"
            fi
        fi

        local label="${display_name} [${status_icon}]"
        checklist_args+=("$tool_id" "$label" "$checked")
    done <<< "$tools"

    if [ ${#checklist_args[@]} -eq 0 ]; then
        return 0
    fi

    local result
    result=$(whiptail \
        --title "$category_name" \
        --checklist "Select tools to install:" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$LIST_HEIGHT" \
        "${checklist_args[@]}" \
        3>&1 1>&2 2>&3) || return 1

    # Parse whiptail output
    echo "$result" | tr -d '"' | tr ' ' '\n'
}

# ------------------------------------------------------------------------------
# Confirmation Dialog
# ------------------------------------------------------------------------------

# Show confirmation dialog with summary of selected tools
# Usage: tui_confirm_install → returns 0 for Yes, 1 for No
tui_confirm_install() {
    local count
    count=$(registry_get_selected_count)

    if [ "$count" -eq 0 ]; then
        tui_msgbox "Nothing Selected" "No tools were selected for installation."
        return 1
    fi

    # Build summary text
    local summary="The following ${count} tool(s) will be installed/configured:\n\n"
    local current_category=""
    local entry

    for entry in $(registry_get_all_selected_tools); do
        local category="${entry%%:*}"
        local tool="${entry#*:}"

        # Add category header when category changes
        if [ "$category" != "$current_category" ]; then
            local cat_name
            cat_name=$(registry_get_category_name "$category")
            summary+="\n--- ${cat_name} ---\n"
            current_category="$category"
        fi

        local tool_name
        tool_name=$(registry_get_tool_name "$category" "$tool")
        summary+="  • ${tool_name}\n"
    done

    summary+="\nProceed with installation?"

    whiptail \
        --title "Confirm Installation" \
        --yesno "$summary" \
        "$DIALOG_HEIGHT" "$DIALOG_WIDTH"
}

# ------------------------------------------------------------------------------
# Installation Progress
# ------------------------------------------------------------------------------

# Run installation of all selected tools with progress gauge
# Usage: tui_run_installation
tui_run_installation() {
    local total
    total=$(registry_get_selected_count)

    if [ "$total" -eq 0 ]; then
        return 0
    fi

    INSTALL_TOTAL=$total
    INSTALL_SUCCESS=0
    INSTALL_FAILED=0
    INSTALL_SKIPPED=0
    FAILED_TOOLS=()
    SUCCESS_TOOLS=()
    SKIPPED_TOOLS=()

    local current=0
    local entry

    log_info "--- Installation Started ---"
    log_info "Total tools to process: $total"

    for entry in $(registry_get_all_selected_tools); do
        local category="${entry%%:*}"
        local tool="${entry#*:}"
        local tool_name
        tool_name=$(registry_get_tool_name "$category" "$tool")

        current=$((current + 1))
        local percent=$(( (current - 1) * 100 / total ))

        # Show progress via infobox (gauge can't be easily updated from a loop)
        tui_infobox "Installing..." "[${current}/${total}] Installing ${tool_name}..."

        log_info "[${current}/${total}] Installing ${tool_name}..."

        # Check if already installed and not always_run
        if registry_is_tool_installed "$category" "$tool" && \
           ! registry_is_always_run "$category" "$tool"; then
            log_info "Skipping ${tool_name} (already installed)"
            INSTALL_SKIPPED=$((INSTALL_SKIPPED + 1))
            SKIPPED_TOOLS+=("$tool_name")
            continue
        fi

        # Run the installation
        if registry_install_tool "$category" "$tool"; then
            log_success "Installed: ${tool_name}"
            INSTALL_SUCCESS=$((INSTALL_SUCCESS + 1))
            SUCCESS_TOOLS+=("$tool_name")
        else
            log_error "Failed: ${tool_name}"
            INSTALL_FAILED=$((INSTALL_FAILED + 1))
            FAILED_TOOLS+=("$tool_name")
        fi
    done

    log_info "--- Installation Completed ---"
}

# Display progress using whiptail gauge (alternative approach using pipe)
# Usage: tui_show_progress <title> <current> <total> <tool_name>
tui_show_progress() {
    local title="$1"
    local current="$2"
    local total="$3"
    local tool_name="$4"
    local percent=$(( current * 100 / total ))

    echo -e "XXX\n${percent}\n[${current}/${total}] Installing ${tool_name}...\nXXX"
}

# ------------------------------------------------------------------------------
# Summary Screen
# ------------------------------------------------------------------------------

# Display installation summary
tui_show_summary() {
    local summary=""
    summary+="✓ Succeeded: ${INSTALL_SUCCESS}\n"
    summary+="✗ Failed:    ${INSTALL_FAILED}\n"
    summary+="~ Skipped:   ${INSTALL_SKIPPED}  (already installed)\n"
    summary+="─────────────────\n"
    summary+="Total:       ${INSTALL_TOTAL}\n"

    # Show failed tools if any
    if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
        summary+="\nFailed tools:\n"
        local tool
        for tool in "${FAILED_TOOLS[@]}"; do
            summary+="  ✗ ${tool}\n"
        done
    fi

    summary+="\nLog file: ${LOG_FILE}"

    tui_msgbox "Installation Summary" "$summary"
}

# ------------------------------------------------------------------------------
# Logout Prompt
# ------------------------------------------------------------------------------

# Ask user if they want to logout to apply changes
# (Docker group, font changes, PATH updates, etc.)
tui_ask_logout() {
    local message="Some changes may require logout to take effect:\n"
    message+="  - Docker group membership\n"
    message+="  - Font changes\n"
    message+="  - PATH updates\n"
    message+="\nLog out now?"

    if tui_yesno "Session Restart" "$message"; then
        log_info "User chose to logout"
        # Give time to read the message
        sleep 1
        gnome-session-quit --logout --no-prompt 2>/dev/null || \
            loginctl terminate-user "$(whoami)" 2>/dev/null || \
            log_warning "Could not initiate logout. Please logout manually."
    else
        log_info "User chose not to logout"
        echo ""
        echo -e "${YELLOW}Remember to logout/restart to apply all changes.${RESET}"
    fi
}

# ------------------------------------------------------------------------------
# Main TUI Flow
# ------------------------------------------------------------------------------

# Run the complete TUI flow: categories → tools → confirm → install → summary
tui_main_flow() {
    # Step 1: Welcome
    tui_welcome

    # Step 2: Category selection
    local selected_categories
    selected_categories=$(tui_category_checklist) || {
        log_info "User cancelled category selection"
        return 0
    }

    if [ -z "$selected_categories" ]; then
        tui_msgbox "Nothing Selected" "No categories were selected. Exiting."
        return 0
    fi

    # Step 3: For each selected category, show tool checklist
    registry_clear_selections
    local category
    while IFS= read -r category; do
        [ -z "$category" ] && continue

        local selected_tools
        selected_tools=$(tui_tool_checklist "$category") || {
            log_info "User cancelled tool selection for: $category"
            continue
        }

        # Register selected tools
        local tool_id
        while IFS= read -r tool_id; do
            [ -z "$tool_id" ] && continue
            registry_select_tool "$category" "$tool_id"
        done <<< "$selected_tools"
    done <<< "$selected_categories"

    # Step 4: Confirm
    if ! tui_confirm_install; then
        log_info "User cancelled installation"
        return 0
    fi

    # Step 5: Install
    tui_run_installation

    # Step 6: Summary
    tui_show_summary

    # Step 7: Ask logout if needed
    if [ "$INSTALL_SUCCESS" -gt 0 ]; then
        tui_ask_logout
    fi
}