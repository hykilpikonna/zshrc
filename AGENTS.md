# AGENTS.md

This is a personal, self-updating shell rc repository. Treat it as live dotfiles:
small regressions can break login shells, SSH sessions, prompts, or update flow.

## Project Map

- `scripts/zshrc.sh` is the main zsh rc.
- `fish/rc.fish` loads fish modules from `fish/includes/*.fish`.
- `powershell.ps1` is the PowerShell rc and should stay useful on Windows and
  PowerShell-on-Unix.
- `scripts/includes/init/update.sh` is the zsh auto-updater. Fish reuses it from
  `fish/includes/final.fish`; PowerShell has its own update job.
- `fastinstall.sh` is the bootstrap installer. Keep it `/bin/sh` compatible.
- `scripts/bin/` contains standalone user commands. Prefer scripts here over
  large inline shell functions when behavior is shared or nontrivial.
- `plugins/` contains vendored/submodule-style code. Do not modify plugin
  internals unless the task is explicitly about that plugin.

## General Rules

- Preserve behavior across zsh, fish, and PowerShell when adding user-facing
  shell commands. If a command is shell-specific, say so in code or docs.
- Do not blindly port Unix-only tools or paths to PowerShell. Gate Unix behavior
  with `$PSVersionTable.Platform -eq 'Unix'`, `$IsLinux`, or equivalent checks.
- Avoid adding binaries to the repository. Add installer scripts instead, as was
  done for `install-fastfetch`.
- Keep startup fast. Prompt code and auto-update checks should have timeouts,
  caching, or async execution.
- Be conservative with SSH-related changes. A bad prompt or auth change can lock
  the user out of remote devices.
- Do not rewrite unrelated files or revert user changes. This repo is often used
  as a live working tree.

## Shell-Specific Notes

### zsh

- Shared zsh helpers live in `scripts/includes/*.sh` and
  `scripts/includes/later/*.zsh`.
- Use `_zshrc_as_root` when a command should run via sudo only for non-root.
- Use `command foo` when wrapping commands like `ssh`, `git`, `ffmpeg`, etc.
- The auto-updater writes `.git/zshrc-update-notification`; prompts read and
  display this once.

### fish

- Fish is modular. Put core environment setup in `core.fish`, git helpers in
  `git.fish`, prompt/title code in `prompt.fish`, and SSH/tmux session behavior
  in `session.fish`.
- Fish already has good builtin autosuggestions, completions, and syntax
  highlighting. Do not port zsh plugins just to mimic zsh.
- Use `command foo` inside wrappers to avoid recursive fish functions.
- `br`, `bru`, and `brup` should stay semantically aligned with zsh and
  PowerShell.
- `git-env-auto {on|off|status}` is fish-only and should automatically enter
  `git-env` inside git worktrees.

### PowerShell

- Never build one shell string for native commands when arguments may contain
  spaces, backslashes, quotes, or Unicode. Use arrays and `& $exe @args`.
- Prefer the existing helpers:
  - `Get-ExternalCommandPath`
  - `Invoke-ExternalCommand`
  - `Invoke-NativeApplication`
  - `Register-ForwardingFunction`
- Keep UTF-8 setup intact. It matters for non-ASCII paths and filenames.
- Prompt color support should use ANSI RGB for prompt segments, except where the
  user specifically wanted hostname/username to remain non-RGB.
- Avoid aliases/functions that shadow PowerShell semantics in surprising ways.
  If wrapping an external command, remove conflicting aliases first.

## Git Helpers

- `br <branch>` should checkout an existing local or remote branch if it exists;
  only create a branch after updating the repository main branch.
- The main branch is not always `main`. Use `origin/HEAD` first, then fallback
  names such as `main`, `master`, `trunk`, and `develop`.
- `brup` means: fetch the latest main branch from origin, then merge
  `refs/remotes/origin/<main>` into the current branch.
- Keep worktree cleanliness checks before branch surgery.

## Prompt and PR Detection

- PR prompt detection has had both false positives and false negatives. Match PRs
  by exact GitHub head owner and head branch, not by branch name alone.
- Keep `gh` calls bounded with `timeout` where available and cache prompt PR
  state. Prompt code should fail quietly if `gh`, `git`, or network access is
  unavailable.
- Fish terminal titles should include the SSH hostname only outside tmux. Inside
  tmux, tab/window naming should not redundantly prepend the hostname.

## SSH, tmux, and OpenWrt

- Auto tmux sessions for SSH should be named `ssh`. If an old `ssh_tmux` session
  is seen, rename it to `ssh`.
- The SSH wrapper should preserve argv exactly. Do not reconstruct arguments as a
  string; that caused paths like `C:\Users\..\meow meow.mp4` and ffmpeg
  arguments to split incorrectly in PowerShell.
- WSL SSH agent relay lives in `scripts/bin/wsl-ssh-agent`. It should detect a
  stale socket and restart the relay without manual `killall socat`.
- For `update-ssh-keys.py`, do not manage OpenWrt Dropbear authorized keys as the
  default target. Dropbear builds on embedded OpenWrt may lack ECDSA and
  ECDSA-SK support. The safer path is to manage OpenSSH
  `~/.ssh/authorized_keys` and offer `update-ssh-keys.py switch-to-openssh`.
- Never disable SSH password auth just because keys were written. Require the
  user to verify public-key login in a second terminal first.
- When switching OpenWrt from Dropbear to OpenSSH, keep Dropbear available on a
  fallback port such as `2222` until OpenSSH login is confirmed.

## Embedded and Installer Constraints

- `fastinstall.sh` must stay POSIX `/bin/sh` compatible. Do not use arrays,
  `pushd`, `popd`, `[[ ... ]]`, process substitution, or bash-only parameter
  expansion there.
- Alpine/OpenWrt bootstrap logic should install only necessary dependencies and
  handle split packages such as git HTTPS helpers and CA bundles.
- Embedded devices may have tiny storage. Avoid shipping large binaries or
  dictionaries unless explicitly requested.
- Auto-update trims git history by default. Preserve `ZSHRC_UPDATE_KEEP_HISTORY`
  as the escape hatch.

## Validation Checklist

Run only the checks relevant to the files you touched:

```sh
git diff --check
```

For Python scripts:

```sh
python3 -m py_compile scripts/bin/update-ssh-keys.py
```

For POSIX shell installers:

```sh
sh -n fastinstall.sh
```

For zsh files, when zsh is available:

```sh
zsh -n scripts/zshrc.sh
zsh -n scripts/includes/init/update.sh
```

For fish files, when fish is available:

```sh
fish --no-config -n fish/rc.fish
fish --no-config -n fish/includes/*.fish
```

For PowerShell, when `pwsh` is available:

```sh
pwsh -NoProfile -Command "[scriptblock]::Create((Get-Content -Raw ./powershell.ps1)) | Out-Null"
```

If you change prompt, SSH, tmux, update, or installer behavior, also describe any
manual testing you could not perform.
