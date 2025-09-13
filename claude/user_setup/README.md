# User-specific AI agent instructions

This folder contains personal instructions for Claude Code that can be copied to your local Claude Code configuration.

## Installation instructions

If you are a human, you can tell Claude Code to fetch this file and execute these instructions.

First, ask the user if they want to:
1. Clone the repository using git into `$CLAUDE_CONFIG_FOLDER/instructions_repository_clone` and symlink their `CLAUDE.md` to this clone so that they can pull updated instructions with git, OR
2. Fetch the instructions once and install them as simple files

Then proceed with the chosen method:

Always clean up any temporary files you've created while doing this, whether you succeed or abort.
VERY IMPORTANT: ONLY delete or modify files that you created. At NO POINT should you overwrite or delete something that was there before you started this task.

**MANDATORY PATH CONFIRMATION**: Before deleting, overwriting, or modifying ANY file or directory:
1. Show the user the full, absolute, resolved path of what will be affected
2. Explain exactly what operation will be performed (delete, overwrite, modify, symlink)
3. Ask for explicit confirmation with a yes/no question
4. If you are not sure that you won't destroy files that you did not create yourself, DO NOT REMOVE ANYTHING and tell the user what the problem is.

**Method 1 (Git clone with symlinks):**
- Clone the repository into `$CLAUDE_CONFIG_FOLDER/instructions_repository_clone`
- Before creating any symlinks, check for existing files and ask for confirmation:
  - For each symlink to be created, show the full absolute path of both the source and target
  - Ask: "I will create a symlink from [full target path] to [full source path]. This will [overwrite existing file/create new file]. Do you want to proceed? (yes/no)"
- Create symlinks only after confirmation:
  - Symlink `CLAUDE.md` from the root of your config directory to `instructions_repository_clone/claude/user_setup/CLAUDE.md`
  - Symlink the `commands` folder to `instructions_repository_clone/claude/user_setup/commands`

**Method 2 (Simple file copy):**
- Create a new, unique temporary directory using the system's utilities dedicated to this. Show the user the full absolute path of this temporary directory and confirm: "I will create temporary directory at [full path]. This directory will be deleted after installation. Do you want to proceed? (yes/no)"
- Perform the following instructions inside this temporary directory. Especially DO NOT DELETE OR MODIFY ANYTHING that isn't inside this new, temporary directory.
- Use GitHub's ZIP repository archive URL to fetch the entire AI instructions repository. Extract it.
- Navigate to the `claude/user_setup` folder in the extracted repository.
- Before removing the installation instructions file, show its full path and ask: "I will delete the installation instructions file at [full path] from the temporary directory. Do you want to proceed? (yes/no)"
- The configuration should now be self-contained and ready for installation.

**For both methods:**
- Check if there are already existing files in your local Claude Code configuration directory (typically `~/.claude` or similar, depending on your system) that would conflict with the new instructions, including `CLAUDE.md`, `commands` folder, or any other files or instructions. If there are conflicts:
  - Show the full absolute path of each conflicting file: "Conflict detected: existing file at [full path] will be affected"
  - Ask the user: "I found [number] conflicting files. Do you want to: (a) merge with backup, (b) abort installation, or (c) overwrite without backup? Please specify your choice."
  - If merging or overwriting, for each affected file, ask: "I will [backup and overwrite/overwrite] the file at [full path]. Do you want to proceed? (yes/no)"
- Before copying or symlinking any files to your local Claude Code configuration directory:
  - Show the full absolute paths of source and destination for each operation
  - Ask: "I will [copy/symlink] from [source path] to [destination path]. This will [create new file/overwrite existing file]. Do you want to proceed? (yes/no)"
- Before cleaning up temporary directories, show the full path and ask: "I will delete the temporary directory at [full path] and all its contents. Do you want to proceed? (yes/no)"
- Test the configuration by asking Claude Code: "I just set up new instructions for you. Is everything set up correctly? Do all references work? Are the instructions self-contained, can you read them entirely without fetching files from the Internet? Is there anything that confuses you?"
