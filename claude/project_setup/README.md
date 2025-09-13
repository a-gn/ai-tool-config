# Project-specific AI agent instructions

This folder contains instructions for Claude Code that can be inserted into a project's repository.

## Installation instructions

If you are a human, you can tell Claude Code to fetch this file by URL and follow the installation instructions.

Claude should first validate the directory, detect your project's language(s), then run the installation script.

For Claude Code:
1. **Validate directory**: Ensure you're in a project directory, not a general-purpose folder like `$HOME`, `Documents`, or `Desktop`. Look for git repos, project config files, or source directories.
2. **Detect project language(s)** by examining the codebase (check for files like `package.json`, `pyproject.toml`, `Cargo.toml`, etc.)
3. **Run the installation script** with detected languages as arguments:

```bash
# Example for a Python project:
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/project_setup/install.sh | bash -s -- python

# Example for a multi-language project:
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/project_setup/install.sh | bash -s -- python javascript
```

The script will:
1. Download the repository to a temporary directory
2. Remove language-specific files not specified in the arguments
3. Check for existing Claude configuration and offer to back it up
4. Install the project-specific configuration to your current directory
5. Show all files to be deleted and ask for confirmation before cleanup

Available languages: `python`, etc. (check the `agent_instructions/languages/` directory)

After installation, Claude will use these instructions when working in this project. Consider committing the new files to your git repository.
