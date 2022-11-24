# ZSH History
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

# Modern unix replacements.
# Usage: modern-replace 'orig cmd' 'new cmd' 'orig cmd with args (optional)' 'new cmd with args (optional)'
modern-replace() {
    orig_cmd="$1"
    new_cmd="$2"
    orig_cmd_with_args="${3:-$1}"
    new_cmd_with_args="${4:-$2}"

    if command -v "$new_cmd" &> /dev/null; then
        alias $orig_cmd="$new_cmd_with_args"
    else
        alias $orig_cmd="$orig_cmd_with_args"
    fi
}

modern-replace 'ls' 'exa' 'ls -h --color=auto'
modern-replace 'df' 'duf' 'df -h'
modern-replace 'cat' 'bat'
modern-replace 'man' 'tldr'
modern-replace 'top' 'btop'
modern-replace 'ping' 'gping'
modern-replace 'dig' 'dog'
# modern-replace 'curl' 'curlie'
# modern-replace 'tree' 'broot'

# Initialize fuck
if command -v 'fuck' &> /dev/null; then 
    eval $(thefuck --alias)
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

alias ports='netstat -tulpn | grep LISTEN'
alias findtxt='grep -IHrnws --exclude=\*.log -s '/' -e'

alias cls='clear'
alias sctl='systemctl'
alias jctl='journalctl'

alias tar-create='tar -cvf'
alias tar-expand='tar -zxvf'

alias du='du -h'
alias sortsize='sort -hr'
alias dus='du -shc * | sortsize'
alias dusa='du -hc --max-depth=1 | sortsize'

alias ts='tailscale'
alias ts-install='curl -fsSL https://tailscale.com/install.sh | sh'

if command -v 'docker-compose' &> /dev/null; then
    alias dc='docker-compose'
else
    alias dc='docker compose'
fi

alias vsucode='sudo code --user-data-dir /root/.config/vscode --no-sandbox'
alias visucode='EDITOR="code --wait" sudoedit'
alias gpu-temp='while sleep 1; do clear; gpustat; done'
alias cpu-temp='s-tui'
alias mine='sudo lolminer --algo ETHASH --pool stratum+ssl://daggerhashimoto.auto.nicehash.com:443 --user=3AcCeSHHwWJRf945iKCbxZ8cjUvy7Tmg3g.Daisy-lol'
alias mine-zel='sudo lolminer --algo ZEL --pers BgoldPoW --pool stratum+tcp://zelhash.auto.nicehash.com:9200 --user=3AcCeSHHwWJRf945iKCbxZ8cjUvy7Tmg3g.Daisy-lol'
alias mount-external='sudo mount -t cifs //192.168.2.1/external /smb/external -o rw,user=azalea,uid=1000,gid=1000,pass='

alias ds-clean="find . -name '.DS_Store' -delete -print"
alias dotclean="find . -name '._*' -delete -print"
alias clean-empty-dir="find . -type d -empty -delete -print"
alias restart-kwin="DISPLAY=:0 setsid kwin_x11 --replace"

alias mkfs.fat32="sudo mkfs.fat -F 32"
alias btrfs-fs-progress="sudo watch -d sudo btrfs fi us"
alias btrfs-balance-progress="sudo watch -d btrfs balance status"

alias catt="echo 🐱"
alias old-update-ssh-keys="curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys"

compress-zst() {
    cores=$(grep -c ^processor /proc/cpuinfo)
    echo "Starting ZSTD compression with $cores cores"
    tar -I 'zstd -T36 -15' --checkpoint=.1024 --totals --totals=SIGUSR1 -c -f "$@"
}
alias tar-kill-progress="watch -n 60 killall tar -SIGUSR1"

# Gradle with auto environment detection
GRADLE="$(which gradle)"
gradle() {
    [[ -f "./gradlew" ]] && ./gradlew "$@" || $GRADLE "$@"
}

# Unix permissions reset (Dangerous! This will make executable files no longer executable)
reset-permissions-dangerous() {
    sudo find . -type d -exec chmod 755 {} \;
    sudo find . -type f -exec chmod 644 {} \;
}

# Mamba (conda replacement)
alias mamba=micromamba
export MAMBA_ROOT_PREFIX="$HOME/.conda"

