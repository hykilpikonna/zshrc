# ZSH History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY

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

modern-replace 'ls' 'eza' 'ls -h --color=auto'
modern-replace 'df' 'duf' 'df -h'
modern-replace 'cat' 'bat'
modern-replace 'man' 'tldr'
modern-replace 'top' 'btop'
modern-replace 'ping' 'gping'
modern-replace 'dig' 'dog'
modern-replace 'grep' 'rg'
modern-replace 'nano' 'micro'
modern-replace 'curl' 'curlie'
# modern-replace 'tree' 'broot'
modern-replace 'pacman' 'paru' 'pacman --color always' 'paru --color always'
modern-replace 'vi' 'nvim'
modern-replace 'vim' 'nvim'

# for macOS
modern-replace 'tar' 'gtar'

source "$BASEDIR/plugins/zsh-z.plugin.zsh"

# Initialize fuck
if command -v 'fuck' &> /dev/null; then 
    eval "$(thefuck --alias)"
fi

if command -v 'xdg-open' &> /dev/null; then 
    alias open="xdg-open"
fi

# 好用的简写w
alias ll='ls -l'
alias l='ll'
alias lla='ls -la'
alias grep='grep --color'
alias rm='rm -ir'
alias mkdirs='mkdir -p'

alias ip='ip -c -h -p'
alias ipa='ip -br a'
alias ipj='ip -j'
alias ipv4="curl https://1.0.0.1/cdn-cgi/trace -4 | grep ip"
alias ipv6="curl 'https://[2606:4700:4700::1111]/cdn-cgi/trace' -6 | grep ip"

alias ports='netstat -tulpn | grep LISTEN'
alias suports='sudo netstat -tulpn | grep LISTEN'
alias findtxt='grep -IHrnws --exclude=\*.log -s '/' -e'

alias cls='clear'

alias tar-create='tar -cvf'
alias tar-expand='tar -zxvf'

alias du='du -h'
alias sortsize='sort -hr'
alias dus='du -shc * | sortsize'
alias dusa='du -hc --max-depth=1 | sortsize'

alias ffmpeg="ffmpeg -hide_banner"
alias ffprobe="ffprobe -hide_banner"

alias ts='sudo tailscale'
alias ts-install='curl -fsSL https://tailscale.com/install.sh | sh'

alias vsucode='sudo code --user-data-dir /root/.config/vscode --no-sandbox'
alias visucode='EDITOR="code --wait" sudoedit'
alias gpu-temp='while sleep 1; do clear; gpustat; done'
alias cpu-temp='s-tui'
alias mount-external='sudo mount -t cifs //192.168.2.1/external /smb/external -o rw,user=azalea,uid=1000,gid=1000,pass='
alias compress-json="find -name '*.json' -print0 | parallel --jobs 80% -0 zstd -z -19 -v -f --rm {}"

alias ds-clean="find . -name '.DS_Store' -delete -print"
alias dotclean="find . -name '._*' -delete -print"
alias clean-empty-dir="find . -type d -empty -delete -print"
alias restart-kwin="DISPLAY=:0 setsid kwin_x11 --replace"

alias mkfs.fat32="sudo mkfs.fat -F 32"
alias btrfs-fs-progress="sudo watch -d sudo btrfs fi us"
alias btrfs-balance-progress="sudo watch -d btrfs balance status"
alias xcp="rsync -aviHAXKhS --one-file-system --partial --info=progress2 --atimes --open-noatime --delete --exclude='*~' --exclude=__pycache__"
alias xcpz="xcp --compress-choice=zstd --compress-level=3 --checksum-choice=xxh3"

alias tmuxs="tmux new-session -s"
alias tmuxr="tmux attach-session -t"
alias tmuxl="tmux list-sessions"

alias catt="echo 🐱"
alias old-update-ssh-keys="curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys"

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
alias sctl="sudo systemctl"
alias sctlu="systemctl --user"
alias jctl="sudo journalctl"
alias jctlu="journalctl --user-unit"
alias ufw="sudo ufw"
alias nginx="sudo nginx"
alias certbot="sudo certbot"
alias apt="sudo apt"
alias dpkg="sudo dpkg"

has() {
    command -v "$1" &> /dev/null
}

# Compress 7z zstd <out_file> <in_files...>
compress-7zst() {
    if [ -z "$1" ]; then
        echo "Usage: compress-7zst <out_file> <in_files...>"
        return
    fi
    7z a -m0=zstd -mx17 -mmt35 "$1" "$2"
}

# Install using system package manager
install-package() {
    if has pacman; then
        pacman -Sy "$1"
    elif has apt; then
        apt install "$1"
    elif has dnf; then
        dnf install "$1"
    elif has brew; then
        brew install "$1"
    fi
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
else
    install-package micro
    export EDITOR="micro"
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
    sudo find . -type d -exec chmod 755 {} \;
    sudo find . -type f -exec chmod 644 {} \;
}
 
export PATH="$SCR/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

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

# Minecraft coloring
color() {
    tmp="$*&r"
    tmp="${tmp//&0/\033[0;30m}"
    tmp="${tmp//&1/\033[0;34m}"
    tmp="${tmp//&2/\033[0;32m}"
    tmp="${tmp//&3/\033[0;36m}"
    tmp="${tmp//&4/\033[0;31m}"
    tmp="${tmp//&5/\033[0;35m}"
    tmp="${tmp//&6/\033[0;33m}"
    tmp="${tmp//&7/\033[0;37m}"
    tmp="${tmp//&8/\033[1;30m}"
    tmp="${tmp//&9/\033[1;34m}"
    tmp="${tmp//&a/\033[1;32m}"
    tmp="${tmp//&b/\033[1;36m}"
    tmp="${tmp//&c/\033[1;31m}"
    tmp="${tmp//&d/\033[1;35m}"
    tmp="${tmp//&e/\033[1;33m}"
    tmp="${tmp//&f/\033[1;37m}"
    tmp="${tmp//&r/\033[0m}"
    newline=$'\n'
    tmp="${tmp//&n/$newline}"
    echo "$tmp"
}
alias colors="color '&000&111&222&333&444&555&666&777&888&999&aaa&bbb&ccc&ddd&eee&fff'"

# Includes
for f in "$SCR/includes/"*.*sh; do source "$f"; done
for f in "$SCR/includes/later/"*.*sh; do source "$f"; done

# Set proxy
setproxy() {
    addr=${1:-127.0.0.1}
    port=${2:-7890}
    full="$addr:$port"
    export https_proxy="http://$full"
    export http_proxy="http://$full"
    export all_proxy="socks5://$full"
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
