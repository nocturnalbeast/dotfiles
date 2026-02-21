"""Command-line interface for the dotfiles installer."""

import argparse
import sys
from pathlib import Path
from typing import Optional

from .bootstrap import run_bootstrap
from .package import Package, get_current_os, get_current_arch
from .stow import (
    is_stowed,
    stow_check,
    stow_install,
    stow_reinstall,
    stow_uninstall,
    StowError,
)
from .tags import TagManager


IGNORE_DIRS = {"repo_resources", "bootstrap", "installer"}


def print_success(msg: str):
    print(f"\033[92mINFO:\033[0m {msg}")


def print_error(msg: str):
    print(f"\033[91mERROR:\033[0m {msg}", file=sys.stderr)


def print_warn(msg: str):
    print(f"\033[93mWARN:\033[0m {msg}", file=sys.stderr)


def print_info(msg: str):
    print(f"INFO: {msg}")


def print_skip(msg: str):
    print(f"\033[90mSKIP:\033[0m {msg}")


class DotfilesManager:
    """Main manager class for dotfiles operations."""

    def __init__(
        self,
        root_dir: Path,
        target_dir: Path,
        target_os: Optional[str] = None,
        target_arch: Optional[str] = None,
    ):
        self.root_dir = root_dir
        self.target_dir = target_dir
        self.target_os = target_os or get_current_os()
        self.target_arch = target_arch or get_current_arch()
        self.tag_manager = TagManager(
            root_dir,
            IGNORE_DIRS,
            self.target_os,
            self.target_arch,
        )

    def install(self, pkg: Package, skip_unavailable: bool = True) -> bool:
        """Install a single package."""
        available, reason = pkg.is_available_for(
            self.target_os,
            self.target_arch,
        )
        if not available:
            if skip_unavailable:
                print_skip(f"{pkg.name}: {reason}")
                return True
            else:
                print_error(f"{pkg.name}: {reason}")
                return False

        if is_stowed(pkg.path, self.target_dir, pkg.name):
            print_error(f"Package {pkg.name} is already installed")
            return False

        if not pkg.has_metadata:
            print_warn(f"Package {pkg.name} has no .package.toml metadata file")

        if stow_install(pkg.path, self.target_dir, pkg.name):
            print_success(f"Installed {pkg.name}")
            success, msg = run_bootstrap(self.root_dir, pkg.name, "install")
            if not success:
                print_error(f"Bootstrap for {pkg.name}: {msg}")
            return True
        else:
            print_error(f"Failed to install package {pkg.name}")
            return False

    def reinstall(self, pkg: Package, skip_unavailable: bool = True) -> bool:
        """Reinstall a single package."""
        available, reason = pkg.is_available_for(
            self.target_os,
            self.target_arch,
        )
        if not available:
            if skip_unavailable:
                print_skip(f"{pkg.name}: {reason}")
                return True
            else:
                print_error(f"{pkg.name}: {reason}")
                return False

        if not pkg.has_metadata:
            print_warn(f"Package {pkg.name} has no .package.toml metadata file")

        if stow_reinstall(pkg.path, self.target_dir, pkg.name):
            print_success(f"Reinstalled {pkg.name}")
            success, msg = run_bootstrap(self.root_dir, pkg.name, "reinstall")
            if not success:
                print_error(f"Bootstrap for {pkg.name}: {msg}")
            return True
        else:
            print_error(f"Failed to reinstall package {pkg.name}")
            return False

    def uninstall(self, pkg: Package) -> bool:
        """Uninstall a single package."""
        if not is_stowed(pkg.path, self.target_dir, pkg.name):
            print_error(f"Package {pkg.name} is not installed")
            return False

        if stow_uninstall(pkg.path, self.target_dir, pkg.name):
            print_success(f"Uninstalled {pkg.name}")
            success, msg = run_bootstrap(self.root_dir, pkg.name, "uninstall")
            if not success:
                print_error(f"Bootstrap for {pkg.name}: {msg}")
            return True
        else:
            print_error(f"Failed to uninstall package {pkg.name}")
            return False

    def check(self, pkg: Package) -> None:
        """Check and display package status."""
        available, reason = pkg.is_available_for(
            self.target_os,
            self.target_arch,
        )

        if not available:
            print_warn(f"Package {pkg.name} is not available: {reason}")
            return

        status = stow_check(pkg.path, self.target_dir, pkg.name)

        if status["installed"]:
            print_info(f"Package {pkg.name} is installed")
        else:
            print_info(f"Package {pkg.name} is not installed")
            if status["can_install"]:
                print_info(f"Package {pkg.name} can be installed without conflicts")
            else:
                print_warn(f"Package {pkg.name} has conflicts:")
                for conflict in status["conflicts"]:
                    print(f"  {conflict}")

    def list_packages(
        self,
        tag_filter: Optional[list[str]] = None,
        show_platform: bool = False,
        show_unavailable: bool = False,
    ) -> None:
        """List all packages, optionally filtered by tags."""
        if tag_filter:
            packages = self.tag_manager.filter_by_tags(tag_filter)
            print(f"Packages with tags: {', '.join(tag_filter)}")
        else:
            packages = self.tag_manager.packages
            print("All packages:")

        print("-" * 70)
        for pkg in packages:
            tags_str = ", ".join(pkg.tags) if pkg.tags else "(no tags)"

            available, reason = pkg.is_available_for(
                self.target_os,
                self.target_arch,
            )

            if show_platform:
                os_str = ", ".join(pkg.os) if pkg.os else "all"
                arch_str = ", ".join(pkg.arch) if pkg.arch else "all"
                enabled_str = "" if pkg.enabled else "\033[91m[disabled]\033[0m "
                avail_str = "" if available else "\033[93m[unavailable]\033[0m "
                print(
                    f"  {enabled_str}{avail_str}{pkg.name:<20} [{tags_str}] os:{os_str} arch:{arch_str}"
                )
            else:
                if not show_unavailable and not available:
                    continue
                enabled_str = "" if pkg.enabled else "\033[91m[disabled]\033[0m "
                print(f"  {enabled_str}{pkg.name:<20} [{tags_str}]")

        print(f"\nTotal: {len(packages)} package(s)")
        print(f"Platform: {self.target_os}/{self.target_arch}")

    def list_tags(self) -> None:
        """List all available tags."""
        tags = sorted(self.tag_manager.get_all_tags())
        print("Available tags:")
        print("-" * 50)
        for tag in tags:
            count = len([p for p in self.tag_manager.packages if tag in p.tags])
            print(f"  {tag:<20} ({count} packages)")

        print(f"\nTotal: {len(tags)} tag(s)")
        print("\nImplicit tags: 'all' (matches all packages), package names")

    def status(self) -> None:
        """Show installation status of all packages."""
        packages = self.tag_manager.packages
        installed = 0
        not_installed = 0
        unavailable = 0

        print("Package Status:")
        print("-" * 70)

        for pkg in packages:
            available, reason = pkg.is_available_for(
                self.target_os,
                self.target_arch,
            )

            if not available:
                status = f"\033[90munavailable ({reason})\033[0m"
                unavailable += 1
            elif is_stowed(pkg.path, self.target_dir, pkg.name):
                status = "\033[92minstalled\033[0m"
                installed += 1
            else:
                status = "\033[91mnot installed\033[0m"
                not_installed += 1

            print(f"  {pkg.name:<20} {status}")

        print("-" * 70)
        print(
            f"Installed: {installed}, Not installed: {not_installed}, Unavailable: {unavailable}"
        )
        print(f"Platform: {self.target_os}/{self.target_arch}")

        missing_metadata = self.tag_manager.get_packages_without_metadata()
        if missing_metadata:
            print(f"\nPackages missing .package.toml: {len(missing_metadata)}")
            for pkg in missing_metadata:
                print(f"  {pkg.name}")


