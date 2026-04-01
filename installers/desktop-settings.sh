#!/usr/bin/env bash
# ==============================================================================
# installers/desktop-settings.sh — Desktop Settings Category
# ==============================================================================
# GNOME desktop preferences and browser privacy policies.
#
# Category: desktop_settings
# Display:  🖥️ Desktop Settings
#
# Tools (3):
#   gnome_settings      — GNOME Desktop Settings (gsettings configuration)
#   browser_policies    — Browser Privacy Policies (managed policy JSON files)
#   libreoffice_config  — LibreOffice Configuration (Thai locale, fonts, A4, .docx)
# ==============================================================================

# REAL_USER and REAL_HOME are defined in lib/core.sh

# ==============================================================================
# Tool: gnome_settings
# ==============================================================================

# Description for GNOME Desktop Settings
desktop_settings__gnome_settings__description() {
    echo "GNOME Desktop Settings — dark theme, hidden files, minimize button, idle timeout"
}

# Check if GNOME settings are applied
# This is an "always_run" tool — returns 1 to always re-apply settings
desktop_settings__gnome_settings__is_installed() {
    # Must have gsettings available (GNOME desktop)
    if ! is_command_available "gsettings"; then
        # No GNOME desktop — consider "installed" (nothing to do)
        return 0
    fi

    # Check key settings to determine if already configured
    local color_scheme
    color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    local show_hidden
    show_hidden=$(gsettings get org.gnome.nautilus.preferences show-hidden-files 2>/dev/null)
    local idle_delay
    idle_delay=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)

    # Check if all critical settings are applied
    if [ "$color_scheme" = "'prefer-dark'" ] && \
       [ "$show_hidden" = "true" ] && \
       [ "$idle_delay" = "uint32 0" ]; then
        return 0
    fi

    return 1
}

# Apply GNOME Desktop Settings via gsettings
desktop_settings__gnome_settings__install() {
    log_info "Applying GNOME Desktop Settings..."

    # ---- Pre-check: gsettings must be available ----
    if ! is_command_available "gsettings"; then
        log_warning "gsettings not available (headless server?). Skipping GNOME settings."
        return 0
    fi

    # gsettings commands need to run as the real user (not root)
    # because they modify the user's dconf database
    local gsettings_cmd="gsettings"

    # If running as root via sudo, we need to run gsettings as the real user
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        gsettings_cmd="su - ${REAL_USER} -c"
    fi

    local errors=0

    # ---- File Manager: Show hidden files ----
    log_info "Setting: Show hidden files in Nautilus"
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "gsettings set org.gnome.nautilus.preferences show-hidden-files true" >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set show-hidden-files"
            errors=$((errors + 1))
        }
    else
        gsettings set org.gnome.nautilus.preferences show-hidden-files true >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set show-hidden-files"
            errors=$((errors + 1))
        }
    fi

    # ---- Dark theme ----
    log_info "Setting: Dark theme (prefer-dark)"
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'" >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set color-scheme"
            errors=$((errors + 1))
        }
        su - "$REAL_USER" -c "gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'" >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set gtk-theme (Yaru-dark may not be available)"
        }
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set color-scheme"
            errors=$((errors + 1))
        }
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set gtk-theme (Yaru-dark may not be available)"
        }
    fi

    # ---- Show battery percentage ----
    log_info "Setting: Show battery percentage"
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "gsettings set org.gnome.desktop.interface show-battery-percentage true" >> "$LOG_FILE" 2>&1 || {
            log_debug "Failed to set show-battery-percentage (may not apply on desktops)"
        }
    else
        gsettings set org.gnome.desktop.interface show-battery-percentage true >> "$LOG_FILE" 2>&1 || {
            log_debug "Failed to set show-battery-percentage (may not apply on desktops)"
        }
    fi

    # ---- Minimize button (GNOME hides it by default!) ----
    log_info "Setting: Window button layout (close, minimize, maximize)"
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'" >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set button-layout"
            errors=$((errors + 1))
        }
    else
        gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set button-layout"
            errors=$((errors + 1))
        }
    fi

    # ---- Disable screen lock timeout (for dev machines) ----
    log_info "Setting: Disable screen idle timeout"
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "gsettings set org.gnome.desktop.session idle-delay 0" >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set idle-delay"
            errors=$((errors + 1))
        }
    else
        gsettings set org.gnome.desktop.session idle-delay 0 >> "$LOG_FILE" 2>&1 || {
            log_warning "Failed to set idle-delay"
            errors=$((errors + 1))
        }
    fi

    # ---- Summary ----
    if [ "$errors" -eq 0 ]; then
        log_success "GNOME Desktop Settings applied successfully"
    else
        log_warning "GNOME Desktop Settings applied with ${errors} warning(s)"
    fi

    return 0
}

# ==============================================================================
# Tool: browser_policies
# ==============================================================================

