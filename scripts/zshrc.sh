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

alias ds-clean="sudo find ./ -name \".DS_Store\" -depth -exec rm {} \;"

# Mac-only commands
if [[ $OSTYPE == 'darwin'* ]]; then
    alias ports="netstat -ap tcp | grep -i \"listen\""
    alias trash="rmtrash"
    alias checkrain="/Applications/checkra1n.app/Contents/MacOS/checkra1n"
    alias obs="open -n -a OBS.app"
fi

# Lisp wrapper
lisp() {
    ros run --load $1 --quit
}

# Remote adb
adblan() {
    adb connect $1:16523
}
alias adblan-start="adb tcpip 16523"

# Minecraft coloring
color() {
    tmp="$@"
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

# Set proxy
setproxy() {
    addr=${1:-127.0.0.1}
    port=${2:-7890}
    full="$addr:$port"
    export https_proxy="http://$full"
    export http_proxy="http://$full"
    export all_proxy="socks5://$full"
    color "&aUsing proxy! $full&r"
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

# Bash PS1 (Not updated)
PS1='\n\[\e[m\][\[\e[35m\]\D{%y-%m-%d} \t\[\e[m\]] [\[\e[34m\]\h\[\e[m\]] [\[\e[33m\]\u\[\e[m\]] \[\e[37m\]\w \n\[\e[m\]$ '

# ZSH
DEFAULT_USER="hykilpikonna"
PROMPT=$(color "&n&5%D{%a %m-%d %H:%M}&r | &1%m&r |")
# Shows a cat if I'm hykilpikonna
if [[ "$USER" != "$DEFAULT_USER" ]]; then
    PROMPT=$(color "$PROMPT &e%n&r")
else
    PROMPT=$(color "$PROMPT 🐱")
fi
PROMPT=$(color "$PROMPT &r%~&n> ")

# Mac-only paths
if [[ $OSTYPE == 'darwin'* ]]; then
    # Java
    export JDK8="/usr/local/opt/openjdk@8/libexec/openjdk.jdk/Contents/Home"
    export JDK11="/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
    export JDK16="/usr/local/opt/openjdk@16/libexec/openjdk.jdk/Contents/Home"
    alias java8="${JDK8}/bin/java"
    alias java11="${JDK11}/bin/java"
    alias java16="${JDK16}/bin/java"
    export JAVA_HOME=${JDK11}
    export PATH="${JDK11}/bin:$PATH"
fi

# Includes
. $SCR/includes/*

# include if it exists
[ -f $HOME/extra.rc.sh ] && . $HOME/extra.rc.sh
