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
import glob
import shlex
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
OPENSSH_INCLUDE_BASE_PATH = Path(os.environ.get('UPDATE_SSH_KEYS_SSHD_INCLUDE_BASE', '/etc/ssh'))
DROPBEAR_CONFIG_PATH = Path(os.environ.get('UPDATE_SSH_KEYS_DROPBEAR_CONFIG', '/etc/config/dropbear'))
if ADDITIONAL_USERS_PATH.is_file():
    GITHUB_USERS.update(
        user.strip()
        for user in ADDITIONAL_USERS_PATH.read_text('utf-8').splitlines()
        if user.strip() and not user.strip().startswith('#')
    )


def is_openwrt_dropbear() -> bool:
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
    return Path.home() / '.ssh' / 'authorized_keys'


def ssh_server_kind() -> str | None:
    override = os.environ.get('UPDATE_SSH_KEYS_SSH_SERVER')
    if override:
        normalized = override.strip().lower()
        return 'openssh' if normalized == 'openssh' else None
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


def is_root() -> bool:
    return hasattr(os, 'geteuid') and os.geteuid() == 0


def package_manager() -> str | None:
    if shutil.which('apk'):
        return 'apk'
    if shutil.which('opkg'):
        return 'opkg'
    return None


def openssh_server_installed() -> bool:
    return OPENSSH_CONFIG_PATH.is_file() or shutil.which('sshd') is not None or Path('/usr/sbin/sshd').exists()


def run_as_root(cmd: list[str]) -> bool:
    if is_root():
        root_cmd = cmd
    elif shutil.which('sudo'):
        root_cmd = ['sudo', *cmd]
    else:
        printc(f'&eNeed root privileges to run: {" ".join(cmd)}')
        return False

    return subprocess.run(root_cmd).returncode == 0


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


def write_backup(path: Path):
    backup = path.with_suffix(path.suffix + '.bak')
    if path.exists() and not backup.exists():
        shutil.copy2(path, backup)


def sshd_config_tokens(line: str) -> list[str]:
    try:
        return shlex.split(line, comments=True, posix=True)
    except ValueError:
        return line.split('#', 1)[0].split()


def expand_sshd_include_paths(patterns: list[str]) -> list[Path]:
    paths: list[Path] = []
    for pattern in patterns:
        path = Path(pattern)
        if not path.is_absolute():
            path = OPENSSH_INCLUDE_BASE_PATH / path

        matches = sorted(glob.glob(str(path)))
        if not matches and not glob.has_magic(str(path)):
            matches = [str(path)]

        paths.extend(Path(match) for match in matches if Path(match).is_file())
    return paths


def read_openssh_global_option(
    option: str,
    config_path: Path = OPENSSH_CONFIG_PATH,
    seen: set[Path] | None = None,
) -> str | None:
    if not config_path.is_file():
        return None

    if seen is None:
        seen = set()

    resolved = config_path.resolve(strict=False)
    if resolved in seen:
        return None
    seen.add(resolved)

    option_lower = option.lower()
    for line in config_path.read_text('utf-8', errors='replace').splitlines():
        tokens = sshd_config_tokens(line)
        if not tokens:
            continue

        key = tokens[0].lower()
        if key == 'match':
            break

        if key == 'include':
            for include_path in expand_sshd_include_paths(tokens[1:]):
                value = read_openssh_global_option(option, include_path, seen)
                if value is not None:
                    return value
            continue

        if key == option_lower and len(tokens) >= 2:
            return tokens[1].lower()

    return None


