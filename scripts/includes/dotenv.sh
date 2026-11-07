# Automatic dotenv sourcing and un-sourcing (direnv-like)

typeset -g _ZSHRC_DOTENV_ACTIVE_FILE=""
typeset -g _ZSHRC_DOTENV_ACTIVE_MTIME=""
typeset -gA _ZSHRC_DOTENV_MODIFIED_VARS
typeset -ga _ZSHRC_DOTENV_ADDED_VARS
typeset -g _ZSHRC_DOTENV_AUTO="${ZSHRC_DOTENV_AUTO:-on}"

zmodload -F zsh/stat b:zstat 2>/dev/null

_zshrc_dotenv_log() {
    if [[ "${ZSHRC_DOTENV_QUIET:-0}" == "1" || "${DOTENV_QUIET:-0}" == "1" ]]; then
        return 0
    fi
    local msg="$1"
    if command -v color >/dev/null 2>&1; then
        color "$msg"
    else
        echo "$msg"
    fi
}

_zshrc_dotenv_get_mtime() {
    if (( $+builtins[zstat] )); then
        zstat +mtime "$1" 2>/dev/null && return 0
    fi
    stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || date +%s
}

_zshrc_dotenv_find() {
    local dir="$PWD"
    while [[ -n "$dir" && "$dir" != "/" ]]; do
        if [[ -f "$dir/.env" ]]; then
            echo "$dir/.env"
            return 0
        fi
        if [[ "$dir" == "$HOME" ]]; then
            break
        fi
        dir="${dir:h}"
    done
    if [[ "$dir" == "/" && -f "/.env" ]]; then
        echo "/.env"
        return 0
    fi
    return 1
}

_zshrc_dotenv_unload() {
    [[ -z "$_ZSHRC_DOTENV_ACTIVE_FILE" ]] && return 0

    local old_file="$_ZSHRC_DOTENV_ACTIVE_FILE"

    # Restore modified variables
    for k in "${(@k)_ZSHRC_DOTENV_MODIFIED_VARS}"; do
        export "$k"="${_ZSHRC_DOTENV_MODIFIED_VARS[$k]}"
    done

    # Unset newly added variables
    for k in "${_ZSHRC_DOTENV_ADDED_VARS[@]}"; do
        unset "$k"
    done

    _ZSHRC_DOTENV_ACTIVE_FILE=""
    _ZSHRC_DOTENV_ACTIVE_MTIME=""
    _ZSHRC_DOTENV_MODIFIED_VARS=()
    _ZSHRC_DOTENV_ADDED_VARS=()

    local display_path="$old_file"
    [[ "$display_path" == "$HOME"* ]] && display_path="~${display_path#$HOME}"
    _zshrc_dotenv_log "&7[&3dotenv&7] &7Unloaded $display_path&r"
}

_zshrc_dotenv_load() {
    local target_file="$1"
    [[ -f "$target_file" ]] || return 0

    _zshrc_dotenv_unload

    typeset -A before_vars
    for k in ${(k)parameters[(R)*export*]}; do
        before_vars[$k]="${(P)k}"
    done

    () {
        setopt LOCAL_OPTIONS NO_NOMATCH NO_BAD_PATTERN NO_EQUALS INTERACTIVE_COMMENTS
        set -a
        source "$target_file" 2>/dev/null
        set +a
    }

    typeset -a added_vars
    typeset -A modified_vars
    for k in ${(k)parameters[(R)*export*]}; do
        if (( ! ${+before_vars[$k]} )); then
            added_vars+=("$k")
        elif [[ "$before_vars[$k]" != "${(P)k}" ]]; then
            modified_vars[$k]="$before_vars[$k]"
        fi
    done

    _ZSHRC_DOTENV_ACTIVE_FILE="$target_file"
    _ZSHRC_DOTENV_ACTIVE_MTIME="$(_zshrc_dotenv_get_mtime "$target_file")"
    _ZSHRC_DOTENV_ADDED_VARS=("${added_vars[@]}")
    _ZSHRC_DOTENV_MODIFIED_VARS=("${(@kv)modified_vars}")

    local display_path="$target_file"
    [[ "$display_path" == "$HOME"* ]] && display_path="~${display_path#$HOME}"
    _zshrc_dotenv_log "&7[&3dotenv&7] &aLoaded $display_path&r"
}

