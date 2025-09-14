#!/bin/bash
set -euo pipefail

# Project setup script for AI agent instructions
# Usage: install.sh <language1> [language2] ...

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Safety check - don't install in dangerous directories
check_safe_directory() {
    local excluded_dirs=(
        "$HOME"
        "$HOME/Documents"
        "$HOME/Desktop"
        "$HOME/Downloads"
        "/tmp"
        "/var"
        "/Users"
        "/home"
        "/System"
        "/usr"
        "/opt"
    )
    for dir in "${excluded_dirs[@]}"; do
        if [[ "$PWD" == "$dir" ]]; then
            print_error "Cannot install in $dir - unsafe directory"
            exit 1
        fi
    done
}

check_safe_to_remove() {
    local target="$1"
    local original_target="$target"

    # Basic parameter check
    [[ -z "$target" ]] && print_error "Unsafe path: empty target" && exit 1

    # Resolve target to handle symlinks and relative paths
    if [[ -e "$target" ]]; then
        target=$(realpath "$target")
    else
        target=$(realpath -m "$target")
    fi

    # Root user check
    [[ "$EUID" -eq 0 ]] && print_error "Rejecting deletion: running as root" && exit 1

    # Path length check
    [[ ${#target} -lt 5 ]] && print_error "Path too short for deletion (suspect): $target" && exit 1

    # Only allow specific temp directory patterns
    case "$target" in
        /tmp/* | /private/var/folders/* | /var/folders/* | /var/tmp/* | /private/tmp/*)
            print_info "Safe path accepted for deletion: $target (original: $original_target)"
            ;;
        *)
            print_error "Path rejected - not in allowed temp directories: $target"
            exit 1
            ;;
    esac
}

remove_dir() {
    local dir="$1"
    check_safe_to_remove "$dir"
    [[ -d "$dir" ]] && rm -rf "$dir"
}

remove_file() {
    local file="$1"
    check_safe_to_remove "$file"
    [[ -f "$file" ]] && rm -f "$file"
}

# Clean up temp directory on exit
cleanup() {
    if [[ -n "${CLAUDE_SETUP_SCRIPT_TEMP_DIR:-}" ]]; then
        # Verify canary file exists before removal for extra safety
        if [[ -f "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/inside_temp_folder_to_delete" ]]; then
            remove_dir "$CLAUDE_SETUP_SCRIPT_TEMP_DIR"
        else
            print_warn "Skipping cleanup - missing safety marker in $CLAUDE_SETUP_SCRIPT_TEMP_DIR"
        fi
    fi
}
trap cleanup EXIT

# Remove language references from CLAUDE.md
clean_claude_md() {
    local claude_md="$1"
    shift
    local keep_languages=("$@")

    [[ ! -f "$claude_md" || ${#keep_languages[@]} -eq 0 ]] && return

    local temp_file
    temp_file=$(mktemp -p "$CLAUDE_SETUP_SCRIPT_TEMP_DIR")

    while IFS= read -r line; do
        if [[ "$line" =~ @agent_instructions/languages/([^/]+)/ ]]; then
            local lang="${BASH_REMATCH[1]}"
            local keep=false
            for keep_lang in "${keep_languages[@]}"; do
                [[ "$lang" == "$keep_lang" ]] && keep=true && break
            done
            [[ "$keep" == true ]] && echo "$line" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$claude_md"

    mv "$temp_file" "$claude_md"
}

# Remove unused language directories
clean_language_files() {
    local temp_source_dir="$1"
    shift
    local keep_languages=("$@")
    local lang_dir="$temp_source_dir/agent_instructions/languages"

    [[ ! -d "$lang_dir" || ${#keep_languages[@]} -eq 0 ]] && return

    for lang_path in "$lang_dir"/*; do
        if [[ -d "$lang_path" ]]; then
            local lang_name
            lang_name=$(basename "$lang_path")
            local keep=false
            for keep_lang in "${keep_languages[@]}"; do
                [[ "$lang_name" == "$keep_lang" ]] && keep=true && break
            done
            [[ "$keep" == false ]] && remove_dir "$lang_path"
        fi
    done
}


# Backup existing config
backup_existing_config() {
    local conflicts=()
    [[ -f "CLAUDE.md" ]] && conflicts+=("CLAUDE.md")
    [[ -d "agent_instructions" ]] && conflicts+=("agent_instructions")

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        local backup_dir=".claude_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        for file in "${conflicts[@]}"; do
            mv "$file" "$backup_dir/"
        done
        print_info "Backed up existing config to: $backup_dir"

        echo
        print_info "To rollback this installation, run:"
        print_info "  # Backup current config"
        print_info "  mkdir -p .claude_rollback_backup_\$(date +%Y%m%d_%H%M%S)"
        for file in "${conflicts[@]}"; do
            print_info "  mv $file .claude_rollback_backup_\$(date +%Y%m%d_%H%M%S)/"
        done
        print_info "  # Restore previous config"
        print_info "  mv $backup_dir/* ./"
        print_info "  rmdir $backup_dir"
        echo
    fi
}

# Main installation
main() {
    # Refuse to run as root
    if [[ "$EUID" -eq 0 ]]; then
        print_error "Do not run this script as root"
        exit 1
    fi

    local languages=("$@")
    [[ ${#languages[@]} -eq 0 ]] && print_error "Usage: $0 <language1> [language2] ..." && exit 1

    print_info "Installing Claude Code configuration for: ${languages[*]}"
    check_safe_directory

    # Download repository - use system temp directory
    CLAUDE_SETUP_SCRIPT_TEMP_DIR=$(mktemp -d -t claude_install.XXXXXX)
    # Create canary file for safety verification
    touch "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/inside_temp_folder_to_delete"
    print_info "Downloading repository..."
    curl -sL "https://github.com/a-gn/ai-tool-config/archive/refs/heads/main.zip" -o "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/repo.zip"

    # Extract to subdirectory to avoid temp files mixing with source files
    print_info "Extracting configuration..."
    mkdir -p "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/extract"
    unzip -q "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/repo.zip" -d "$CLAUDE_SETUP_SCRIPT_TEMP_DIR/extract"

    local temp_source_dir="$CLAUDE_SETUP_SCRIPT_TEMP_DIR/extract/ai-tool-config-main/claude/project_setup"
    [[ ! -d "$temp_source_dir" ]] && print_error "Project setup folder not found" && exit 1

    # Validate languages exist
    local lang_dir="$temp_source_dir/agent_instructions/languages"
    for lang in "${languages[@]}"; do
        [[ ! -d "$lang_dir/$lang" ]] && print_error "Language '$lang' not found" && exit 1
    done

    # Clean up files
    print_info "Cleaning up instructions, only keeping languages: ${languages[@]}"
    clean_language_files "$temp_source_dir" "${languages[@]}"
    clean_claude_md "$temp_source_dir/CLAUDE.md" "${languages[@]}"
    remove_file "$temp_source_dir/README.md"
    remove_file "$temp_source_dir/install.sh"

    # Install
    backup_existing_config
    print_info "Moving final instructions to $(pwd)..."
    cp -r "$temp_source_dir"/* ./
    print_info "✓ Installation complete"
}

[[ "${BASH_VERSION:-}" == "" ]] && print_error "This script requires bash" && exit 1
main "$@"