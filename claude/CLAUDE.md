# AI Agent Programming Guidelines

## Core Principles

- **Error Handling**: Never suppress errors or bypass failures; crash early or deliver everything requested
- **Dependencies**: Prefer standard library → project code → third-party (minimize additions)
- **Type Safety**: Type-check everything thoroughly, including type parameters, recursively
- **Input Validation**: Document constraints, validate inputs, provide helpful error messages
- **Simplicity**: Prefer short diffs, reuse existing code, remove lines if you can, use pure functions, factor out common logic
- **Testing**: Always unit-test thoroughly; write code so tests can inject dependencies (avoid mocking)
- **Attribution**: Add "Originally written by [model] on YYYY/MM/DD" for large new code units
- **Tool Installation**: Install cautiously, ask permission, adapt to environment

## Python

- Use uv for package management unless otherwise specified by the project's config.
- Add any dependencies you use with `uv add`
- Use `uv run` to run commands inside the project's environment

### Complete Example

```python
"""Data processing module with validation.

Originally written by Claude Sonnet 4 on 2025/01/15
"""

# Imports at top in 3 blocks: stdlib, external, project-internal (nothing in-between so that import sorters work)
# ALL imports are at the top of the file, no local imports inside functions
import json
from collections.abc import Mapping, Sequence
from logging import getLogger
from pathlib import Path

import numpy as np

from current_project import helper_function

_log = getLogger(__name__)

# Pure function: immutable inputs/outputs, no side-effects
def process_data(
    values: Sequence[float],              # Good: float is not a sequence
    labels: tuple[str, ...] = (),         # Avoid Sequence[str] since str is a Sequence[str]; immutable default
    config: Mapping[str, int] | None = None,  # Use | None only when None has different meaning than empty
    random_gen: np.random.Generator = np.random.default_rng()  # Injection point for testing
) -> tuple[tuple[float, ...], dict[str, int]]:
    """Process data with optional configuration.

    @param values: Numeric values to process. Any sequence type accepted.
    @param labels: Labels for values. Must match length. Immutable for safety.
    @param config: Optional configuration mapping. None means that we fetch the defaults ourselves.
    @param random_gen: RNG for noise. Inject seeded generator for tests.
    @return: Tuple of (processed_values, statistics)
    @raises ValueError: If values is empty or labels length mismatches
    """
    # Input validation with helpful context
    if len(values) == 0:
        raise ValueError("values cannot be empty")
    if len(labels) > 0 and len(labels) != len(values):
        raise ValueError(f"labels length {len(labels)} must match values length {len(values)}")

    _log.debug(f"Processing {len(values)} values with {len(labels)} labels")

    # Let exceptions percolate (conserve tracebacks with 'from')
    try:
        threshold = config["threshold"] if config is not None else 10
    except KeyError as err:
        raise ValueError(f"config missing required key: {err}") from err

    # Pure function returns new immutable data
    noise = random_gen.normal(0, 0.1, len(values))
    processed = tuple(v + n for v, n in zip(values, noise) if v >= threshold)
    stats = {"count": len(processed), "threshold": threshold}

    return processed, stats

# Non-pure function: explicit mutation, clear documentation
def add_to_list(target: list[float], maximum: int) -> None:
    """Modify list in-place by appending range.

    @param target: List to modify. Will be mutated.
    @param maximum: Append 0 to maximum (inclusive). Must be positive.
    @raises ValueError: If maximum is not positive
    """
    if maximum <= 0:
        raise ValueError(f"maximum must be positive, got {maximum}")
    target.extend(range(maximum + 1))

def load_config(path: Path) -> dict[str, str]:
    """Load JSON config with error context.

    @param path: Config file path
    @return: Configuration dictionary
    @raises FileNotFoundError: If file doesn't exist
    @raises ValueError: If JSON is invalid
    """

    # No local imports here, `json` is imported at the top of the file

    try:
        with path.open() as f:
            return json.load(f)
    except json.JSONDecodeError as err:
        raise ValueError(f"Invalid JSON in {path}: {err}") from err  # Conserve traceback
    # NO bare except Exception - let unexpected errors crash with full trace
```

### Testing Example

```python
import numpy as np
import pytest

@pytest.fixture
def sample_data() -> tuple[float, ...]:
    """Provide deterministic test data."""
    return (1.0, 2.0, 3.0)

@pytest.mark.parametrize(["input_val", "expected"], [
    (0.0, 0.0),
    (2.0, 4.0),
    (-1.0, 1.0),
])
def test_square(input_val: float, expected: float):
    """Verify square function."""
    assert square(input_val) == expected

def test_process_data_with_injection(sample_data: tuple[float, ...]):
    """Test with deterministic RNG via dependency injection."""
    # Fixed algorithm and seed for determinism
    test_rng = np.random.Generator(np.random.PCG64(42))

    result, stats = process_data(
        sample_data,
        labels=("a", "b", "c"),
        config={"threshold": 0},
        random_gen=test_rng  # Inject seeded generator
    )

    # Compare entire structures strictly
    expected_rng = np.random.Generator(np.random.PCG64(42))
    expected_noise = expected_rng.normal(0, 0.1, 3)
    expected_result = tuple(v + n for v, n in zip(sample_data, expected_noise))

    assert np.allclose(result, expected_result)
    # Compare the entire structure exactly, no incomplete list of asserts for individual attributes
    assert stats == {"count": 3, "threshold": 0}

def test_validation_error():
    """Verify helpful error messages."""
    with pytest.raises(ValueError, match="values cannot be empty"):
        process_data([])

# Async testing with pytest-asyncio
@pytest.mark.asyncio
async def test_async_function():
    """Test async code."""
    result = await fetch_async("url")
    assert result == {"status": "ok"}
```

### Quick Reference

```python
import json
import subprocess
from logging import getLogger

import click

_log = getLogger(__name__)

def run_cmd(args: tuple[str, ...], cwd: Path | None = None) -> str:
    """Run command safely."""
    # Subprocess: always check=True, capture output, log args as JSON
    _log.debug(f"Running: {json.dumps(args)}")
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True)
    return result.stdout.strip()

# Click CLI: either required=True, default, or | None
@click.command()
@click.option('--input', type=click.Path(exists=True, path_type=Path), required=True)
@click.option('--threshold', type=float, default=0.5)
@click.option('--output', type=click.Path(path_type=Path))
def main(input: Path, threshold: float, output: Path | None) -> None:
    """Process with Click."""
    # Explicit type conversion for safety
    input = Path(input)
    threshold = float(threshold)
    output = Path(output) if output is not None else None

    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter(f"threshold must be 0.0-1.0, got {threshold}")
```

### Validation Workflow

Mandatory before considering your task done (install these tools if needed):

```bash
uv run pyright                                    # Type checking
uv run ruff check                                 # Linting
uv run ruff format                                # Formatting
uv run ruff check --select I --fix                # Import sorting
uv run pytest -v --tb=short -W error::UserWarning # Tests (warnings as errors)
```

Fix all errors and re-run until everything is resolved.
