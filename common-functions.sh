# shellcheck shell=bash
# common-functions.sh - Utility functions for Debian/Linux environments
# https://github.com/oszuidwest/bash-functions

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# Helper to safely get optional arguments (set -u compatible)
# Usage: local value=$(_get_opt "${1:-}")
function _get_opt() {
    echo "${1:-}"
}

# Helper to check if --silent flag is present in arguments
# Usage: if _has_flag "--silent" "$@"; then ...
function _has_flag() {
    local flag="$1"
    shift
    for arg in "$@"; do
        [[ "$arg" == "$flag" ]] && return 0
    done
    return 1
}

# Helper to remove a flag from arguments and return the rest
# Usage: local args=($(_remove_flag "--silent" "$@"))
function _remove_flag() {
    local flag="$1"
    shift
    for arg in "$@"; do
        [[ "$arg" != "$flag" ]] && echo "$arg"
    done
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Initialize color variables for terminal text.
# Called automatically when library is sourced.
# These variables are exported for use in scripts that source this library.
function set_colors() {
    # shellcheck disable=SC2034  # Variables are used by scripts sourcing this library
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[1;36m'
    NC='\033[0m'
    # shellcheck disable=SC2034  # Variables are used by scripts sourcing this library
    BOLD='\033[1m'
    # shellcheck disable=SC2034  # Variables are used by scripts sourcing this library
    UNDERLINE='\033[4m'
}

# =============================================================================
# SUDO HANDLING
# =============================================================================

# Returns the appropriate sudo command based on user privileges
# Returns empty string if running as root, "sudo" if not
# Usage: local sudo_cmd=$(get_sudo_if_needed)
function get_sudo_if_needed() {
    if [[ "$(id -u)" -eq 0 ]]; then
        echo ""
    else
        echo "sudo"
    fi
}

# =============================================================================
# SYSTEM CHECKS (exit on failure)
# =============================================================================

# Checks if this is a Linux distribution. Exits on failure.
function check_linux() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo -e "${RED}Error: this script does not support '$(uname -s)' Operating System. Exiting.${NC}"
        exit 1
    fi
}

# Checks if this system is 64-bit. Exits on failure.
function check_os_64bit() {
    if [[ $(getconf LONG_BIT) -ne 64 ]]; then
        echo -e "${RED}Error: 64-bit operating system required.${NC}"
        exit 1
    fi
}

# Checks if this is a Raspberry Pi with minimum model requirement.
# Parameters:
# $1 - The minimal Raspberry Pi model required (number)
function check_rpi_model() {
    if ! [[ $1 =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: the argument provided is not a number. Please enter a Raspberry Pi model number.${NC}"
        exit 1
    fi

    local model
    model=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null) || {
        echo -e "${RED}** NOT RUNNING ON A RECOGNIZED RASPBERRY PI MODEL **${NC}"
        exit 1
    }

    local detected_model_number
    if [[ $model =~ Raspberry\ Pi\ ([0-9]+) ]]; then
        detected_model_number=${BASH_REMATCH[1]}
    elif [[ $model == *"Raspberry Pi Model"* ]]; then
        detected_model_number=1
    else
        echo -e "${RED}** NOT RUNNING ON A RECOGNIZED RASPBERRY PI MODEL **${NC}"
        exit 1
    fi

    if ((detected_model_number < $1)); then
        echo -e "${RED}** NOT RUNNING ON A RASPBERRY PI $1 OR HIGHER **${NC}"
        echo -e "${YELLOW}This script is only tested on a Raspberry Pi $1 or higher.${NC}"

        local response
        while true; do
            read -r -p "Continue anyway? (y/n): " response
            case "$response" in
                [Yy]) return 0 ;;
                [Nn]) exit 1 ;;
                *) echo "Please enter 'y' or 'n'." ;;
            esac
        done
    fi
}

# Check user privileges. Exits on failure.
# Parameters:
# $1 - "privileged" to require root, "regular" to require non-root
function check_user_privileges() {
    local required_privilege="$1"

    if [[ "$required_privilege" == "privileged" && "$(id -u)" -ne 0 ]]; then
        echo -e "${RED}Error: this script must be run as root. Please run 'sudo su' first.${NC}"
        exit 1
    elif [[ "$required_privilege" == "regular" && "$(id -u)" -eq 0 ]]; then
        echo -e "${RED}Error: this script must not be run as root. Please run as a regular user.${NC}"
        exit 1
    fi
}

