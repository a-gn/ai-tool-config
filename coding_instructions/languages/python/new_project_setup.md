# Python Project Setup with uv

For new Python projects, use `uv` for fast dependency management:

```bash
# Create new project
uv init my-project
cd my-project

# Add dependencies
uv add click pathlib-extensions

# Add development dependencies
uv add --dev pytest pyright ruff

# Install and run
uv run python -m my_project
```
