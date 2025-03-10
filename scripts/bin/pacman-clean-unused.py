#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


log_file = Path("pacman-cleanup.json")
log = {} if not log_file.exists() else json.loads(log_file.read_text())


def get_unused_packages() -> list[str]:
    result = subprocess.run(["pacman", "-Qdtq"], capture_output=True, text=True)
    return result.stdout.splitlines() if result.returncode == 0 else []


def get_package_description(package: str) -> str:
    result = subprocess.run(["pacman", "-Qi", package], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if line.startswith("Description"):
            return line.split(":", 1)[1].strip()
    return "No description available."


def exec_remove() -> None:
    subprocess.run(["sudo", "pacman", "-Rns", *log.get("removed", [])])


def log_action(package: str, removed: bool) -> None:
    removed = "removed" if removed else "kept"
    log[removed] = log.get(removed, []) + [package]
    log_file.write_text(json.dumps(log, indent=4))
    

def main() -> None:
    packages = get_unused_packages()
    if not packages:
        print("No unused packages found.")
        return
    
    for package in packages:
        if package in log.get("removed", []) or package in log.get("kept", []):
            continue
        
        desc = get_package_description(package)
        answer = input(f"Remove {package}? ({desc}) [y/N]: ").strip().lower()
        if answer == "y":
            log_action(package, True)
        else:
            log_action(package, False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove unused packages.")
    parser.add_argument("--exec", action="store_true", help="Execute the removal.")
    args = parser.parse_args()
    
    try:
        main()
        if args.exec:
            exec_remove()
    except KeyboardInterrupt:
        sys.exit("\nOperation canceled by user.")
