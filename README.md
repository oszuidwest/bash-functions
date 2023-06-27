# bash-functions
This is a Bash shell script that provides a set of common utility functions to ease and streamline the scripting process in Unix-like environments.

## Function Definitions

1. `set_colors`: Initializes color variables for terminal text.
2. `is_silent`: Checks if the first argument is 'silent'. If it is, output from commands can be suppressed.
3. `is_this_linux`: Checks if the script is running on a Linux distribution.
4. `is_this_os_64bit`: Checks if the system is a 64-bit system.
5. `check_rpi_model`: Checks if the script is running on a Raspberry Pi with a model number higher than the input parameter.
6. `are_we_root`: Checks if the script is running as root.
7. `check_apt`: Checks if the 'apt' package manager is present.
8. `update_os`: Updates the operating system using the 'apt' package manager.
9. `install_packages`: Installs packages using the 'apt' package manager. 
10. `set_timezone`: Sets the system timezone.
11. `check_required_command`: Checks if the system has specific commands installed. (WIP)
12. `ask_user`: Prompts the user for input with different input types including 'y/n', 'num', 'str', and 'email'.

## How to Use

These functions can be imported and used in your own Bash scripts. 

To import the functions, use the following line in your script:

```bash
# Download the functions library
if ! curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/oszuidwest/bash-functions/main/common-functions.sh; then
  echo -e  "*** Failed to download functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions file
source /tmp/functions.sh
```