# Check if the 'apt' package manager is present. Exits on failure.
function check_apt() {
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}Error: apt is not installed. Exiting...${NC}"
        exit 1
    fi
}

# Check for one or more required tools. Exits on failure.
# Parameters:
# $@ - The names of the commands/tools to check for
function require_tool() {
    local missing_tools=()

    for tool in "$@"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        echo -e "${RED}Error: Required tool(s) missing!${NC}\n"

        if [[ ${#missing_tools[@]} -eq 1 ]]; then
            echo -e "The following tool is not installed:${YELLOW}"
            echo "→ ${missing_tools[0]}"
        else
            echo -e "The following tools are not installed:${YELLOW}"
            for tool in "${missing_tools[@]}"; do
                echo "→ $tool"
            done
        fi

        echo -e "${NC}"
        exit 1
    fi
}

# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

# Update the OS using 'apt' package manager.
# Parameters:
# --silent - (Optional) Suppress output
function update_os() {
    check_apt

    local silent=false
    if _has_flag "--silent" "$@"; then
        silent=true
    fi

    local sudo_cmd
    sudo_cmd=$(get_sudo_if_needed)

    # Save current env vars
    local old_debian_frontend="${DEBIAN_FRONTEND:-}"
    local old_debconf_seen="${DEBCONF_NONINTERACTIVE_SEEN:-}"

    if [[ "$silent" == true ]]; then
        echo -e "${BLUE}►► Updating all OS packages in silent mode...${NC}"
        export DEBIAN_FRONTEND="noninteractive"
        export DEBCONF_NONINTERACTIVE_SEEN=true

        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            update > /dev/null 2>&1

        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            full-upgrade > /dev/null 2>&1

        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y autoremove > /dev/null 2>&1
    else
        echo -e "${BLUE}►► Updating all OS packages...${NC}"
        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y update
        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y full-upgrade
        ${sudo_cmd:+$sudo_cmd} apt-get -qq -y autoremove
    fi

    # Restore env vars
    if [[ -n "$old_debian_frontend" ]]; then
        export DEBIAN_FRONTEND="$old_debian_frontend"
    else
        unset DEBIAN_FRONTEND 2>/dev/null || true
    fi
    if [[ -n "$old_debconf_seen" ]]; then
        export DEBCONF_NONINTERACTIVE_SEEN="$old_debconf_seen"
    else
        unset DEBCONF_NONINTERACTIVE_SEEN 2>/dev/null || true
    fi
}

# Installs packages using 'apt' package manager.
# Parameters:
# --silent - (Optional) Suppress output
# $@ - Package names to install
function install_packages() {
    local silent=false
    local packages=()

    # Parse arguments
    for arg in "$@"; do
        if [[ "$arg" == "--silent" ]]; then
            silent=true
        else
            packages+=("$arg")
        fi
    done

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No packages specified.${NC}"
        return 1
    fi

    check_apt

    local sudo_cmd
    sudo_cmd=$(get_sudo_if_needed)

    # Save current env vars
    local old_debian_frontend="${DEBIAN_FRONTEND:-}"
    local old_debconf_seen="${DEBCONF_NONINTERACTIVE_SEEN:-}"

    echo -e "${BLUE}►► Installing dependencies...${NC}"

    if [[ "$silent" == true ]]; then
        export DEBIAN_FRONTEND="noninteractive"
        export DEBCONF_NONINTERACTIVE_SEEN=true

        ${sudo_cmd:+$sudo_cmd} apt-get update > /dev/null 2>&1
        ${sudo_cmd:+$sudo_cmd} apt-get install -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            "${packages[@]}" > /dev/null 2>&1
    else
        ${sudo_cmd:+$sudo_cmd} apt-get update
        ${sudo_cmd:+$sudo_cmd} apt-get install -y "${packages[@]}"
    fi

    # Restore env vars
    if [[ -n "$old_debian_frontend" ]]; then
        export DEBIAN_FRONTEND="$old_debian_frontend"
    else
        unset DEBIAN_FRONTEND 2>/dev/null || true
    fi
    if [[ -n "$old_debconf_seen" ]]; then
        export DEBCONF_NONINTERACTIVE_SEEN="$old_debconf_seen"
    else
        unset DEBCONF_NONINTERACTIVE_SEEN 2>/dev/null || true
    fi
}

# =============================================================================
# SYSTEM CONFIGURATION
# =============================================================================

# Set the system timezone.
# Parameters:
# $1 - A valid timezone, e.g. "Europe/Amsterdam"
function set_timezone() {
    local timezone="$1"
    local sudo_cmd
    sudo_cmd=$(get_sudo_if_needed)

    if [[ -f "/usr/share/zoneinfo/${timezone}" ]]; then
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        ${sudo_cmd:+$sudo_cmd} ln -fs "/usr/share/zoneinfo/$timezone" /etc/localtime > /dev/null
        ${sudo_cmd:+$sudo_cmd} dpkg-reconfigure -f noninteractive tzdata > /dev/null
    else
        echo -e "${RED}Error: Invalid timezone: ${timezone}${NC}"
        return 1
    fi
}

# =============================================================================
# INPUT VALIDATION
# =============================================================================

# Validate input based on type
# Parameters:
# $1 - The input value to validate
# $2 - The type of the variable (y/n, num, str, email, host)
# $3 - The name of the variable (used for error messages)
function validate_input() {
    local input="$1"
    local var_type="$2"
    local var_name="$3"

    case $var_type in
        'y/n')
            if ! [[ "$input" =~ ^(y|n)$ ]]; then
                echo "Invalid value for $var_name. Expected 'y' or 'n'."
                return 1
            fi
            ;;
        'num')
            if ! [[ "$input" =~ ^[0-9]+$ ]]; then
                echo "Invalid value for $var_name. Expected a number."
                return 1
            fi
            ;;
        'str')
            if [[ -z "$input" ]]; then
                echo "Invalid value for $var_name. Expected a non-empty string."
                return 1
            fi
            ;;
        'email')
            if ! [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                echo "Invalid value for $var_name. Expected a valid email address."
                return 1
            fi
            ;;
        'host')
            # Accept both hostnames and IPv4 addresses
            local hostname_regex='^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][a-zA-Z0-9\-]*[A-Za-z0-9])$'
            local ipv4_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
            if ! [[ "$input" =~ $hostname_regex || "$input" =~ $ipv4_regex ]]; then
                echo "Invalid value for $var_name. Expected a valid hostname or IP address."
                return 1
            fi
            ;;
        *)
            echo "Unknown validation type: $var_type"
            return 1
            ;;
    esac
}