_zshrc_dotenv_update() {
    if [[ "$_ZSHRC_DOTENV_AUTO" != "on" ]]; then
        if [[ -n "$_ZSHRC_DOTENV_ACTIVE_FILE" ]]; then
            _zshrc_dotenv_unload
        fi
        return 0
    fi

    local found_file
    found_file="$(_zshrc_dotenv_find)"

    if [[ -n "$found_file" ]]; then
        local current_mtime
        current_mtime="$(_zshrc_dotenv_get_mtime "$found_file")"
        if [[ "$found_file" != "$_ZSHRC_DOTENV_ACTIVE_FILE" || "$current_mtime" != "$_ZSHRC_DOTENV_ACTIVE_MTIME" ]]; then
            _zshrc_dotenv_load "$found_file"
        fi
    elif [[ -n "$_ZSHRC_DOTENV_ACTIVE_FILE" ]]; then
        _zshrc_dotenv_unload
    fi
}

dotenv-auto() {
    case "${1:-status}" in
        on)
            _ZSHRC_DOTENV_AUTO="on"
            export ZSHRC_DOTENV_AUTO="on"
            _zshrc_dotenv_update
            if command -v color >/dev/null 2>&1; then
                color "&7[&3dotenv&7] Automatic .env sourcing &aenabled&r."
            else
                echo "[dotenv] Automatic .env sourcing enabled."
            fi
            ;;
        off)
            _ZSHRC_DOTENV_AUTO="off"
            export ZSHRC_DOTENV_AUTO="off"
            _zshrc_dotenv_unload
            if command -v color >/dev/null 2>&1; then
                color "&7[&3dotenv&7] Automatic .env sourcing &cdisabled&r."
            else
                echo "[dotenv] Automatic .env sourcing disabled."
            fi
            ;;
        status)
            if [[ "$_ZSHRC_DOTENV_AUTO" == "on" ]]; then
                if [[ -n "$_ZSHRC_DOTENV_ACTIVE_FILE" ]]; then
                    if command -v color >/dev/null 2>&1; then
                        color "&7[&3dotenv&7] Auto dotenv: &aon&r (active: &b$_ZSHRC_DOTENV_ACTIVE_FILE&r)"
                    else
                        echo "[dotenv] Auto dotenv: on (active: $_ZSHRC_DOTENV_ACTIVE_FILE)"
                    fi
                else
                    if command -v color >/dev/null 2>&1; then
                        color "&7[&3dotenv&7] Auto dotenv: &aon&r (no active .env)"
                    else
                        echo "[dotenv] Auto dotenv: on (no active .env)"
                    fi
                fi
            else
                if command -v color >/dev/null 2>&1; then
                    color "&7[&3dotenv&7] Auto dotenv: &coff&r"
                else
                    echo "[dotenv] Auto dotenv: off"
                fi
            fi
            ;;
        *)
            echo "Usage: dotenv-auto {on|off|status}"
            return 1
            ;;
    esac
}

dotenv() {
    case "${1:-status}" in
        reload)
            if [[ -n "$_ZSHRC_DOTENV_ACTIVE_FILE" ]]; then
                local f="$_ZSHRC_DOTENV_ACTIVE_FILE"
                _zshrc_dotenv_load "$f"
            else
                _zshrc_dotenv_update
            fi
            ;;
        unload)
            _zshrc_dotenv_unload
            ;;
        status|on|off)
            dotenv-auto "$@"
            ;;
        *)
            echo "Usage: dotenv {status|reload|unload|on|off}"
            return 1
            ;;
    esac
}

if [[ -o interactive ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook -d chpwd _zshrc_dotenv_update 2>/dev/null
    add-zsh-hook chpwd _zshrc_dotenv_update
    add-zsh-hook -d precmd _zshrc_dotenv_update 2>/dev/null
    add-zsh-hook precmd _zshrc_dotenv_update
    _zshrc_dotenv_update
fi
