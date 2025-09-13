# Project-specific AI agent instructions

This folder contains instructions for Claude Code that can be inserted into a project's repository.

## Installation instructions

- Fetch the entire folder containing this file. Prefer downloading it in one request with GitHub's ZIP repository archive URL. Extract them at the root of the project's repository.
- If there are conflicts, abort, return to the original state before you started this, and tell the user about it.
- Remove files specific to languages the project doesn't use, from the file hierarchy and the index. (If the project is a skeleton, guess from the existing configuration files and your context.)
- The repository's instructions should then be self-contained, without needing to fetch further files.
- Once the instructions are set up, clean up the temporary downloads and unneeded files, including this current one, which should not be left in the repository.
- If a git repository is set up, commit the new instructions and tell the user that you did. Don't push them.
