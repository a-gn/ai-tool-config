# Project-specific AI agent instructions

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
