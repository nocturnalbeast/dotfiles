"""Tag resolution and package filtering."""

from pathlib import Path
from typing import Optional

from .package import (
    Package,
    discover_packages,
    get_package_by_name,
    get_current_os,
    get_current_arch,
)


class TagManager:
    """Manages tag-based package filtering and resolution."""

    def __init__(
        self,
        root_dir: Path,
        ignore_dirs: set[str],
        target_os: Optional[str] = None,
        target_arch: Optional[str] = None,
    ):
        self.root_dir = root_dir
        self.ignore_dirs = ignore_dirs
        self.target_os = target_os or get_current_os()
        self.target_arch = target_arch or get_current_arch()
        self._packages: Optional[list[Package]] = None
        self._tags_cache: Optional[set[str]] = None

    @property
    def packages(self) -> list[Package]:
        """Lazily load packages."""
        if self._packages is None:
            self._packages = discover_packages(self.root_dir, self.ignore_dirs)
        return self._packages

    def get_all_tags(self) -> set[str]:
        """Get all unique tags across all packages."""
        if self._tags_cache is None:
            tags = set()
            for pkg in self.packages:
                tags.update(pkg.tags)
            self._tags_cache = tags
        return self._tags_cache

    def get_available_packages(
        self,
        check_condition: bool = True,
        include_disabled: bool = False,
    ) -> list[Package]:
        """
        Get packages available for current platform.

        Args:
            check_condition: Whether to check condition field
            include_disabled: Whether to include disabled packages

        Returns:
            List of available packages with their availability reasons
        """
        result = []
        for pkg in self.packages:
            if not include_disabled and not pkg.enabled:
                continue
            available, _ = pkg.is_available_for(
                self.target_os,
                self.target_arch,
                check_condition,
            )
            if available:
                result.append(pkg)
        return result

    def get_unavailable_packages(
        self,
        check_condition: bool = True,
    ) -> list[tuple[Package, str]]:
        """
        Get packages unavailable for current platform with reasons.

        Returns:
            List of (package, reason) tuples
        """
        result = []
        for pkg in self.packages:
            available, reason = pkg.is_available_for(
                self.target_os,
                self.target_arch,
                check_condition,
            )
            if not available:
                result.append((pkg, reason))
        return result

    def filter_by_tags(
        self, tags: list[str], require_all: bool = False
    ) -> list[Package]:
        """
        Filter packages by tags.

        Args:
            tags: List of tags to filter by
            require_all: If True, package must have ALL tags.
                        If False, package must have ANY tag.

        Returns:
            List of matching packages
        """
        if not tags:
            return self.packages

        result = []
        for pkg in self.packages:
            pkg_tags = set(pkg.all_tags)
            query_tags = set(tags)

            if require_all:
                if query_tags.issubset(pkg_tags):
                    result.append(pkg)
            else:
                if query_tags & pkg_tags:
                    result.append(pkg)

        return result

    def resolve_packages(
        self,
        package_names: Optional[list[str]] = None,
        tags: Optional[list[str]] = None,
        require_all_tags: bool = False,
        filter_available: bool = True,
    ) -> list[Package]:
        """
        Resolve packages from names and/or tags.

        Priority:
        1. If package_names provided, use those directly
        2. If tags provided, filter by tags
        3. Otherwise, return all packages

        Args:
            package_names: Specific package names to resolve
            tags: Tags to filter by
            require_all_tags: Require all tags (AND logic)
            filter_available: Filter to only available packages for platform
        """
        if package_names:
            result = []
            for name in package_names:
                pkg = get_package_by_name(self.packages, name)
                if pkg:
                    result.append(pkg)
            packages = result
        elif tags:
            packages = self.filter_by_tags(tags, require_all_tags)
        else:
            packages = self.packages

        if filter_available:
            available = []
            for pkg in packages:
                is_avail, _ = pkg.is_available_for(
                    self.target_os,
                    self.target_arch,
                )
                if is_avail:
                    available.append(pkg)
            return available

        return packages

    def get_packages_without_metadata(self) -> list[Package]:
        """Get packages that don't have .package.toml files."""
        return [pkg for pkg in self.packages if not pkg.has_metadata]