def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        prog="install.py",
        description="Manage dotfiles using GNU stow with tag-based package management.",
    )

    parser.add_argument(
        "--target",
        "-t",
        type=Path,
        default=Path.home(),
        help="Target directory for symlinks (default: $HOME)",
    )
    parser.add_argument(
        "--os",
        dest="target_os",
        help=f"Target OS (default: {get_current_os()})",
    )
    parser.add_argument(
        "--arch",
        dest="target_arch",
        help=f"Target architecture (default: {get_current_arch()})",
    )

    subparsers = parser.add_subparsers(dest="action", help="Action to perform")

    for action in ["install", "reinstall", "uninstall", "check"]:
        sub = subparsers.add_parser(action, help=f"{action} packages")
        sub.add_argument(
            "packages",
            nargs="*",
            help="Package names to operate on (default: all packages)",
        )
        sub.add_argument(
            "--tag",
            "-T",
            action="append",
            dest="tags",
            help="Filter by tag (can be specified multiple times)",
        )
        sub.add_argument(
            "--and",
            action="store_true",
            dest="require_all",
            help="Package must have ALL specified tags (default: ANY tag)",
        )
        sub.add_argument(
            "--include-unavailable",
            action="store_true",
            help="Include packages not available for current platform",
        )

    list_parser = subparsers.add_parser("list", help="list packages")
    list_parser.add_argument(
        "--tag",
        "-T",
        action="append",
        dest="tags",
        help="Filter by tag (can be specified multiple times)",
    )
    list_parser.add_argument(
        "--and",
        action="store_true",
        dest="require_all",
        help="Package must have ALL specified tags (default: ANY tag)",
    )
    list_parser.add_argument(
        "--platform",
        "-p",
        action="store_true",
        help="Show platform information (OS/arch)",
    )
    list_parser.add_argument(
        "--all",
        "-a",
        action="store_true",
        dest="show_all",
        help="Show all packages including unavailable ones",
    )

    subparsers.add_parser("list-tags", help="list all available tags")
    subparsers.add_parser("status", help="show installation status")

    return parser


