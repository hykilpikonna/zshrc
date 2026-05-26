#!/usr/bin/env python3
from __future__ import annotations
import importlib
import subprocess
import sys
from pathlib import Path
import textwrap
import os
import shutil
import re
from urllib.request import Request, urlopen

from color_utils import printc


def import_or_install(module: str, package: str | None = None):
    try:
        return importlib.import_module(module)
    except ModuleNotFoundError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package or module])
        return importlib.import_module(module)


# Load github users
GITHUB_USERS = {'hykilpikonna', 'sauricat'}
ADDITIONAL_USERS_PATH = Path.home() / '.ssh' / 'authorized_github_users'
OPENSSH_CONFIG_PATH = Path(os.environ.get('UPDATE_SSH_KEYS_SSHD_CONFIG', '/etc/ssh/sshd_config'))
DROPBEAR_CONFIG_PATH = Path(os.environ.get('UPDATE_SSH_KEYS_DROPBEAR_CONFIG', '/etc/config/dropbear'))
if ADDITIONAL_USERS_PATH.is_file():
    GITHUB_USERS.update(
        user.strip()
        for user in ADDITIONAL_USERS_PATH.read_text('utf-8').splitlines()
        if user.strip() and not user.strip().startswith('#')
    )


def is_openwrt_dropbear() -> bool:
    """
    OpenWrt's Dropbear integration reads /etc/dropbear/authorized_keys.
    Plain Dropbear on other distributions commonly keeps the OpenSSH-style
    ~/.ssh/authorized_keys path, so only switch paths for OpenWrt-like systems.
    """
    openwrt_markers = (
        Path('/etc/openwrt_release'),
        Path('/etc/openwrt_version'),
        DROPBEAR_CONFIG_PATH,
    )
    return (
        any(p.exists() for p in openwrt_markers)
        and Path('/etc/dropbear').is_dir()
        and (shutil.which('dropbear') is not None or Path('/usr/sbin/dropbear').exists())
    )


def authorized_keys_path() -> Path:
    override = os.environ.get('UPDATE_SSH_KEYS_PATH') or os.environ.get('AUTHORIZED_KEYS_PATH')
    if override:
        return Path(override).expanduser()
    if is_openwrt_dropbear():
        return Path('/etc/dropbear/authorized_keys')
    return Path.home() / '.ssh' / 'authorized_keys'


def ssh_server_kind() -> str | None:
    override = os.environ.get('UPDATE_SSH_KEYS_SSH_SERVER')
    if override:
        normalized = override.strip().lower()
        if normalized in {'dropbear', 'openssh', 'none'}:
            return None if normalized == 'none' else normalized
    if is_openwrt_dropbear():
        return 'dropbear'
    if OPENSSH_CONFIG_PATH.is_file() or shutil.which('sshd') or Path('/usr/sbin/sshd').exists():
        return 'openssh'
    return None


KEYS_PATH = authorized_keys_path()
KEYS_PATH.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
ADDITIONAL_USERS_PATH.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
if KEYS_PATH.parent == Path.home() / '.ssh':
    KEYS_PATH.parent.chmod(0o700)
ADDITIONAL_USERS_PATH.parent.chmod(0o700)


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


def is_github_key(key: str) -> bool:
    parts = key.split()
    return len(parts) >= 3 and parts[2].endswith('@github')


