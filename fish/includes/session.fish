set -g __fishrc_proxy_segment ''
set -g __fishrc_git_id_segment ''

function setproxy --description 'Set common proxy environment variables'
    set -l addr 127.0.0.1
    set -l port 7890
    test (count $argv) -ge 1; and set addr $argv[1]
    test (count $argv) -ge 2; and set port $argv[2]
    set -l full "$addr:$port"

    set -gx https_proxy "http://$full"
    set -gx http_proxy "http://$full"
    set -gx all_proxy "http://$full"
    set -gx HTTPS_PROXY "http://$full"
    set -gx HTTP_PROXY "http://$full"
    set -gx ALL_PROXY "http://$full"
    set -g __fishrc_proxy_segment "proxy $full "

    if has color
        color "&aUsing proxy! $full&r"
    else
        echo "Using proxy! $full"
    end
end

function ssh --description 'Use xterm-256color when connecting from kitty'
    if test "$TERM" = xterm-kitty
        env TERM=xterm-256color command ssh $argv
    else
        command ssh $argv
    end
end

if status is-interactive; and test -z "$TMUX"; and test -n "$SSH_TTY"; and has tmux
    tmux attach-session -t ssh_tmux; or tmux new-session -s ssh_tmux
end

function subtitle --description 'Generate subtitles with auto_subtitle'
    env CUDA_VISIBLE_DEVICES=1 auto_subtitle --srt_only True --model large "$argv[1]"
end

function upload --description 'Upload a file to HyDEV daisy'
    if test (count $argv) -eq 0
        echo 'Usage: upload <file>'
        return 1
    end

    if not set -q UP_PASSWORD; or test -z "$UP_PASSWORD"
        echo 'Error: Password not set, please export UP_PASSWORD=xxx'
        return 1
    end

    set -l file $argv[1]
    set -l server_url 'https://daisy.hydev.org/upload?path=/'
    set -l up_username azalea

    if test -f "$file"
        curl -u "$up_username:$UP_PASSWORD" -F "path=@$file" "$server_url"
    else
        echo 'Error: File not found.'
        return 1
    end
end
