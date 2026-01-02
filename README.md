# bash-functions v2

A Bash shell library providing common utility functions for Debian-like environments.

## Breaking Changes from v1

If upgrading from v1, update your scripts:

| v1 | v2 |
|----|-----|
| `is_this_linux` | `check_linux` |
| `is_this_os_64bit` | `check_os_64bit` |
| `update_os silent` | `update_os --silent` |
| `install_packages silent pkg1 pkg2` | `install_packages --silent pkg1 pkg2` |
| `download_file URL DEST DESC backup` | `download_file URL DEST DESC --backup` |
| `download_file -m DIR DESC "URL:file"` | `download_file -m DIR DESC "URL\|file"` |
| `is_silent` function | Removed (internal only) |
| `set_colors` must be called | Auto-initialized on source |
| `backup_file` returns 0 on no-file | Returns 2 when file doesn't exist |

## Installation

```bash
curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/oszuidwest/bash-functions/v2/common-functions.sh
source /tmp/functions.sh
```

Colors are automatically initialized - no need to call `set_colors`.

## Function Reference

### System Checks

All check functions exit with code 1 on failure.

```bash
check_linux                        # Verify running on Linux
check_os_64bit                     # Verify 64-bit OS
check_apt                          # Verify apt is available
check_user_privileges "privileged" # Require root
check_user_privileges "regular"    # Require non-root
check_rpi_model 4                  # Require Raspberry Pi 4+
require_tool git curl wget         # Require tools installed
```

### Package Management

```bash
update_os                          # Update all packages
update_os --silent                 # Update silently

install_packages nginx php mysql   # Install packages (batch)
install_packages --silent nginx    # Install silently
```

### File Operations

```bash
# Backup (returns: 0=success, 1=failed, 2=file didn't exist)
backup_file "/etc/config.conf"

# Download single file
download_file "https://example.com/file.txt" "/tmp/file.txt" "config"
download_file "https://example.com/file.txt" "/tmp/file.txt" "config" --backup

# Download multiple files (use | as delimiter for port support)
download_file -m "/opt/app" "libs" \
  "https://example.com:8080/lib1.so|lib1.so" \
  "https://example.com:8080/lib2.so|lib2.so"
```

Download features:
- Automatic retries (3x with 5s delay)
- Connection timeout (30s)
- Max download time (5 min)
- HTTP error detection

### User Input

```bash
# Basic usage
ask_user "USERNAME" "admin" "Enter username" "str"
ask_user "PORT" "8080" "Enter port" "num"
ask_user "ENABLE_SSL" "y" "Enable SSL?" "y/n"
ask_user "EMAIL" "a@b.com" "Enter email" "email"
ask_user "SERVER" "localhost" "Enter host" "host"  # accepts hostname or IP
```

For non-interactive usage, set environment variables:
```bash
export USERNAME="myuser"
export PORT="3000"
./myscript.sh  # Will use env vars instead of prompting
```

### Configuration

```bash
set_timezone "Europe/Amsterdam"
```

### Colors

Available after sourcing (auto-initialized):
- `$GREEN`, `$RED`, `$YELLOW`, `$BLUE`
- `$BOLD`, `$UNDERLINE`
- `$NC` (reset)

```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error!${NC}"
```

## Requirements

- Bash 4.3+ (for `declare -n`)
- Debian-like system with apt
- curl (for download_file)

## License

MIT License - see LICENSE.md

Bugs and feedback: `techniek@zuidwesttv.nl` or via pull requests.
