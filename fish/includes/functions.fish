function mkcd --description 'Create a directory and cd into it'
    if test (count $argv) -eq 0
        echo 'Usage: mkcd <directory>'
        return 1
    end

    mkdir -p "$argv[1]"; and cd "$argv[1]"
end

function __fishrc_z_datafile --description 'Print the z database path'
    if set -q ZSHZ_DATA; and test -n "$ZSHZ_DATA"
        printf '%s\n' "$ZSHZ_DATA"
    else if set -q _Z_DATA; and test -n "$_Z_DATA"
        printf '%s\n' "$_Z_DATA"
    else
        printf '%s\n' "$HOME/.z"
    end
end

function __fishrc_z_unescape_path --description 'Unescape paths written by zsh-z'
    string replace -a '\\' '' -- "$argv[1]"
end

function __fishrc_z_add --description 'Record the current directory in the z database'
    status is-interactive; or return 0
    test "$PWD" != "$HOME"; or return 0
    test -d "$PWD"; or return 0

    if has zoxide
        zoxide add "$PWD" >/dev/null 2>&1
    end

    set -l datafile (__fishrc_z_datafile)
    test -d "$datafile"; and return 0

    set -l now (date +%s)
    set -l tmp "$datafile."(random)
    set -l found 0
    set -l total 0

    if test -f "$datafile"
        while read -l line
            set -l fields (string split -m2 '|' -- "$line")
            test (count $fields) -eq 3; or continue

            set -l path (__fishrc_z_unescape_path "$fields[1]")
            set -l rank "$fields[2]"
            set -l time "$fields[3]"
            string match -rq '^[0-9]+([.][0-9]+)?$' -- "$rank"; or continue
            string match -rq '^[0-9]+$' -- "$time"; or continue
            test -d "$path"; or continue

            if test "$path" = "$PWD"
                set rank (math "$rank + 1")
                set time "$now"
                set found 1
            end

            set total (math "$total + $rank")
            printf '%s|%s|%s\n' "$path" "$rank" "$time" >>"$tmp"; or begin
                rm -f "$tmp"
                return 1
            end
        end <"$datafile"
    end

    if test "$found" = 0
        printf '%s|1|%s\n' "$PWD" "$now" >>"$tmp"; or begin
            rm -f "$tmp"
            return 1
        end
        set total (math "$total + 1")
    end

    if test (math "floor($total)") -gt 9000
        set -l aged "$tmp.aged"
        while read -l line
            set -l fields (string split -m2 '|' -- "$line")
            test (count $fields) -eq 3; or continue
            set -l rank (math "$fields[2] * 0.99")
            test (math "floor($rank)") -ge 1; or continue
            printf '%s|%s|%s\n' "$fields[1]" "$rank" "$fields[3]" >>"$aged"; or begin
                rm -f "$tmp" "$aged"
                return 1
            end
        end <"$tmp"
        mv -f "$aged" "$tmp"
    end

    mv -f "$tmp" "$datafile"
end

function __fishrc_z_on_prompt --on-event fish_prompt --description 'Track directories for z'
    __fishrc_z_add >/dev/null 2>&1
end

function z --description 'Jump to a frecent directory'
    set -l list 0
    set -l echo_only 0
    set -l remove 0
    set -l current_only 0
    set -l method frecency
    set -l terms

    for arg in $argv
        switch "$arg"
            case -l --list
                set list 1
            case -e --echo
                set echo_only 1
            case -x --remove
                set remove 1
            case -c --current
                set current_only 1
            case -r --rank
                set method rank
            case -t --recent
                set method time
            case -h --help
                echo 'Usage: z [-l|-e|-x|-c|-r|-t] [pattern ...]'
                return 0
            case '--'
            case '-*'
            echo "z: unknown option $arg" >&2
            return 1
        case '*'
            set terms $terms "$arg"
        end
    end

    if has zoxide; and test "$remove" = 0; and test "$current_only" = 0; and test "$method" = frecency
        if test "$list" = 1; or test (count $argv) -eq 0
            zoxide query -l -- $terms
            return $status
        end

        set -l match (zoxide query -- $terms); or return $status
        if test "$echo_only" = 1
            printf '%s\n' "$match"
        else
            cd "$match"
        end
        return $status
    end

    set -l datafile (__fishrc_z_datafile)
    if test "$remove" = 1
        set -l target "$PWD"
        test (count $terms) -gt 0; and set target "$terms[1]"
        set target (path resolve "$target" 2>/dev/null); or return 1
        test -f "$datafile"; or return 1
        set -l tmp "$datafile."(random)
        while read -l line
            set -l fields (string split -m2 '|' -- "$line")
            test (count $fields) -eq 3; or continue
            set -l path (__fishrc_z_unescape_path "$fields[1]")
            test "$path" = "$target"; and continue
            printf '%s\n' "$line" >>"$tmp"
        end <"$datafile"
        mv -f "$tmp" "$datafile"
        return 0
    end

    test -f "$datafile"; or return 1

    set -l now (date +%s)
    set -l rows

    while read -l line
        set -l fields (string split -m2 '|' -- "$line")
        test (count $fields) -eq 3; or continue

        set -l path (__fishrc_z_unescape_path "$fields[1]")
        set -l rank "$fields[2]"
        set -l time "$fields[3]"
        string match -rq '^[0-9]+([.][0-9]+)?$' -- "$rank"; or continue
        string match -rq '^[0-9]+$' -- "$time"; or continue
        test -d "$path"; or continue

        if test "$current_only" = 1
            string match -q -- "$PWD/*" "$path"; or test "$path" = "$PWD"; or continue
        end

        set -l haystack (string lower -- "$path")
        set -l matched 1
        for term in $terms
            if not string match -q -- "*"(string lower -- "$term")"*" "$haystack"
                set matched 0
                break
            end
        end
        test "$matched" = 1; or continue

        switch "$method"
            case rank
                set score "$rank"
            case time
                set score "$time"
            case frecency
                set -l dx (math "max(0, $now - $time)")
                set score (math "10000 * $rank * (3.75 / ((0.0001 * $dx + 1) + 0.25))")
        end

        set rows $rows (printf '%s\t%s' "$score" "$path")
    end <"$datafile"

    if test "$list" = 1; or test (count $argv) -eq 0
        for row in $rows
            printf '%s\n' "$row"
        end | sort -n
        return 0
    end

    set -l sorted_rows
    for row in $rows
        set sorted_rows $sorted_rows (printf '%s\n' "$row")
    end
    set sorted_rows (printf '%s\n' $sorted_rows | sort -n)
    set -l best_row "$sorted_rows[-1]"
    set -l best_path (string split -m1 \t -- "$best_row")[2]
    test -n "$best_path"; or return 1

    if test "$echo_only" = 1
        printf '%s\n' "$best_path"
    else
        cd "$best_path"
    end
