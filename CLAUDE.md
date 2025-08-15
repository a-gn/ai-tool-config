# Programming Guidelines and Preferences (Enhanced for Static Analysis)

## General Coding Principles

- **Maintainability first**: Write code that clearly shows intent. Use descriptive names that help first-time readers understand the purpose. Don't abbreviate unnecessarily—characters are cheap.
- **Static analysis first**: Write code to be as statically checkable as possible given the language constraints. Catch errors at compile/analysis time rather than runtime.
- **Minimal scope changes**: Only modify what's needed for the specific task. Don't refactor unrelated code unless explicitly requested.
- **Complete implementations**: Write full-featured code. If something can't be implemented, explicitly state what's missing rather than using placeholder functions or dummy return values.
- **Pure functions preferred**: Use pure functions when applicable. Only introduce side effects (like in-place modifications) when there's a significant advantage in performance or maintainability. Always document side effects clearly.
- **Simple solutions first**: Start with straightforward approaches before adding complexity.
- **Tests must pass**: All tests must pass in both Python and C++.

## Python-Specific Requirements

### Language Features
- Use Python 3.12 features including `|` for union types and built-in generic types (`list`, `dict`, etc.)
- Minimize external dependencies: standard library first, then popular domain-specific libraries
- Use `click` for CLI argument parsing with proper type hints and explicit conversions
- Use `pathlib` for path handling, supplemented by `os`, `shutil`, and `glob` as needed

### Type System (Enhanced for Static Checking)
- **Type hint everything**: Use the loosest constraints that satisfy requirements. Every function parameter, return value, and class attribute must have type annotations.
- **Precise type annotations**: Avoid `Any` unless absolutely necessary. Use specific protocols, unions, or generics instead.
- **Immutable defaults**: Prefer `()` over `[]` for sequence defaults to avoid mutation traps
- **Strict Optional handling**: Mark all variables that can be `None` as `Optional[]` or use `| None` syntax
- **Precise generic types**: Fill type arguments for all generics, not just collections (e.g., `Sequence[float]`, `Mapping[str, list[int]]`, `Optional[int]`, `Callable[[str, int], bool]`)
- **Callable type guarantees**: Callable type hints must guarantee that an argument following them actually provides what is needed - be specific about parameter types and return types
- **Avoid nested sequences**: Don't use `Sequence[T]` for any `T` that itself is a `Sequence[T]` (like `str`). Use `list[str]` or `tuple[str, ...]` instead.
- **Protocol usage**: Define and use protocols for duck typing to improve static analysis
- **Literal types**: Use `Literal` types for string/int constants that have specific allowed values
- **Dataclasses for complex options**: Only use dataclasses for function arguments when there is a large set of them and grouping them makes logical sense. By default, stick with simple function signatures.

### Static Analysis Requirements (NEW)
- **Tool installation**: Install pyright and ruff using the current environment (uv, pip, etc.) if not already available
- **Pyright compliance**: All code must pass pyright type checking in standard mode with zero errors
- **Ruff linting**: All code must pass ruff linting with zero errors using default configuration
- **Pre-commit formatting**: Always run `ruff format` and `ruff --fix` before committing or finishing large changes
- **Import organization**: Use ruff's import sorting (`ruff check --select I --fix`) to organize imports consistently

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
- **Type-safe error handling**: Use Result/Either patterns or typed exceptions where appropriate

### Documentation Requirements
- **Comprehensive docstrings**: Document all functions, classes, and modules
- **Parameter documentation**: Use `@param`, `@return`, and `@raises` style
- **Array/tensor shapes**: Always document shapes, dtypes, and axis meanings
- **Implementation comments**: Explain non-obvious design choices and main algorithm steps
- **Concise language**: Use correct English but avoid unnecessary verbosity
- **Attribution**: For complex modules/functions, include: "Initial version written by [model_name] on YYYY/MM/DD"
- **Type constraints**: Document any runtime constraints that can't be expressed in the type system

