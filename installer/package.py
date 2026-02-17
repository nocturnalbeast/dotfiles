"""Package discovery and metadata loading."""

import platform
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

try:
    import tomllib
except ImportError:
    import tomli as tomllib


def get_current_os() -> str:
    """Get the current operating system."""
    system = platform.system().lower()
    os_map = {
        "linux": "linux",
        "darwin": "macos",
        "windows": "windows",
    }
    return os_map.get(system, system)


def get_current_arch() -> str:
    """Get the current architecture."""
    machine = platform.machine().lower()
    arch_map = {
        "x86_64": "x86_64",
        "amd64": "x86_64",
        "arm64": "arm64",
        "aarch64": "arm64",
        "armv7l": "arm",
        "armv6l": "arm",
    }
    return arch_map.get(machine, machine)


@dataclass
class Package:
    """Represents a dotfiles package with its metadata."""

    name: str
    path: Path
    tags: list[str] = field(default_factory=list)
    description: Optional[str] = None
    os: list[str] = field(default_factory=list)
    arch: list[str] = field(default_factory=list)
    enabled: bool = True
    condition: Optional[str] = None

    @property
    def all_tags(self) -> list[str]:
        """Return tags including implicit 'all' and package name."""
        implicit = ["all", self.name]
        return list(set(self.tags + implicit))

    @property
    def has_metadata(self) -> bool:
        """Check if package has explicit metadata file."""
        return (self.path / ".package.toml").exists()

    def matches_os(self, target_os: Optional[str] = None) -> bool:
        """Check if package supports the target OS."""
        if not self.os:
            return True
        check_os = target_os or get_current_os()
        return check_os in self.os

    def matches_arch(self, target_arch: Optional[str] = None) -> bool:
        """Check if package supports the target architecture."""
        if not self.arch:
            return True
        check_arch = target_arch or get_current_arch()
        return check_arch in self.arch

    def check_condition(self) -> tuple[bool, str]:
        """
        Check if the package condition is met.

        Returns:
            Tuple of (success, message)
        """
        if not self.condition:
            return True, "No condition"

        try:
            result = subprocess.run(
                self.condition,
                shell=True,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 0:
                return True, "Condition met"
            else:
                return False, f"Condition failed: {self.condition}"
        except subprocess.TimeoutExpired:
            return False, f"Condition timed out: {self.condition}"
        except Exception as e:
            return False, f"Condition error: {e}"

    def is_available_for(
        self,
        target_os: Optional[str] = None,
        target_arch: Optional[str] = None,
        check_condition: bool = True,
    ) -> tuple[bool, str]:
        """
        Check if package is available for the target platform.

        Returns:
            Tuple of (available, reason)
        """
        if not self.enabled:
            return False, "Package is disabled"

        if not self.matches_os(target_os):
            return False, f"OS mismatch (requires: {self.os})"

        if not self.matches_arch(target_arch):
            return False, f"Architecture mismatch (requires: {self.arch})"

        if check_condition and self.condition:
            cond_ok, cond_msg = self.check_condition()
            if not cond_ok:
                return False, cond_msg

        return True, "Available"


def load_package_metadata(pkg_path: Path) -> dict:
    """Load metadata from .package.toml if it exists."""
    metadata_file = pkg_path / ".package.toml"
    if not metadata_file.exists():
        return {}

    with open(metadata_file, "rb") as f:
        return tomllib.load(f)


def discover_packages(root_dir: Path, ignore_dirs: set[str]) -> list[Package]:
    """Discover all packages in the root directory."""
    packages = []

    for item in root_dir.iterdir():
        if not item.is_dir():
            continue
        if item.name.startswith("."):
            continue
        if item.name in ignore_dirs:
            continue

        metadata = load_package_metadata(item)
        pkg = Package(
            name=item.name,
            path=item,
            tags=metadata.get("tags", []),
            description=metadata.get("description"),
            os=metadata.get("os", []),
            arch=metadata.get("arch", []),
            enabled=metadata.get("enabled", True),
            condition=metadata.get("condition"),
        )
        packages.append(pkg)

    return sorted(packages, key=lambda p: p.name)


def get_package_by_name(packages: list[Package], name: str) -> Optional[Package]:
    """Find a package by its name."""
    for pkg in packages:
        if pkg.name == name:
            return pkg
    return None
