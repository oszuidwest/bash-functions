# bash-functions v2

A Bash shell library providing common utility functions for Debian-like environments.

## Installation

```bash
curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/oszuidwest/bash-functions/v2/common-functions.sh
source /tmp/functions.sh
```

Colors are automatically initialized when the library is sourced.

## Quick Start

```bash
#!/bin/bash
source /tmp/functions.sh

assert_os_linux
assert_tool curl git
assert_user_privileged "root"

prompt_user "DOMAIN" "example.com" "Enter domain" "host"
apt_install --silent nginx certbot

echo -e "${GREEN}Setup complete for ${DOMAIN}${NC}"
```

## Function Reference

### Assertions (exit on failure)

Guards that validate preconditions and exit the script if they fail.

```bash
assert_os_linux                    # Require Linux OS
assert_os_64bit                    # Require 64-bit OS
assert_tool curl git wget          # Require tools to be installed
assert_user_privileged "root"      # Require root user
assert_user_privileged "regular"   # Require non-root user
assert_hw_rpi 4                    # Require Raspberry Pi 4 or higher
```

### Predicates (return 0 or 1)

Functions that test a condition and return a boolean result.

```bash
# Validate input - returns 0 if valid, 1 if invalid
if is_valid "$email" "email" "EMAIL"; then
    echo "Valid"
fi
```

**Validation types:**

| Type | Description | Example valid values |
|------|-------------|---------------------|
| `y/n` | Yes or no | `y`, `n` |
| `num` | Positive integer | `0`, `42`, `8080` |
| `str` | Non-empty string | Any non-empty string |
| `email` | Email address | `user@example.com` |
| `host` | Hostname or IPv4 | `example.com`, `192.168.1.1` |

### Getters (echo a value)

Functions that compute and output a value.

```bash
local sudo_cmd=$(get_sudo)
# Returns "sudo" if not root, empty string if root
${sudo_cmd:+$sudo_cmd} systemctl restart nginx
```

### Prompts (interactive input)

```bash
prompt_user "VAR_NAME" "default" "Prompt message" "type"
```

**Parameters:**
- `VAR_NAME` - Variable name to store result (will be created)
- `default` - Default value if user presses Enter
- `Prompt message` - Text shown to user
- `type` - Validation type (optional, defaults to `str`)

**Examples:**

```bash
prompt_user "USERNAME" "admin" "Enter username" "str"
prompt_user "PORT" "8080" "Enter port number" "num"
prompt_user "ENABLE_SSL" "y" "Enable SSL?" "y/n"
prompt_user "EMAIL" "admin@example.com" "Contact email" "email"
prompt_user "SERVER" "localhost" "Server address" "host"
```

**Non-interactive mode:** Set environment variables before running the script:

```bash
export USERNAME="deploy"
export PORT="3000"
./script.sh  # Uses env vars, skips prompts
```

### APT Package Management

```bash
apt_update                         # Update and upgrade all packages
apt_update --silent                # Same, but suppress output

apt_install nginx php mysql        # Install packages (single apt call)
apt_install --silent nginx         # Same, but suppress output
```

### Setters

```bash
set_timezone "Europe/Amsterdam"    # Returns 1 if timezone invalid
```

### File Operations

**Backup:**

```bash
file_backup "/etc/nginx/nginx.conf"
```

**Download:**

```bash
# Single file
file_download "https://example.com/config.txt" "/etc/app/config.txt" "config file"

# With backup of existing file
file_download "https://example.com/config.txt" "/etc/app/config.txt" "config file" --backup

# Multiple files (use | as URL/filename delimiter for port support)
file_download -m "/opt/app/lib" "library files" --backup \
  "https://cdn.example.com:8080/lib1.so|lib1.so" \
  "https://cdn.example.com:8080/lib2.so|lib2.so"
```

Download features: automatic retries, connection timeouts, HTTP error detection.

### Colors

Available globally after sourcing:

```bash
echo -e "${GREEN}Success${NC}"
echo -e "${RED}Error${NC}"
echo -e "${YELLOW}Warning${NC}"
echo -e "${BLUE}Info${NC}"
echo -e "${BOLD}Bold text${NC}"
echo -e "${UNDERLINE}Underlined${NC}"
```

## Flags

| Flag | Available in | Description |
|------|--------------|-------------|
| `--silent` | `apt_update`, `apt_install` | Suppress output, auto-accept prompts |
| `--backup` | `file_download` | Backup existing file before overwriting |

