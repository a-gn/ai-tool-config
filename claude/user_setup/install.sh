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

# Simple user input using TTY
ask_user() {
    local prompt="$1"
    local response=""
    read -p "$prompt" response < /dev/tty
    echo "$response"
}

# Clean up function
cleanup() {
    if [[ -n "${CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR:-}" && -d "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR" ]]; then
        echo
        print_info "Cleanup - temporary directory to be deleted:"
        echo "  $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
        echo
        local response
        response=$(ask_user "Execute this cleanup command? (y/N): ")
        case "$response" in
            [Yy]*)
                print_info "Executing cleanup: rm -rf $(printf '%q' "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR")"
                rm -rf "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
                print_info "Cleanup completed"
                ;;
            *)
                print_warn "Cleanup skipped. You may need to manually delete:"
                echo "  $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
                print_info "To delete manually, run: rm -rf $(printf '%q' "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR")"
                ;;
        esac
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

        local backup_dir="$HOME/.claude_backup_$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up to: $backup_dir"
        mv "$config_dir" "$backup_dir"
        print_info "✓ Backed up existing configuration"

        # Recreate the config directory
        mkdir -p "$config_dir"
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

    # Just use git clone by default (most flexible)
    install_with_git_clone "$config_dir"

    print_info "Configuration directory: $config_dir"
}

# Check if running with bash
if [[ "${BASH_VERSION:-}" == "" ]]; then
    print_error "This script requires bash"
    exit 1
fi

# Run main function
main "$@"