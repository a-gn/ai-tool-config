<coding_guidelines>

<core_principles>
- Crash early or deliver everything requested — never suppress errors or bypass failures
- Prefer standard library → project code → third-party; minimize new dependencies
- Type-check everything thoroughly, including type parameters, recursively
- Document constraints, validate inputs, and provide helpful error messages
- Prefer short diffs; reuse existing code, remove lines where possible; use pure functions; factor out common logic
- Unit-test thoroughly; write code so tests can inject dependencies (avoid mocking)
- Add "Originally written by [model] on YYYY/MM/DD" for large new code units
- Install tools cautiously and ask permission; adapt to the environment
- Refuse to commit API keys, passwords, or secrets unless the user explicitly says it's okay, or a comment near the code says it's okay to check in
</core_principles>

<python>

<package_management>
Use uv for package management unless the project config specifies otherwise.
- Add dependencies with `uv add`
- Run commands inside the project environment with `uv run`
</package_management>

<imports>
Place all imports at the top of the file in three blocks, in this order: stdlib, external, project-internal. Leave no lines between blocks so import sorters work correctly. Never use local imports inside functions.
</imports>

<examples>

<example id="module">
```python
"""Data processing module with validation.

Originally written by Claude Sonnet 4 on 2025/01/15
"""

import json
from collections.abc import Mapping, Sequence
from logging import getLogger
from pathlib import Path

import numpy as np

from current_project import helper_function

_log = getLogger(__name__)

# Pure function: immutable inputs/outputs, no side-effects
def process_data(
    values: Sequence[float],
    labels: tuple[str, ...] = (),
    config: Mapping[str, int] | None = None,
    random_gen: np.random.Generator = np.random.default_rng()
) -> tuple[tuple[float, ...], dict[str, int]]:
    """Process data with optional configuration.

    @param values: Numeric values to process. Any sequence type accepted.
    @param labels: Labels for values. Must match length. Immutable for safety.
    @param config: Optional configuration mapping. None means fetch defaults.
    @param random_gen: RNG for noise. Inject seeded generator for tests.
    @return: Tuple of (processed_values, statistics)
    @raises ValueError: If values is empty or labels length mismatches
    """
    if len(values) == 0:
        raise ValueError("values cannot be empty")
    if len(labels) > 0 and len(labels) != len(values):
        raise ValueError(f"labels length {len(labels)} must match values length {len(values)}")

    _log.debug(f"Processing {len(values)} values with {len(labels)} labels")

    try:
        threshold = config["threshold"] if config is not None else 10
    except KeyError as err:
        raise ValueError(f"config missing required key: {err}") from err

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
    try:
        with path.open() as f:
            return json.load(f)
    except json.JSONDecodeError as err:
        raise ValueError(f"Invalid JSON in {path}: {err}") from err
```
</example>

<example id="tests">
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
    assert square(input_val) == expected

def test_process_data_with_injection(sample_data: tuple[float, ...]):
    test_rng = np.random.Generator(np.random.PCG64(42))

    result, stats = process_data(
        sample_data,
        labels=("a", "b", "c"),
        config={"threshold": 0},
        random_gen=test_rng
    )

    expected_rng = np.random.Generator(np.random.PCG64(42))
    expected_noise = expected_rng.normal(0, 0.1, 3)
    expected_result = tuple(v + n for v, n in zip(sample_data, expected_noise))

    assert np.allclose(result, expected_result)
    assert stats == {"count": 3, "threshold": 0}

def test_validation_error():
    with pytest.raises(ValueError, match="values cannot be empty"):
        process_data([])

@pytest.mark.asyncio
async def test_async_function():
    result = await fetch_async("url")
    assert result == {"status": "ok"}
```
</example>

<example id="cli_and_subprocess">
```python
import json
import subprocess
from logging import getLogger

import click

_log = getLogger(__name__)

def run_cmd(args: tuple[str, ...], cwd: Path | None = None) -> str:
    """Run command safely."""
    _log.debug(f"Running: {json.dumps(args)}")
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True)
    return result.stdout.strip()

@click.command()
@click.option('--input', type=click.Path(exists=True, path_type=Path), required=True)
@click.option('--threshold', type=float, default=0.5)
@click.option('--output', type=click.Path(path_type=Path))
def main(input: Path, threshold: float, output: Path | None) -> None:
    input = Path(input)
    threshold = float(threshold)
    output = Path(output) if output is not None else None

    if not 0.0 <= threshold <= 1.0:
        raise click.BadParameter(f"threshold must be 0.0-1.0, got {threshold}")
```
</example>

</examples>

<validation>
Run all of the following before considering the task done. Install any missing tools as needed. Fix all errors and re-run until everything passes.
```bash
uv run pyright
uv run ruff check
uv run ruff format
uv run ruff check --select I --fix
uv run pytest -v --tb=short -W error::UserWarning
```
</validation>

</python>

</coding_guidelines>