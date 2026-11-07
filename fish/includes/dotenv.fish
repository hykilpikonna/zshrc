# Automatic dotenv sourcing and un-sourcing (direnv-like)

set -q __fishrc_dotenv_auto; or set -g __fishrc_dotenv_auto on
set -g __fishrc_dotenv_active_file ""
set -g __fishrc_dotenv_active_mtime ""
set -g __fishrc_dotenv_added_vars
set -g __fishrc_dotenv_modified_vars
set -g __fishrc_dotenv_modified_vals

function __fishrc_dotenv_log
    if test "$FISHRC_DOTENV_QUIET" = 1 -o "$DOTENV_QUIET" = 1
        return 0
    end
    set -l msg $argv[1]
    if has color
        color "$msg"
    else
        echo "$msg"
    end
end

function __fishrc_dotenv_get_mtime
    set -l target $argv[1]
    if command -sq path
        path mtime "$target" 2>/dev/null; and return 0
    end
    command stat -c %Y "$target" 2>/dev/null; or command stat -f %m "$target" 2>/dev/null; or command date +%s
end

function __fishrc_dotenv_find
    set -l dir "$PWD"
    while test -n "$dir" -a "$dir" != "/"
        if test -f "$dir/.env"
            echo "$dir/.env"
            return 0
        end
        if test "$dir" = "$HOME"
            break
        end
        set dir (string replace -r '/[^/]*$' '' -- "$dir")
        test -z "$dir"; and set dir "/"
    end
    if test "$dir" = "/" -a -f "/.env"
        echo "/.env"
        return 0
    end
    return 1
end

function __fishrc_dotenv_unload --description 'Unload variables set by active .env'
    test -z "$__fishrc_dotenv_active_file"; and return 0

    set -l old_file "$__fishrc_dotenv_active_file"

    for key in $__fishrc_dotenv_added_vars
        set -e $key
    end

    set -l count_mod (count $__fishrc_dotenv_modified_vars)
    if test $count_mod -gt 0
        for i in (seq 1 $count_mod)
            set -l m_key $__fishrc_dotenv_modified_vars[$i]
            set -l m_val $__fishrc_dotenv_modified_vals[$i]
            if test "$m_key" = "PATH"
                set -gx PATH (string split : -- "$m_val")
            else
                set -gx $m_key "$m_val"
            end
        end
    end

    set -g __fishrc_dotenv_active_file ""
    set -g __fishrc_dotenv_active_mtime ""
    set -g __fishrc_dotenv_added_vars
    set -g __fishrc_dotenv_modified_vars
    set -g __fishrc_dotenv_modified_vals

    set -l display_path "$old_file"
    if string match -q "$HOME*" -- "$display_path"
        set display_path "~"(string sub -s (math (string length -- "$HOME") + 1) -- "$display_path")
    end
    __fishrc_dotenv_log "&7[&3dotenv&7] &7Unloaded $display_path&r"
end

function __fishrc_dotenv_load --description 'Load environment variables from .env'
    set -l target_file $argv[1]
    test -f "$target_file"; or return 0

    __fishrc_dotenv_unload

    set -l new_added
    set -l new_mod_vars
    set -l new_mod_vals

    for line in (cat "$target_file")
        set line (string trim -- $line)
        test -z "$line"; and continue
        string match -q "#*" -- $line; and continue
        set line (string replace -r '^export\s+' '' -- $line)
        set -l parts (string split -m 1 "=" -- $line)
        if test (count $parts) -eq 2
            set -l key (string trim -- $parts[1])
            set -l val (string trim -- $parts[2])

            if string match -q -r '^".*"$' -- $val
                set val (string sub -s 2 -l (math (string length -- $val) - 2) -- $val)
            else if string match -q -r "^\'.*\'\$" -- $val
                set val (string sub -s 2 -l (math (string length -- $val) - 2) -- $val)
            else
                set val (string replace -r '\s+#.*$' '' -- $val)
            end

            # Expand if contains $
            if string match -q '*$*' -- $val
                if test "$key" = "PATH"
                    set -l current_path_str (string join : -- $PATH)
                    set val (string replace -a '$PATH' "$current_path_str" -- "$val")
                    set val (string replace -a '${PATH}' "$current_path_str" -- "$val")
                end
                set val (eval "echo $val" 2>/dev/null; or echo "$val")
            end

            if set -q $key
                set -a new_mod_vars $key
                if test "$key" = "PATH"
                    set -a new_mod_vals (string join : -- $PATH)
                else
                    set -a new_mod_vals "$$key"
                end
            else
                set -a new_added $key
            end

            if test "$key" = "PATH"
                set -gx PATH (string split : -- "$val")
            else
                set -gx $key "$val"
            end
        end
    end

    set -g __fishrc_dotenv_active_file "$target_file"
    set -g __fishrc_dotenv_active_mtime (__fishrc_dotenv_get_mtime "$target_file")
    set -g __fishrc_dotenv_added_vars $new_added
    set -g __fishrc_dotenv_modified_vars $new_mod_vars
    set -g __fishrc_dotenv_modified_vals $new_mod_vals

    set -l display_path "$target_file"
    if string match -q "$HOME*" -- "$display_path"
        set display_path "~"(string sub -s (math (string length -- "$HOME") + 1) -- "$display_path")
    end
    __fishrc_dotenv_log "&7[&3dotenv&7] &aLoaded $display_path&r"