# Prompt the user for input.
# If the user doesn't provide a value, the default value is assigned.
# Checks environment variables first for non-interactive usage.
# Parameters:
# $1 - The variable name (will be all caps)
# $2 - The default value for the variable
# $3 - The prompt to display to the user
# $4 - (Optional) The type of the variable (y/n, num, str, email, host). Default is str.
# Example:
# ask_user "MY_NUM" "1" "Please enter a number" "num"
function ask_user() {
    local var_name="$1"
    local default_value="$2"
    local prompt="$3"
    local var_type="${4:-str}"

    local input

    # Check if the environment variable is already set and validate
    if [[ -n "${!var_name:-}" ]]; then
        input="${!var_name}"
        if ! validate_input "$input" "$var_type" "$var_name"; then
            echo "Error: Invalid value for $var_name. Exiting script."
            exit 1
        fi
    else
        while true; do
            read -r -p "${prompt} [default: ${default_value}]: " input
            input="${input:-$default_value}"
            if validate_input "$input" "$var_type" "$var_name"; then
                break
            fi
        done
    fi

    # Use nameref instead of eval for safety
    declare -n _ref="$var_name"
    _ref="$input"
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Backup a file if it exists
# Parameters:
# $1 - The path to the file to backup
# Returns:
# 0 - Backup created successfully
# 1 - Backup failed
# 2 - File does not exist (no backup needed)
function backup_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 2
    fi

    local backup_path
    backup_path="${file}.bak.$(date +%Y%m%d%H%M%S)"
    local sudo_cmd
    sudo_cmd=$(get_sudo_if_needed)

    ${sudo_cmd:+$sudo_cmd} cp "$file" "$backup_path"

    if [[ -f "$backup_path" ]]; then
        echo -e "${YELLOW}Backup of '$file' created at '$backup_path'.${NC}"
        return 0
    else
        echo -e "${RED}Failed to create backup of '$file'.${NC}"
        return 1
    fi
}

