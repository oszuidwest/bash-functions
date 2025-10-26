# Initialize color variables for terminal text.
# No parameters.
function set_colors() {
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[1;36m'
    NC='\033[0m'
    BOLD='\033[1m'
    UNDERLINE='\033[4m'
}

# Returns the appropriate sudo command based on user privileges
# Returns empty string if running as root, "sudo -E" if not
# Usage: local sudo_cmd=$(get_sudo_if_needed)
function get_sudo_if_needed() {
    if [[ "$(id -u)" -eq 0 ]]; then
        # Running as root, no sudo needed
        echo ""
    else
        # Not root, need sudo with environment preservation
        echo "sudo -E"
    fi
}

# Function to backup a file if it exists
# Parameters:
# $1 - The path to the file to backup
function backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_path="${file}.bak.$(date +%Y%m%d%H%M%S)"
        local sudo_cmd=$(get_sudo_if_needed)
        
        # Copy with or without sudo based on privileges
        ${sudo_cmd} cp "$file" "$backup_path"
        
        # Verify the backup was created
        if [ -f "$backup_path" ]; then
            echo -e "${YELLOW}Backup of '$file' created at '$backup_path'.${NC}"
        else
            echo -e "${RED}Failed to create backup of '$file'.${NC}"
            return 1
        fi
    fi
}

# Checks if the first argument is 'silent'.
# Parameters:
# $1 - The first argument, which should be "silent" to suppress output.
function is_silent() {
    [[ $1 == "silent" ]]
}

# Checks if this is a Linux distribution
# No parameters.
function is_this_linux() {
  if [ "$(uname -s)" != "Linux" ]; then
    echo -e "${RED}Error: this script does not support '$(uname -s)' Operating System. Exiting.${NC}"
    exit 1
  fi
}

# Checks if this system is 64-bit
# No parameters.
function is_this_os_64bit() {
  if [[ $(getconf LONG_BIT) -ne 64 ]]; then
    echo -e "${RED}Error: 64-bit operating system required.${NC}"
    exit 1
  fi
}

# Checks if this is a Raspberry Pi
# Parameters:
# $1 - The minimal Raspberry Pi model required
function check_rpi_model() {
  if ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: the argument provided is not a number. Please enter a Raspberry Pi model number.${NC}"
    exit 1
  fi

  local model=$(tr -d '\0' < /proc/device-tree/model)

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
    echo -e "${YELLOW}This script is only tested on a Raspberry Pi $1 or higher. Press Enter to continue anyway...${NC}"
    read -r
  fi
}

# Check user privileges
# Takes one parameter: "privileged" to check if the user is root, "regular" to check if the user is not root.
function check_user_privileges() {
  local required_privilege="$1"

  if [[ "$required_privilege" == "privileged" && "$(id -u)" -ne 0 ]]; then
    echo -e "\e[31mError: this script must be run as root. Please run 'sudo su' first.\e[0m"
    exit 1
  elif [[ "$required_privilege" == "regular" && "$(id -u)" -eq 0 ]]; then
    echo -e "\e[31mError: this script must not be run as root. Please run as a regular user.\e[0m"
    exit 1
  fi
}

# Check if the 'apt' package manager is present.
# No parameters.
function check_apt() {
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}Error: apt is not installed. Exiting...${NC}"
        exit 1
    fi
}

# Update the OS using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
function update_os() {
    check_apt
    
    # Determine if we need sudo
    local sudo_cmd=$(get_sudo_if_needed)
    
    if is_silent "$1"; then
        echo -e "${BLUE}►► Updating all OS packages in silent mode...${NC}"
        export DEBIAN_FRONTEND="noninteractive"
        export DEBCONF_NONINTERACTIVE_SEEN=true
        local apt_opts="-qq -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
        local output_redirection="> /dev/null 2>&1"
    else
        echo -e "${BLUE}►► Updating all OS packages...${NC}"
        local apt_opts="-qq -y"
        local output_redirection=""
    fi
    eval "${sudo_cmd} apt ${apt_opts} update ${output_redirection}"
    eval "${sudo_cmd} apt ${apt_opts} full-upgrade ${output_redirection}"
    eval "${sudo_cmd} apt ${apt_opts} autoremove ${output_redirection}"
}

# Installs packages using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
# $@ - All the arguments, which should be the names of packages to install.
function install_packages() {
    local redirect=""
    local apt_opts="-y"
    
    # Determine if we need sudo
    local sudo_cmd=$(get_sudo_if_needed)
    
    if is_silent "$1"; then
        export DEBIAN_FRONTEND="noninteractive"
        export DEBCONF_NONINTERACTIVE_SEEN=true
        redirect="> /dev/null 2>&1"
        apt_opts+=" -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
        shift
    fi

    check_apt
    echo -e "${BLUE}►► Installing dependencies...${NC}"
    
    eval "${sudo_cmd} apt-get update ${redirect}"
    for package in "$@"; do
        eval "${sudo_cmd} apt-get install ${apt_opts} ${package} ${redirect}"
    done
}

# Set the system timezone.
# Parameters:
# $1 - The first argument, which should be a valid timezone, e.g. "Europe/Amsterdam".
function set_timezone() {
    local timezone=$1
    local sudo_cmd=$(get_sudo_if_needed)
    
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        eval "${sudo_cmd} ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null"
        eval "${sudo_cmd} dpkg-reconfigure -f noninteractive tzdata > /dev/null"
    else
        echo -e "${RED} Error: Invalid timezone: ${timezone}${NC}"
    fi
}

