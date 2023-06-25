# Function to check if the first argument is 'silent'.
# Parameters:
# $1 - The first argument, which should be "silent" to suppress output.
function is_silent() {
    [[ $1 == "silent" ]]
}

# Function that checks if this is a Linux distribution
function is_this_linux() {
  if [ "$(uname -s)" != "Linux" ]; then
    echo -e "${RED}This script does not support '$(uname -s)' Operating System. Exiting.${NC}"
    exit 1
  fi

# Function that checks if this is a Rapsberry Pi
# Parameters:
# $1 - The minimal Raspberry Pi model required
function check_rpi_model() {
  # Check if the first argument is a number
  if ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo -e "${RED}** ERROR: The argument provided is not a number. Please enter a Raspberry Pi model number. **${NC}"
    return 1
  fi

  # Get the Raspberry Pi model number
  local model_number=$(tr -dc '0-9' <<< $(tr -d '\0' </proc/device-tree/model))

  # Check if the Raspberry Pi model number is less than the minimum required
  if ((model_number < $1)); then
    echo -e "${RED}** NOT RUNNING ON A RASPBERRY PI $1 OR HIGHER **${NC}"
    echo -e "${YELLOW}This script is only tested on a Raspberry Pi $1 or higher. Press Enter to continue anyway...${NC}"
    read -r
  fi
}

# Function to check if running as root
function are_we_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${RED}This script must be run as root. Please run 'sudo su' first.${NC}"
    exit 1
  fi
}

# Function to check if the 'apt' package manager is present.
# No parameters.
function check_apt() {
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}apt is not installed. Exiting...${NC}"
        exit 1
    fi
}

# Function to update the OS using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
function update_os() {
    check_apt
    if is_silent $1; then
        echo -e "${BLUE}►► Updating all OS packages in silent mode...${NC}"
        eval "apt -qq -y update > /dev/null 2>&1"
        eval "apt -qq -y full-upgrade > /dev/null 2>&1"
        eval "apt -qq -y autoremove > /dev/null 2>&1"
    else
        echo -e "${BLUE}►► Updating all OS packages...${NC}"
        apt -qq -y update
        apt -qq -y full-upgrade
        apt -qq -y autoremove
    fi
}

# Function to install packages using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
# $@ - All the arguments, which should be the names of packages to install.
function install_packages() {
    is_silent $1 && output_redirection='> /dev/null 2>&1' || output_redirection=''
    check_apt

    shift
    echo -e "${BLUE}►► Installing dependencies...${NC}"
    for package in "$@"; do
        eval "apt -qq -y update ${output_redirection}"
        eval "apt -qq -y install ${package} ${output_redirection}"
    done
}

# Function to set the system timezone.
# Parameters:
# $1 - The first argument, which should be a valid timezone, e.g. "Europe/Amsterdam".
function set_timezone() {
    local timezone=$1
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null
        dpkg-reconfigure -f noninteractive tzdata > /dev/null
    else
        echo "Invalid timezone: ${timezone}"
    fi
}

# Function to initialize color variables for terminal text.
# No parameters.
function set_colors() {
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[1;34m'
    NC='\033[0m'
}
