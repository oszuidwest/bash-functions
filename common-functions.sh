# This function is used to update the OS packages using the apt package manager. 
# It performs three operations: updating the package list, upgrading all upgradable packages, and auto removing unnecessary packages.
# 
# Usage:
# update_os([option])
# 
# Parameters:
# option: (optional) It is a string parameter. When "silent" is passed as the argument, the function will execute 
#         without producing any output on the terminal. Any other string or no argument will result in the function's 
#         operations being outputted to the terminal.
#
# Note: 
# The function utilizes the -qq flag for apt commands, which implies no output except for errors. 

function update_os() {
    # Check if the function should be silent or not
    if [[ $1 == "silent" ]]; then
        output_redirection='> /dev/null 2>&1'
    else
        output_redirection=''
    fi

    # Check if 'apt' is present, exit if it's not
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}apt is not installed. Exiting...${NC}"
        exit 1
    fi

    # Update the OS
    echo -e "${BLUE}►► Updating all OS packages...${NC}"
    apt -qq -y update ${output_redirection}
    apt -qq -y full-upgrade ${output_redirection}
    apt -qq -y autoremove ${output_redirection}
}

# This is a bash function named 'install_packages' which automates the process of installing packages on a system with apt package manager. 
# It accepts any number of arguments, the first of which can be the string "silent" to suppress all output, and the rest are assumed to be package names to install.
#
# If the first argument is "silent", all the output generated by the installation process will be redirected to /dev/null, effectively making the installation process silent.
# If not, the output from the installation process is not suppressed.
#
# After checking for the 'silent' option, it then shifts the argument list, leaving only the package names to be installed.
# It then iterates through all remaining arguments, treating them as package names to install using 'apt-get -qq -y install'.
#
# Example usage:
#     install_packages silent vim emacs
# This will silently install the vim and emacs packages.
#
# Note: This script requires apt package manager to work properly and needs to be run with sufficient permissions to install packages.

function install_packages() {
    # Check if the function should be silent or not
    if [[ $1 == "silent" ]]; then
        output_redirection='> /dev/null 2>&1'
    else
        output_redirection=''
    fi

    # Check if 'apt-get' is present, exit if it's not
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}apt is not installed. Exiting...${NC}"
        exit 1
    fi

    # Remove 'silent' from the arguments list, leaving only the packages
    shift

    # Install the packages
    echo -e "${BLUE}►► Installing dependencies...${NC}"
    for package in "$@"; do
        eval "apt-get -qq -y install ${package} ${output_redirection}"
    done
}

# This function sets the system timezone to a given value.
# It first checks if the provided timezone is valid by looking for a corresponding
# file in /usr/share/zoneinfo/. If the file exists, it is used to set the timezone.
# If it doesn't exist, an error message is printed to the console.
# The function uses dpkg-reconfigure to set the new timezone in a non-interactive way.
#
# Args:
#    timezone: The timezone to set, e.g. "Europe/Amsterdam". It should correspond
#              to a valid file in /usr/share/zoneinfo/.

function set_timezone() {
    local timezone=$1
    
    # Check if the timezone is valid
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        # Notify the user about the timezone change
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        
        # Create a symbolic link between the timezone file and /etc/localtime
        ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null
        
        # Reconfigure the tzdata package with the new timezone in a non-interactive way
        dpkg-reconfigure -f noninteractive tzdata > /dev/null
    else
        # Inform the user about the invalid timezone
        echo "Invalid timezone: ${timezone}"
    fi
}

# This function 'set_colors' is used to initialize color variables that can be used to change text color in the terminal.
# The colors that are set include Green, Red, Yellow, Blue, and No Color.
# These variables can be used to improve the readability and organization of terminal output.
# To use these color variables, call the 'set_colors' function after sourcing the script containing it.

function set_colors() {
    # Set some colors
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[1;34m'
    NC='\033[0m' # No Color
}