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

# Clean up function
cleanup() {
    if [[ -n "${CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR:-}" && -d "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR" ]]; then
        echo
        print_info "Cleanup - temporary directory to be deleted:"
        echo "  $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
        echo
        read -p "Execute this cleanup command? (y/N): " confirm
        case $confirm in
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
    local conflicts=()

    if [[ -f "$config_dir/CLAUDE.md" ]]; then
        conflicts+=("$config_dir/CLAUDE.md")
    fi
    if [[ -d "$config_dir/commands" ]]; then
        conflicts+=("$config_dir/commands")
    fi

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        print_warn "Found existing configuration files:"
        printf '%s\n' "${conflicts[@]}"

        echo
        echo "Choose an option:"
        echo "1) Backup existing files and overwrite"
        echo "2) Abort installation"
        read -p "Enter choice (1-2): " choice

        case $choice in
            1)
                local backup_dir="$config_dir/backup_$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$backup_dir"
                print_info "Backup directory created: $backup_dir"

                # Build backup command
                local backup_files=()
                for file in "${conflicts[@]}"; do
                    if [[ -e "$file" ]]; then
                        backup_files+=("$file")
                    fi
                done

                if [[ ${#backup_files[@]} -gt 0 ]]; then
                    echo
                    print_info "The following backup command will be executed:"
                    echo "  mv $(printf '%q ' "${backup_files[@]}") $(printf '%q' "$backup_dir")/"
                    echo
                    read -p "Execute this backup command? (y/N): " backup_confirm
                    case $backup_confirm in
                        [Yy]*)
                            print_info "Executing backup command..."
                            for file in "${backup_files[@]}"; do
                                mv "$file" "$backup_dir/"
                                print_info "Backed up: $(basename "$file")"
                            done
                            ;;
                        *)
                            print_error "Backup declined, cannot proceed with installation"
                            exit 1
                            ;;
                    esac
                fi
                ;;
            2)
                print_info "Installation aborted by user"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

# Main installation
main() {
    print_info "Installing user-wide Claude Code configuration..."

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

    # Find destination directory
    local config_dir
    config_dir=$(find_claude_config_dir)
    print_info "Installing to: $config_dir"

    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"

    # Handle existing configuration
    handle_existing_config "$config_dir"

    # Copy files to destination
    print_info "Installing configuration files..."
    cp -r "$source_dir"/* "$config_dir/"

    print_info "✓ User-wide Claude Code configuration installed successfully!"
    print_info "Configuration directory: $config_dir"
}

# Check if running with bash
if [[ "${BASH_VERSION:-}" == "" ]]; then
    print_error "This script requires bash"
    exit 1
fi

# Run main function
main "$@"