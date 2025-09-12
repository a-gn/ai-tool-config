# Programming guidelines for AI agents

## Behavior

### Installing tools

If you need tools that aren't installed, such as the `gh` GitHub CLI tool or a type checker, linter, formatter, testing framework, etc. used by the current project, you can install them. Try to change the user's environment as little as possible. Do not install new package management tools. Always suggest an installation method adapted to the environment and project and ask the user if this is what they want.

### Dependencies

Use code in this order: the language's standard library, the project's internal code, then third-party libraries if they are needed.

Minimize the dependencies you add in your code. If you can implement something robustly with what is already available (i.e. already in the project's dependencies, not just installed on the system), do that. Only add dependencies when the feature shouldn't reasonably be implemented in the current project, for example if your task involves deep learning and the project doesn't already depend on a deep learning framework.

Make sure to update a project's configuration and lockfile, if any, to reference the dependencies you are adding. Follow best practices for the given system. For example, in a Python project using `uv`, you can `uv add some_project~=2.0`.

### Errors

Do not try to bypass errors, suppress exceptions, handle problematic conditions by disabling features, etc. If something is wrong, clearly report it. This applies to code (programs and units should crash early if something the user/caller requested is not possible) and to your own behavior (you should implement what was asked without shortcuts like making imports optional, disabling static analysis, making tests skippable, etc.)

As a rule, code should either crash or do _everything_ the user asked for. If you don't know how to solve something without a workaround, pause and ask me.

Always document the constraints on a unit's inputs and check those constraints. Report an error and do not continue if something is wrong with the inputs.

### Simplicity

When you design a piece of code or make large changes, think about how to keep the result as simple and concise as possible. Check if you can re-use or extend existing units of code before writing new ones. You should lean towards short diffs, factoring, and removing lines by default.

## Python Development Guidelines

### Type System & Language Features

```python
"""Module documentation.

[ONLY write the line below if you are writing this module for the first time.]
Originally written by [agent name] on [date in YYYY/MM/DD format].
"""

# Imports ALWAYS at the top
# No optional imports, no `except ImportError`, just let Python handle it
# Nothing between import lines, all imports in one block, so that import sorters work
# Standard library, then external packages, then project-internal stuff
from collections.abc import Mapping, Sequence
from pathlib import Path

from external_lib import external_thing

from current_project import internal_thing

# Immutable argument types and defaults: `Sequence[]` or `tuple[]` over `list[]`, for example
# Also, avoid `| None` unless required. The empty case is well-represented by an empty collection here
def process_items(input_items: tuple[str, ...] = ()) -> dict[str, int]:
    """Process items with modern typing and immutable default."""
    item_length_mapping: dict[str, int] = {}
    for current_item in input_items:
        item_length_mapping[current_item] = len(current_item)
    return item_length_mapping

# Here the absence of a collection is different from an empty collection, it has meaning. We use `| None`
def process_optional_items(input_items: tuple[str, ...] | None) -> dict[str, int]:
    """When None is meaningful, handle explicitly."""
    if input_items is None:
        return {}
    return {current_item: len(current_item) for current_item in input_items}

# Type system examples - when to use Sequence vs specific types
def process_various_collections(
    integer_values: Sequence[int],        # Good: int is not a sequence
    float_measurements: Sequence[float],  # Good: float is not a sequence
    byte_data: Sequence[bytes],          # Good: bytes is not a sequence
    name_list: tuple[str, ...],          # Immutable - avoid Sequence[str] since str is itself a Sequence[str]
    config_mapping: Mapping[str, int]    # Good: use Mapping for dict-like inputs
) -> tuple[tuple[int, ...], dict[str, float]]:
    """Process various collection types showing proper type hints.
    
    Pure function with immutable inputs and outputs.
    
    @param integer_values: Any sequence of integers (list, tuple, etc.)
    @param float_measurements: Any sequence of floats
    @param byte_data: Any sequence of byte strings
    @param name_list: Immutable tuple of strings (avoid Sequence[str])
    @param config_mapping: Any mapping from strings to integers
    @return: Processed integers and float statistics (both immutable)
    """
    # Process sequences where element type is not itself a sequence
    processed_ints = tuple(value * 2 for value in integer_values)
    
    # For strings, be specific about tuple to avoid sequence confusion and ensure immutability
    cleaned_names = tuple(name.strip() for name in name_list if len(name.strip()) > 0)
    
    # Mapping allows dict, defaultdict, etc. - return new dict (pure function)
    statistics = {key: float(value) for key, value in config_mapping.items()}
    
    return processed_ints, statistics

# Non-pure function: make it clear what the side-effects are. Mutable argument type is necessary, so accepted
def add_integer_sequence_to_list(list_to_modify: list[float], maximum_integer: int) -> None:
    """Modify a list in-place to add numbers to it.
    
    @param list_to_modify The collection to which we will add numbers. It will be modified in place.
    @param maximum_integer We will add integers from 0 to this one, included. Must be strictly positive.
    """

    if maximum_integer <= 0:
        raise ValueError(f"maximum_integer must be strictly positive, we got {maximum_integer}")
    list_to_modify.extend(range(0, maximum_integer + 1))
```

### Exception Handling & Logging

ALWAYS let exceptions percolate up by default. Do NOT suppress errors.

Only suppress an exception and use `_log.warning(...)` if EVERYTHING the user asked for can still be done. If any part of it is compromised, raiee instead. Warnings are for recoverable conditions.

```python
import json
import subprocess
from logging import getLogger
from pathlib import Path

_log = getLogger(__name__)

def read_config(config_path: Path) -> dict[str, str]:
    """Read configuration file.
    
    @param config_path: Path to configuration file
    @return: Configuration dictionary
    @raises FileNotFoundError: If config file doesn't exist
    @raises ValueError: If config format is invalid
    """
    # Conserve exception tracebacks with 'from'
    try:
        with config_path.open() as config_file:
            configuration_data = json.load(config_file)
    except json.JSONDecodeError as json_error:
        raise ValueError(f"Invalid JSON in config file {config_path}: {json_error}") from json_error
    except OSError as os_error:
        raise FileNotFoundError(f"Cannot read config file {config_path}") from os_error
    # NO `except Exception`, let exceptions you didn't plan for percolate up
    
    _log.debug(f"Loaded config from {config_path}")
    return configuration_data

# Input validation with helpful messages
def calculate_average(input_values: tuple[float, ...]) -> float:
    """Calculate average of numeric values."""
    if len(input_values) == 0:
        raise ValueError("Cannot calculate average of empty sequence")
    if any(current_value < 0 for current_value in input_values):
        negative_values = [current_value for current_value in input_values if current_value < 0]
        raise ValueError(f"All values must be non-negative, got: {negative_values}")
    return sum(input_values) / len(input_values)

def main():
    # NO global `try: ... except Exception: ...` that just prints errors, let Python show a stack trace
    config = read_config("./config_path.json")
```

### CLI with Click

```python
import click
from pathlib import Path

@click.command()
@click.option('--input-file', type=click.Path(exists=True, path_type=Path), required=True)
@click.option('--threshold', type=float, default=0.5, help='Threshold (0.0-1.0)')
@click.option('--output-dir', type=click.Path(path_type=Path), help='Output directory')
def main(input_file: Path, threshold: float, output_dir: Path | None) -> None:
    """Process input file with threshold filtering.
    
    Click options must be: required=True, have default, or be | None.
    """
    # Explicit type conversion and validation (reassign since types match)
    input_file = Path(input_file)  # Ensure proper Path type
    threshold = float(threshold)   # Explicit conversion
    output_dir = Path(output_dir) if output_dir is not None else None
    
    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter(f'Threshold must be 0.0-1.0, got {threshold}')
    
    _log.debug(f"Processing {input_file} with threshold={threshold}")
    
    # Use converted types for type safety
    process_file(input_file, threshold, output_dir)
```

### Subprocess Handling

```python
def run_command(command_arguments: tuple[str, ...], working_directory: Path | None = None) -> str:
    """Run shell command safely.
    
    @param command_arguments: Command and arguments to execute
    @param working_directory: Directory to run command in (None for current directory)
    @return: Command stdout output
    @raises subprocess.CalledProcessError: If command fails
    """
    # use JSON to log complex data precisely for reproduction
    _log.debug(f"Running command (logged as JSON): {json.dumps(command_arguments)}")
    
    # Always use check=True and capture output
    command_result = subprocess.run(
        command_arguments, 
        cwd=working_directory, 
        capture_output=True, 
        text=True, 
        check=True
    )
    
    return command_result.stdout.strip()
```

### Documentation Template

```python
def process_matrix(
    matrix_data: tuple[tuple[float, ...], ...], 
    processing_axis: int = 0,
    should_normalize: bool = True
) -> tuple[tuple[tuple[float, ...], ...], dict[str, float]]:
    """Process 2D matrix with optional normalization.
    
    Originally written by Claude Sonnet 4 on 2025/08/22
    
    @param matrix_data: 2D matrix as tuple of rows. Shape: (n_rows, n_cols).
                        All rows must have same length. Immutable for safety.
    @param processing_axis: Axis along which to process (0=rows, 1=columns)
    @param should_normalize: Whether to normalize to [0, 1] range
    @return: Tuple of (processed_matrix, statistics_dict) where statistics contains
             'mean', 'std', and 'range' statistics
    @raises ValueError: If matrix_data is empty, ragged, or processing_axis is invalid
    """
    # Input validation with helpful messages
    if len(matrix_data) == 0:
        raise ValueError("Input matrix_data cannot be empty")
    
    row_lengths = [len(matrix_row) for matrix_row in matrix_data]
    if len(set(row_lengths)) > 1:
        raise ValueError(f"All rows must have same length, got lengths: {row_lengths}")
    
    if processing_axis not in (0, 1):
        raise ValueError(f"processing_axis must be 0 or 1, got {processing_axis}")
    
    _log.debug(f"Processing {len(matrix_data)}x{len(matrix_data[0])} matrix along axis={processing_axis}")
    
    # Implementation...
    processed_matrix_data: tuple[tuple[float, ...], ...] = ()
    processing_statistics: dict[str, float] = {"mean": 0.0, "std": 0.0, "range": 0.0}
    
    return processed_matrix_data, processing_statistics
```

### Attribution Requirements

Add "Originally written by [model_name] on YYYY/MM/DD" to:
- **Modules**: At top of file docstring
- **Non-trivial functions/classes**: In docstring (prefer larger scopes)
- **Significant code units**: Any substantial implementation Claude creates

```python
"""Data processing utilities module.

Originally written by Claude Sonnet 4 on 2025/08/22
"""

class DataProcessor:
    """Main data processing class.
    
    Originally written by Claude Sonnet 4 on 2025/08/22
    """
    
    def simple_helper(self, input_value: int) -> int:
        """Simple helper - no attribution needed."""
        return input_value * 2
```

### Project Setup with uv

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

### Validation Workflow - IMPORTANT

After large changes, before committing, before PRs, if I ask you to validate, or if there's a good chance that some of this is broken:

```bash

# 1. Type checking (standard mode)
pyright

# 2. Linting and formatting
ruff check
ruff format
ruff check --select I --fix  # Import sorting

# 3. Tests with warnings as errors
pytest -v --tb=short -W error::UserWarning
```

Make sure that all are fixed before continuing. Run them again after fixes to make sure that fixing one doesn't break the others.
