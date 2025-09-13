# Project-specific AI agent instructions

This folder contains instructions for Claude Code that can be inserted into a project's repository.

## Installation instructions

If you are a human, you can tell Claude Code to fetch this file and execute these instructions.

Always clean up any temporary files you've created while doing this, whether you succeed or abort.
VERY IMPORTANT: ONLY delete or modify files that you created. At NO POINT should you overwrite or delete something that was there before you started this task.

**MANDATORY PATH CONFIRMATION**: Before deleting, overwriting, or modifying ANY file or directory:
1. Show the user the full, absolute, resolved path of what will be affected
2. Explain exactly what operation will be performed (delete, overwrite, modify, move)
3. Ask for explicit confirmation with a yes/no question
4. If you are not sure that you won't destroy files that you did not create yourself, DO NOT REMOVE ANYTHING and tell the user what the problem is.

- Create a new, unique temporary directory using the system's utilities dedicated to this. Show the user the full absolute path and ask: "I will create temporary directory at [full path]. This directory will be deleted after installation. Do you want to proceed? (yes/no)"
- Perform the following instructions inside this temporary directory. Especially DO NOT DELETE OR MODIFY ANYTHING that isn't inside this new, temporary directory.
- Use GitHub's ZIP repository archive URL to fetch the entire AI instructions repository. Extract it.
- Navigate to the `claude/project_setup` folder in the extracted repository.
- Before removing any language-specific files, show each file's full path and ask: "I will delete the language-specific file at [full path] from the temporary directory because it's not relevant to this project. Do you want to proceed? (yes/no)"
- Adapt the instructions to the project's setup if you find discrepancies. Before modifying any instruction files, show the full path and describe the changes: "I will modify the file at [full path] to change [specific change description]. Do you want to proceed? (yes/no)"
- Before removing the installation instructions file, show its full path and ask: "I will delete the installation instructions file at [full path] from the temporary directory. Do you want to proceed? (yes/no)"
- The repository's instructions should now be self-contained, without needing to fetch further files.
- Check if there are already existing files in the project's repository that would conflict with the new instructions, including `CLAUDE.md`, agent instruction folders, or any other files or commands. If there are conflicts:
  - Show the full absolute path of each conflicting file: "Conflict detected: existing file at [full path] will be affected"
  - Ask the user: "I found [number] conflicting files. Do you want to: (a) merge with backup, (b) abort installation, or (c) overwrite without backup? Please specify your choice."
  - If merging or overwriting, for each affected file, ask: "I will [backup and overwrite/overwrite] the file at [full path]. Do you want to proceed? (yes/no)"
- When the final instructions are ready and conflicts are resolved, before moving files to the project repository:
  - Show the full absolute paths of source and destination for each file to be moved
  - Ask: "I will move [source path] to [destination path]. This will [create new file/overwrite existing file]. Do you want to proceed? (yes/no)"
- Before cleaning up temporary directories, show the full path and ask: "I will delete the temporary directory at [full path] and all its contents. Do you want to proceed? (yes/no)"
- Test the configuration by asking Claude Code: "I just set up new instructions for you. Is everything set up correctly? Do all references work? Are the instructions self-contained, can you read them entirely without fetching files from the Internet? Is there anything that confuses you?"
- If a git repository is set up, before committing show what will be committed and ask: "I will commit the following files to git: [list of full paths]. The commit message will be: '[proposed message]'. Do you want to proceed? (yes/no)" Don't push them.