def set_openssh_global_options(options: dict[str, str], config_path: Path = OPENSSH_CONFIG_PATH) -> bool:
    lines = config_path.read_text('utf-8', errors='replace').splitlines() if config_path.exists() else []
    output: list[str] = []
    pending = {key.lower(): (key, value) for key, value in options.items()}
    option_pattern = '|'.join(re.escape(key) for key in options)
    changed = False
    inserted = False

    def append_pending():
        nonlocal changed
        for option, value in pending.values():
            output.append(f'{option} {value}')
            changed = True
        pending.clear()

    for line in lines:
        if not inserted:
            tokens = sshd_config_tokens(line)
            if tokens and tokens[0].lower() in {'include', 'match'}:
                append_pending()
                inserted = True
                output.append(line)
                continue

        if not inserted:
            match = re.match(rf'(?i)^\s*#?\s*({option_pattern})\b', line)
            if match:
                key = match.group(1).lower()
                if key in pending:
                    option, value = pending.pop(key)
                    replacement = f'{option} {value}'
                    output.append(replacement)
                    changed = changed or line != replacement
                    continue

        output.append(line)

    if pending:
        append_pending()

    if changed:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        write_backup(config_path)
        config_path.write_text('\n'.join(output).rstrip() + '\n')
    return changed


def set_dropbear_backup_port(config_path: Path = DROPBEAR_CONFIG_PATH, port: str = '2222') -> bool:
    if not config_path.exists():
        return False

    lines = config_path.read_text('utf-8', errors='replace').splitlines()
    output: list[str] = []
    in_dropbear = False
    saw_port = False
    changed = False

    def finish_section():
        nonlocal changed, saw_port
        if in_dropbear and not saw_port:
            output.append(f"\toption Port '{port}'")
            changed = True
        saw_port = False

    for line in lines:
        if re.match(r'^\s*config\s+', line):
            finish_section()
            in_dropbear = bool(re.match(r'^\s*config\s+dropbear\b', line))
            output.append(line)
            continue

        port_match = re.match(r'^\s*option\s+Port\s+[\'"]?([^\'"\s#]+)', line)
        if in_dropbear and port_match:
            saw_port = True
            if port_match.group(1) == '22':
                replacement = f"\toption Port '{port}'"
                output.append(replacement)
                changed = changed or line != replacement
            else:
                output.append(line)
            continue

        output.append(line)

    finish_section()

    if changed:
        write_backup(config_path)
        config_path.write_text('\n'.join(output).rstrip() + '\n')
    return changed


def install_openssh_server() -> bool:
    if openssh_server_installed():
        printc('&aOpenSSH server already appears installed.')
        return True

    manager = package_manager()
    if manager == 'apk':
        return run_as_root(['apk', 'update']) and run_as_root(['apk', 'add', 'openssh-server'])
    if manager == 'opkg':
        return run_as_root(['opkg', 'update']) and run_as_root(['opkg', 'install', 'openssh-server'])

    printc('&eCould not find apk or opkg to install openssh-server.')
    return False