# Check for one or more required tools, or exit
# Parameters:
# $@ - The names of the commands/tools to check for
function require_tool() {
    local missing_tools=()
    
    # Check each tool
    for tool in "$@"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    # If tools are missing, show appropriate message based on count
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Required tool(s) missing!${NC}\n"
        
        if [ ${#missing_tools[@]} -eq 1 ]; then
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
        if ! [[ "$input" =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][a-zA-Z0-9\-]*[A-Za-z0-9])$ ]]; then
          echo "Invalid value for $var_name. Expected a valid hostname."
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
# Parameters:
# $1 - The variable name (will be all caps)
# $2 - The default value for the variable
# $3 - The prompt to display to the user
# $4 - (Optional) The type of the variable (y/n, num, str, email, host). Default is str.
# Example:
# ask_user "MY_NUM" "1" "Please enter a number" "num"
function ask_user {
  local var_name="$1"
  local default_value="$2"
  local prompt="$3"
  local var_type="${4:-str}"

  local input

  # Check if the environment variable is already set and validate
  if [[ -n "${!var_name}" ]]; then
    input="${!var_name}"
    if ! validate_input "$input" "$var_type" "$var_name"; then
        echo "Error: Invalid value for $var_name. Exiting script."
        exit 1
    fi
  else
    while true; do
      read -p "${prompt} [default: ${default_value}]: " input
      input="${input:-$default_value}"
      if validate_input "$input" "$var_type" "$var_name"; then
        break
      fi
    done
  fi
  
  eval "$var_name=\"$input\""
}

# Downloads one or more files using curl with error handling and optional backup
# Usage:
#   Single file: download_file URL DEST DESCRIPTION [backup]
#   Multiple files: download_file -m DEST_DIR DESCRIPTION [backup] URL1:FILENAME1 URL2:FILENAME2 ...
# 
# Examples:
#   # Single file without backup
#   download_file "http://example.com/file.txt" "/tmp/file.txt" "configuration file"
#   
#   # Single file with backup
#   download_file "http://example.com/file.txt" "/tmp/file.txt" "configuration file" backup
#   
#   # Multiple files without backup
#   download_file -m "/tmp" "library files" \
#     "http://example.com/file1.txt:file1.txt" \
#     "http://example.com/file2.txt:file2.txt"
#   
#   # Multiple files with backup
#   download_file -m "/tmp" "library files" backup \
#     "http://example.com/file1.txt:file1.txt" \
#     "http://example.com/file2.txt:file2.txt"
function download_file() {
  local multi_mode=false
  local dest dest_dir description backup_option=""
  local failed=0
  local temp_file
  
  # Check for multi-file mode
  if [[ "$1" == "-m" ]]; then
    multi_mode=true
    shift
    dest_dir="$1"
    description="$2"
    shift 2
    
    # Check for backup option
    if [[ "$1" == "backup" ]]; then
      backup_option="backup"
      shift
    fi
    
    # Download each file
    for url_file in "$@"; do
      # Use a more reliable method to split URL and filename
      # Find the last colon that's not part of http:// or https://
      local filename="${url_file##*:}"
      local url="${url_file%:${filename}}"
      local file_dest="${dest_dir}/${filename}"
      
      # Backup if requested
      if [[ "$backup_option" == "backup" ]]; then
        backup_file "${file_dest}"
      fi
      
      # Check if we need sudo
      local sudo_cmd=$(get_sudo_if_needed)
      if [[ -z "$sudo_cmd" ]]; then
        # Running as root, download directly
        if ! curl -sLo "${file_dest}" "${url}"; then
          echo -e "${RED}Error: Unable to download ${description} - ${filename}.${NC}"
          failed=1
        fi
      else
        # Not root, download to temp file first, then move with sudo
        temp_file=$(mktemp)
        if curl -sLo "${temp_file}" "${url}"; then
          ${sudo_cmd} mv "${temp_file}" "${file_dest}"
          # Preserve original permissions if file existed
          if [ -f "${file_dest}" ]; then
            ${sudo_cmd} chmod --reference="${dest_dir}" "${file_dest}" 2>/dev/null || true
          fi
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
    backup_option="${4:-}"
    
    # Backup if requested
    if [[ "$backup_option" == "backup" ]]; then
      backup_file "${dest}"
    fi
    
    # Check if we need sudo
    local dest_dir=$(dirname "$dest")
    local sudo_cmd=$(get_sudo_if_needed)
    if [[ -z "$sudo_cmd" ]]; then
      # Running as root, download directly
      if ! curl -sLo "${dest}" "${url}"; then
        echo -e "${RED}Error: Unable to download ${description}.${NC}"
        return 1
      fi
    else
      # Not root, download to temp file first, then move with sudo
      temp_file=$(mktemp)
      if curl -sLo "${temp_file}" "${url}"; then
        ${sudo_cmd} mv "${temp_file}" "${dest}"
        # Preserve original permissions if file existed
        if [ -f "${dest}" ]; then
          ${sudo_cmd} chmod --reference="${dest_dir}" "${dest}" 2>/dev/null || true
        fi
      else
        echo -e "${RED}Error: Unable to download ${description}.${NC}"
        rm -f "${temp_file}"
        return 1
      fi
    fi
  fi
  
  return $failed
}