### Code Quality
- **Input validation**: Validate user inputs with helpful error messages including expected vs actual values
- **Internal assertions**: Use `assert` for debugging internal consistency (assume disabled in production)
- **Process exit codes**: Always check subprocess return codes and log command details
- **Constraint documentation**: Clearly specify expected properties of arguments and guarantees about return values
- **Defensive programming**: Use type guards and runtime checks for external data that can't be statically verified

### Static Analysis Workflow (NEW)
1. Write code with complete type annotations
2. Run `pyright .` and fix all errors (standard mode)
3. Run `ruff check .` and fix all linting errors
4. Run `ruff format .` to format code
5. Run `ruff check --select I --fix .` to sort imports
6. Verify all tools pass before committing or finalizing changes

### Formatting
- Follow PEP8 standards
- Line length limit: 120 characters (especially important for docstrings and comments)
- Use ruff for automatic formatting and import organization
- Code will be auto-formatted, so focus on logical structure over exact spacing

## CLI Development with Click (Enhanced)
```python
import click
from pathlib import Path
from typing import Optional

@click.command()
@click.option(
    '--input-file', 
    type=click.Path(exists=True, path_type=Path), 
    required=True, 
    help='Path to input file. Must exist and be readable.'
)
@click.option(
    '--threshold', 
    type=float, 
    default=0.5,
    help='Threshold value between 0.0 and 1.0 (default: 0.5)'
)
def main(input_file: Path, threshold: float) -> None:
    """Main CLI entry point with type-safe argument handling."""
    # Type-safe validation with pyright-friendly checks
    if not (0.0 <= threshold <= 1.0):
        raise click.BadParameter('Threshold must be between 0.0 and 1.0')
    
    # input_file is already a Path due to path_type parameter
    process_file(input_file, threshold)

def process_file(input_path: Path, threshold: float) -> None:
    """Process file with validated inputs."""
    # Implementation here...
    pass
```

## Example Function Template (Enhanced)
```python
from collections.abc import Sequence

def process_data(
    input_data: Sequence[float], 
    window_size: int,
    normalize: bool = True
) -> tuple[list[float], dict[str, float]]:
    """Process numerical data with sliding window analysis.
    
    Initial version written by Claude Sonnet 4 on 2025/08/15
    
    @param input_data: Sequence of numerical values to process. Must have at least 
                      `window_size` elements. All values must be finite.
    @param window_size: Size of sliding window. Must be positive and <= len(input_data).
    @param normalize: Whether to normalize results to [0, 1] range.
    @return: Tuple of (processed_values, metadata_dict) where metadata contains 
             statistics about the processing.
    @raises ValueError: If window_size is invalid, input_data is too short, or 
                       contains non-finite values.
    """
    if window_size <= 0:
        raise ValueError(f"window_size must be positive, got {window_size}")
    if len(input_data) < window_size:
        raise ValueError(
            f"input_data length ({len(input_data)}) must be >= window_size ({window_size})"
        )
    
    # Type-safe validation for finite values
    if not all(isinstance(x, (int, float)) and not (x != x or x == float('inf') or x == float('-inf')) 
               for x in input_data):
        raise ValueError("All input_data values must be finite numbers")
    
    _log.debug("Processing %d values with window_size=%d", len(input_data), window_size)
    
    # Implementation with explicit types
    processed_values: list[float] = []
    # ... processing logic ...
    
    metadata: dict[str, float] = {
        'mean': sum(processed_values) / len(processed_values) if processed_values else 0.0,
        'std_dev': 0.0,  # Calculate actual std dev
        'window_count': float(len(processed_values))
    }
    
    return processed_values, metadata
```

## Key Reminders (Enhanced)
- **Static analysis is mandatory**: Never ignore type checker or linter errors
- **Ask for clarifications** when requirements are unclear, especially around type constraints
- **Prefer explicit over implicit** behavior, especially for types and error handling  
- **Document any performance trade-offs** or design decisions that affect static analysis
- **Use logging levels appropriately** (DEBUG for internal details, INFO for user-relevant events)
- **Always validate inputs** at function boundaries with helpful error messages
- **Run the full static analysis pipeline** before considering any code complete
- **Type safety over convenience**: Choose solutions that can be statically verified even if slightly more verbose
