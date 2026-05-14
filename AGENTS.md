# AI Tool Config Project Instructions

AGENTS.md is the file to modify for LLM instructions inside this project.
CLAUDE.md automatically imports AGENTS.md and should remain a simple reference.

This repository will be publicly exposed. It must not contain private information, secrets, credentials, tokens, private paths, account-specific state, unpublished personal details, or local machine configuration unless the user has explicitly requested publishing that exact content. Only add things the user has explicitly requested to publish.

When an agent adds, removes, or changes allowed commands for one agent, it should make the same change for the other agent unless otherwise specified and unless those settings are clearly agent-specific.

## Committing

Whenever you finish a change the user asked for, when it is self-contained and confirmed to work, commit and push it.
Use commit messages in this format: "$programName: $changeWeJustMade". Keep them short and clear.
Unless another instruction makes an exception, commit and push immediately.
When there are separate changes that are not part of the same task, commit them separately.
