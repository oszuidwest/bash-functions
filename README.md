# bash-functions v2

A Bash shell library providing common utility functions for Debian-like environments.

## Naming Conventions

| Prefix | Behavior | Example |
|--------|----------|---------|
| `assert_*` | Exit on failure | `assert_os_linux` |
| `is_*` | Return 0/1 (predicate) | `is_valid` |
| `get_*` | Echo a value | `get_sudo` |
| `set_*` | Modify state | `set_timezone` |
| `prompt_*` | Interactive input | `prompt_user` |
| `apt_*` | Package management | `apt_install` |
| `file_*` | File operations | `file_download` |

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
| `install_packages` | `apt_install` |
| `backup_file` | `file_backup` |
| `download_file` | `file_download` |

## Installation

```bash
curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/oszuidwest/bash-functions/v2/common-functions.sh
source /tmp/functions.sh
```

Colors are automatically initialized.

## Function Reference

### Assertions (exit on failure)

```bash
assert_os_linux                    # Require Linux
assert_os_64bit                    # Require 64-bit OS
assert_tool apt curl git           # Require tools installed
assert_user_privileged "root"      # Require root
assert_user_privileged "regular"   # Require non-root
assert_hw_rpi 4                    # Require Raspberry Pi 4+
```

### Predicates (return 0/1)

```bash
if is_valid "$value" "email" "EMAIL"; then
    echo "Valid email"
fi
```

Validation types: `y/n`, `num`, `str`, `email`, `host`

### Getters

```bash
local sudo_cmd=$(get_sudo)         # Returns "sudo" or ""
```

### Prompts

```bash
prompt_user "USERNAME" "admin" "Enter username" "str"
prompt_user "PORT" "8080" "Enter port" "num"
prompt_user "ENABLE_SSL" "y" "Enable SSL?" "y/n"
```

For non-interactive usage, set environment variables:
```bash
export USERNAME="myuser"
./myscript.sh  # Uses env var instead of prompting
```

### APT Package Management

```bash
apt_update                         # Update all packages
apt_update --silent                # Update silently

apt_install nginx php mysql        # Install packages
apt_install --silent nginx         # Install silently
```

### Setters

```bash
set_timezone "Europe/Amsterdam"
```

### File Operations

```bash
# Backup (returns: 0=success, 1=failed, 2=no file)
file_backup "/etc/config.conf"

# Download single file
file_download "https://example.com/f.txt" "/tmp/f.txt" "config"
file_download "https://example.com/f.txt" "/tmp/f.txt" "config" --backup

# Download multiple (use | delimiter for port support)
file_download -m "/opt/app" "libs" \
  "https://example.com:8080/lib1.so|lib1.so" \
  "https://example.com:8080/lib2.so|lib2.so"
```

### Colors

Available after sourcing:
```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error!${NC}"
echo -e "${YELLOW}Warning${NC}"
echo -e "${BLUE}Info${NC}"
echo -e "${BOLD}Bold${NC}"
```

## Requirements

- Bash 4.3+
- Debian-like system with apt
- curl (for file_download)

## License

MIT License - see LICENSE.md

Bugs and feedback: `techniek@zuidwesttv.nl` or via pull requests.