def run_command(cmd: list[str], check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=check, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def run_existing_reload_commands(commands: list[list[str]]) -> bool:
    for cmd in commands:
        executable = Path(cmd[0])
        if executable.is_absolute():
            if not executable.exists():
                continue
        elif not shutil.which(cmd[0]):
            continue

        result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            return True
    return False


def reload_ssh_server(kind: str):
    if kind == 'dropbear':
        if run_existing_reload_commands([
            ['/etc/init.d/dropbear', 'reload'],
            ['/etc/init.d/dropbear', 'restart'],
            ['service', 'dropbear', 'reload'],
            ['service', 'dropbear', 'restart'],
        ]):
            printc('&aReloaded dropbear.')
        else:
            printc('&eCould not reload dropbear automatically; restart SSH manually.')
        return

    if kind == 'openssh':
        if run_existing_reload_commands([
            ['systemctl', 'reload', 'sshd'],
            ['systemctl', 'reload', 'ssh'],
            ['service', 'sshd', 'reload'],
            ['service', 'ssh', 'reload'],
            ['/etc/init.d/sshd', 'reload'],
            ['/etc/init.d/ssh', 'reload'],
            ['rc-service', 'sshd', 'reload'],
            ['rc-service', 'ssh', 'reload'],
        ]):
            printc('&aReloaded sshd.')
        else:
            printc('&eCould not reload sshd automatically; restart SSH manually.')


def dropbear_password_auth_enabled(config_path: Path = DROPBEAR_CONFIG_PATH) -> bool | None:
    if not config_path.is_file():
        return None

    disabled_values = {'0', 'false', 'no', 'off', 'disabled'}
    password_auth_values: list[str | None] = []
    in_dropbear = False
    saw_password_auth = False

    def finish_section():
        nonlocal saw_password_auth
        if in_dropbear and not saw_password_auth:
            password_auth_values.append(None)
        saw_password_auth = False

    for line in config_path.read_text('utf-8', errors='replace').splitlines():
        if re.match(r'^\s*config\s+', line):
            finish_section()
            in_dropbear = bool(re.match(r'^\s*config\s+dropbear\b', line))
            continue

        if in_dropbear:
            match = re.match(r'^\s*option\s+PasswordAuth\s+[\'"]?([^\'"\s#]+)', line)
            if match:
                saw_password_auth = True
                password_auth_values.append(match.group(1))

    finish_section()

    if not password_auth_values:
        return True
    return any(value is None or value.lower() not in disabled_values for value in password_auth_values)


def set_dropbear_password_auth_disabled(config_path: Path = DROPBEAR_CONFIG_PATH) -> bool:
    lines = config_path.read_text('utf-8', errors='replace').splitlines()
    output: list[str] = []
    in_dropbear = False
    section_seen = False
    saw_password_auth = False
    saw_root_password_auth = False
    changed = False

    def finish_section():
        nonlocal changed, saw_password_auth, saw_root_password_auth
        if in_dropbear:
            if not saw_password_auth:
                output.append("\toption PasswordAuth 'off'")
                changed = True
            if not saw_root_password_auth:
                output.append("\toption RootPasswordAuth 'off'")
                changed = True
        saw_password_auth = False
        saw_root_password_auth = False

    for line in lines:
        if re.match(r'^\s*config\s+', line):
            finish_section()
            in_dropbear = bool(re.match(r'^\s*config\s+dropbear\b', line))
            section_seen = section_seen or in_dropbear
            output.append(line)
            continue

        if in_dropbear and re.match(r'^\s*option\s+PasswordAuth\b', line):
            saw_password_auth = True
            replacement = "\toption PasswordAuth 'off'"
            output.append(replacement)
            changed = changed or line != replacement
            continue

        if in_dropbear and re.match(r'^\s*option\s+RootPasswordAuth\b', line):
            saw_root_password_auth = True
            replacement = "\toption RootPasswordAuth 'off'"
            output.append(replacement)
            changed = changed or line != replacement
            continue

        output.append(line)

    finish_section()

    if not section_seen:
        output.extend([
            '',
            'config dropbear',
            "\toption PasswordAuth 'off'",
            "\toption RootPasswordAuth 'off'",
        ])
        changed = True

    if changed:
        backup = config_path.with_suffix(config_path.suffix + '.bak')
        if config_path.exists() and not backup.exists():
            shutil.copy2(config_path, backup)
        config_path.write_text('\n'.join(output).rstrip() + '\n')
    return changed


def openssh_effective_password_auth() -> bool | None:
    if os.environ.get('UPDATE_SSH_KEYS_SSHD_CONFIG'):
        return None

    sshd = shutil.which('sshd') or ('/usr/sbin/sshd' if Path('/usr/sbin/sshd').exists() else None)
    if not sshd:
        return None

    result = run_command([sshd, '-T'])
    if result.returncode != 0:
        return None

    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) >= 2 and fields[0].lower() == 'passwordauthentication':
            return fields[1].lower() == 'yes'
    return None