# Downloads one or more files using curl with error handling and optional backup
# Usage:
#   Single file: download_file URL DEST DESCRIPTION [--backup]
#   Multiple files: download_file -m DEST_DIR DESCRIPTION [--backup] "URL|FILENAME" ...
#
# Note: In multi-mode, use | as delimiter between URL and filename to support URLs with ports
#
# Examples:
#   # Single file without backup
#   download_file "http://example.com/file.txt" "/tmp/file.txt" "configuration file"
#
#   # Single file with backup
#   download_file "http://example.com/file.txt" "/tmp/file.txt" "configuration file" --backup
#
#   # Multiple files with port in URL
#   download_file -m "/tmp" "library files" \
#     "http://server:8080/file1.txt|file1.txt" \
#     "http://server:8080/file2.txt|file2.txt"
function download_file() {
    local dest dest_dir description backup_option=false
    local failed=0
    local temp_file

    # Curl options for robustness
    local curl_opts=(
        --silent
        --show-error
        --location
        --fail
        --connect-timeout 30
        --max-time 300
        --retry 3
        --retry-delay 5
    )

    # Check for multi-file mode
    if [[ "$1" == "-m" ]]; then
        shift
        dest_dir="$1"
        description="$2"
        shift 2

        # Check for backup option
        if [[ "${1:-}" == "--backup" ]]; then
            backup_option=true
            shift
        fi

        local sudo_cmd
        sudo_cmd=$(get_sudo_if_needed)

        # Download each file
        for url_file in "$@"; do
            # Use | as delimiter (safe for URLs)
            local filename="${url_file##*|}"
            local url="${url_file%|*}"
            local file_dest="${dest_dir}/${filename}"

            # Backup if requested
            if [[ "$backup_option" == true ]]; then
                backup_file "${file_dest}" || true
            fi

            if [[ -z "$sudo_cmd" ]]; then
                # Running as root, download directly
                if ! curl "${curl_opts[@]}" -o "${file_dest}" "${url}"; then
                    echo -e "${RED}Error: Unable to download ${description} - ${filename}.${NC}"
                    failed=1
                fi
            else
                # Not root, download to temp file first, then move with sudo
                temp_file=$(mktemp)
                if curl "${curl_opts[@]}" -o "${temp_file}" "${url}"; then
                    ${sudo_cmd} mv "${temp_file}" "${file_dest}"
                    ${sudo_cmd} chmod 644 "${file_dest}"
                else
                    echo -e "${RED}Error: Unable to download ${description} - ${filename}.${NC}"
                    rm -f "${temp_file}"
                    failed=1
                fi
            fi
        done
    else
        # Single file mode
        local url="$1"
        dest="$2"
        description="$3"

        # Check for backup option
        if [[ "${4:-}" == "--backup" ]]; then
            backup_option=true
        fi

        # Backup if requested
        if [[ "$backup_option" == true ]]; then
            backup_file "${dest}" || true
        fi

        local sudo_cmd
        sudo_cmd=$(get_sudo_if_needed)

        if [[ -z "$sudo_cmd" ]]; then
            # Running as root, download directly
            if ! curl "${curl_opts[@]}" -o "${dest}" "${url}"; then
                echo -e "${RED}Error: Unable to download ${description}.${NC}"
                return 1
            fi
        else
            # Not root, download to temp file first, then move with sudo
            temp_file=$(mktemp)
            if curl "${curl_opts[@]}" -o "${temp_file}" "${url}"; then
                ${sudo_cmd} mv "${temp_file}" "${dest}"
                ${sudo_cmd} chmod 644 "${dest}"
            else
                echo -e "${RED}Error: Unable to download ${description}.${NC}"
                rm -f "${temp_file}"
                return 1
            fi
        fi
    fi

    return $failed
}

# =============================================================================
# AUTO-INITIALIZATION
# =============================================================================

# Initialize colors when library is sourced
set_colors