def main(args: Optional[list[str]] = None) -> int:
    """Main entry point."""
    parser = create_parser()
    ns = parser.parse_args(args)

    if not ns.action:
        parser.print_help()
        return 0

    root_dir = Path(__file__).parent.parent.resolve()
    manager = DotfilesManager(
        root_dir,
        ns.target,
        ns.target_os,
        ns.target_arch,
    )

    if ns.action == "list":
        require_all = getattr(ns, "require_all", False)
        show_all = getattr(ns, "show_all", False)
        show_platform = getattr(ns, "platform", False)

        if ns.tags and require_all:
            packages = manager.tag_manager.filter_by_tags(ns.tags, require_all=True)
            print(f"Packages with ALL tags: {', '.join(ns.tags)}")
            print("-" * 70)
            for pkg in packages:
                tags_str = ", ".join(pkg.tags) if pkg.tags else "(no tags)"
                available, _ = pkg.is_available_for(
                    manager.target_os,
                    manager.target_arch,
                )
                if not show_all and not available:
                    continue
                print(f"  {pkg.name:<20} [{tags_str}]")
            print(f"\nTotal: {len(packages)} package(s)")
            print(f"Platform: {manager.target_os}/{manager.target_arch}")
        else:
            manager.list_packages(
                ns.tags,
                show_platform=show_platform,
                show_unavailable=show_all,
            )
        return 0

    if ns.action == "list-tags":
        manager.list_tags()
        return 0

    if ns.action == "status":
        manager.status()
        return 0

    include_unavailable = getattr(ns, "include_unavailable", False)

    packages = manager.tag_manager.resolve_packages(
        package_names=ns.packages if ns.packages else None,
        tags=ns.tags,
        require_all_tags=ns.require_all if hasattr(ns, "require_all") else False,
        filter_available=not include_unavailable,
    )

    if not packages:
        print_error("No packages matched the criteria")
        return 1

    missing_metadata = [p for p in packages if not p.has_metadata]
    if missing_metadata:
        print_warn(
            f"{len(missing_metadata)} package(s) missing .package.toml metadata:"
        )
        for pkg in missing_metadata:
            print(f"  {pkg.name}")

    action_method = {
        "install": manager.install,
        "reinstall": manager.reinstall,
        "uninstall": manager.uninstall,
        "check": manager.check,
    }[ns.action]

    failed = 0
    for pkg in packages:
        if ns.action in ["install", "reinstall"]:
            result = action_method(pkg, skip_unavailable=not include_unavailable)
        else:
            result = action_method(pkg)
        if result is False:
            failed += 1

    if failed > 0:
        print_error(f"{failed} package(s) failed")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
