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
    if is_silent $1; then
        echo -e "${BLUE}►► Updating all OS packages in silent mode...${NC}"
        output_redirection="> /dev/null 2>&1"
    else
        echo -e "${BLUE}►► Updating all OS packages...${NC}"
        output_redirection=""
    fi
    eval "sudo apt -qq -y update $output_redirection"
    eval "sudo apt -qq -y full-upgrade $output_redirection"
    eval "sudo apt -qq -y autoremove $output_redirection"
}

# Installs packages using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
# $@ - All the arguments, which should be the names of packages to install.
function install_packages() {
    if is_silent $1; then
        output_redirection='> /dev/null 2>&1'
        shift
    else
        output_redirection=''
    fi
    
    check_apt
    echo -e "${BLUE}►► Installing dependencies...${NC}"
    eval "sudo apt -qq -y update ${output_redirection}"
    for package in "$@"; do
        eval "sudo apt -qq -y install ${package} ${output_redirection}"
    done
}

# Set the system timezone.
# Parameters:
# $1 - The first argument, which should be a valid timezone, e.g. "Europe/Amsterdam".
function set_timezone() {
    local timezone=$1
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        sudo ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null
        sudo dpkg-reconfigure -f noninteractive tzdata > /dev/null
    else
        echo -e "${RED} Error: Invalid timezone: ${timezone}${NC}"
    fi
}

# -----------------------------------------------------------------
# @ TODO: REFACTOR THIS TO A MANDATORY COMMAND OR FILE FUNCTION
# -----------------------------------------------------------------
# Checks the installation of packages that provide required commands
# Parameters:
# $@ - All the arguments, which should be the names of the commands to check.
function check_required_command {
  for cmd in "$@"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo -e "${RED} Error: Installation failed. $cmd is not successfully installed.${NC}"
      INSTALL_FAILED=true
    fi
  done
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

  while true; do
    read -p "${prompt} [default: ${default_value}]: " input
    input="${input:-$default_value}"

    case $var_type in
      'y/n')
        if [[ "$input" =~ ^(y|n)$ ]]; then
          break
        else
          echo "Invalid input. Please enter y or n."
        fi
        ;;
      'num')
        if [[ "$input" =~ ^[0-9]+$ ]]; then
          break
        else
          echo "Invalid input. Please enter a number."
        fi
        ;;
      'str')
        if [[ -n "$input" ]]; then
          break
        else
          echo "Invalid input. Please enter a string."
        fi
        ;;
      'email')
        if [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
          break
        else
          echo "Invalid input. Please enter a valid e-mail address."
        fi
        ;;
      'host')
        if [[ "$input" =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]]; then
          break
        else
          echo "Invalid input. Please enter a valid hostname."
        fi
        ;;  
      *)
        echo "Unknown validation type: $var_type"
        return 1
        ;;
    esac
  done

  eval "$var_name=\"$input\""
}
