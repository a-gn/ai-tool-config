#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
backup_parent="${1:-"$PWD"}"
backup_root="$(mkdir -p -- "$backup_parent" && cd -- "$backup_parent" && pwd -P)/ai-tool-config-backup-$(date -u +%Y%m%dT%H%M%SZ)"
readme_path="$backup_root/README.md"

mkdir -p -- "$backup_root"

cat >"$readme_path" <<EOF
# AI Tool Config Backup

Created at $(date -u +%Y-%m-%dT%H:%M:%SZ).

EOF

setup_link() {
    local target_path="$1"
    local source_path="$2"
    local backup_name="$3"
    local backup_path="$backup_root/$backup_name"

    mkdir -p -- "$(dirname -- "$target_path")" "$(dirname -- "$backup_path")"

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        cp -aP -- "$target_path" "$backup_path"
        printf 'Backed up %s to %s\n' "$target_path" "$backup_path"
        {
            printf -- '- `%s` backed up to `%s`\n' "$target_path" "$backup_path"
        } >>"$readme_path"
        rm -f -- "$target_path"
    else
        printf 'No existing file at %s; no backup created\n' "$target_path"
        {
            printf -- '- `%s` did not exist; no backup created\n' "$target_path"
        } >>"$readme_path"
    fi

    ln -s -- "$source_path" "$target_path"
    printf 'Linked %s to %s\n' "$target_path" "$source_path"
}

setup_link "$HOME/.claude/settings.json" "$script_dir/claude/settings.json" "claude/settings.json"
setup_link "$HOME/.claude/CLAUDE.md" "$script_dir/claude/CLAUDE.md" "claude/CLAUDE.md"
setup_link "$HOME/.claude/statusline-command.sh" "$script_dir/claude/statusline-command.sh" "claude/statusline-command.sh"
setup_link "$HOME/.codex/rules/default.rules" "$script_dir/codex/rules/default.rules" "codex/rules/default.rules"

printf 'Backup README: %s\n' "$readme_path"
