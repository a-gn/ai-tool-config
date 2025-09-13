#!/bin/bash
set -euo pipefail

# User setup script for AI agent instructions

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

ask_user() {
    local prompt="$1"
    local response=""
    read -p "$prompt" response < /dev/tty
    echo "$response"
}

# Clean up temp directory on exit
cleanup() {
    if [[ -n "${CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR:-}" && -d "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR" ]]; then
        echo
        print_info "Cleanup - temporary directory to be deleted: $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
        local response
        response=$(ask_user "Execute cleanup? (y/N): ")
        case "$response" in
            [Yy]*) rm -rf "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR" && print_info "Cleanup completed" ;;
            *) print_warn "Cleanup skipped. Manual delete: rm -rf $(printf '%q' "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR")" ;;
        esac
    fi
}
trap cleanup EXIT


# Backup existing config
backup_existing_config() {
    local config_dir="$1"
    if [[ -d "$config_dir" ]] && [[ -n "$(ls -A "$config_dir" 2>/dev/null)" ]]; then
        local backup_dir="$HOME/.claude_backup_$(date +%Y%m%d_%H%M%S)"
        mv "$config_dir" "$backup_dir"
        mkdir -p "$config_dir"
        print_info "Backed up existing config to: $backup_dir"

        echo
        print_info "To rollback this installation, run:"
        print_info "  # Backup current config"
        print_info "  mv $config_dir $HOME/.claude_rollback_backup_\$(date +%Y%m%d_%H%M%S)"
        print_info "  # Restore previous config"
        print_info "  mv $backup_dir $config_dir"
        echo
    fi
}

# Install via git clone with symlinks
install_with_git_clone() {
    local config_dir="$1"
    local repo_dir="$config_dir/instructions_repository_clone"

    print_info "Installing via git clone with symlinks..."
    git clone https://github.com/a-gn/ai-tool-config.git "$repo_dir"

    local user_setup_dir="$repo_dir/claude/user_setup"
    [[ -f "$user_setup_dir/CLAUDE.md" ]] && ln -sf "$user_setup_dir/CLAUDE.md" "$config_dir/CLAUDE.md"
    [[ -d "$user_setup_dir/commands" ]] && ln -sf "$user_setup_dir/commands" "$config_dir/commands"

    print_info "✓ Installation complete"
    print_info "To update: cd $repo_dir && git pull"
}

# Main installation
main() {
    print_info "Installing user-wide Claude Code configuration..."

    local config_dir="$HOME/.claude"
    print_info "Installing to: $config_dir"

    mkdir -p "$config_dir"
    backup_existing_config "$config_dir"
    install_with_git_clone "$config_dir"

    print_info "Configuration directory: $config_dir"
}

[[ "${BASH_VERSION:-}" == "" ]] && print_error "This script requires bash" && exit 1
main "$@"