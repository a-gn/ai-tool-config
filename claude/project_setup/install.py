#!/usr/bin/env python3
"""Project setup script for AI agent instructions.

Originally written by Claude on 2025/09/14
"""

import argparse
import os
import shutil
import tempfile
import urllib.request
import zipfile
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


def check_safe_directory(target_dir: Path) -> None:
    """Check if target directory is safe for installation.

    @param target_dir: Directory to check for safety
    @raises ValueError: If directory is unsafe
    """

    excluded_dirs = [
        Path.home(),
        Path.home() / "Documents",
        Path.home() / "Desktop",
        Path.home() / "Downloads",
        Path("/tmp"),
        Path("/var"),
        Path("/Users"),
        Path("/home"),
        Path("/System"),
        Path("/usr"),
        Path("/opt"),
    ]

    resolved_target = target_dir.resolve()
    for excluded in excluded_dirs:
        excluded_resolved = excluded.resolve()
        if resolved_target == excluded_resolved:
            raise ValueError(f'Cannot install in "{excluded}" - unsafe directory')


def safe_delete(path: Path, directory_okay: bool) -> None:
    """Safely delete file or directory from a temporary directory.

    @param path: Path to delete
    @param directory_okay: Whether to allow directory deletion
    @raises RuntimeError: If running as the root user (UID 0)
    @raises ValueError: If path is unsafe to delete
    """
    if os.geteuid() == 0:
        raise RuntimeError("Rejecting deletion: running as root")

    resolved_path = path.resolve()

    # Path length check
    if len(resolved_path.parts) <= 1:
        raise ValueError(
            f"Path too short for deletion (only {len(resolved_path.parts)} components, which is suspect): "
            f"{resolved_path}"
        )

    # Only allow specific temp directory patterns
    temp_roots = [
        Path("/tmp"),
        Path("/private/var/folders"),
        Path("/var/folders"),
        Path("/var/tmp"),
        Path("/private/tmp"),
    ]

    is_safe = False
    for single_root in temp_roots:
        if single_root in resolved_path.parents:
            is_safe = True

    if not is_safe:
        raise ValueError(
            f'Path "{resolved_path}" not identified as a safe path to delete, aborting'
        )
    elif resolved_path.is_dir() and directory_okay:
        shutil.rmtree(resolved_path)
    elif resolved_path.is_dir() and not directory_okay:
        raise ValueError(f"Expected file but found directory: {resolved_path}")
    elif resolved_path.is_file() or resolved_path.is_symlink():
        resolved_path.unlink()
    elif not resolved_path.exists():
        raise FileNotFoundError(f"Path does not exist: {resolved_path}")
    else:
        # Should this happen? Fishy
        raise RuntimeError(
            f'Path "{resolved_path}" seems to exist but our checks didn\'t identify it as a file or directory'
            ", aborting deletion as a precaution"
        )


def clean_claude_md(claude_md_path: Path, keep_languages: tuple[str, ...]) -> None:
    """Remove language references from CLAUDE.md except for kept languages.

    @param claude_md_path: Path to CLAUDE.md file
    @param keep_languages: Languages to keep in the file
    @raises FileNotFoundError: If CLAUDE.md file is missing
    @raises ValueError: If no languages to keep
    """
    if not claude_md_path.is_file():
        raise FileNotFoundError(f"CLAUDE.md file not found: {claude_md_path}")

    if not keep_languages:
        raise ValueError("No languages specified to keep in CLAUDE.md")

    lines = claude_md_path.read_text().splitlines()
    filtered_lines = []

    for line in lines:
        if "@agent_instructions/languages/" in line:
            # Extract language from pattern like @agent_instructions/languages/python/
            parts = line.split("@agent_instructions/languages/")
            if len(parts) > 1:
                lang_part = parts[1].split("/")[0]
                if lang_part in keep_languages:
                    filtered_lines.append(line)
            # If we can't parse it properly, skip the line
        else:
            filtered_lines.append(line)

    claude_md_path.write_text("\n".join(filtered_lines) + "\n")


