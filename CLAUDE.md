# Programming Guidelines and Preferences

## General Coding Principles

- **Maintainability first**: Write code that clearly shows intent. Use descriptive names that help first-time readers understand the purpose. Don't abbreviate unless it would make things more readable. Be especially careful when abbreviating to one letter. Prefer full words when reasonable.
- **Minimal scope changes**: Only modify what's needed for the specific task. Don't refactor unrelated code unless explicitly requested.
- **Complete implementations**: Write full-featured code. If something can't be implemented, explicitly state what's missing rather than using placeholder functions or dummy return values.
- **Pure functions preferred**: Use pure functions when applicable. Only introduce side effects (like in-place modifications) when there's a significant advantage in performance or maintainability. Always document side effects clearly.
- **Simple solutions first**: Start with straightforward approaches before adding complexity.
- **Dependencies at top**: All imports and includes must be at the top of files. Dependencies should be clearly visible and well-organized.
- **Testable design**: Write code in small, focused units with clear interfaces to enable comprehensive testing.
- **Deduplication**: Eliminate code duplication across all contexts and languages.
- **Cross-platform code**: Write cross-platform code. If you must implement something platform-dependently, wrap it and isolate it from the rest of the code (e.g., separate compilation units with #ifs while keeping headers clean).
- **Smart dependency strategy**: Prefer the standard library first, then established libraries (boost for C++). Prefer implementing utilities for things that can be easily implemented by us over pulling a new dependency. Use dependencies for truly valuable things like UI frameworks, optimization libraries, etc.

## Code Validation Requirements

- **Static analysis emphasis**: Make code as statically checkable as possible given the language to catch errors before runtime.
- **Follow best practices**: Follow language-specific best practices and style guides. When unsure, fetch relevant documentation, PEPs, or language specifications.
- **Fix all warnings**: Fix any warnings that appear during test runs, static analysis, or when running code (including developer warnings, deprecation warnings, etc.), unless they are another library's responsibility. This includes pytest warnings even when tests are passing.
- **Tests must pass**: All tests must pass in both Python and C++ before finalizing code.
- **Tool installation allowed**: Agents are permitted to install required tools (pyright, ruff, etc.) using the current environment (uv, etc.).

## Testing Requirements

- **Unit tests for critical functionality**: Write comprehensive unit tests for anything that matters to system correctness or business logic.
- **Regression testing**: When fixing bugs or issues, add regression tests to prevent future recurrence if the issue could cause problems again.
- **Instantaneous execution**: All tests must run as close to instantaneously as possible:
  - No reliance on external executables unless absolutely necessary
  - No requests to servers not controlled by the tests
  - Use mocking/stubbing for external dependencies
  - Focus on pure logic testing where possible
- **Test isolation**: Each test should be independent and not rely on shared state.

## Python-Specific Requirements

### Language Features
- Python 3.12 features are allowed (not required), but prefer `|` for union types and built-in generic types (`list`, `dict`, etc.)
- Minimize external dependencies: standard library first, then popular domain-specific libraries
- Use `click` for CLI argument parsing with proper type hints and explicit conversions
- Use `pathlib.Path` and `pathlib.PurePath` for path handling as warranted, supplemented by `os`, `shutil`, and `glob` as needed. Do not use `str` for paths unless warranted (e.g. converting for an outside library or manipulating S3 "paths").

### Import Organization
```python
import json
import logging
from pathlib import Path
from typing import Sequence

import click
import numpy as np

from .utils import helper_function
from .models import DataModel
```

**Note**: Keep imports organized (standard library, third-party, local) but don't prevent import/include sorting with comments or other mechanisms unless absolutely necessary (e.g., platform-specific includes like `#include <Windows.h>` which should be kept contained in separate compilation units anyway). Don't add lines between includes and imports that would prevent automatic import organizers from doing their job, unless you need to.

### Type System
- **Type hint everything**: Use the loosest constraints that satisfy requirements
- **Fill all generic type arguments**: Provide type arguments for all generics, not just collections (e.g., `Callable[[int, str], bool]`, `Sequence[float]`, `Mapping[str, list[int]]`)
- **Immutable defaults**: Prefer `()` over `[]` for sequence defaults to avoid mutation traps
- **Strict Optional handling**: Mark all variables that can be `None` using `| None` syntax
- **Precise sequence types**: Don't use `Sequence[T]` for any T that itself is a `Sequence[T]`. Use `list[str]` or `tuple[str, ...]` instead of `Sequence[str]`
- **Callable vs Protocol**: Use `Callable` for simple callbacks with few arguments, or whenever you think it makes more sense. For functions with more complex interfaces, use `Protocol`. You have leeway to do what you think is best.
- **Callable type hints must guarantee**: Callable type hints for interfaces should guarantee that an argument that follows them actually provides what is needed.

### Function Design
- **Return value typing**: Functions returning multiple values should use either:
  - Typed tuples with clear types for each value: `tuple[list[float], ProcessingMetadata]`
  - Dataclasses with descriptive names for complex return data
- **Dataclass usage**: Any grouping of values that needs to be passed around can be a dataclass. Only make function arguments a dataclass if there's a large set of them and grouping them makes logical sense. By default, stick with simple function signatures.

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
- **Project-wide documentation**: If a project includes a documentation folder, reference, or any other documentation that exists outside the code, for users or developers, update it as needed after making changes

### Code Quality
- **Input validation**: Validate user inputs with helpful error messages including expected vs actual values
- **Internal assertions**: Use `assert` for debugging internal consistency (assume disabled in production)
- **Process exit codes**: Always check subprocess return codes and log command details
- **Constraint documentation**: Clearly specify expected properties of arguments and guarantees about return values
- **PEP8 compliance**: Follow PEP8 standards with 120-character line limit

### Validation Workflow
Before finalizing any Python code, run these commands and fix all issues:

1. **Static type checking**: `pyright .` (standard mode, zero errors)
2. **Linting**: `ruff check .` (zero errors)
3. **Formatting and import sorting**: `ruff format . && ruff check --select I --fix .`
4. **Test execution**: Run tests and ensure they pass with no warnings

## C++ Requirements

### Language Features
- Use C++20 features and modern practices
- Prefer standard library, then boost for additional functionality
- Use CMake for build configuration

### Code Quality Tools
- **Formatting**: Use `clang-format` for consistent code formatting
- **Static analysis**: Use `clang-tidy` for static analysis and linting
- **Build system**: Use CMake with appropriate compiler flags
- **Fix compilation warnings**: Address all compilation warnings, not just errors

### Validation Workflow
Before finalizing C++ code:

1. **Static analysis**: Run `clang-tidy` and fix all warnings
2. **Formatting**: Run `clang-format` to ensure consistent style
3. **Build and test**: Ensure code compiles without warnings and all tests pass

## CLI Development with Click
```python
import click
from pathlib import Path

@click.command()
@click.option('--input-file', type=click.Path(exists=True, path_type=Path), required=True, 
              help='Path to input file. Must exist and be readable.')
@click.option('--output-file', type=click.Path(path_type=Path), required=False,
              help='Optional output file path.')
@click.option('--threshold', type=float, default=0.5,
              help='Threshold value between 0.0 and 1.0 (default: 0.5)')
def main(input_file: Path, output_file: Path | None, threshold: float) -> None:
    """Process input file with specified threshold."""
    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter('Threshold must be between 0.0 and 1.0')
```

## Example Function Template
```python
from dataclasses import dataclass
from logging import getLogger
from typing import Sequence

_log = getLogger(__name__)

@dataclass
class ProcessingMetadata:
    """Metadata about data processing results."""
    mean_value: float
    std_deviation: float
    total_windows: int
    processing_time_ms: float

def process_data(
    input_data: Sequence[float], 
    window_size: int,
    normalize: bool = True
) -> tuple[list[float], ProcessingMetadata]:
    """Process numerical data with sliding window analysis.
    
    Initial version written by Claude Sonnet 4 on 2025/08/15
    
    @param input_data: Sequence of numerical values to process. Must have at least 
                      `window_size` elements.
    @param window_size: Size of sliding window. Must be positive and <= len(input_data).
    @param normalize: Whether to normalize results to [0, 1] range.
    @return: Tuple of (processed_values, metadata) where metadata contains 
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
    processed_values: list[float] = []
    metadata = ProcessingMetadata(
        mean_value=0.0,
        std_deviation=0.0, 
        total_windows=len(input_data) - window_size + 1,
        processing_time_ms=0.0
    )
    
    return processed_values, metadata
```

## Key Reminders
- Ask for clarifications when requirements are unclear
- Prefer explicit over implicit behavior
- Document any performance trade-offs or design decisions
- Use logging levels appropriately (DEBUG for internal details, INFO for user-relevant events)
- Always validate inputs at function boundaries with helpful error messages
- Write tests that execute instantly without external dependencies
- Add regression tests when fixing issues that could recur
- Keep all dependencies clearly visible and organized
- Apply these principles consistently across all programming languages and contexts