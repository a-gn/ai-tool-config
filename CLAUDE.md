# Programming Guidelines and Preferences

## General Coding Principles

- **Maintainability first**: Write code that clearly shows intent. Use descriptive names that help first-time readers understand the purpose. Don't abbreviate unless it would make things *more* readable. Be especially careful when abbreviating to one letter - prefer full words when reasonable. Characters are cheap.
- **Static analysis first**: Write code to be as statically checkable as possible given the language constraints. Catch errors at compile/analysis time rather than runtime.
- **Cross-platform code**: Write cross-platform code by default. If platform-dependent implementation is needed, wrap it and isolate it from the rest of the code (e.g., separate compilation units with `#if`s, keeping headers clean).
- **Dependency strategy**: Prefer standard library first, then well-established libraries (boost for C++). Prefer implementing simple utilities yourself over adding dependencies. Use dependencies for truly valuable things like UI frameworks, optimization libraries, etc.
- **Minimal scope changes**: Only modify what's needed for the specific task. Don't refactor unrelated code unless explicitly requested.
- **Complete implementations**: Write full-featured code. If something can't be implemented, explicitly state what's missing rather than using placeholder functions or dummy return values.
- **Pure functions preferred**: Use pure functions when applicable. Only introduce side effects (like in-place modifications) when there's a significant advantage in performance or maintainability. Always document side effects clearly.
- **Simple solutions first**: Start with straightforward approaches before adding complexity.

## Code Validation Requirements

- **Static analysis**: All code must pass static type checking with zero errors
- **Linting**: All code must pass language-specific linting with zero errors
- **Formatting**: Use automated formatting tools before committing or finishing changes
- **Import organization**: Use tools to organize imports consistently
- **Tests must pass**: All tests must pass and any warnings during test runs must be fixed (unless they are another library's responsibility)
- **Follow best practices**: Adhere to language-specific style guides and best practices. Fetch relevant documentation, PEPs, or style guides when unsure.

## Python-Specific Requirements

### Language Features
- Python features up to 3.12 are allowed. Prefer `|` for union types and built-in generic types (`list`, `dict`, etc.)
- Minimize external dependencies: standard library first, then popular domain-specific libraries
- Use `click` for CLI argument parsing with proper type hints and explicit conversions
- Use `pathlib` for path handling, supplemented by `os`, `shutil`, and `glob` as needed

### Type System
- **Type hint everything**: Use the loosest constraints that satisfy requirements. Every function parameter, return value, and class attribute must have type annotations.
- **Precise type annotations**: Avoid `Any` unless absolutely necessary. Use specific protocols, unions, or generics instead.
- **Immutable defaults**: Prefer `()` over `[]` for sequence defaults to avoid mutation traps
- **Strict Optional handling**: Mark all variables that can be `None` as `| None`
- **Precise generic types**: Fill type arguments for all generics, not just collections (e.g., `Sequence[float]`, `Mapping[str, list[int]]`, `Optional[int]`, `Callable[[str, int], bool]`)
- **Callable type guarantees**: Callable type hints must guarantee that an argument following them actually provides what is needed - be specific about parameter types and return types
- **Avoid nested sequences**: Don't use `Sequence[T]` for any `T` that itself is a `Sequence[T]` (like `str`). Use `list[str]` or `tuple[str, ...]` instead.
- **Callable vs Protocol**: Use `Callable` for simple callbacks with few arguments. For functions with more complex interfaces, use `Protocol`s. Use your judgment for what makes most sense in each situation.
- **Literal types**: Use `Literal` types for string/int constants that have specific allowed values
- **Dataclasses for complex options**: Only use dataclasses for function arguments when there is a large set of them and grouping them makes logical sense. By default, stick with simple function signatures.
- **Dataclasses for return values**: Functions returning multiple values should use either a tuple with clear types for each value, or a dataclass with descriptive names. Any grouping of values that needs to be passed around can be a dataclass - use your judgment.

### Validation Workflow
1. Install pyright and ruff using the current environment (uv, pip, etc.) if not already available
2. Write code with complete type annotations
3. Run `pyright .` and fix all errors (standard mode)
4. Run `ruff check .` and fix all linting errors
5. Run `ruff format .` to format code
6. Run `ruff check --select I --fix .` to sort imports
7. Run tests and fix any warnings
8. Verify all validation steps pass before committing or finalizing changes

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

## C++ Requirements

### Language Features
- Use C++20 features when appropriate
- Prefer standard library first, then boost for additional functionality
- Prefer implementing simple utilities yourself over adding new dependencies
- Use dependencies for truly valuable functionality like UI frameworks, optimization libraries, etc.
- Use CMake for build configuration

### Validation Workflow
1. Install clang-format and clang-tidy if not already available
2. Write code with clear type annotations and const-correctness
3. Run clang-tidy for static analysis and fix all errors
4. Run clang-format for code formatting
5. Run tests and fix any warnings
6. Verify all validation steps pass before committing or finalizing changes

## CLI Development with Click (Python)
```python
import click
from pathlib import Path

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
@click.option(
    '--output-file',
    type=click.Path(path_type=Path),
    help='Optional output file path.'
)
def main(input_file: Path, threshold: float, output_file: Path | None) -> None:
    """Main CLI entry point with type-safe argument handling."""
    # Type-safe validation with pyright-friendly checks
    if not (0.0 <= threshold <= 1.0):
        raise click.BadParameter('Threshold must be between 0.0 and 1.0')
    
    # input_file is already a Path due to path_type parameter
    # output_file is optional and properly typed as Path | None
    process_file(input_file, threshold, output_file)

def process_file(input_path: Path, threshold: float, output_path: Path | None) -> None:
    """Process file with validated inputs."""
    # Implementation here...
    pass
```

## Example Function Template (Python)
```python
from collections.abc import Sequence
from dataclasses import dataclass

@dataclass
class ProcessingMetadata:
    """Metadata returned by process_data function."""
    mean: float
    std_dev: float
    window_count: int

def process_data(
    input_data: Sequence[float], 
    window_size: int,
    normalize: bool = True
) -> tuple[list[float], ProcessingMetadata]:
    """Process numerical data with sliding window analysis.
    
    Initial version written by Claude Sonnet 4 on 2025/08/15
    
    @param input_data: Sequence of numerical values to process. Must have at least 
                      `window_size` elements. All values must be finite.
    @param window_size: Size of sliding window. Must be positive and <= len(input_data).
    @param normalize: Whether to normalize results to [0, 1] range.
    @return: Tuple of (processed_values, metadata) where metadata contains 
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
    
    metadata = ProcessingMetadata(
        mean=sum(processed_values) / len(processed_values) if processed_values else 0.0,
        std_dev=0.0,  # Calculate actual std dev
        window_count=len(processed_values)
    )
    
    return processed_values, metadata
```

## Key Reminders
- **Static analysis is mandatory**: Never ignore type checker or linter errors
- **Ask for clarifications** when requirements are unclear, especially around type constraints
- **Prefer explicit over implicit** behavior, especially for types and error handling  
- **Document any performance trade-offs** or design decisions that affect static analysis
- **Use logging levels appropriately** (DEBUG for internal details, INFO for user-relevant events)
- **Always validate inputs** at function boundaries with helpful error messages
- **Run the full validation pipeline** before considering any code complete
- **Type safety over convenience**: Choose solutions that can be statically verified even if slightly more verbose