# Description for Browser Privacy Policies
desktop_settings__browser_policies__description() {
    echo "Browser Privacy Policies — disable password manager, autofill, telemetry for Chrome/Brave/Firefox"
}

# Check if browser policy files exist
# This is an "always_run" tool — returns 1 to always re-apply policies
desktop_settings__browser_policies__is_installed() {
    local chrome_policy="/etc/opt/chrome/policies/managed/dev-tool-installer.json"
    local brave_policy="/etc/brave/policies/managed/dev-tool-installer.json"
    local firefox_policy="/etc/firefox/policies/policies.json"
    local firefox_snap_policy="/etc/firefox/policies/policies.json"

    # Check if at least one policy file exists
    if [ -f "$chrome_policy" ] || [ -f "$brave_policy" ] || [ -f "$firefox_policy" ]; then
        return 0
    fi

    return 1
}

# Deploy browser privacy policy JSON files
desktop_settings__browser_policies__install() {
    log_info "Deploying browser privacy policies..."

    local errors=0

    # ---- Chrome Policies ----
    _deploy_chrome_policies || errors=$((errors + 1))

    # ---- Brave Policies ----
    _deploy_brave_policies || errors=$((errors + 1))

    # ---- Firefox Policies ----
    _deploy_firefox_policies || errors=$((errors + 1))

    # ---- Summary ----
    if [ "$errors" -eq 0 ]; then
        log_success "Browser privacy policies deployed successfully"
    else
        log_warning "Browser privacy policies deployed with ${errors} error(s)"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Helper: Deploy Chrome policies
# ------------------------------------------------------------------------------
_deploy_chrome_policies() {
    local policy_dir="/etc/opt/chrome/policies/managed"
    local policy_file="${policy_dir}/dev-tool-installer.json"

    # Only deploy if Chrome is installed
    if ! is_command_available "google-chrome-stable" && ! is_command_available "google-chrome"; then
        log_debug "Google Chrome not installed, skipping Chrome policies"
        return 0
    fi

    log_info "Deploying Chrome privacy policies..."

    # Create policy directory
    sudo mkdir -p "$policy_dir" >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to create Chrome policy directory: ${policy_dir}"
        return 1
    }

    # Write policy JSON
    sudo tee "$policy_file" > /dev/null << 'CHROME_POLICY'
{
    "PasswordManagerEnabled": false,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "DefaultNotificationsSetting": 2,
    "TranslateEnabled": false,
    "SpellcheckEnabled": true,
    "SpellcheckLanguage": ["en-US", "th"]
}
CHROME_POLICY

    if [ -f "$policy_file" ]; then
        log_success "Chrome policies deployed: ${policy_file}"
        return 0
    else
        log_error "Failed to write Chrome policy file"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Helper: Deploy Brave policies
# ------------------------------------------------------------------------------
_deploy_brave_policies() {
    local policy_dir="/etc/brave/policies/managed"
    local policy_file="${policy_dir}/dev-tool-installer.json"

    # Only deploy if Brave is installed
    if ! is_command_available "brave-browser"; then
        log_debug "Brave Browser not installed, skipping Brave policies"
        return 0
    fi

    log_info "Deploying Brave privacy policies..."

    # Create policy directory
    sudo mkdir -p "$policy_dir" >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to create Brave policy directory: ${policy_dir}"
        return 1
    }

    # Write policy JSON
    sudo tee "$policy_file" > /dev/null << 'BRAVE_POLICY'
{
    "PasswordManagerEnabled": false,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "DefaultNotificationsSetting": 2,
    "TranslateEnabled": false,
    "SpellcheckEnabled": true,
    "SpellcheckLanguage": ["en-US", "th"]
}
BRAVE_POLICY

    if [ -f "$policy_file" ]; then
        log_success "Brave policies deployed: ${policy_file}"
        return 0
    else
        log_error "Failed to write Brave policy file"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Helper: Deploy Firefox policies
# ------------------------------------------------------------------------------
_deploy_firefox_policies() {
    # Only deploy if Firefox is installed
    if ! is_command_available "firefox"; then
        log_debug "Firefox not installed, skipping Firefox policies"
        return 0
    fi

    log_info "Deploying Firefox privacy policies..."

    local deployed=false

    # Detect Firefox installation type (snap vs apt)
    local firefox_snap=false
    if snap list firefox &>/dev/null 2>&1; then
        firefox_snap=true
    fi

    # ---- APT/system Firefox policy ----
    local apt_policy_dir="/etc/firefox/policies"
    local apt_policy_file="${apt_policy_dir}/policies.json"

    log_info "Deploying Firefox policy to: ${apt_policy_file}"
    sudo mkdir -p "$apt_policy_dir" >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to create Firefox policy directory: ${apt_policy_dir}"
    }

    sudo tee "$apt_policy_file" > /dev/null << 'FIREFOX_POLICY'
{
    "policies": {
        "DisablePasswordManager": true,
        "DisableFormHistory": true,
        "OfferToSaveLogins": false,
        "PasswordManagerEnabled": false,
        "DisableTelemetry": true,
        "DisableFirefoxStudies": true,
        "DisablePocket": true,
        "EnableTrackingProtection": {
            "Value": true,
            "Locked": true,
            "Cryptomining": true,
            "Fingerprinting": true
        }
    }
}
FIREFOX_POLICY

    if [ -f "$apt_policy_file" ]; then
        log_success "Firefox policies deployed: ${apt_policy_file}"
        deployed=true
    fi

    # ---- Snap Firefox policy (additional location) ----
    if [ "$firefox_snap" = true ]; then
        local snap_policy_dir="/etc/firefox/policies"
        # For snap Firefox, the same /etc/firefox/policies/policies.json
        # location is used as a system-level override
        # Note: snap Firefox reads from /etc/firefox/policies/policies.json
        # which we already created above
        log_debug "Firefox snap detected — policy at ${apt_policy_file} applies to snap as well"
    fi

    if [ "$deployed" = true ]; then
        return 0
    else
        log_error "Failed to deploy Firefox policies"
        return 1
    fi
}

