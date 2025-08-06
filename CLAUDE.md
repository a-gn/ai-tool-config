# Programming Guidelines and Preferences

**THESE INSTRUCTIONS ARE VERY IMPORTANT AND YOU MUST FOLLOW THEM CAREFULLY. GO BACK TO THEM AFTER WRITING CODE TO MAKE SURE THAT YOU FOLLOWED ALL OF THEM.**

## General Coding Principles

- **Maintainability first**: Write code that clearly shows intent. Use descriptive names that help first-time readers understand the purpose. Don't abbreviate unnecessarily—characters are cheap.
- **Minimal scope changes**: Only modify what's needed for the specific task. Don't refactor unrelated code unless explicitly requested.
- **Complete implementations**: Write full-featured code. If something can't be implemented, explicitly state what's missing rather than using placeholder functions or dummy return values.
- **Pure functions preferred**: Use pure functions when applicable. Only introduce side effects (like in-place modifications) when there's a significant advantage in performance or maintainability. Always document side effects clearly.
- **Simple solutions first**: Start with straightforward approaches before adding complexity.
- **Focus on current file only** unless asked otherwise
- **No verbose progress updates**
- **Prefer simple solutions**

## Python-Specific Requirements

### Language Features
- **Use Python 3.9**: Be compatible with this version (not 3.12 features)
- **Prefer uv when creating new projects**: Use uv for project initialization and dependency management
- **Minimal dependencies**: If something can be done easily in our code, don't add a dependency for it. Standard library first, then popular domain-specific libraries only when truly necessary
- Use `click` for CLI argument parsing with proper type hints and explicit conversions
- Use `pathlib` for path handling, supplemented by `os`, `shutil`, and `glob` as needed

### Type System - CRITICAL REQUIREMENTS
- **Always include type hints for everything**:
```python
def my_function(param1: str, param2: Optional[int] = None) -> bool:
    pass

class MyClass:
    def __init__(self, items: list[str]) -> None:
        self.items = items
```
- **Precise typing requirements**:
  - Avoid `Any` unless absolutely necessary (e.g., truly dynamic content)
  - Always specify complete type arguments for collections: `list[str]`, `dict[str, int]`, `set[Path]`
  - Track type arguments recursively: `dict[str, list[tuple[int, float]]]`
  - Use union types for known alternatives: `Union[str, int]` not `Any`
  - Preserve and propagate specific types throughout function chains
  - When uncertain about a type, investigate and use the most specific type possible
- **Required type patterns**:
  - Use `list[T]`, `dict[K, V]` not `List[T]`, `Dict[K, V]`
  - **Never use `Sequence[str]`**: Use `list[str]` or `tuple[str, ...]` since `str` is itself a sequence
  - Use `Optional[T]` for nullable types
  - **Immutable defaults**: Prefer `()` over `[]` for sequence defaults to avoid mutation traps
  - **Strict Optional handling**: Mark all variables that can be `None` as `Optional[]`

### Error Handling and Logging
```python
from logging import getLogger
_logger = getLogger(__name__)

# Use _logger.info(), etc. not print()
```

- **Error handling rules**:
  - Use specific exceptions, not bare `except:`
  - Let exceptions propagate unless you can handle them
  - Functions must succeed or raise an exception
- **Specific exception handling**: Only catch specific exception types at levels that can handle them
- **Let exceptions propagate**: Don't catch indiscriminately unless explicitly requested
- **Subprocess safety**: Always use `check=True` and log full CLI commands at DEBUG level
- **Structured logging**: Use JSON format for complex debugging information
- **Input validation**: Check constraints with clear `ValueError` messages that help fix the problem

### Required Code Patterns
- **Use f-strings**: `f"Value: {x}"` not `"Value: {}".format(x)`
- **Use `Optional[T]`** for nullable types
- **Use `list[T]`, `dict[K, V]`** not `List[T]`, `Dict[K, V]`
- **Never use `Sequence[str]`** (use `list[str]` instead)

### Security Practices
- **Input sanitization**: Validate and sanitize all external inputs
- **SQL injection**: Always use parameterized queries, never string concatenation
- **Path traversal**: Use `Path.resolve()` and validate paths stay within expected directories
- **Secrets**: Never log secrets, use environment variables or secret management

### Performance Considerations
- **Premature optimization**: Document when and why you're optimizing
- **Memory usage**: Be explicit about memory-intensive operations and cleanup
- **I/O patterns**: Batch I/O operations when possible, use async for network calls

### Testing Strategy
- **Test pyramid**: Unit tests for logic, integration tests for workflows, minimal E2E
- **Static type checking preferred**: Rely on type system, but allow `TypeGuard` functions for runtime type checking when they help
- **API design for testability**: Prefer APIs that let tests change what they need (passing values computed in the caller or callables) to mocking
- **Mock strategy**: Only mock when it makes more sense than dependency injection or parameterization
- **Test data**: Use factories/fixtures for complex data. Allow generated data only if necessary (vs all-zero examples) and only if reproducible (using modern numpy random API with fixed generator algorithm and seed). Prefer the smallest data that enables a test case

### Debugging Guidelines
- **Reproducible environments**: Document exact versions and environment setup
- **Debug logging**: Use structured logging with sufficient context to understand what's happening
- **State inspection**: Prefer debugger over print statements
- **Minimal reproduction**: Create minimal examples that reproduce issues

### Documentation Requirements - CRITICAL
- **Always add docstrings with `@param` format**:
```python
"""This module does X.

Initially written entirely by Claude Sonnet 4 on 2025/07/28.
"""
# Should contain the real model and date, only for new files.

def process_data(input_path: Path, threshold: float) -> dict[str, str]:
    """Process data from input file and return results.
    
    @param input_path: Path to the input data file
    @param threshold: Minimum threshold value for processing
    @return: Dictionary containing processed results
    """
```
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
from pathlib import Path
from typing import Optional

@click.command()
@click.option('--input-file', type=click.Path(exists=True, path_type=Path), required=True, 
              help='Path to input file. Must exist and be readable.')
@click.option('--threshold', type=float, default=0.5,
              help='Threshold value between 0.0 and 1.0 (default: 0.5)')
def main(input_file: Path, threshold: float) -> None:
    # Explicit validation
    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter('Threshold must be between 0.0 and 1.0')
```

## Example Function Template
```python
def process_data(
    input_data: list[float], 
    window_size: int,
    normalize: bool = True
) -> tuple[list[float], dict[str, float]]:
    """Process numerical data with sliding window analysis.
    
    Initial version written by Claude Sonnet 4 on 2025/08/05
    
    @param input_data: List of numerical values to process. Must have at least 
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
    
    _logger.debug(f"Processing {len(input_data)} values with window_size={window_size}")
    
    # Implementation here...
    return processed_values, metadata
```

## Key Reminders
- Ask for clarifications when requirements are unclear
- Prefer explicit over implicit behavior
- Document any performance trade-offs or design decisions
- Use logging levels appropriately (DEBUG for internal details, INFO for user-relevant events)
- Always validate inputs at function boundaries with helpful error messages
- When refactoring, preserve existing behavior unless explicitly asked to change it
- Always run tests after making changes, even for "simple" modifications
- If you're unsure about a requirement, ask for clarification rather than assuming
- Consider backwards compatibility impact when modifying public APIs

