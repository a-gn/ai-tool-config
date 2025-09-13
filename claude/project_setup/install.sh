#!/bin/bash
set -euo pipefail

# Project setup script for AI agent instructions
# This script safely installs project-specific Claude Code configuration
# Usage: install.sh [language1] [language2] ...

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

# Clean up language references in CLAUDE.md that aren't needed
clean_claude_md_references() {
    local source_dir="$1"
    shift
    local keep_languages=("$@")
    local claude_md="$source_dir/CLAUDE.md"

    if [[ ! -f "$claude_md" ]]; then
        return
    fi

    # If no languages specified, keep all references
    if [[ ${#keep_languages[@]} -eq 0 ]]; then
        return
    fi

    print_info "Cleaning language references in CLAUDE.md..."

    # Create temporary file for modifications
    local temp_file
    temp_file=$(mktemp)

    # Process CLAUDE.md line by line
    while IFS= read -r line; do
        # Check if this line references a language-specific file
        if [[ "$line" =~ @agent_instructions/languages/([^/]+)/ ]]; then
            local referenced_lang="${BASH_REMATCH[1]}"
            local should_keep=false

            # Check if this language should be kept
            for keep_lang in "${keep_languages[@]}"; do
                if [[ "$referenced_lang" == "$keep_lang" ]]; then
                    should_keep=true
                    break
                fi
            done

            if [[ "$should_keep" == true ]]; then
                echo "$line" >> "$temp_file"
            else
                print_info "Removing reference to $referenced_lang from CLAUDE.md"
            fi
        else
            # Keep non-language reference lines
            echo "$line" >> "$temp_file"
        fi
    done < "$claude_md"

    # Replace original file with cleaned version
    mv "$temp_file" "$claude_md"
}

# Remove language files not specified by Claude
clean_language_files() {
    local source_dir="$1"
    shift
    local keep_languages=("$@")
    local lang_dir="$source_dir/agent_instructions/languages"

    if [[ ! -d "$lang_dir" ]]; then
        return
    fi

    # If no languages specified, keep all
    if [[ ${#keep_languages[@]} -eq 0 ]]; then
        print_warn "No languages specified, keeping all language files"
        return
    fi

    print_info "Languages to keep: ${keep_languages[*]}"

    # Find languages to remove
    for lang_path in "$lang_dir"/*; do
        if [[ -d "$lang_path" ]]; then
            local lang_name
            lang_name=$(basename "$lang_path")

            # Validate that lang_name is just a simple directory name (no paths)
            if [[ "$lang_name" != "$lang_path" ]] && [[ "$lang_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                local should_keep=false
                for keep_lang in "${keep_languages[@]}"; do
                    if [[ "$lang_name" == "$keep_lang" ]]; then
                        should_keep=true
                        break
                    fi
                done

                if [[ "$should_keep" == false ]]; then
                    print_info "Removing language directory: $lang_name"
                    rm -rf "$lang_path"
                fi
            else
                print_error "Invalid language directory name: $lang_name"
                exit 1
            fi
        fi
    done
}


# Check if destination exists and handle conflicts
handle_existing_config() {
    local project_root="$1"
    local conflicts=()

    if [[ -f "$project_root/CLAUDE.md" ]]; then
        conflicts+=("$project_root/CLAUDE.md")
    fi
    if [[ -d "$project_root/agent_instructions" ]]; then
        conflicts+=("$project_root/agent_instructions")
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
                local backup_dir="$project_root/.claude_backup_$(date +%Y%m%d_%H%M%S)"
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
    local languages=("$@")
    print_info "Installing project-specific Claude Code configuration..."

    # Find project root (current directory)
    local project_root="$PWD"
    print_info "Installing to project: $project_root"

    # Create temporary directory
    CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR=$(mktemp -d)
    print_info "Using temporary directory: $CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"

    # Download and extract repository
    print_info "Downloading repository..."
    local zip_url="https://github.com/a-gn/ai-tool-config/archive/refs/heads/main.zip"
    curl -L "$zip_url" -o "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR/repo.zip"

    cd "$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR"
    unzip -q repo.zip

    # Navigate to project setup folder
    local source_dir="$CLAUDE_INSTRUCTIONS_SETUP_SCRIPT_TEMP_DIR/ai-tool-config-main/claude/project_setup"
    if [[ ! -d "$source_dir" ]]; then
        print_error "Project setup folder not found in repository"
        exit 1
    fi

    # Clean language-specific files
    clean_language_files "$source_dir" "${languages[@]}"

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

    # Clean up language references in CLAUDE.md
    clean_claude_md_references "$source_dir" "${languages[@]}"

    # Return to project directory
    cd "$project_root"

    # Handle existing configuration
    handle_existing_config "$project_root"

    # Copy files to destination
    print_info "Installing configuration files..."
    cp -r "$source_dir"/* "$project_root/"

    print_info "✓ Project-specific Claude Code configuration installed successfully!"

    # Check if this is a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        print_info "Git repository detected."
        print_info "Consider committing the new configuration files:"
        print_info "  git add CLAUDE.md agent_instructions/"
        print_info "  git commit -m 'Add Claude Code configuration'"
    fi
}

# Check if running with bash
if [[ "${BASH_VERSION:-}" == "" ]]; then
    print_error "This script requires bash"
    exit 1
fi

# Run main function with all arguments
main "$@"