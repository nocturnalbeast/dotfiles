"""Bootstrap script execution for packages."""

import os
import subprocess
from pathlib import Path
from typing import Optional


def get_bootstrap_script(root_dir: Path, pkg_name: str) -> Optional[Path]:
    """Get the bootstrap script path for a package if it exists."""
    bootstrap_dir = root_dir / "bootstrap" / pkg_name
    if bootstrap_dir.exists() and os.access(bootstrap_dir, os.X_OK):
        return bootstrap_dir
    return None


def run_bootstrap(root_dir: Path, pkg_name: str, action: str) -> tuple[bool, str]:
    """
    Run a package's bootstrap script.

    Args:
        root_dir: Repository root directory
        pkg_name: Name of the package
        action: Action to pass to bootstrap script (install/reinstall/uninstall)

    Returns:
        Tuple of (success, output_message)
    """
    script_path = get_bootstrap_script(root_dir, pkg_name)
    if not script_path:
        return True, "No bootstrap script"

    result = subprocess.run(
        [str(script_path), action],
        cwd=root_dir,
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        return True, result.stdout.strip() if result.stdout else "Bootstrap completed"
    else:
        return False, result.stderr.strip() if result.stderr else "Bootstrap failed"
