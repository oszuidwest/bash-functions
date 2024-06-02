# bash-functions
This is a Bash shell library that provides a set of common utility functions to ease and streamline the scripting process in Debian-like environments.

## Function definitions

1. `set_colors`: Initializes color and text variables for terminal text.
2. `is_silent`: Checks if the first parameter is 'silent'. If it is, output from commands can be suppressed.
3. `is_this_linux`: Checks if the script is running on a Linux distribution.
4. `is_this_os_64bit`: Checks if the system is a 64-bit system.
5. `check_rpi_model`: Checks if the script is running on a Raspberry Pi with a model number equal to or higher than the input parameter.
6. `check_user_privileges`: Checks if the script is running with the required privileges. Takes one parameter: "privileged" to check if the user is root, "regular" to check if the user is not root.
7. `check_apt`: Checks if the 'apt' package manager is present.
8. `update_os`: Updates the operating system using the 'apt' package manager.
9. `install_packages`: Installs packages using the 'apt' package manager. 
10. `set_timezone`: Sets the system timezone.
11. `check_required_command`: Checks if the system has specific commands installed. (WIP)
12. `ask_user`: Prompts the user for input with different input types including 'y/n', 'num', 'str', 'email' and 'host'.

## How to Use

These functions can be imported and used in your own Bash scripts. To import the functions, use the following line in your script:

```bash
# Remove old functions libraries and download the latest version
rm -f /tmp/functions.sh
if ! curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/oszuidwest/bash-functions/main/common-functions.sh; then
  echo -e "*** Failed to download functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions file
source /tmp/functions.sh
```

And use it like this:

```bash
# Example
set_colors
echo -e "${GREEN}This text is green!${NC}"
```

Or this to ask the user for input, set a default (n) and validate the input (it should be y or n)

```bash
ask_user "SSL" "n" "Do you want Let's Encrypt to get a certificate for this server? (y/n)" "y/n"
```

All functions are documented inline with their parameters. 

### Note
This script should be run on a Unix-like system, such as Linux, that uses the Bash shell and 'apt' package manager. Certain functions specifically check for these conditions and will exit if they are not met.

Always ensure to use the correct permissions when running scripts that import these functions. For instance, functions like `update_os` and `install_packages` should be run with root permissions.

Be aware that the `ask_user` function does not just prompt the user for input, but also assigns the input to a variable. The name of the variable is passed as the first argument, and the function uses the eval command to assign the input to it. It's important to only pass safe, pre-defined strings as the first argument.

# License
This project is licensed under the MIT License - see the LICENSE.md file for details. 

Bugs, feedback, and ideas are welcome at `techniek@zuidwesttv.nl` or through pull requests.
