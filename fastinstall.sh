#!/bin/sh
set -eu

repo_url="${ZSHRC_REPO_URL:-https://github.com/hykilpikonna/zshrc}"
repo_dir="${ZSHRC_INSTALL_DIR:-$HOME/zshrc}"
default_submodules="plugins/zsh-autosuggestions plugins/nanorc plugins/find-the-command"
rime_submodules="config-sync/.config/ibus/rime/_submodules/rime-ice config-sync/.config/ibus/rime/_submodules/rime-kagiroi"

log() {
  printf '[zshrc] %s\n' "$*"
}

die() {
  printf '[zshrc] Error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "Need root privileges to run: $*"
  fi
}

git_has_https() {
  have git || return 1

  git_exec_path="$(git --exec-path 2>/dev/null || true)"
  [ -n "$git_exec_path" ] || return 1
  [ -x "$git_exec_path/git-remote-https" ]
}

has_ca_bundle() {
  [ -f /etc/ssl/certs/ca-certificates.crt ] || \
    [ -f /etc/ssl/cert.pem ] || \
    [ -f /etc/ssl/certs/ca-bundle.crt ]
}

install_first_available_apk() {
  for package in "$@"; do
    if as_root apk add "$package" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

install_apk_dependencies() {
  log 'Detected apk; installing Alpine/OpenWrt bootstrap dependencies.'
  as_root apk update

  packages=""
  have bash || packages="$packages bash"
  have curl || packages="$packages curl"
  have git || packages="$packages git"

  if [ -n "$packages" ]; then
    # shellcheck disable=SC2086
    as_root apk add $packages || die "apk failed to install: $packages"
  fi

  if ! git_has_https; then
    as_root apk add git-http || die 'git is missing HTTPS support and apk could not install git-http.'
  fi

  if ! has_ca_bundle; then
    install_first_available_apk ca-certificates ca-bundle || \
      die 'Could not install a CA certificate bundle with apk.'
  fi

  if ! have zsh; then
    as_root apk add zsh || die 'apk failed to install zsh.'
  fi
}

install_opkg_dependencies() {
  log 'Detected opkg; installing OpenWrt bootstrap dependencies.'
  as_root opkg update

  packages=""
  have bash || packages="$packages bash"
  have curl || packages="$packages curl"
  have git || packages="$packages git"

  if [ -n "$packages" ]; then
    # shellcheck disable=SC2086
    as_root opkg install $packages || die "opkg failed to install: $packages"
  fi

  if ! git_has_https; then
    as_root opkg install git-http || die 'git is missing HTTPS support and opkg could not install git-http.'
  fi

  if ! has_ca_bundle; then
    as_root opkg install ca-bundle || die 'Could not install ca-bundle with opkg.'
  fi

  if ! have zsh; then
    as_root opkg install zsh || die 'opkg failed to install zsh.'
  fi
}

install_bootstrap_dependencies() {
  if have apk; then
    install_apk_dependencies
  elif have opkg; then
    install_opkg_dependencies
  fi
}

is_enabled() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES | on | ON)
      return 0
      ;;
  esac

  return 1
}

install_repo_submodules() {
  log 'Installing shell plugin submodules.'
  # shellcheck disable=SC2086
  git -C "$repo_dir" submodule update --init --recursive --depth 1 -- $default_submodules

  if is_enabled "${ZSHRC_INSTALL_RIME_SUBMODULES:-}"; then
    log 'Installing Rime submodules.'
    # shellcheck disable=SC2086
    git -C "$repo_dir" submodule update --init --recursive --depth 1 -- $rime_submodules
  else
    log 'Skipping Rime submodules. Set ZSHRC_INSTALL_RIME_SUBMODULES=1 before install or run install-rime-submodules later.'
  fi
}

addline() {
  file="$1"
  line="$2"
  touch "$file"
  grep -qxF "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

if [ -d "$repo_dir" ]; then
  log "Already installed at $repo_dir."
  exit 0
fi

install_bootstrap_dependencies

have git || die 'git is required.'
git_has_https || die 'git HTTPS support is required. Install git-http.'
have zsh || die 'zsh is required.'

old_pwd="$(pwd)"
cd "$HOME"

log "Cloning $repo_url into $repo_dir."
git clone --depth 1 "$repo_url" "$repo_dir"
install_repo_submodules

if [ "$repo_dir" = "$HOME/zshrc" ]; then
  addline "$HOME/.zshrc" 'SCR="$HOME/zshrc/scripts"'
else
  addline "$HOME/.zshrc" "SCR=\"$repo_dir/scripts\""
fi
addline "$HOME/.zshrc" '. $SCR/zshrc.sh'

cd "$old_pwd"

log 'Installed. Starting zsh.'
exec zsh
