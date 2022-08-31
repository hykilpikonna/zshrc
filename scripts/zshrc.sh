# ZSH History
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

# 好用的简写w
alias ls='ls -h --color=auto'
alias ll='ls -l'
alias lla='ls -la'
alias grep='grep --color'
alias rm='rm -ir'

alias ports='netstat -tulpn | grep LISTEN'
alias findtxt='grep -IHrnws --exclude=\*.log -s '/' -e'

alias cls='clear'
alias sctl='systemctl'
alias jctl='journalctl'

alias tar-create='tar -cvf'
alias tar-expand='tar -zxvf'

alias du='du -h'
alias df='df -h'
alias dirusage='du -shc *'
alias dirusagea='du -hc --max-depth=1'
alias fileusage='du -ahc --max-depth=1'
alias sortsize='sort -hr'
alias duss='dirusage | sortsize'
alias duass='dirusagea | sortsize'
alias fuss='fileusage | sortsize'

alias dc='docker-compose'

alias vsucode='sudo code --user-data-dir /root/.config/vscode --no-sandbox'
alias gpu-temp='while sleep 1; do clear; gpustat; done'
alias cpu-temp='s-tui'
alias mine='sudo lolminer --algo ETHASH --pool stratum+ssl://daggerhashimoto.auto.nicehash.com:443 --user=3AcCeSHHwWJRf945iKCbxZ8cjUvy7Tmg3g.Daisy-lol'
alias mine-zel='sudo lolminer --algo ZEL --pers BgoldPoW --pool stratum+tcp://zelhash.auto.nicehash.com:9200 --user=3AcCeSHHwWJRf945iKCbxZ8cjUvy7Tmg3g.Daisy-lol'
alias mount-external='sudo mount -t cifs //192.168.2.1/external /smb/external -o rw,user=azalea,uid=1000,gid=1000,pass='

alias ds-clean="sudo find ./ -name \".DS_Store\" -depth -exec rm {} \;"
alias clean-empty-dir="find . -type d -empty -delete -print"
alias compress-zst="tar -I 'zstd -T36 -19' --checkpoint=.1024 --totals -c -f"

alias catt="echo 🐱"
alias update-ssh-keys="curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys"

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
