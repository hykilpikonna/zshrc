# 好用的简写
if has xdg-open
    alias open xdg-open
end

alias ll 'ls -l'
alias l ll
alias llg 'll --git --git-repos'
alias lla 'ls -la'
alias grep 'grep --color=auto'
alias rm 'rm -ir'
alias mkdirs 'mkdir -p'

alias ip 'ip -c -h -p'
alias ipa 'ip -br a'

function ports --description 'Show listening ports'
    if has ss
        ss -tulpn
    else
        netstat -tulpn | grep LISTEN
    end
end

function suports --description 'Show listening ports with root privileges when needed'
    if has ss
        __fishrc_as_root ss -tulpn
    else
        __fishrc_as_root netstat -tulpn | grep LISTEN
    end
end

function findtxt --description 'Search for text under /'
    if test (count $argv) -eq 0
        echo 'Usage: findtxt <pattern>'
        return 1
    end

    set -l pattern (string join ' ' -- $argv)
    if has rg
        rg -n --no-messages -- "$pattern" /
    else
        grep -IHrnws -s -e "$pattern" /
    end
end

alias clr reset
alias please sudo

if test "$IS_SANDBOX" = 1
    alias codex 'codex --dangerously-bypass-approvals-and-sandbox'
    alias claude 'claude --dangerously-skip-permissions'
end

alias du 'du -h'

alias ffmpeg 'ffmpeg -hide_banner'
alias ffprobe 'ffprobe -hide_banner'

function ts --description 'Run tailscale with root privileges when needed'
    __fishrc_as_root tailscale $argv
end
alias ts-install 'curl -fsSL https://tailscale.com/install.sh | sh'

alias visucode 'env EDITOR="code --wait" sudoedit'
alias cpu-temp s-tui

function gpu-temp --description 'Watch GPU temperatures with gpustat'
    while sleep 1
        clear
        gpustat
    end
end

function ipv4 --description 'Show public IPv4 from Cloudflare trace'
    curl https://1.0.0.1/cdn-cgi/trace -4 | grep ip
end

function ipv6 --description 'Show public IPv6 from Cloudflare trace'
    curl 'https://[2606:4700:4700::1111]/cdn-cgi/trace' -6 | grep ip
end

function compress-json --description 'Zstd-compress JSON files below the current directory'
    find . -name '*.json' -print0 | parallel --jobs 80% -0 zstd -z -19 -v -f --rm '{}'
end

function dotclean --description 'Remove macOS metadata files below the current directory'
    find . \( -name '.DS_Store' -o -name '._*' \) -delete -print
end

alias clean-empty-dir 'find . -type d -empty -delete -print'

function mkfs.fat32 --description 'Format FAT32 with root privileges when needed'
    __fishrc_as_root mkfs.fat -F 32 $argv
end

# Rsync aliases by 依云, for synching (keep hard links, ACL, atime, xattr, etc)
# Deletes files in destination that are not in source
alias xcp "rsync -aviHAXKhS --one-file-system --partial --info=progress2 --atimes --open-noatime --delete --exclude='*~' --exclude=__pycache__"
alias xcpz 'xcp --compress-choice=zstd --compress-level=3 --checksum-choice=xxh3'
alias xmv 'xcp --remove-source-files'
alias xmvz 'xcpz --remove-source-files'

# Rsync aliases by Azalea, for file transfer (do not keep hard links, ACL, atime, etc.)
# Will not delete files in destination that are not in source
alias rcp "rsync -avihS --partial --info=progress2 --exclude='*~' --exclude=__pycache__"
alias rcpz 'rcp --compress --compress-level=3 --checksum-choice=xxh3'
alias rmv 'rcp --remove-source-files'
alias rmvz 'rcpz --remove-source-files'

alias tmuxs 'tmux new-session -s'
alias tmuxr 'tmux attach-session -t'
alias tmuxl 'tmux list-sessions'

alias catt 'echo 🐱'
alias old-update-ssh-keys 'curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys'
alias colors "color '&000&111&222&333&444&555&666&777&888&999&aaa&bbb&ccc&ddd&eee&fff'"
alias tar-kill-progress 'watch -n 60 killall tar -SIGUSR1'

alias valgrin 'valgrind --leak-check=full --show-leak-kinds=all --leak-resolution=med --track-origins=yes --vgdb=no'

# Automatic sudo aliases.
if test (id -u) -ne 0
    alias sctl 'sudo systemctl'
    alias sctlu 'systemctl --user'
    alias jctl 'sudo journalctl'
    alias jctlu 'journalctl --user-unit'
    alias ufw 'sudo ufw'
    alias nginx 'sudo nginx'
    alias certbot 'sudo certbot'
    alias apt 'sudo apt'
    alias dpkg 'sudo dpkg'
else
    alias sctl systemctl
    alias sctlu 'systemctl --user'
    alias jctl journalctl
    alias jctlu 'journalctl --user-unit'
end
