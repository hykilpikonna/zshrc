function mkcd --description 'Create a directory and cd into it'
    if test (count $argv) -eq 0
        echo 'Usage: mkcd <directory>'
        return 1
    end

    mkdir -p "$argv[1]"; and cd "$argv[1]"
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

# Use the stable SSH agent socket maintained by ~/.ssh/rc inside SSH/tmux sessions.
if test -n "$SSH_TTY"; or test -n "$SSH_CONNECTION"
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