# Mamba initialize function
mamba-init()
{
    export MAMBA_EXE="$(which micromamba)";
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --prefix "$HOME/micromamba" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        if [ -f "$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh" ]; then
            . "$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh"
        else
            export PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
        fi
    fi
    unset __mamba_setup
}

# Pyenv
if command -v 'pyenv' &> /dev/null; then
    eval "$(pyenv init -)"
    PATH=$(pyenv root)/shims:$PATH
fi

export PATH="$SCR/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Lisp wrapper
lisp() {
    ros run --load $1 --quit
}

test-nf() {
    CUSTOM_DISTRO="$1" ./neofetch test_distro_ascii
}

# Remote adb
adblan() {
    adb connect $1:16523
}
alias adblan-start="adb tcpip 16523"

# Add line if it doesn't exist in a file
addline() {
  grep -qxF "$2" "$1" || echo "$2" >> $1
}

# Silent pushd and popd
spushd () {
    pushd "$@" > /dev/null
}
spopd () {
    popd "$@" > /dev/null
}

# Minecraft coloring
color() {
    tmp="$@"
    tmp="$tmp&r"
    tmp=$(echo "${tmp//&0/\033[0;30m}")
    tmp=$(echo "${tmp//&1/\033[0;34m}")
    tmp=$(echo "${tmp//&2/\033[0;32m}")
    tmp=$(echo "${tmp//&3/\033[0;36m}")
    tmp=$(echo "${tmp//&4/\033[0;31m}")
    tmp=$(echo "${tmp//&5/\033[0;35m}")
    tmp=$(echo "${tmp//&6/\033[0;33m}")
    tmp=$(echo "${tmp//&7/\033[0;37m}")
    tmp=$(echo "${tmp//&8/\033[1;30m}")
    tmp=$(echo "${tmp//&9/\033[1;34m}")
    tmp=$(echo "${tmp//&a/\033[1;32m}")
    tmp=$(echo "${tmp//&b/\033[1;36m}")
    tmp=$(echo "${tmp//&c/\033[1;31m}")
    tmp=$(echo "${tmp//&d/\033[1;35m}")
    tmp=$(echo "${tmp//&e/\033[1;33m}")
    tmp=$(echo "${tmp//&f/\033[1;37m}")
    tmp=$(echo "${tmp//&r/\033[0m}")
    newline=$'\n'
    tmp=$(echo "${tmp//&n/$newline}")
    echo $tmp
}
alias colors="color '&000&111&222&333&444&555&666&777&888&999&aaa&bbb&ccc&ddd&eee&fff'"

# Includes
for f in $SCR/includes/*; do source $f; done

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

# Git identity
git-ida() {
    # Zsh only
    TMP_ARR=("${(@f)$(git-id-list get "$1")}")
    git-id "${TMP_ARR[1]}" "${TMP_ARR[2]}"
}
git-id() {
    export GIT_USER="$1"
    export GIT_EMAIL="$2"
    git-id-prompt
}
git-id-prompt() {
    if [[ -z "$GIT_USER" ]] && [[ -z "$GIT_EMAIL" ]]; then
        prompt-reset
    else
        prompt-set 30 "&cGit ID: $GIT_USER | $GIT_EMAIL "
        prompt-update
    fi
}
git-id-prompt
export GIT_BIN=$(which git)
git() {
    [[ -z "$GIT_USER" ]] && $GIT_BIN "$@" || $GIT_BIN -c "user.name=$GIT_USER" -c "user.email=$GIT_EMAIL" "$@"
}

# Mac hostname
mac-hostname() {
    name="$@"
    sudo scutil --set HostName "$name"
    sudo scutil --set LocalHostName "$name"
    sudo scutil --set ComputerName "$name"
}

# Cut videos - cut <file name> <end time> [start time (default 00:00:00)]
cut() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: cut <file name> <end time (hh:mm:ss)> [start time (00:00:00)]"
        return -1
    fi

    local start="${3:-00:00:00}"
    echo $1
    echo $2
    echo $start
    ffmpeg -i $1 -codec copy -ss $start -t $2 Cut\ $1
}
alias vcomp="$SCR/helpers/video.py"
alias vcompy="ipython -i $SCR/helpers/video.py"

# include if it exists
[ -f $HOME/extra.rc.sh ] && . $HOME/extra.rc.sh