def clean_language_files(
    temp_source_dir: Path, keep_languages: tuple[str, ...]
) -> None:
    """Remove unused language directories.

    @param temp_source_dir: Temporary source directory path
    @param keep_languages: Languages to keep
    @raises FileNotFoundError: If languages directory is missing
    @raises ValueError: If no languages to keep
    """
    if not keep_languages:
        raise ValueError("No languages specified to keep")

    lang_dir = temp_source_dir / "agent_instructions" / "languages"
    if not lang_dir.exists():
        raise FileNotFoundError(f"Languages directory not found: {lang_dir}")

    for lang_path in lang_dir.iterdir():
        if lang_path.is_dir():
            lang_name = lang_path.name
            if lang_name not in keep_languages:
                safe_delete(lang_path, directory_okay=True)


def get_available_languages() -> tuple[str, ...]:
    """Get list of available languages by fetching from GitHub.

    @return: Tuple of available language names
    @raises FileNotFoundError: If languages directory not found in repository
    """
    with tempfile.TemporaryDirectory(prefix="claude_lang_check_") as temp_dir:
        # Download and extract to check available languages
        zip_path = Path(temp_dir) / "repo.zip"
        urllib.request.urlretrieve(
            "https://github.com/a-gn/ai-tool-config/archive/refs/heads/main.zip",
            zip_path,
        )

        with zipfile.ZipFile(zip_path, "r") as zip_file:
            zip_file.extractall(temp_dir)

        lang_dir = (
            Path(temp_dir)
            / "ai-tool-config-main"
            / "claude"
            / "project_setup"
            / "agent_instructions"
            / "languages"
        )

        if not lang_dir.exists():
            raise FileNotFoundError(
                f"Languages directory not found in repository: {lang_dir}"
            )

        languages = tuple(p.name for p in lang_dir.iterdir() if p.is_dir())
        return languages


def choose_languages_interactively(
    available_languages: tuple[str, ...],
) -> tuple[str, ...]:
    """Let user choose languages interactively.

    @param available_languages: Available languages to choose from
    @return: Tuple of chosen language names
    @raises ValueError: If user input is invalid
    @raises KeyboardInterrupt: If user cancels
    @raises EOFError: If no input received
    """
    print()
    print_info("Available languages:")
    for i, lang in enumerate(available_languages, 1):
        print(f"  {i}. {lang}")

    print()
    print_info("Enter language numbers (space-separated) or language names:")
    print_info("Examples: '1 3' or 'python javascript' or 'python'")

    try:
        user_input = input("> ").strip()
        if not user_input:
            raise ValueError("No languages selected")

        chosen_languages = []
        parts = user_input.split()

        for part in parts:
            if part.isdigit():
                # Number selection
                index = int(part) - 1
                if 0 <= index < len(available_languages):
                    chosen_languages.append(available_languages[index])
                else:
                    raise ValueError(f"Invalid number: {part}")
            else:
                # Name selection
                if part in available_languages:
                    chosen_languages.append(part)
                else:
                    raise ValueError(
                        f"Unknown language: {part}\n"
                        f"Available: {', '.join(available_languages)}"
                    )

        # Remove duplicates while preserving order
        seen = set()
        unique_languages = []
        for lang in chosen_languages:
            if lang not in seen:
                seen.add(lang)
                unique_languages.append(lang)

        return tuple(unique_languages)

    except KeyboardInterrupt:
        print()
        print_info("Installation cancelled")
        raise
    except EOFError:
        raise


def backup_conflicting_files(dest_dir: Path, source_items: list[Path]) -> None:
    """Backup files that would conflict with installation.

    @param dest_dir: Destination directory
    @param source_items: Items from source that will be copied
    """
    conflicts = []
    for source_item in source_items:
        dest_item = dest_dir / source_item.name
        if dest_item.exists():
            conflicts.append(dest_item.name)

    if conflicts:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = dest_dir / f".claude_backup_{timestamp}"
        backup_dir.mkdir()

        for item_name in conflicts:
            source_path = dest_dir / item_name
            dest_path = backup_dir / item_name
            shutil.move(str(source_path), str(dest_path))

        print_info(f"Backed up existing config to: {backup_dir}")
        print()
        print_info("To rollback this installation, run:")
        print_info("  # Backup current config")
        backup_cmd = "mkdir -p .claude_rollback_backup_$(date +%Y%m%d_%H%M%S)"
        print_info(f"  {backup_cmd}")
        for item_name in conflicts:
            print_info(
                f"  mv {item_name} .claude_rollback_backup_$(date +%Y%m%d_%H%M%S)/"
            )
        print_info("  # Restore previous config")
        print_info(f"  mv {backup_dir}/* ./")
        print_info(f"  rmdir {backup_dir}")
        print()