def start_openssh_switch_services() -> bool:
    script = Path('/tmp/update-ssh-keys-switch-openssh.sh')
    log_path = Path('/tmp/update-ssh-keys-switch-openssh.log')
    script.write_text(textwrap.dedent("""\
        #!/bin/sh
        sleep 1
        if [ -x /etc/init.d/dropbear ]; then
          /etc/init.d/dropbear restart || /etc/init.d/dropbear reload || true
        fi
        if [ -x /etc/init.d/sshd ]; then
          /etc/init.d/sshd enable || true
          /etc/init.d/sshd restart || /etc/init.d/sshd start || true
        fi
        if [ -x /etc/init.d/ssh ]; then
          /etc/init.d/ssh enable || true
          /etc/init.d/ssh restart || /etc/init.d/ssh start || true
        fi
        """))
    script.chmod(0o755)

    log_file = log_path.open('ab')
    subprocess.Popen(
        ['/bin/sh', str(script)],
        stdin=subprocess.DEVNULL,
        stdout=log_file,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    printc(f'&aStarted OpenSSH switch in the background. Log: {log_path}')
    return True


def switch_to_openssh(update_keys: bool = True) -> bool:
    if not is_root() and shutil.which('sudo'):
        cmd = ['sudo', sys.executable, str(Path(__file__).resolve()), 'switch-to-openssh']
        return subprocess.run(cmd).returncode == 0
    if not is_root():
        printc('&eRun update-ssh-keys.py switch-to-openssh as root.')
        return False

    if update_keys:
        update_ssh_keys()
    if not install_openssh_server():
        return False

    set_openssh_global_options({
        'PubkeyAuthentication': 'yes',
        'AuthorizedKeysFile': '.ssh/authorized_keys',
        'PermitRootLogin': 'prohibit-password',
    })
    set_dropbear_backup_port()

    printc('&eDropbear will be moved to port 2222 as a fallback.')
    printc('&eThis may close the current SSH session if it is connected through Dropbear.')
    if not start_openssh_switch_services():
        return False

    printc('&aAfter a few seconds, test OpenSSH on port 22:')
    printc('&6> ssh -o PasswordAuthentication=no root@<host>')
    printc('&6> ssh -p 2222 root@<host>  # Dropbear fallback')
    return True


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

    value = read_openssh_global_option('PasswordAuthentication', config_path)
    if value is None:
        return True
    if value in {'yes', 'no'}:
        return value == 'yes'
    return None


def set_openssh_password_auth_disabled(config_path: Path = OPENSSH_CONFIG_PATH) -> bool:
    return set_openssh_global_options({'PasswordAuthentication': 'no'}, config_path)


def password_auth_enabled() -> tuple[str | None, bool | None]:
    kind = ssh_server_kind()
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

    if enabled is True:
        printc('&eOpenSSH password authentication appears enabled.')
        return 2
    if enabled is False:
        printc('&aOpenSSH password authentication appears disabled.')
        return 0

    printc('&eCould not determine OpenSSH password authentication state.')
    return 3


def maybe_offer_disable_password_auth():
    if os.environ.get('UPDATE_SSH_KEYS_NO_PASSWORD_AUTH_PROMPT'):
        return

    kind, enabled = password_auth_enabled()
    if enabled is not True:
        return

    printc('&eWarning: OpenSSH password authentication appears enabled.')
    printc('&eAfter installing SSH keys, disabling password authentication is recommended.')
    printc('&eBefore disabling it, open another terminal and verify public-key login works:')
    printc('&6> ssh -o PasswordAuthentication=no <user>@<host>')
    if os.environ.get('SSH_CONNECTION') or os.environ.get('SSH_CLIENT'):
        printc('&eReloading SSH may close this current SSH session.')

    if not sys.stdin.isatty():
        printc('&eRun update-ssh-keys.py disable-password-auth to disable it.')
        return

    try:
        answer = input('Type "disable" after verifying key login, or press Enter to skip: ').strip().lower()
    except (EOFError, KeyboardInterrupt):
        print()
        return
    if answer == 'disable':
        disable_password_auth()
    else:
        printc('&6> You can disable it later with: update-ssh-keys.py disable-password-auth')


def maybe_offer_openssh_switch():
    if os.environ.get('UPDATE_SSH_KEYS_NO_OPENSSH_PROMPT'):
        return
    if not is_openwrt_dropbear() or openssh_server_installed():
        return

    printc('&eDetected OpenWrt Dropbear without OpenSSH server.')
    printc('&eThis script now manages ~/.ssh/authorized_keys for OpenSSH instead of Dropbear keys.')
    printc('&eOpenWrt Dropbear builds may reject ECDSA and ECDSA-SK keys.')

    if not sys.stdin.isatty():
        printc('&eRun update-ssh-keys.py switch-to-openssh to install OpenSSH and move Dropbear to port 2222.')
        return

    try:
        answer = input('Type "openssh" to install OpenSSH on port 22 and move Dropbear to 2222: ').strip().lower()
    except (EOFError, KeyboardInterrupt):
        print()
        return
    if answer == 'openssh':
        switch_to_openssh(update_keys=not is_root())
    else:
        printc('&6> You can switch later with: update-ssh-keys.py switch-to-openssh')


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
        maybe_offer_openssh_switch()
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
        maybe_offer_openssh_switch()
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

    elif sys.argv[0] == 'switch-to-openssh':
        exit(0 if switch_to_openssh() else 1)

    # Unknown argument
    else:
        print(textwrap.dedent("""
            Usage: update-ssh-keys.py
            - add/remove [github username]
            - list
            - check-password-auth
            - disable-password-auth
            - switch-to-openssh
            """))
