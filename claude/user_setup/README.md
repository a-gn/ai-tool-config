# User-specific AI agent instructions

This folder contains personal instructions for Claude Code that can be copied to your user's Claude Code configuration.

This modifies the global Claude configuration for all instances of Claude. It's not project-specific.

## Installation instructions

If you are a human, you can tell Claude Code to fetch this file by URL and follow the installation instructions.

Run the installation script:

```bash
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/user_setup/install.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/user_setup/install.sh
chmod +x install.sh
./install.sh
```

The script will:
1. Download the repository to a temporary directory
2. Check for existing Claude configuration and offer to back it up
3. Install the user-wide configuration to `~/.claude` (or `$CLAUDE_CONFIG_DIR`)
4. Clean up temporary files

After installation, Claude will use these instructions for all projects that don't have their own `CLAUDE.md` file.