def openssh_password_auth_enabled(config_path: Path = OPENSSH_CONFIG_PATH) -> bool | None:
    effective = openssh_effective_password_auth()
    if effective is not None:
        return effective

    if not config_path.is_file():
        return None

    in_match = False
    value: str | None = None
    for line in config_path.read_text('utf-8', errors='replace').splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        if re.match(r'(?i)^Match\s+', stripped):
            in_match = True
        if in_match:
            continue
        match = re.match(r'(?i)^PasswordAuthentication\s+(\S+)', stripped)
        if match:
            value = match.group(1).lower()

    if value is None:
        return True
    return value == 'yes'


def set_openssh_password_auth_disabled(config_path: Path = OPENSSH_CONFIG_PATH) -> bool:
    lines = config_path.read_text('utf-8', errors='replace').splitlines() if config_path.exists() else []
    output: list[str] = []
    changed = False
    saw_password_auth = False
    inserted = False

    for line in lines:
        if not inserted and re.match(r'(?i)^\s*Match\s+', line):
            if not saw_password_auth:
                output.append('PasswordAuthentication no')
                changed = True
            inserted = True
            output.append(line)
            continue

        if not inserted and re.match(r'(?i)^\s*#?\s*PasswordAuthentication\b', line):
            saw_password_auth = True
            replacement = 'PasswordAuthentication no'
            output.append(replacement)
            changed = changed or line != replacement
            continue

        output.append(line)

    if not saw_password_auth and not inserted:
        output.append('PasswordAuthentication no')
        changed = True

    if changed:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        backup = config_path.with_suffix(config_path.suffix + '.bak')
        if config_path.exists() and not backup.exists():
            shutil.copy2(config_path, backup)
        config_path.write_text('\n'.join(output).rstrip() + '\n')
    return changed


def password_auth_enabled() -> tuple[str | None, bool | None]:
    kind = ssh_server_kind()
    if kind == 'dropbear':
        return kind, dropbear_password_auth_enabled()
    if kind == 'openssh':
        return kind, openssh_password_auth_enabled()
    return None, None


def disable_password_auth_local() -> bool:
    kind, enabled = password_auth_enabled()
    if kind is None:
        printc('&eCould not detect an SSH server config.')
        return False
    if enabled is False:
        printc('&aSSH password authentication already appears disabled.')
        return True
    if enabled is None:
        printc('&eCould not determine whether SSH password authentication is enabled.')
        return False

    if kind == 'dropbear':
        changed = set_dropbear_password_auth_disabled()
    else:
        changed = set_openssh_password_auth_disabled()

    if changed:
        printc('&aDisabled SSH password authentication in config.')
        reload_ssh_server(kind)
    else:
        printc('&aSSH password authentication already appears disabled in config.')
    return True


def disable_password_auth():
    if hasattr(os, 'geteuid') and os.geteuid() == 0:
        return disable_password_auth_local()
    if shutil.which('sudo'):
        cmd = ['sudo', sys.executable, str(Path(__file__).resolve()), 'disable-password-auth']
        result = subprocess.run(cmd)
        return result.returncode == 0

    printc('&eRun update-ssh-keys.py disable-password-auth as root to change SSH server config.')
    return False


def check_password_auth():
    kind, enabled = password_auth_enabled()
    if kind is None:
        printc('&eCould not detect an SSH server config.')
        return 1

    label = 'OpenWrt Dropbear' if kind == 'dropbear' else 'OpenSSH'
    if enabled is True:
        printc(f'&e{label} password authentication appears enabled.')
        return 2
    if enabled is False:
        printc(f'&a{label} password authentication appears disabled.')
        return 0

    printc(f'&eCould not determine {label} password authentication state.')
    return 3


def maybe_offer_disable_password_auth():
    if os.environ.get('UPDATE_SSH_KEYS_NO_PASSWORD_AUTH_PROMPT'):
        return

    kind, enabled = password_auth_enabled()
    if enabled is not True:
        return

    label = 'OpenWrt Dropbear' if kind == 'dropbear' else 'OpenSSH'
    printc(f'&eWarning: {label} password authentication appears enabled.')
    printc('&eAfter installing SSH keys, disabling password authentication is recommended.')

    if not sys.stdin.isatty():
        printc('&eRun update-ssh-keys.py disable-password-auth to disable it.')
        return

    answer = input('Disable SSH password authentication now? [y/N] ').strip().lower()
    if answer in {'y', 'yes'}:
        disable_password_auth()
    else:
        printc('&6> You can disable it later with: update-ssh-keys.py disable-password-auth')


