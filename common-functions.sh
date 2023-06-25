# Function to check if the first argument is 'silent'.
# Parameters:
# $1 - The first argument, which should be "silent" to suppress output.
function is_silent() {
    [[ $1 == "silent" ]]
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
    is_silent $1 && output_redirection='> /dev/null 2>&1' || output_redirection=''
    check_apt

    echo -e "${BLUE}►► Updating all OS packages...${NC}"
    apt -qq -y update ${output_redirection}
    apt -qq -y full-upgrade ${output_redirection}
    apt -qq -y autoremove ${output_redirection}
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
        eval "apt-get -qq -y install ${package} ${output_redirection}"
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
