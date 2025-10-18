Please run static analysis on the code to find and fix any issues.

## Which tools to use

If the project is configured to use a given set of tools, use them. Otherwise, refer to the default rules below.

### Default tools per language

#### Python

Run:

- pyright in standard mode,
- ruff for linting,
- pytest for testing (or whatever the current project uses).

#### C++

Check for compiler errors and linter errors.

#### Other languages

Use whatever tool is commonly used to analyze and lint code in the current language.