end

function set-java --description 'Set JAVA_HOME and PATH to an installed JDK version'
    if test (count $argv) -eq 0
        echo 'Usage: set-java <version>'
        return 1
    end

    set -l java_home
    if test -d /usr/lib/jvm
        set java_home (find /usr/lib/jvm -maxdepth 1 -type d -name "*$argv[1]*" -name '*jdk*' | head -n 1)
    end

    if test -z "$java_home"
        echo "Error: Java version $argv[1] not found in /usr/lib/jvm"
        return 1
    end

    set -gx JAVA_HOME "$java_home"
    __fishrc_prepend_path "$JAVA_HOME/bin"
end

function upload-daisy --description 'Upload a file to daisy-ddns'
    set -l file (string join ' ' -- $argv)
    curl -u azalea -F "path=@$file" 'https://daisy-ddns.hydev.org/upload?path=/'
end

function ttmp --description 'Go to /tmp/tmp'
    mkdir -p /tmp/tmp; and cd /tmp/tmp
end

if has micro
    set -gx EDITOR micro
else if has nano
    set -gx EDITOR nano
end

# Use the Windows OpenSSH agent from WSL through npiperelay.
set -l __fishrc_wsl_ssh_auth_sock
if test -x "$SCR/bin/wsl-ssh-agent"
    set __fishrc_wsl_ssh_auth_sock ("$SCR/bin/wsl-ssh-agent" 2>/dev/null)
end
if test -n "$__fishrc_wsl_ssh_auth_sock"
    set -gx SSH_AUTH_SOCK "$__fishrc_wsl_ssh_auth_sock"

# Use the stable SSH agent socket maintained by ~/.ssh/rc inside SSH/tmux sessions.
else if test -n "$SSH_TTY"; or test -n "$SSH_CONNECTION"
    if test -n "$SSH_AUTH_SOCK"; and test "$SSH_AUTH_SOCK" != "$HOME/.ssh/current_agent.sock"; and test -S "$SSH_AUTH_SOCK"
        mkdir -p "$HOME/.ssh"
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/current_agent.sock"
    end

    if test -S "$HOME/.ssh/current_agent.sock"
        set -gx SSH_AUTH_SOCK "$HOME/.ssh/current_agent.sock"
    end
end

if not set -q GRADLE; and has gradle
    set -gx GRADLE (command -s gradle)
end

function gradle --description 'Use ./gradlew when present, otherwise system gradle'
    if test -f ./gradlew
        ./gradlew $argv
    else if set -q GRADLE; and test -n "$GRADLE"
        $GRADLE $argv
    else
        echo 'Neither gradle nor ./gradlew is found, please install it and restart fish.'
        return 1
    end
end

function 7z --description 'Block the dangerous 7z d command'
    if test (count $argv) -gt 0; and test "$argv[1]" = d
        echo "7z d is blocked. It does not stand for decompress, it stands for delete."
    else
        command 7z $argv
    end
end

function reset-permissions-dangerous --description 'Reset file and directory permissions below the current directory'
    __fishrc_as_root find . -type d -exec chmod 755 '{}' ';'
    __fishrc_as_root find . -type f -exec chmod 644 '{}' ';'
end

function lisp --description 'Run a lisp file through roswell'
    ros run --load "$argv[1]" --quit
end

function adblan --description 'Connect adb over LAN on port 16523'
    adb connect "$argv[1]:16523"
end
alias adblan-start 'adb tcpip 16523'

function addline --description 'Add a line to a file if it does not already exist'
    if test (count $argv) -lt 2
        echo 'Usage: addline <file> <line>'
        return 1
    end

    grep -qxF "$argv[2]" "$argv[1]"; or echo "$argv[2]" >>"$argv[1]"
end

function spushd --description 'Silent pushd'
    pushd $argv >/dev/null; or return 1
end

function spopd --description 'Silent popd'
    popd $argv >/dev/null; or return 1
end

function modern-replace --description 'Alias a command to a modern replacement when installed'
    set -l orig_cmd $argv[1]
    set -l new_cmd $argv[2]
    set -l orig_cmd_with_args $argv[3]
    set -l new_cmd_with_args $argv[4]

    test -n "$orig_cmd_with_args"; or set orig_cmd_with_args $orig_cmd
    test -n "$new_cmd_with_args"; or set new_cmd_with_args $new_cmd

    if has "$new_cmd"
        alias "$orig_cmd" "$new_cmd_with_args"
    else
        alias "$orig_cmd" "$orig_cmd_with_args"
    end
end
