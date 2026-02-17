"""GNU Stow wrapper for package management."""

import subprocess
from pathlib import Path
from typing import Optional


class StowError(Exception):
    """Exception raised for stow operations failures."""

    pass


IGNORE_PATTERN = "\\.package\\.toml$"


def is_stowed(pkg_path: Path, target: Path, pkg_name: str) -> bool:
    """Check if a package is already stowed."""
    result = subprocess.run(
        ["stow", "-n", "-v", "-t", str(target), f"--ignore={IGNORE_PATTERN}", pkg_name],
        cwd=pkg_path.parent,
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr

    if "would cause conflicts" in output or "LINK:" in output:
        return False
    if not output.strip() or "WARNING: in simulation mode" in output:
        return True
    return False


def stow_install(pkg_path: Path, target: Path, pkg_name: str) -> bool:
    """Install a package using stow."""
    result = subprocess.run(
        ["stow", "-t", str(target), f"--ignore={IGNORE_PATTERN}", pkg_name],
        cwd=pkg_path.parent,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def stow_reinstall(pkg_path: Path, target: Path, pkg_name: str) -> bool:
    """Reinstall a package using stow (with override)."""
    result = subprocess.run(
        [
            "stow",
            "--override='.*'",
            "-R",
            "-t",
            str(target),
            f"--ignore={IGNORE_PATTERN}",
            pkg_name,
        ],
        cwd=pkg_path.parent,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def stow_uninstall(pkg_path: Path, target: Path, pkg_name: str) -> bool:
    """Uninstall a package using stow."""
    result = subprocess.run(
        ["stow", "-D", "-t", str(target), f"--ignore={IGNORE_PATTERN}", pkg_name],
        cwd=pkg_path.parent,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def stow_check(pkg_path: Path, target: Path, pkg_name: str) -> dict:
    """
    Check package installation status and potential conflicts.

    Returns dict with:
        - installed: bool
        - can_install: bool
        - conflicts: list[str]
    """
    if is_stowed(pkg_path, target, pkg_name):
        return {"installed": True, "can_install": False, "conflicts": []}

    result = subprocess.run(
        ["stow", "-n", "-v", "-t", str(target), f"--ignore={IGNORE_PATTERN}", pkg_name],
        cwd=pkg_path.parent,
        capture_output=True,
        text=True,
    )

    output = result.stdout + result.stderr
    conflicts = []

    for line in output.splitlines():
        line = line.strip()
        if line.startswith("*") or "conflict" in line.lower():
            conflicts.append(line)

    return {
        "installed": False,
        "can_install": len(conflicts) == 0,
        "conflicts": conflicts,
    }
