"""Package discovery and metadata loading."""

import os
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


def get_current_host() -> str:
    """
    Get the current host name.

    Resolution order:
        1. Override file at ${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/host
           (single line, stripped; empty file falls through to auto-detect)
        2. platform.node(), lowercased, truncated at the first dot
           ("Earth.local" -> "earth")
    """
    config_home = os.environ.get("XDG_CONFIG_HOME") or str(Path.home() / ".config")
    override_file = Path(config_home) / "dotfiles" / "host"
    if override_file.is_file():
        lines = override_file.read_text().splitlines()
        if lines and lines[0].strip():
            return lines[0].strip()

    return platform.node().lower().split(".", 1)[0]


@dataclass
class Package:
    """Represents a dotfiles package with its metadata."""

    name: str
    path: Path
    tags: list[str] = field(default_factory=list)
    description: Optional[str] = None
    os: list[str] = field(default_factory=list)
    arch: list[str] = field(default_factory=list)
    hosts: list[str] = field(default_factory=list)
    enabled: bool = True
    condition: Optional[str] = None
    ignore: dict[str, list[str]] = field(default_factory=dict)

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

    def matches_host(self, target_host: Optional[str] = None) -> bool:
        """Check if package supports the target host."""
        if not self.hosts:
            return True
        check_host = target_host or get_current_host()
        return check_host in self.hosts

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
        target_host: Optional[str] = None,
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

        if not self.matches_host(target_host):
            return False, f"Host mismatch (requires: {self.hosts})"

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
        metadata_file = item / ".package.toml"

        hosts = metadata.get("hosts", [])
        if not isinstance(hosts, list) or not all(
            isinstance(host, str) for host in hosts
        ):
            raise ValueError(f"{metadata_file}: 'hosts' must be a list of host names")

        ignore = metadata.get("ignore", {})
        if not isinstance(ignore, dict):
            raise ValueError(
                f"{metadata_file}: 'ignore' must be a table of per-OS rule lists"
            )
        for os_name, os_rules in ignore.items():
            if os_name == "fold":
                # reserved: opts the package out of the forced --no-folding
                if not isinstance(os_rules, bool):
                    raise ValueError(
                        f"{metadata_file}: 'ignore.fold' must be a boolean"
                    )
                continue
            if not isinstance(os_rules, list) or not all(
                isinstance(rule, str) for rule in os_rules
            ):
                raise ValueError(
                    f"{metadata_file}: 'ignore.{os_name}' must be a list "
                    "of rule strings"
                )

        pkg = Package(
            name=item.name,
            path=item,
            tags=metadata.get("tags", []),
            description=metadata.get("description"),
            os=metadata.get("os", []),
            arch=metadata.get("arch", []),
            hosts=metadata.get("hosts", []),
            enabled=metadata.get("enabled", True),
            condition=metadata.get("condition"),
            ignore=ignore,
        )
        packages.append(pkg)

    return sorted(packages, key=lambda p: p.name)


def get_package_by_name(packages: list[Package], name: str) -> Optional[Package]:
    """Find a package by its name."""
    for pkg in packages:
        if pkg.name == name:
            return pkg
    return None
