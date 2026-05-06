# ZSH History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY

# UTF-8 Support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ $EUID -eq 0 ]]; then
    ZSHRC_SUDO=""
else
    ZSHRC_SUDO="sudo "
fi

_zshrc_as_root() {
    if [[ $EUID -eq 0 ]]; then
        command "$@"
    else
        sudo "$@"
    fi
}

BASEDIR="$(dirname "$(dirname "$0")")"

# Bash-like shortcuts
bindkey '^[[1;5C' forward-word  # Ctrl + Right
bindkey '^[[1;5D' backward-word # Ctrl + Left
# ^w for delete backward until a space
# ^backspace for delete backward until a word delimiter
autoload -U select-word-style
select-word-style bash
bindkey '^W' backward-delete-word
bindkey '^H' backward-kill-word

# Early includes
for f in "$SCR/includes/init/"*.*sh; do source "$f"; done

source "$BASEDIR/plugins/zsh-z.plugin.zsh"

# Initialize fuck
if command -v 'fuck' &> /dev/null; then 
    eval "$(thefuck --alias)"
fi

if command -v 'xdg-open' &> /dev/null; then 
    alias open="xdg-open"
fi

# 好用的简写
alias ll='ls -l'
alias l='ll'
alias llg='ll --git --git-repos'
alias lla='ls -la'
alias grep='grep --color'
alias rm='rm -ir'
alias mkdirs='mkdir -p'

alias ip='ip -c -h -p'
alias ipa='ip -br a'
alias ipv4="curl https://1.0.0.1/cdn-cgi/trace -4 | grep ip"
alias ipv6="curl 'https://[2606:4700:4700::1111]/cdn-cgi/trace' -6 | grep ip"

ports() {
    if command -v ss &> /dev/null; then
        ss -tulpn
    else
        netstat -tulpn | grep LISTEN
    fi
}

suports() {
    if command -v ss &> /dev/null; then
        _zshrc_as_root ss -tulpn
    else
        _zshrc_as_root netstat -tulpn | grep LISTEN
    fi
}

findtxt() {
    if [[ -z $1 ]]; then
        echo "Usage: findtxt <pattern>"
        return 1
    fi

    local pattern="$*"
    if command -v rg &> /dev/null; then
        rg -n --no-messages -- "$pattern" /
    else
        grep -IHrnws -s -e "$pattern" /
    fi
}

alias clr='reset'
alias please='sudo'

if [[ "$IS_SANDBOX" == "1" ]]; then
    alias codex='codex --dangerously-bypass-approvals-and-sandbox'
    alias claude='claude --dangerously-skip-permissions'
fi

alias du='du -h'

alias ffmpeg="ffmpeg -hide_banner"
alias ffprobe="ffprobe -hide_banner"

alias ts="${ZSHRC_SUDO}tailscale"
alias ts-install='curl -fsSL https://tailscale.com/install.sh | sh'

alias visucode='EDITOR="code --wait" sudoedit'
alias gpu-temp='while sleep 1; do clear; gpustat; done'
alias cpu-temp='s-tui'
alias compress-json="find -name '*.json' -print0 | parallel --jobs 80% -0 zstd -z -19 -v -f --rm {}"

dotclean() {
    find . \( -name '.DS_Store' -o -name '._*' \) -delete -print
}
alias clean-empty-dir="find . -type d -empty -delete -print"

alias mkfs.fat32="${ZSHRC_SUDO}mkfs.fat -F 32"

# Rsync aliases by 依云, for synching (keep hard links, ACL, atime, xattr, etc)
# Deletes files in destination that are not in source
alias xcp="rsync -aviHAXKhS --one-file-system --partial --info=progress2 --atimes --open-noatime --delete --exclude='*~' --exclude=__pycache__"
alias xcpz="xcp --compress-choice=zstd --compress-level=3 --checksum-choice=xxh3"
alias xmv="xcp --remove-source-files"
alias xmvz="xcpz --remove-source-files"

