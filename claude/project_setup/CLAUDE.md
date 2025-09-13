# Project-specific AI agent instructions

## Project Directory Validation

**IMPORTANT**: Before running the installation script, you must validate that you are in an appropriate project directory. Do NOT install project-specific instructions in:

• **General-purpose directories**: `$HOME`, `Documents`, `Desktop`, `Downloads`, etc.
• **System directories**: `/tmp`, `/var`, `/Users`, `/home`

**ONLY install in**:
• **Git repositories** (check with `git rev-parse --git-dir`)
• **Directories with project files**: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.
• **Directories with source folders**: `src/`, `lib/`, `app/`, etc.
• **Empty directories** intended for new projects

**Validation steps**:
1. Check current directory with `pwd`
2. Look for project indicators (git repo, config files, source dirs)
3. If unsure, ask the user to confirm this is a project directory
4. Only proceed if confident this is an appropriate project location

## Core Principles

• **Error Handling**: Never suppress errors or bypass failures; crash early or deliver everything requested
• **Dependencies**: Use standard library → project code → third-party (minimize additions)
• **Type Safety**: Type-check everything thoroughly, including type parameters, recursively
• **Input Validation**: Document constraints, validate inputs, provide helpful error messages
• **Simplicity**: Prefer short diffs, reuse existing code, remove lines by default, use pure functions, factor
• **Attribution**: Add "Originally written by [model] on YYYY/MM/DD" for large, new code units
• **Tool Installation**: Install cautiously, ask permission, adapt to environment

## Language-Specific Guidelines

@agent_instructions/languages/python/README.md