Flags can appear anywhere in the argument list:

```bash
apt_install --silent nginx php    # Flag first
apt_install nginx --silent php    # Flag in middle
apt_install nginx php --silent    # Flag last
```

## Error Handling

### Return Codes

**`file_backup`:**

| Code | Meaning |
|------|---------|
| 0 | Backup created successfully |
| 1 | Backup failed |
| 2 | File does not exist (nothing to backup) |

**`file_download`:**

| Code | Meaning |
|------|---------|
| 0 | Download successful |
| 1 | Download failed (network error, HTTP error, etc.) |

**`is_valid`:**

| Code | Meaning |
|------|---------|
| 0 | Input is valid |
| 1 | Input is invalid (error message printed to stdout) |

**`set_timezone`:**

| Code | Meaning |
|------|---------|
| 0 | Timezone set successfully |
| 1 | Invalid timezone |

### Handling Errors

```bash
# Check return code
if ! file_download "$url" "$dest" "config"; then
    echo "Download failed, using fallback"
    cp /defaults/config.txt "$dest"
fi

# Handle backup status
file_backup "/etc/app.conf"
case $? in
    0) echo "Backup created" ;;
    1) echo "Backup failed!" ; exit 1 ;;
    2) echo "No existing file, skipping backup" ;;
esac

# Validate before using
if ! is_valid "$input" "email" "EMAIL"; then
    echo "Please provide a valid email"
    exit 1
fi
```

## Naming Conventions

### Prefixes

| Prefix | Behavior | When to use |
|--------|----------|-------------|
| `assert_*` | Exit on failure | Preconditions that must be true |
| `is_*` | Return 0/1 | Testing conditions |
| `get_*` | Echo a value | Retrieving computed values |
| `set_*` | Modify state | Changing system/global state |
| `prompt_*` | Interactive I/O | Getting user input |
| `apt_*` | Package management | Installing/updating packages |
| `file_*` | File operations | Backup, download, etc. |

### Assert Sub-namespaces

| Namespace | Purpose | Functions |
|-----------|---------|-----------|
| `assert_os_*` | Operating system checks | `assert_os_linux`, `assert_os_64bit` |
| `assert_user_*` | User privilege checks | `assert_user_privileged` |
| `assert_hw_*` | Hardware requirements | `assert_hw_rpi` |
| `assert_tool` | Tool/dependency checks | `assert_tool` |

## Compatibility

### Bash Version

Requires **Bash 4.3+** due to use of `declare -n` (namerefs).

### `set -u` (nounset)

The library is fully compatible with `set -u`. All optional parameters use `${var:-}` syntax.

### `set -e` (errexit)

The library works with `set -e`, but be aware:

- `assert_*` functions call `exit 1` on failure (script stops)
- `is_valid` returns 1 on invalid input (may trigger errexit if not in condition)

**Safe patterns with `set -e`:**

```bash
set -e

# Safe: in if condition
if is_valid "$input" "num" "PORT"; then
    echo "Valid"
fi

# Safe: with || true
is_valid "$input" "num" "PORT" || handle_invalid

# Unsafe: bare call will exit on invalid input
is_valid "$input" "num" "PORT"  # Exits if invalid!
```

## Requirements

- Bash 4.3+
- Debian-like system with apt package manager
- curl (for `file_download`)

## Breaking Changes from v1

| v1 | v2 |
|----|-----|
| `is_this_linux` | `assert_os_linux` |
| `is_this_os_64bit` | `assert_os_64bit` |
| `check_user_privileges "privileged"` | `assert_user_privileged "root"` |
| `check_user_privileges "regular"` | `assert_user_privileged "regular"` |
| `check_apt` | `assert_tool apt` |
| `require_tool git curl` | `assert_tool git curl` |
| `check_rpi_model 4` | `assert_hw_rpi 4` |
| `validate_input` | `is_valid` |
| `ask_user` | `prompt_user` |
| `get_sudo_if_needed` | `get_sudo` |
| `update_os` | `apt_update` |
| `update_os silent` | `apt_update --silent` |
| `install_packages` | `apt_install` |
| `install_packages silent nginx` | `apt_install --silent nginx` |
| `backup_file` | `file_backup` |
| `download_file` | `file_download` |
| `download_file ... backup` | `file_download ... --backup` |
| Multi-file `URL:filename` | Multi-file `URL\|filename` |

## License

MIT License - see LICENSE.md

Bugs and feedback: `techniek@zuidwesttv.nl` or via pull requests.