def install_configuration(
    dest_dir: Path, temp_source_dir: Path, languages: tuple[str, ...]
) -> None:
    """Install configuration files to destination directory.

    @param dest_dir: Destination directory for installation
    @param temp_source_dir: Temporary source directory
    @param languages: Languages to install
    @raises FileNotFoundError: If required files not found
    """
    # Validate languages exist
    lang_dir = temp_source_dir / "agent_instructions" / "languages"
    for lang in languages:
        if not (lang_dir / lang).exists():
            raise FileNotFoundError(f"Language '{lang}' not found in repository")

    # Clean up files - remove languages not in the list
    print_info(
        f"Cleaning up instructions, only keeping languages: {' '.join(languages)}"
    )
    clean_language_files(temp_source_dir, languages)
    clean_claude_md(temp_source_dir / "CLAUDE.md", languages)

    # Remove unnecessary files
    files_to_remove = ["README.md", "install.sh", "install.py"]
    for file_name in files_to_remove:
        file_path = temp_source_dir / file_name
        if file_path.exists():
            file_path.unlink()

    # Get list of items that will be copied
    source_items = list(temp_source_dir.iterdir())

    # Backup conflicting files before installation
    backup_conflicting_files(dest_dir, source_items)

    print_info(f"Moving final instructions to {dest_dir}...")

    for item in source_items:
        dest = dest_dir / item.name
        if item.is_dir():
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(item, dest)
        else:
            shutil.copy2(item, dest)


def main() -> None:
    """Main installation function."""
    parser = argparse.ArgumentParser(
        description="Install Claude Code project configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s python javascript    # Install specific languages
  %(prog)s --interactive        # Choose languages interactively
  %(prog)s                      # Install all available languages
        """,
    )
    parser.add_argument(
        "languages",
        nargs="*",
        help="Languages to install (e.g., python javascript). If none specified, installs all available languages.",
    )
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Choose languages interactively",
    )

    args = parser.parse_args()
    dest_dir = Path.cwd().resolve()

    # Check if running as root
    if os.geteuid() == 0:
        raise RuntimeError("Do not run this script as root")

    check_safe_directory(dest_dir)

    # Determine languages to install
    if args.interactive:
        print_info("Fetching available languages...")
        available_languages = get_available_languages()
        languages = choose_languages_interactively(available_languages)
    elif args.languages:
        languages = tuple(args.languages)
    else:
        # No arguments provided - install all languages
        print_info("No languages specified, installing all available languages...")
        languages = get_available_languages()

    print_info(f"Installing Claude Code configuration for: {' '.join(languages)}")

    # Create temporary directory and download/extract
    with tempfile.TemporaryDirectory(prefix="claude_install_") as temp_dir:
        temp_path = Path(temp_dir)

        print_info("Downloading repository...")
        zip_path = temp_path / "repo.zip"
        urllib.request.urlretrieve(
            "https://github.com/a-gn/ai-tool-config/archive/refs/heads/main.zip",
            zip_path,
        )

        print_info("Extracting configuration...")
        extract_dir = temp_path / "extract"
        extract_dir.mkdir()

        with zipfile.ZipFile(zip_path, "r") as zip_file:
            zip_file.extractall(extract_dir)

        temp_source_dir = (
            extract_dir / "ai-tool-config-main" / "claude" / "project_setup"
        )
        if not temp_source_dir.exists():
            raise FileNotFoundError(
                f"Project setup folder not found in repository: {temp_source_dir}"
            )

        # Install configuration
        install_configuration(dest_dir, temp_source_dir, languages)

    print_info("✓ Installation complete")


if __name__ == "__main__":
    main()