# Rsync aliases by Azalea, for file transfer (do not keep hard links, ACL, atime, etc.)
# Will not delete files in destination that are not in source
alias rcp="rsync -avihS --partial --info=progress2 --exclude='*~' --exclude=__pycache__"
alias rcpz="rcp --compress --compress-level=3 --checksum-choice=xxh3"
alias rmv="rcp --remove-source-files"
alias rmvz="rcpz --remove-source-files"

alias tmuxs="tmux new-session -s"
alias tmuxr="tmux attach-session -t"
alias tmuxl="tmux list-sessions"

alias catt="echo 🐱"
alias old-update-ssh-keys="curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys"
alias colors="color '&000&111&222&333&444&555&666&777&888&999&aaa&bbb&ccc&ddd&eee&fff'"

alias tar-kill-progress="watch -n 60 killall tar -SIGUSR1"

alias valgrin="valgrind \
  --leak-check=full \
  --show-leak-kinds=all \
  --leak-resolution=med \
  --track-origins=yes \
  --vgdb=no"

mkcd() {
  if [[ -z $1 ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi

  mkdir -p "$1" && cd "$1" || return 1
}

set-java() {
    eval "$(switch-java "$1")"
}

upload-daisy() {
    file="$@"
    curl -u azalea -F "path=@$file" "https://daisy-ddns.hydev.org/upload\?path\=/"
}

# Automatic sudo
if [[ $EUID -ne 0 ]]; then
alias sctl="sudo systemctl"
alias sctlu="systemctl --user"
alias jctl="sudo journalctl"
alias jctlu="journalctl --user-unit"
alias ufw="sudo ufw"
alias nginx="sudo nginx"
alias certbot="sudo certbot"
alias apt="sudo apt"
alias dpkg="sudo dpkg"
else
alias sctl="systemctl"
alias sctlu="systemctl --user"
alias jctl="journalctl"
alias jctlu="journalctl --user-unit"
fi

has() {
    command -v "$1" &> /dev/null
}

ttmp() {
    mkdir -p /tmp/tmp
    cd /tmp/tmp || return
}

# Set EDITOR
if has micro; then 
    export EDITOR="micro"
elif has nano; then
    export EDITOR="nano"
fi

# Use the stable SSH agent socket maintained by ~/.ssh/rc inside SSH/tmux sessions.
if [[ -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
    if [[ -n "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$HOME/.ssh/current_agent.sock" && -S "$SSH_AUTH_SOCK" ]]; then
        mkdir -p "$HOME/.ssh"
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/current_agent.sock"
    fi

    if [[ -S "$HOME/.ssh/current_agent.sock" ]]; then
        export SSH_AUTH_SOCK="$HOME/.ssh/current_agent.sock"
    fi
fi

# Gradle with auto environment detection
if [[ -z $GRADLE ]] && command -v 'gradle' &> /dev/null; then
    GRADLE="$(which gradle)"
fi

gradle() {
    if [[ -f "./gradlew" ]]; then 
        ./gradlew "$@"
    else 
        if [[ -z $GRADLE ]]; then 
            echo "Neither gradle nor ./gradlew is found, please install it and restart zsh." 
        else 
            $GRADLE "$@" 
        fi
    fi
}

# Block the 7z d command becuase it's dangerous
7z() {
    if [[ "$1" == "d" ]]; then
        echo "7z d is blocked. It doesn't stand for decompress, it stands for delete."
    else
        command 7z "$@"
    fi
}

# Unix permissions reset (Dangerous! This will make executable files no longer executable)
reset-permissions-dangerous() {
    _zshrc_as_root find . -type d -exec chmod 755 {} \;
    _zshrc_as_root find . -type f -exec chmod 644 {} \;
}
 
export PATH="$SCR/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
if [[ "$(uname -s)" == "Linux" ]] && [[ "$(uname -m)" == "x86_64" ]]; then
    export PATH="$SCR/bin/linux-x64:$PATH"
fi
export PATH="$PATH:."

# Lisp wrapper
lisp() {
    ros run --load "$1" --quit
}

# Remote adb
adblan() {
    adb connect "$1:16523"
}
alias adblan-start="adb tcpip 16523"

# Add line if it doesn't exist in a file
addline() {
  grep -qxF "$2" "$1" || echo "$2" >> "$1"
}

# Silent pushd and popd
spushd () {
    pushd "$@" > /dev/null || exit
}
spopd () {
    popd "$@" > /dev/null || exit
}

# Modern unix replacements.
# Usage: modern-replace 'orig cmd' 'new cmd' 'orig cmd with args (optional)' 'new cmd with args (optional)'
modern-replace() {
    orig_cmd="$1"
    new_cmd="$2"
    orig_cmd_with_args="${3:-$1}"
    new_cmd_with_args="${4:-$2}"

    if command -v "$new_cmd" &> /dev/null; then
        alias "$orig_cmd=$new_cmd_with_args"
    else
        alias "$orig_cmd=$orig_cmd_with_args"
    fi
}

# Includes
for f in "$SCR/includes/"*.*sh; do source "$f"; done
for f in "$SCR/includes/later/"*.*sh; do source "$f"; done

modern-replace 'ls' 'eza' 'ls -h --color=auto'
modern-replace 'df' 'duf' 'df -h'
modern-replace 'cat' 'bat'
modern-replace 'man' 'tldr'
modern-replace 'top' 'btop'
# modern-replace 'ping' 'gping'
# modern-replace 'dig' 'dog'
# modern-replace 'grep' 'rg'
modern-replace 'nano' 'micro'
modern-replace 'curl' 'curlie'
modern-replace 'pacman' 'paru' 'pacman --color always' 'paru --color always'
modern-replace 'vi' 'nvim'
modern-replace 'vim' 'nvim'
# modern-replace 'wget' 'aria2c'

# for macOS
modern-replace 'tar' 'gtar'

# for ArchLinux compat
modern-replace 'code' 'visual-studio-code-electron'

# If podman binary exists and docker binary doesn't exist, alias docker=podman
if (( ! $+commands[docker] && $+commands[podman] )); then
    alias docker='podman'
    if (( $+commands[podman-compose] )); then
        alias docker-compose='podman-compose'
    fi
fi

# Set proxy
setproxy() {
    addr=${1:-127.0.0.1}
    port=${2:-7890}
    full="$addr:$port"
    export https_proxy="http://$full"
    export http_proxy="http://$full"
    export all_proxy="http://$full"
    export HTTPS_PROXY="http://$full"
    export HTTP_PROXY="http://$full"
    export ALL_PROXY="http://$full"
    color "&aUsing proxy! $full&r"

    prompt-set 30 "🌎 "
    prompt-update
}

# SSH Patch
[[ -z $SSH_BIN ]] && SSH_BIN=$(which ssh)
ssh() {
    if [[ "$TERM" == 'xterm-kitty' ]]; then
        env TERM=xterm-256color "$SSH_BIN" "$@"
    else
        "$SSH_BIN" "$@"
    fi
}

# SSH Tmux
if [[ $- =~ i ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
  if command -v tmux >/dev/null 2>&1; then
    tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
  fi
fi

# Subtitle generation
subtitle() {
    CUDA_VISIBLE_DEVICES=1 auto_subtitle --srt_only True --model large "$1"
}

# Uplaod to HyDEV daisy
upload() {
    local FILE=$1
    local SERVER_URL="https://daisy.hydev.org/upload?path=/"
    local UP_USERNAME="azalea"

    # Check if UP_PASSWORD is set
    if [ -z "$UP_PASSWORD" ]; then
        echo "Error: Password not set, please export UP_PASSWORD=xxx"
        return
    fi

    if [ -f "$FILE" ]; then
        curl -u $UP_USERNAME:$UP_PASSWORD -F "path=@$FILE" "$SERVER_URL"
    else
        echo "Error: File not found."
    fi
}


# include if it exists
[ -f "$HOME/extra.rc.sh" ] && source "$HOME/extra.rc.sh"
