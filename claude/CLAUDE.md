# Programming guidelines for AI agents

My coding guidelines are at https://github.com/a-gn/ai-tool-config/blob/main/project_instructions

## If there are project-specific instructions

Follow the project's instructions. They take precedence over my personal instruction files.

## If there are no project-specific instructions

Fetch mine at https://github.com/a-gn/ai-tool-config/blob/main/project_instructions and follow them. Fetch referenced files as needed.

If you browse the instructions on the Web instead of reading them locally, it's best to use the `gh` CLI tool. If it's not available, ask the user whether to install it or fall back to Web fetching.

## If you set up a new project, or if I ask you to include my instructions into a project

- Fetch my instructions and insert all of them (including optional files) into the project's repository. Prefer downloading the instructions with GitHub's archive functionality, then moving them and editing them in place, instead of slowly downloading each file and reading them unnecessarily.
- Remove files specific to languages the project doesn't use, from the file hierarchy and the index.
- The `CLAUDE.md` file should be where Claude Code will find it if started at the project's root.
- The repository's instructions should then be self-contained, without needing to fetch further files.
- Commit the new instructions if git is set up.