end

function __fishrc_dotenv_update --description 'Refresh automatic dotenv state'
    if test "$__fishrc_dotenv_auto" != on
        if test -n "$__fishrc_dotenv_active_file"
            __fishrc_dotenv_unload
        end
        return 0
    end

    set -l found_file (__fishrc_dotenv_find)
    if test -n "$found_file"
        set -l current_mtime (__fishrc_dotenv_get_mtime "$found_file")
        if test "$found_file" != "$__fishrc_dotenv_active_file" -o "$current_mtime" != "$__fishrc_dotenv_active_mtime"
            __fishrc_dotenv_load "$found_file"
        end
    else if test -n "$__fishrc_dotenv_active_file"
        __fishrc_dotenv_unload
    end
end

function __fishrc_dotenv_on_pwd --on-variable PWD --description 'Refresh automatic dotenv after cd'
    __fishrc_dotenv_update
end

function __fishrc_dotenv_on_prompt --on-event fish_prompt --description 'Refresh automatic dotenv before prompt'
    __fishrc_dotenv_update
end

function dotenv-auto --description 'Toggle automatic .env sourcing'
    if test (count $argv) -eq 0
        echo "dotenv-auto $__fishrc_dotenv_auto"
        return 0
    end

    switch "$argv[1]"
        case on
            set -g __fishrc_dotenv_auto on
            set -U __fishrc_dotenv_auto on
            __fishrc_dotenv_update
            if has color
                color "&7[&3dotenv&7] Automatic .env sourcing &aenabled&r."
            else
                echo "[dotenv] Automatic .env sourcing enabled."
            end
        case off
            set -g __fishrc_dotenv_auto off
            set -U __fishrc_dotenv_auto off
            __fishrc_dotenv_unload
            if has color
                color "&7[&3dotenv&7] Automatic .env sourcing &cdisabled&r."
            else
                echo "[dotenv] Automatic .env sourcing disabled."
            end
        case status
            if test "$__fishrc_dotenv_auto" = on
                if test -n "$__fishrc_dotenv_active_file"
                    if has color
                        color "&7[&3dotenv&7] Auto dotenv: &aon&r (active: &b$__fishrc_dotenv_active_file&r)"
                    else
                        echo "[dotenv] Auto dotenv: on (active: $__fishrc_dotenv_active_file)"
                    end
                else
                    if has color
                        color "&7[&3dotenv&7] Auto dotenv: &aon&r (no active .env)"
                    else
                        echo "[dotenv] Auto dotenv: on (no active .env)"
                    end
                end
            else
                if has color
                    color "&7[&3dotenv&7] Auto dotenv: &coff&r"
                else
                    echo "[dotenv] Auto dotenv: off"
                end
            end
        case '*'
            echo 'Usage: dotenv-auto {on|off|status}'
            return 1
    end
end

function dotenv --description 'Dotenv management command'
    if test (count $argv) -eq 0
        dotenv-auto status
        return $status
    end

    switch "$argv[1]"
        case reload
            if test -n "$__fishrc_dotenv_active_file"
                __fishrc_dotenv_load "$__fishrc_dotenv_active_file"
            else
                __fishrc_dotenv_update
            end
        case unload
            __fishrc_dotenv_unload
        case status on off
            dotenv-auto $argv
        case '*'
            echo 'Usage: dotenv {status|reload|unload|on|off}'
            return 1
    end
end

if status is-interactive
    __fishrc_dotenv_update
end
