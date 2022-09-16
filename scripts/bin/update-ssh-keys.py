#!/usr/bin/env python3
from __future__ import annotations
import importlib
import subprocess
import sys
from pathlib import Path
from color_utils import printc


def import_or_install(module: str, package: str | None = None):
    try:
        return importlib.import_module(module)
    except ModuleNotFoundError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package or module])
        return importlib.import_module(module)


requests = import_or_install('requests')


GITHUB_USERS = ['hykilpikonna']
KEYS_PATH = Path.home() / '.ssh' / 'authorized_keys'


def fetch_keys(user: str) -> set[str]:
    resp = requests.get(f"https://github.com/{user}.keys").text
    return {f"{l} {user}@github" for l in resp.strip().splitlines()}


def fetch_all_keys() -> set[str]:
    return {l for u in GITHUB_USERS for l in fetch_keys(u)}


def normalize_key(key: str) -> str:
    """
    Remove comment from keys
    """
    return ' '.join(key.split(' ')[:2])


def update_ssh_keys():
    all_keys = list(fetch_all_keys())
    normalized_keys = {normalize_key(k) for k in all_keys}

    existing_keys = set(KEYS_PATH.read_text('utf-8').strip().splitlines())
    for k in existing_keys:
        if normalize_key(k) not in normalized_keys:
            all_keys.append(k)

    len_diff = len(all_keys) - len(existing_keys)
    if len_diff > 0:
        printc(f"&aSSH Keys Updated! Added {len_diff} keys")

    KEYS_PATH.write_text('\n'.join(all_keys))


if __name__ == "__main__":
    update_ssh_keys()
