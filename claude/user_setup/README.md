# User-specific AI agent instructions

This folder contains personal instructions for Claude Code that can be copied to your user's Claude Code configuration.

This modifies the global Claude configuration for all instances of Claude. It's not project-specific.

## Installation instructions

Run the installation script:

```bash
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/user_setup/install.py | python3 -
```

Or download and run manually:

```bash
curl -o install.py https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/user_setup/install.py
python3 install.py
```

The script will:

**Install with Git clone and symlinks**
- Clones the repository to `~/.claude/instructions_repository_clone/`
- Creates symlinks from `~/.claude/CLAUDE.md` and `~/.claude/commands/` to the cloned repo
- Allows easy updates with `cd ~/.claude/instructions_repository_clone && git pull`
- Keeps files in sync with the latest changes

The installation will:
1. Check for existing Claude configuration and offer to back it up
2. Install the user-wide configuration to `~/.claude/`
3. Clean up temporary files

After installation, Claude will use these instructions for all projects that don't have their own `CLAUDE.md` file.