# ==============================================================================
# Tool: libreoffice_config
# ==============================================================================

# Description for LibreOffice Configuration
desktop_settings__libreoffice_config__description() {
    echo "Configure LibreOffice: Thai locale, TH Sarabun font, A4 paper, .docx default format"
}

# Check if LibreOffice configuration has been applied
desktop_settings__libreoffice_config__is_installed() {
    # If LibreOffice is not installed, nothing to configure — consider "done"
    if ! is_command_available "libreoffice" && ! is_command_available "soffice"; then
        return 0
    fi

    local xcu_file="${REAL_HOME}/.config/libreoffice/4/user/registrymodifications.xcu"

    # If config file doesn't exist yet, not configured
    if [ ! -f "$xcu_file" ]; then
        return 1
    fi

    # Check for our key settings (TH SarabunPSK font and MS Word default format)
    if grep -q "TH SarabunPSK" "$xcu_file" && \
       grep -q "MS Word 2007 XML" "$xcu_file"; then
        return 0
    fi

    return 1
}

# Apply LibreOffice configuration
desktop_settings__libreoffice_config__install() {
    log_info "Configuring LibreOffice..."

    # ---- Pre-check: LibreOffice must be installed ----
    if ! is_command_available "libreoffice" && ! is_command_available "soffice"; then
        log_warning "LibreOffice not installed. Skipping configuration."
        return 0
    fi

    local lo_profile_dir="${REAL_HOME}/.config/libreoffice/4/user"
    local xcu_file="${lo_profile_dir}/registrymodifications.xcu"

    # ---- Kill running LibreOffice processes ----
    if pgrep -f soffice > /dev/null 2>&1; then
        log_info "Closing running LibreOffice instances..."
        pkill -f soffice 2>/dev/null || true
        sleep 2
    fi

    # ---- Initialize profile if it doesn't exist ----
    if [ ! -f "$xcu_file" ]; then
        log_info "LibreOffice profile not found. Initializing (timeout: 30s)..."
        if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
            timeout 30 su - "$REAL_USER" -c "soffice --headless --terminate_after_init" >> "$LOG_FILE" 2>&1 || true
        else
            timeout 30 soffice --headless --terminate_after_init >> "$LOG_FILE" 2>&1 || true
        fi
        sleep 3
        # Kill any leftover process
        pkill -f soffice 2>/dev/null || true
        sleep 1
    fi

    # ---- Verify profile was created ----
    if [ ! -f "$xcu_file" ]; then
        log_error "Failed to initialize LibreOffice profile. File not found: ${xcu_file}"
        return 1
    fi

    # ---- Backup before modification ----
    log_info "Backing up registrymodifications.xcu..."
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        su - "$REAL_USER" -c "cp '${xcu_file}' '${xcu_file}.bak'" >> "$LOG_FILE" 2>&1
    else
        cp "$xcu_file" "${xcu_file}.bak" >> "$LOG_FILE" 2>&1
    fi

    # ---- Define config entries to add ----
    # Each entry is a single <item> XML line
    local -a CONFIG_ENTRIES=(
        # Default Font: TH SarabunPSK for Thai CTL
        '<item oor:path="/org.openoffice.VCL/DefaultFonts/org.openoffice.VCL:LocalizedDefaultFonts['"'"'th'"'"']"><prop oor:name="CTL_DISPLAY" oor:op="fuse"><value>TH SarabunPSK</value></prop></item>'
        '<item oor:path="/org.openoffice.VCL/DefaultFonts/org.openoffice.VCL:LocalizedDefaultFonts['"'"'th'"'"']"><prop oor:name="CTL_HEADING" oor:op="fuse"><value>TH SarabunPSK</value></prop></item>'
        '<item oor:path="/org.openoffice.VCL/DefaultFonts/org.openoffice.VCL:LocalizedDefaultFonts['"'"'th'"'"']"><prop oor:name="CTL_SPREADSHEET" oor:op="fuse"><value>TH SarabunPSK</value></prop></item>'
        '<item oor:path="/org.openoffice.VCL/DefaultFonts/org.openoffice.VCL:LocalizedDefaultFonts['"'"'th'"'"']"><prop oor:name="CTL_TEXT" oor:op="fuse"><value>TH SarabunPSK</value></prop></item>'
        # Default Paper Size: A4
        '<item oor:path="/org.openoffice.Office.Writer/Print"><prop oor:name="PaperSize" oor:op="fuse"><value>A4</value></prop></item>'
        # Thai Locale
        '<item oor:path="/org.openoffice.Office.Linguistic/General"><prop oor:name="DefaultLocale" oor:op="fuse"><value>th</value></prop></item>'
        '<item oor:path="/org.openoffice.Setup/L10N"><prop oor:name="ooLocale" oor:op="fuse"><value>th</value></prop></item>'
        # Auto Save: every 5 minutes
        '<item oor:path="/org.openoffice.Office.Recovery/AutoSave"><prop oor:name="Enabled" oor:op="fuse"><value>true</value></prop></item>'
        '<item oor:path="/org.openoffice.Office.Recovery/AutoSave"><prop oor:name="TimeIntervall" oor:op="fuse"><value>5</value></prop></item>'
        # Default Save Format: MS Office formats
        '<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['"'"'com.sun.star.text.TextDocument'"'"']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>MS Word 2007 XML</value></prop></item>'
        '<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['"'"'com.sun.star.sheet.SpreadsheetDocument'"'"']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>Calc MS Excel 2007 XML</value></prop></item>'
        '<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['"'"'com.sun.star.presentation.PresentationDocument'"'"']"><prop oor:name="ooSetupFactoryDefaultFilter" oor:op="fuse"><value>Impress MS PowerPoint 2007 XML</value></prop></item>'
        # Disable Start Center
        '<item oor:path="/org.openoffice.Setup/Office"><prop oor:name="FirstStartWizardCompleted" oor:op="fuse"><value>true</value></prop></item>'
    )

    # ---- Insert entries (idempotent — skip if already present) ----
    local added=0
    local skipped=0

    for entry in "${CONFIG_ENTRIES[@]}"; do
        # Extract the oor:path and oor:name for duplicate detection
        local oor_path
        oor_path=$(echo "$entry" | grep -oP 'oor:path="[^"]*"')
        local oor_name
        oor_name=$(echo "$entry" | grep -oP 'oor:name="[^"]*"' | head -1)

        # Check if this specific path+name combo already exists
        if grep -qF "$oor_path" "$xcu_file" && grep -qF "$oor_name" "$xcu_file"; then
            # More precise check: both path and name on the same line
            local search_pattern="${oor_path}.*${oor_name}"
            if grep -qP "$search_pattern" "$xcu_file" 2>/dev/null || \
               grep -q "${oor_path}" "$xcu_file" && grep -q "${oor_name}" "$xcu_file"; then
                # Check if this exact combination exists on a single <item> line
                local path_value
                path_value=$(echo "$oor_path" | sed 's/oor:path="//;s/"//')
                local name_value
                name_value=$(echo "$oor_name" | sed 's/oor:name="//;s/"//')
                if grep "oor:path=\"${path_value}\"" "$xcu_file" | grep -q "oor:name=\"${name_value}\""; then
                    log_debug "Entry already exists, skipping: ${path_value} / ${name_value}"
                    skipped=$((skipped + 1))
                    continue
                fi
            fi
        fi

        # Insert entry before the closing </oor:items> tag
        if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
            su - "$REAL_USER" -c "sed -i 's|</oor:items>|${entry}\n</oor:items>|' '${xcu_file}'" >> "$LOG_FILE" 2>&1
        else
            sed -i "s|</oor:items>|${entry}\n</oor:items>|" "$xcu_file" >> "$LOG_FILE" 2>&1
        fi
        added=$((added + 1))
    done

    # ---- Summary ----
    log_success "LibreOffice configured: ${added} entries added, ${skipped} already present"
    return 0
}

# ==============================================================================
# Registration — register all tools in this category
# ==============================================================================

register_tool "desktop_settings" "gnome_settings" "GNOME Desktop Settings" "true"
register_tool "desktop_settings" "browser_policies" "Browser Privacy Policies" "true"
register_tool "desktop_settings" "libreoffice_config" "LibreOffice Configuration" "true"