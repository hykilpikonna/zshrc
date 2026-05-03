set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

function has --description 'Return success if a command exists'
    test (count $argv) -gt 0; and command -sq -- $argv[1]
end

function __fishrc_as_root --description 'Run a command through sudo only when not root'
    if test (id -u) -eq 0
        command $argv
    else
        sudo $argv
    end
end

function __fishrc_prepend_path --description 'Prepend directories to PATH if they exist'
    for dir in $argv
        if test -d "$dir"
            if type -q fish_add_path
                fish_add_path -g -p "$dir"
            else if not contains -- "$dir" $PATH
                set -gx PATH "$dir" $PATH
            end
        end
    end
end

__fishrc_prepend_path \
    "$SCR/bin" \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin"

if test (uname -s) = Linux; and test (uname -m) = x86_64
    __fishrc_prepend_path "$SCR/bin/linux-x64"
end

if not contains -- . $PATH
    set -gx PATH $PATH .
end
