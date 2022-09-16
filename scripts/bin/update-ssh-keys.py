#!/usr/bin/env python3
from __future__ import annotations
import importlib
import subprocess
import sys
from pathlib import Path
from urllib.request import Request, urlopen

from color_utils import printc


def import_or_install(module: str, package: str | None = None):
    try:
        return importlib.import_module(module)
    except ModuleNotFoundError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package or module])
        return importlib.import_module(module)


# Load github users
GITHUB_USERS = {'hykilpikonna'}
ADDITIONAL_USERS_PATH = Path.home() / '.ssh' / 'authorized_github_users'
if ADDITIONAL_USERS_PATH.is_file():
    GITHUB_USERS.update(set(ADDITIONAL_USERS_PATH.read_text('utf-8').split('\n')))

KEYS_PATH = Path.home() / '.ssh' / 'authorized_keys'


def fetch_keys(user: str) -> set[str]:
    req = Request(f"https://github.com/{user}.keys")
    with urlopen(req) as response:
        assert response.status == 200
        resp = response.read().decode()
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


def list_users():
    printc(f'&6> Now you have {len(GITHUB_USERS)} GitHub users in authorized_keys')
    printc(f'&6> They are: {", ".join(GITHUB_USERS)}')


def remove_user_keys(user: str):
    keys = set(fetch_keys(user))
    normalized_keys = {normalize_key(k) for k in keys}

    existing_keys = set(KEYS_PATH.read_text('utf-8').strip().splitlines())
    updated_keys = set(existing_keys)
    for k in existing_keys:
        if f'{user}@github' in k or normalize_key(k) in normalized_keys:
            updated_keys.remove(k)

    len_diff = len(existing_keys) - len(updated_keys)
    if len_diff > 0:
        printc(f"&aSSH Keys Updated! Removed {len_diff} keys")

    KEYS_PATH.write_text('\n'.join(updated_keys))


if __name__ == "__main__":
    sys.argv.pop(0)

    # No args provided
    if len(sys.argv) == 0:
        update_ssh_keys()
        exit(0)

    # Add users
    if sys.argv[0] == 'add':
        if len(sys.argv) == 1:
            printc('&cUsage: update-ssh-keys.py add {github usernames...}')
            exit(4)
        usernames = sys.argv[1:]

        GITHUB_USERS.update(set(usernames))
        ADDITIONAL_USERS_PATH.write_text('\n'.join(GITHUB_USERS))
        printc(f'&aAdded {", ".join(usernames)}!')
        list_users()
        update_ssh_keys()

    # Remove users
    if sys.argv[0] == 'remove':
        if len(sys.argv) == 1:
            printc('&cUsage: update-ssh-keys.py remove {github usernames...}')
            exit(4)
        usernames = sys.argv[1:]

        for u in usernames:
            if u in GITHUB_USERS:
                GITHUB_USERS.remove(u)
                remove_user_keys(u)
        ADDITIONAL_USERS_PATH.write_text('\n'.join(GITHUB_USERS))
        printc(f'&aRemoved {", ".join(usernames)}!')
        list_users()

    # List users
    if sys.argv[0] == 'list':
        list_users()
