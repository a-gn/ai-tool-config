#!/bin/bash
set -euo pipefail

# User setup script for AI agent instructions
# This script safely installs user-wide Claude Code configuration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Robust user input function that works in various environments
ask_user() {
    local prompt="$1"
    local default="${2:-}"
    local response=""

    # Check if we can get user input
    if [[ -t 0 ]] && [[ -n "${TERM:-}" ]]; then
        # Standard interactive terminal
        read -p "$prompt" response
    elif [[ -e /dev/tty ]]; then
        # Try to read from TTY
        if read -p "$prompt" response < /dev/tty 2>/dev/null; then
            true  # Success
        else
            response="$default"
            if [[ -n "$default" ]]; then
                print_warn "Non-interactive environment detected, using default: $default"
            else
                print_error "Cannot get user input in non-interactive environment"
                exit 1
            fi
        fi
    else
        # No TTY available - use default or exit
        response="$default"
        if [[ -n "$default" ]]; then
            print_warn "No TTY available, using default: $default"
        else
            print_error "Cannot get user input - no TTY available"
            exit 1
        fi
    fi

    echo "$response"
}

# Ask user for confirmation with default
ask_confirmation() {
    local prompt="$1"
    local default="${2:-N}"

    local full_prompt
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        full_prompt="$prompt (Y/n): "
    else
        full_prompt="$prompt (y/N): "
    fi

    local response
    response=$(ask_user "$full_prompt" "$default")

    case "$response" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        "")
            case "$default" in
                [Yy]*) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

# Ask user for choice with default
ask_choice() {
    local prompt="$1"
    local default="$2"
    shift 2
    local choices=("$@")

    local full_prompt="$prompt (1-${#choices[@]})"
    if [[ -n "$default" ]]; then
        full_prompt="$full_prompt [default: $default]"
    fi
    full_prompt="$full_prompt: "

    local response
    response=$(ask_user "$full_prompt" "$default")

    echo "$response"
}

# Clean up function
cleanup() {
    if [[ -n "${CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR:-}" && -d "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR" ]]; then
        echo
        print_info "Cleanup - temporary directory to be deleted:"
        echo "  $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
        echo
        if ask_confirmation "Execute this cleanup command?" "N"; then
            print_info "Executing cleanup: rm -rf $(printf '%q' "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR")"
            rm -rf "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
            print_info "Cleanup completed"
        else
            print_warn "Cleanup skipped. You may need to manually delete:"
            echo "  $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
            print_info "To delete manually, run: rm -rf $(printf '%q' "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR")"
        fi
    fi
}
trap cleanup EXIT

# Find Claude configuration directory
find_claude_config_dir() {
    echo "$HOME/.claude"
}

# Check if destination exists and handle conflicts
handle_existing_config() {
    local config_dir="$1"

    # Check if config directory exists and has any content
    if [[ -d "$config_dir" ]] && [[ -n "$(ls -A "$config_dir" 2>/dev/null)" ]]; then
        print_warn "Found existing Claude configuration directory: $config_dir"

        echo
        echo "Choose an option:"
        echo "1) Backup existing configuration and overwrite"
        echo "2) Abort installation"

        local choice
        choice=$(ask_choice "Enter choice" "2" "Backup and overwrite" "Abort installation")

        case $choice in
            1)
                local backup_dir="$HOME/.claude_backup_$(date +%Y%m%d_%H%M%S)"
                print_info "The following backup command will be executed:"
                echo "  mv $(printf '%q' "$config_dir") $(printf '%q' "$backup_dir")"
                echo
                if ask_confirmation "Execute this backup command?" "N"; then
                    print_info "Executing backup command..."
                    mv "$config_dir" "$backup_dir"
                    print_info "Backed up entire configuration to: $backup_dir"
                    # Recreate the config directory
                    mkdir -p "$config_dir"
                else
                    print_error "Backup declined, cannot proceed with installation"
                    exit 1
                fi
                ;;
            2)
                print_info "Installation aborted by user"
                exit 0
                ;;
            *)
                print_error "Invalid choice: $choice"
                exit 1
                ;;
        esac
    fi
}

# Install via git clone with symlinks
install_with_git_clone() {
    local config_dir="$1"
    local repo_dir="$config_dir/instructions_repository_clone"

    print_info "Installing via git clone with symlinks..."

    # Clone repository
    print_info "Cloning repository to: $repo_dir"
    git clone https://github.com/a-gn/ai-tool-config.git "$repo_dir"

    # Create symlinks
    local user_setup_dir="$repo_dir/claude/user_setup"

    if [[ -f "$user_setup_dir/CLAUDE.md" ]]; then
        print_info "Creating symlink: CLAUDE.md"
        ln -sf "$user_setup_dir/CLAUDE.md" "$config_dir/CLAUDE.md"
    fi

    if [[ -d "$user_setup_dir/commands" ]]; then
        print_info "Creating symlink: commands/"
        ln -sf "$user_setup_dir/commands" "$config_dir/commands"
    fi

    print_info "✓ Git clone installation completed!"
    print_info "Repository cloned to: $repo_dir"
    print_info "To update instructions: cd $repo_dir && git pull"
}

# Install via file copy
install_with_file_copy() {
    local config_dir="$1"

    print_info "Installing via file copy..."

    # Create temporary directory
    CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR=$(mktemp -d)
    print_info "Using temporary directory: $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"

    # Download and extract repository
    print_info "Downloading repository..."
    local zip_url="https://github.com/a-gn/ai-tool-config/archive/refs/heads/main.zip"
    curl -L "$zip_url" -o "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR/repo.zip"

    cd "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
    unzip -q repo.zip

    # Navigate to user setup folder
    local source_dir="$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR/ai-tool-config-main/claude/user_setup"
    if [[ ! -d "$source_dir" ]]; then
        print_error "User setup folder not found in repository"
        exit 1
    fi

    # Remove installation files from source immediately (safe since we know exact paths)
    print_info "Removing installation files from temporary directory..."
    if [[ -f "$source_dir/README.md" ]]; then
        rm -f "$source_dir/README.md"
        print_info "Removed: $source_dir/README.md"
    fi
    if [[ -f "$source_dir/install.sh" ]]; then
        rm -f "$source_dir/install.sh"
        print_info "Removed: $source_dir/install.sh"
    fi

    # Copy files to destination
    print_info "Installing configuration files..."
    cp -r "$source_dir"/* "$config_dir/"

    print_info "✓ File copy installation completed!"
}

# Main installation
main() {
    print_info "Installing user-wide Claude Code configuration..."

    # Find destination directory
    local config_dir
    config_dir=$(find_claude_config_dir)
    print_info "Installing to: $config_dir"

    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"

    # Handle existing configuration
    handle_existing_config "$config_dir"

    # Ask user for installation method
    echo
    echo "Choose installation method:"
    echo "1) Git clone with symlinks (allows easy updates with git pull)"
    echo "2) Simple file copy (static installation)"

    local choice
    choice=$(ask_choice "Enter choice" "1" "Git clone with symlinks" "Simple file copy")

    case $choice in
        1)
            install_with_git_clone "$config_dir"
            ;;
        2)
            install_with_file_copy "$config_dir"
            ;;
        *)
            print_error "Invalid choice: $choice"
            exit 1
            ;;
    esac

    print_info "Configuration directory: $config_dir"
}

# Check if running with bash
if [[ "${BASH_VERSION:-}" == "" ]]; then
    print_error "This script requires bash"
    exit 1
fi

# Run main function
main "$@"