def update_ssh_keys():
    all_keys = sorted(fetch_all_keys())
    normalized_keys = {normalize_key(k) for k in all_keys}

    existing_keys = set(KEYS_PATH.read_text('utf-8').strip().splitlines()) \
        if KEYS_PATH.is_file() else set()
    existing_normalized_keys = {normalize_key(k) for k in existing_keys}
    for k in existing_keys:
        if k and normalize_key(k) not in normalized_keys and not is_github_key(k):
            all_keys.append(k)

    len_added = len([k for k in all_keys if normalize_key(k) not in existing_normalized_keys])
    len_removed = len([k for k in existing_keys if is_github_key(k) and normalize_key(k) not in normalized_keys])
    if len_added > 0 or len_removed > 0:
        printc(f"&aSSH Keys Updated in {KEYS_PATH}! Added {len_added} keys, removed {len_removed} revoked GitHub keys")

    KEYS_PATH.write_text('\n'.join(all_keys) + '\n')
    KEYS_PATH.chmod(0o600)


def list_users():
    printc(f'&6> authorized_keys path: {KEYS_PATH}')
    printc(f'&6> Now you have {len(GITHUB_USERS)} GitHub users in authorized_keys')
    printc(f'&6> They are: {", ".join(sorted(GITHUB_USERS))}')


def remove_user_keys(user: str):
    keys = set(fetch_keys(user))
    normalized_keys = {normalize_key(k) for k in keys}

    existing_keys = set(KEYS_PATH.read_text('utf-8').strip().splitlines()) \
        if KEYS_PATH.is_file() else set()
    updated_keys = set(existing_keys)
    for k in existing_keys:
        if f'{user}@github' in k or normalize_key(k) in normalized_keys:
            updated_keys.remove(k)

    len_diff = len(existing_keys) - len(updated_keys)
    if len_diff > 0:
        printc(f"&aSSH Keys Updated in {KEYS_PATH}! Removed {len_diff} keys")

    KEYS_PATH.write_text('\n'.join(updated_keys) + '\n')
    KEYS_PATH.chmod(0o600)


if __name__ == "__main__":
    sys.argv.pop(0)

    # No args provided
    if len(sys.argv) == 0:
        update_ssh_keys()
        maybe_offer_disable_password_auth()
        exit(0)

    # Add users
    elif sys.argv[0] == 'add':
        if len(sys.argv) == 1:
            printc('&cUsage: update-ssh-keys.py add {github usernames...}')
            exit(4)
        usernames = sys.argv[1:]

        GITHUB_USERS.update(set(usernames))
        ADDITIONAL_USERS_PATH.write_text('\n'.join(sorted(GITHUB_USERS)) + '\n')
        printc(f'&aAdded {", ".join(usernames)}!')
        list_users()
        update_ssh_keys()
        maybe_offer_disable_password_auth()

    # Remove users
    elif sys.argv[0] == 'remove':
        if len(sys.argv) == 1:
            printc('&cUsage: update-ssh-keys.py remove {github usernames...}')
            exit(4)
        usernames = sys.argv[1:]

        for u in usernames:
            if u in GITHUB_USERS:
                GITHUB_USERS.remove(u)
                remove_user_keys(u)
        ADDITIONAL_USERS_PATH.write_text('\n'.join(sorted(GITHUB_USERS)) + '\n')
        printc(f'&aRemoved {", ".join(usernames)}!')
        list_users()

    # List users
    elif sys.argv[0] == 'list':
        list_users()

    elif sys.argv[0] == 'check-password-auth':
        exit(check_password_auth())

    elif sys.argv[0] == 'disable-password-auth':
        exit(0 if disable_password_auth() else 1)

    # Unknown argument
    else:
        print(textwrap.dedent("""
            Usage: update-ssh-keys.py
            - add/remove [github username]
            - list
            - check-password-auth
            - disable-password-auth
            """))
