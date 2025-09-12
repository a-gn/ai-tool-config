# Python Development Guidelines

## Type System & Language Features

```python
"""Module documentation.

[ONLY write the line below if you are writing this module for the first time.]
Originally written by [agent name] on [date in YYYY/MM/DD format].
"""

# Imports at the top, no optional imports, nothing between import lines, all imports in one block
# PEP8 followed: standard library, then external packages, then project-internal stuff
from collections.abc import Mapping, Sequence
from pathlib import Path

from external_lib import external_thing

from current_project import internal_thing

# Type system examples - when to use Sequence vs specific types
def process_items(input_items: tuple[str, ...] = ()) -> dict[str, int]:
    """Process items with modern typing and immutable default."""
    # Immutable default avoids mutable default trap
    item_length_mapping: dict[str, int] = {}
    for current_item in input_items:
        item_length_mapping[current_item] = len(current_item)
    return item_length_mapping

def process_optional_items(input_items: list[str] | None) -> dict[str, int]:
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
```

## Exception Handling & Logging

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
```

## CLI with Click

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

## Subprocess Handling

```python
def run_command(command_arguments: tuple[str, ...], working_directory: Path | None = None) -> str:
    """Run shell command safely.
    
    @param command_arguments: Command and arguments to execute
    @param working_directory: Directory to run command in (None for current directory)
    @return: Command stdout output
    @raises subprocess.CalledProcessError: If command fails
    """
    _log.debug(f"Running command: {' '.join(command_arguments)}")
    
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

## Documentation Template

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


## Attribution Requirements

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

## Project Setup with uv

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

## Validation Workflow - IMPORTANT

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

All must pass without errors.
