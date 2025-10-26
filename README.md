# bash-functions

This is a Bash shell library that provides a set of common utility functions to ease and streamline the scripting process in Debian-like environments.

## Function Reference

### 1. `set_colors`
Initializes color variables for terminal text formatting.

**Parameters:** None

**Example:**
```bash
set_colors
echo -e "${GREEN}Success!${NC}"
```

**Available colors:** GREEN, RED, YELLOW, BLUE, NC (No Color), BOLD, UNDERLINE

---

### 2. `backup_file`
Creates a timestamped backup of a file if it exists.

**Parameters:**
- `$1` - The path to the file to backup

**Example:**
```bash
backup_file "/etc/config.conf"
# Creates: /etc/config.conf.bak.20240206123045
```

---

### 3. `is_silent`
Checks if the first parameter is 'silent' to determine if output should be suppressed.

**Parameters:**
- `$1` - (Optional) Pass "silent" to return true

**Returns:** 0 if silent, 1 otherwise

**Example:**
```bash
if is_silent "$1"; then
    echo "Running in silent mode"
fi
```

---

### 4. `is_this_linux`
Verifies that the script is running on a Linux distribution.

**Parameters:** None

**Exits:** With code 1 if not running on Linux

---

### 5. `is_this_os_64bit`
Verifies that the system is running a 64-bit operating system.

**Parameters:** None

**Exits:** With code 1 if not 64-bit

---

### 6. `check_rpi_model`
Checks if running on a Raspberry Pi and verifies minimum model requirement.

**Parameters:**
- `$1` - The minimal Raspberry Pi model number required

**Example:**
```bash
check_rpi_model 4  # Requires Raspberry Pi 4 or higher
```

---

### 7. `check_user_privileges`
Verifies that the script is running with the correct user privileges.

**Parameters:**
- `$1` - Either "privileged" (must be root) or "regular" (must not be root)

**Example:**
```bash
check_user_privileges "privileged"  # Requires root
check_user_privileges "regular"     # Requires non-root
```

---

### 8. `check_apt`
Verifies that the 'apt' package manager is available.

**Parameters:** None

**Exits:** With code 1 if apt is not installed

---

### 9. `update_os`
Updates the operating system using apt package manager.

**Parameters:**
- `$1` - (Optional) Pass "silent" to suppress output

**Example:**
```bash
update_os          # Verbose mode
update_os silent   # Silent mode
```

---

### 10. `install_packages`
Installs one or more packages using apt package manager.

**Parameters:**
- `$1` - (Optional) Pass "silent" as first argument to suppress output
- `$@` - Package names to install

**Example:**
```bash
install_packages nginx mysql-server php
install_packages silent nginx mysql-server php
```

---

### 11. `set_timezone`
Sets the system timezone.

**Parameters:**
- `$1` - Valid timezone (e.g., "Europe/Amsterdam")

**Example:**
```bash
set_timezone "Europe/Amsterdam"
set_timezone "America/New_York"
```

---

### 12. `require_tool`
Checks for required tools and exits if any are missing.

**Parameters:**
- `$@` - Names of commands/tools to check for

**Example:**
```bash
require_tool git curl wget
```

---

### 13. `validate_input`
Validates input based on a specified type.

**Parameters:**
- `$1` - The input value to validate
- `$2` - The type of the variable: "y/n", "num", "str", "email", or "host"
- `$3` - The name of the variable (used for error messages)

**Returns:** 0 if the input is valid, 1 otherwise.

**Example:**
```bash
if validate_input "yes" "y/n" "CONFIRMATION"; then
    echo "Valid input"
else
    echo "Invalid input"
fi
```

---

### 14. `ask_user`
Prompts the user for input with validation and default values. The function follows two paths:

1. **Environment Variable Path**: If an environment variable with the same name as the variable is set, its value is used directly. The value is validated, and if it is invalid, the script exits immediately with an error message.

2. **User Input Path**: If no environment variable is set, the user is prompted for input. The function re-asks the question until valid input is provided.

This ensures that the script can operate non-interactively when environment variables are pre-set, while still enforcing validation.

**Parameters:**
- `$1` - Variable name to store the result
- `$2` - Default value if user presses Enter
- `$3` - Prompt message to display
- `$4` - (Optional) Validation type: "y/n", "num", "str", "email", or "host" (default: "str")

**Example:**
```bash
ask_user "USERNAME" "admin" "Enter username" "str"
ask_user "PORT" "8080" "Enter port number" "num"
ask_user "ENABLE_SSL" "y" "Enable SSL?" "y/n"
ask_user "EMAIL" "admin@example.com" "Enter email" "email"
ask_user "HOSTNAME" "server.local" "Enter hostname" "host"
```

---

### 14. `download_file`
Downloads files using curl with error handling and optional backup.

**Single file mode:**
```bash
download_file URL DEST DESCRIPTION [backup]
```

**Multi-file mode:**
```bash
download_file -m DEST_DIR DESCRIPTION [backup] URL1:FILENAME1 URL2:FILENAME2
```

**Examples:**
```bash
# Single file
download_file "http://example.com/config.txt" "/etc/app/config.txt" "config file"

# Single file with backup
download_file "http://example.com/config.txt" "/etc/app/config.txt" "config file" backup

# Multiple files
download_file -m "/opt/app" "library files" \
  "http://example.com/lib1.so:lib1.so" \
  "http://example.com/lib2.so:lib2.so"

# Multiple files with backup
download_file -m "/opt/app" "library files" backup \
  "http://example.com/lib1.so:lib1.so" \
  "http://example.com/lib2.so:lib2.so"
```

## How to Use

These functions can be imported and used in your own Bash scripts. To import the functions, use the following lines in your script:

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

To check for required tools:
```bash
require_tool git curl wget
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
