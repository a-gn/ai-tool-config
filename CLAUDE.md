# Programming Guidelines and Preferences

## General Coding Principles

- **Maintainability first**: Write code that clearly shows intent. Use descriptive names that help first-time readers understand the purpose. Don't abbreviate unnecessarily—characters are cheap.
- **Minimal scope changes**: Only modify what's needed for the specific task. Don't refactor unrelated code unless explicitly requested.
- **Complete implementations**: Write full-featured code. If something can't be implemented, explicitly state what's missing rather than using placeholder functions or dummy return values.
- **Pure functions preferred**: Use pure functions when applicable. Only introduce side effects (like in-place modifications) when there's a significant advantage in performance or maintainability. Always document side effects clearly.
- **Simple solutions first**: Start with straightforward approaches before adding complexity.

## Python-Specific Requirements

### Language Features
- Use Python 3.12 features including `|` for union types and built-in generic types (`list`, `dict`, etc.)
- Minimize external dependencies: standard library first, then popular domain-specific libraries
- Use `click` for CLI argument parsing with proper type hints and explicit conversions
- Use `pathlib` for path handling, supplemented by `os`, `shutil`, and `glob` as needed

### Type System
- **Type hint everything**: Use the loosest constraints that satisfy requirements
- **Immutable defaults**: Prefer `()` over `[]` for sequence defaults to avoid mutation traps
- **Strict Optional handling**: Mark all variables that can be `None` as `Optional[]`
- **Precise generic types**: Fill type arguments for collections (e.g., `Sequence[float]`, `Mapping[str, list[int]]`)
- **Avoid `Sequence[str]`**: Use `list[str]` or `tuple[str, ...]` since `str` is itself a sequence

### Error Handling and Logging
```python
from logging import getLogger
_log = getLogger(__name__)
```

- **Specific exception handling**: Only catch specific exception types at levels that can handle them
- **Let exceptions propagate**: Don't catch indiscriminately unless explicitly requested
- **Subprocess safety**: Always use `check=True` and log full CLI commands at DEBUG level
- **Structured logging**: Use JSON format for complex debugging information
- **Input validation**: Check constraints with clear `ValueError` messages that help fix the problem

### Documentation Requirements
- **Comprehensive docstrings**: Document all functions, classes, and modules
- **Parameter documentation**: Use `@param`, `@return`, and `@raises` style
- **Array/tensor shapes**: Always document shapes, dtypes, and axis meanings
- **Implementation comments**: Explain non-obvious design choices and main algorithm steps
- **Concise language**: Use correct English but avoid unnecessary verbosity
- **Attribution**: For complex modules/functions, include: "Initial version written by [model_name] on YYYY/MM/DD"

### Code Quality
- **Input validation**: Validate user inputs with helpful error messages including expected vs actual values
- **Internal assertions**: Use `assert` for debugging internal consistency (assume disabled in production)
- **Process exit codes**: Always check subprocess return codes and log command details
- **Constraint documentation**: Clearly specify expected properties of arguments and guarantees about return values

### Formatting
- Follow PEP8 standards
- Line length limit: 120 characters (especially important for docstrings and comments)
- Code will be auto-formatted, so focus on logical structure over exact spacing

## CLI Development with Click
```python
import click
from typing import Optional

@click.command()
@click.option('--input-file', type=click.Path(exists=True), required=True, 
              help='Path to input file. Must exist and be readable.')
@click.option('--threshold', type=float, default=0.5,
              help='Threshold value between 0.0 and 1.0 (default: 0.5)')
def main(input_file: str, threshold: float) -> None:
    # Explicit type conversion and validation
    input_path = Path(input_file)
    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter('Threshold must be between 0.0 and 1.0')
```

## Example Function Template
```python
def process_data(
    input_data: Sequence[float], 
    window_size: int,
    normalize: bool = True
) -> tuple[list[float], dict[str, float]]:
    """Process numerical data with sliding window analysis.
    
    Initial version written by Claude Sonnet 4 on 2025/08/05
    
    @param input_data: Sequence of numerical values to process. Must have at least 
                      `window_size` elements.
    @param window_size: Size of sliding window. Must be positive and <= len(input_data).
    @param normalize: Whether to normalize results to [0, 1] range.
    @return: Tuple of (processed_values, metadata_dict) where metadata contains 
             statistics about the processing.
    @raises ValueError: If window_size is invalid or input_data is too short.
    """
    if window_size <= 0:
        raise ValueError(f"window_size must be positive, got {window_size}")
    if len(input_data) < window_size:
        raise ValueError(
            f"input_data length ({len(input_data)}) must be >= window_size ({window_size})"
        )
    
    _log.debug(f"Processing {len(input_data)} values with window_size={window_size}")
    
    # Implementation here...
    return processed_values, metadata
```

## Key Reminders
- Ask for clarifications when requirements are unclear
- Prefer explicit over implicit behavior
- Document any performance trade-offs or design decisions
- Use logging levels appropriately (DEBUG for internal details, INFO for user-relevant events)
- Always validate inputs at function boundaries with helpful error messages

