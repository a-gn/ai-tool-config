# Project-specific AI agent instructions

This folder contains instructions for Claude Code that can be inserted into a project's repository.

## Installation

### If you are a human

You can point Claude Code to this `README.md` by URL so that it takes care of the instructions below. (Review the script's code before, obviously.)

### If you are an AI agent

Run from within a project directory with the languages you want to include:

```bash
# For a Python project:
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/project_setup/install.py | python3 - python

# For interactive language selection:
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/project_setup/install.py | python3 - --interactive

# For all available languages:
curl -sSL https://raw.githubusercontent.com/a-gn/ai-tool-config/main/claude/project_setup/install.py | python3 -
```

Available languages: `python` (check the `agent_instructions/languages/` directory for others)

## What it does

The script will:
1. Validate you're in a valid project directory
2. Download the repository to a temporary directory
3. Remove language-specific files not specified in the arguments
4. Check for existing Claude configuration and back it up with rollback instructions
5. Install the project-specific configuration to your current directory
6. Automatically clean up temporary files

After installation, Claude will use these instructions when working in this project. Consider committing the new files to your git repository.
