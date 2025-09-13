# Project-specific AI agent instructions

This folder contains instructions for Claude Code that can be inserted into a project's repository.

## Installation instructions

If you are a human, you can tell Claude Code to fetch this file and execute these instructions.

Always clean up any temporary files you've created while doing this, whether you succeed or abort.
VERY IMPORTANT: ONLY delete or modify files that you created. At NO POINT should you overwrite or delete something that was there before you started this task. Ask the user about any risky operations. If you are not sure that you won't destroy files that you did not create yourself, DO NOT REMOVE ANYTHING and tell the user what the problem is.

- Create a new, unique temporary directory using the system's utilities dedicated to this. Perform the following instructions inside this temporary directory. Especially DO NOT DELETE OR MODIFY ANYTHING that isn't inside this new, temporary directory.
- Use GitHub's ZIP repository archive URL to fetch the entire AI instructions repository. Extract it.
- Remove files specific to languages the project doesn't use from the temporary directory, from the file hierarchy and the index. (If the project is a skeleton, guess from the existing configuration files and your context. Do not modify the project's repository itself.)
- Adapt the instructions to the project's setup if you find discrepancies. For example, if the instructions mention pytest but the project uses unittest, update the instructions.
- Remove the current file (the one containing installation instructions) from the temporary directory.
- The repository's instructions should then be self-contained, without needing to fetch further files.
- When the final instructions are ready, move them to the root of the project's repository. `CLAUDE.md` should be at the root of the project. The other files should be where it will be able to import them. If there are any conflicts, abort and ask the user what to do.
- If a git repository is set up, commit the new instructions and tell the user that you did. Don't push them.
