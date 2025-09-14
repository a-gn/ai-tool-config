#!/usr/bin/env python3
"""User setup script for AI agent instructions.

Originally written by Claude on 2025/09/14
"""

import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path


class Color:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"


def print_info(msg: str) -> None:
    """Print info message with green color."""
    print(f"{Color.GREEN}[INFO]{Color.NC} {msg}")


def print_warn(msg: str) -> None:
    """Print warning message with yellow color."""
    print(f"{Color.YELLOW}[WARN]{Color.NC} {msg}")


def print_error(msg: str) -> None:
    """Print error message with red color."""
    print(f"{Color.RED}[ERROR]{Color.NC} {msg}")


def check_safe_directory(config_dir: Path) -> None:
    """Check if running environment is safe.

    @param config_dir: Configuration directory to check
    @raises ValueError: If config directory is unsafe
    """
    # Ensure we're installing to a reasonable location
    home_dir = Path.home()
    config_dir.resolve().relative_to(home_dir.resolve())


def backup_existing_config(config_dir: Path) -> None:
    """Backup existing configuration directory if it exists.

    @param config_dir: Configuration directory to backup
    """
    if not config_dir.exists():
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = Path.home() / f".claude_backup_{timestamp}"

    shutil.move(str(config_dir), str(backup_dir))
    print_info(f"Backed up existing config to: {backup_dir}")
    print()
    print_info("To rollback this installation, run:")
    print_info(f"  mv {backup_dir} {config_dir}")
    print()


def install_with_git_clone(config_dir: Path) -> None:
    """Install configuration via git clone with symlinks.

    @param config_dir: Target configuration directory
    @raises FileNotFoundError: If expected files not found in repository
    """
    repo_dir = config_dir / "instructions_repository_clone"

    print_info("Installing via git clone with symlinks...")

    subprocess.run(
        ["git", "clone", "https://github.com/a-gn/ai-tool-config.git", str(repo_dir)],
        check=True,
        capture_output=True,
        text=True,
    )

    user_setup_dir = repo_dir / "claude" / "user_setup"
    if not user_setup_dir.exists():
        raise FileNotFoundError(
            f"User setup directory not found in repository: {user_setup_dir}"
        )

    # Create symlinks for configuration files
    claude_md = user_setup_dir / "CLAUDE.md"
    if not claude_md.exists():
        raise FileNotFoundError(f"CLAUDE.md not found in repository: {claude_md}")

    target_link = config_dir / "CLAUDE.md"
    target_link.symlink_to(claude_md)

    commands_dir = user_setup_dir / "commands"
    if commands_dir.exists():
        target_link = config_dir / "commands"
        target_link.symlink_to(commands_dir)

    print_info("✓ Installation complete")
    print_info(f"To update: cd {repo_dir} && git pull")


def main() -> None:
    """Main installation function."""
    config_dir = Path.home() / ".claude"

    print_info("Installing user-wide Claude Code configuration...")
    print_info(f"Installing to: {config_dir}")

    # Check if running as root
    if os.geteuid() == 0:
        raise RuntimeError("Do not run this script as root")

    backup_existing_config(config_dir)
    config_dir.mkdir(parents=False, exist_ok=False)
    install_with_git_clone(config_dir)

    print_info(f"Configuration directory: {config_dir}")


if __name__ == "__main__":
    main()
