if [[ -z "$ZSHRC_UPDATE_ASYNC_CHILD" && -z "$ZSHRC_UPDATE_SYNC" ]]; then
    _zshrc_start_async_update() {
        if (( $+functions[add-zsh-hook] )); then
            add-zsh-hook -d precmd _zshrc_start_async_update 2>/dev/null
        fi
        (
            export ZSHRC_UPDATE_ASYNC_CHILD=1
            export SCR
            export PATH="$SCR/bin:$PATH"
            exec zsh -f "$SCR/includes/init/update.sh"
        ) &!
        unset -f _zshrc_start_async_update 2>/dev/null
    }

    if [[ -o interactive ]]; then
        autoload -Uz add-zsh-hook
        add-zsh-hook -d precmd _zshrc_start_async_update 2>/dev/null
        add-zsh-hook precmd _zshrc_start_async_update
    else
        _zshrc_start_async_update
    fi

    return 0 2>/dev/null || exit 0
fi

old_pwd="$PWD"
repo_root="$(git -C "$SCR" rev-parse --show-toplevel 2>/dev/null)"
[[ -n "$repo_root" ]] || repo_root="${SCR:h}"
cd "$repo_root" || { cd "$old_pwd" 2>/dev/null; return 0 2>/dev/null || exit 0; }
export PATH="$SCR/bin:$PATH"

prefix="&7[&3zshrc&7]"
remote_ref="${ZSHRC_UPDATE_REF:-origin/master}"
lock_dir="$repo_root/.git/zshrc-update.lock"
notify_file="$repo_root/.git/zshrc-update-notification"
_zshrc_update_default_submodules=(
    plugins/zsh-autosuggestions
    plugins/nanorc
    plugins/find-the-command
)
_zshrc_update_rime_submodules=(
    config-sync/.config/ibus/rime/_submodules/rime-ice
    config-sync/.config/ibus/rime/_submodules/rime-kagiroi
)

_zshrc_update_lock_mtime() {
    command stat -c %Y "$lock_dir" 2>/dev/null || command stat -f %m "$lock_dir" 2>/dev/null
}

_zshrc_update_lock_stale() {
    [[ -d "$lock_dir" ]] || return 1

    local now mtime stale_seconds
    stale_seconds="${ZSHRC_UPDATE_LOCK_STALE_SECONDS:-1800}"
    now="$(date +%s 2>/dev/null)" || return 1
    mtime="$(_zshrc_update_lock_mtime)" || return 1

    [[ "$now" == <-> && "$mtime" == <-> && "$stale_seconds" == <-> ]] || return 1
    (( now - mtime > stale_seconds ))
}

_zshrc_update_make_lock() {
    if mkdir "$lock_dir" 2>/dev/null; then
        print -r -- "$$" >| "$lock_dir/owner" 2>/dev/null || true
        return 0
    fi

    if _zshrc_update_lock_stale; then
        rm -rf "$lock_dir" 2>/dev/null || return 1
        if mkdir "$lock_dir" 2>/dev/null; then
            print -r -- "$$" >| "$lock_dir/owner" 2>/dev/null || true
            return 0
        fi
    fi

    return 1
}

if ! _zshrc_update_make_lock; then
    cd "$old_pwd" 2>/dev/null
    return 0 2>/dev/null || exit 0
fi
_zshrc_update_cleanup() {
    rm -rf "$lock_dir" 2>/dev/null
    cd "$old_pwd" 2>/dev/null
}
trap _zshrc_update_cleanup EXIT INT TERM

_zshrc_write_update_notification() {
    printf '%s\n' "$1" >| "$notify_file" 2>/dev/null || true
}

_zshrc_update_enabled() {
    case "$1" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

_zshrc_update_rime_submodules_enabled() {
    if [[ -n "$ZSHRC_UPDATE_RIME_SUBMODULES" ]]; then
        _zshrc_update_enabled "$ZSHRC_UPDATE_RIME_SUBMODULES"
        return
    fi

    if [[ -n "$ZSHRC_INSTALL_RIME_SUBMODULES" ]]; then
        _zshrc_update_enabled "$ZSHRC_INSTALL_RIME_SUBMODULES"
        return
    fi

    local path
    for path in "${_zshrc_update_rime_submodules[@]}"; do
        [[ -e "$repo_root/$path/.git" ]] && return 0
    done

    return 1
}

_zshrc_update_submodules() {
    git submodule update --init --recursive --depth 1 -- "${_zshrc_update_default_submodules[@]}" || return 1

    if _zshrc_update_rime_submodules_enabled; then
        git submodule update --init --recursive --depth 1 -- "${_zshrc_update_rime_submodules[@]}" || return 1
    fi
}

_zshrc_stash_created=0
_zshrc_stash_if_needed() {
    if ! git diff --quiet --ignore-submodules -- \
        || ! git diff --cached --quiet --ignore-submodules -- \
        || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        if git stash push -u -m "zshrc auto-update before applying $remote_ref" >/dev/null; then
            _zshrc_stash_created=1
        fi
    fi
}

_zshrc_restore_stash() {
    if [[ "$_zshrc_stash_created" == "1" ]]; then
        if git stash pop >/dev/null; then
            return 0
        fi
        color "$prefix &cUpdated, but saved local changes need manual conflict resolution."
        _zshrc_write_update_notification "Updated, but saved local changes need manual conflict resolution."
        return 1
    fi
    return 0
}

_zshrc_trim_git_history() {
    [[ -z "$ZSHRC_UPDATE_KEEP_HISTORY" ]] || return 0

    # Keep auto-updated checkouts shallow so old binary blobs disappear after
    # repository cleanup. Failures here should never block shell startup.
    git fetch --quiet --depth 1 --prune origin >/dev/null 2>&1 || true
    git reflog expire --expire=now --expire-unreachable=now --all >/dev/null 2>&1 || true
    git gc --prune=now >/dev/null 2>&1 || true
    git submodule foreach --recursive '
        git fetch --quiet --depth 1 --prune origin >/dev/null 2>&1 || :
        git reflog expire --expire=now --expire-unreachable=now --all >/dev/null 2>&1 || :
        git gc --prune=now >/dev/null 2>&1 || :
    ' >/dev/null 2>&1 || true
}

# Check for updates
if git fetch origin --quiet && git rev-parse --verify --quiet "$remote_ref" >/dev/null; then
    _zshrc_update_ok=1

    # Handle rewritten or force-pushed history. This keeps auto-update working
    # after repository cleanup that removes old large objects.
    if ! git merge-base --is-ancestor HEAD "$remote_ref" 2>/dev/null; then
        color "$prefix &cRepo history changed. Resetting local zshrc to $remote_ref..."

        _zshrc_stash_if_needed
        if git reset --hard "$remote_ref" && _zshrc_update_submodules; then
            if _zshrc_restore_stash; then
                _zshrc_write_update_notification "Updated after history rewrite. Open a new shell to load the latest rc."
                color "$prefix &aUpdated after history rewrite. Open a new shell to load the latest rc."
            else
                _zshrc_update_ok=0
            fi
        else
            _zshrc_update_ok=0
            color "$prefix &cUpdate failed!"
        fi
    else
        reslog=$(git log HEAD.."$remote_ref" --oneline)
        if [[ "${reslog}" != "" ]] ; then

            # Has updates
            color "$prefix &cYour zshrc is outdated. Automatically updating..."

            # Try to fast-forward without invoking git pull's merge/rebase behavior.
            _zshrc_stash_if_needed
            if git merge --ff-only "$remote_ref" && _zshrc_update_submodules; then
                if _zshrc_restore_stash; then
                    _zshrc_write_update_notification "Updated. Open a new shell to load the latest rc."
                    color "$prefix &aUpdated. Open a new shell to load the latest rc."
                else
                    _zshrc_update_ok=0
                fi
            else
                _zshrc_update_ok=0
                color "$prefix &cUpdate failed!"
            fi
        fi
    fi

    if [[ "$_zshrc_update_ok" == "1" ]]; then
        _zshrc_trim_git_history
    fi
elif [[ -n "$ZSHRC_UPDATE_VERBOSE" ]]; then
    color "$prefix &cUpdate check failed!"
fi

unset -f _zshrc_update_lock_mtime _zshrc_update_lock_stale _zshrc_update_make_lock 2>/dev/null
unset -f _zshrc_update_enabled _zshrc_update_rime_submodules_enabled _zshrc_update_submodules 2>/dev/null
unset -f _zshrc_stash_if_needed _zshrc_restore_stash _zshrc_trim_git_history _zshrc_write_update_notification 2>/dev/null
_zshrc_update_cleanup
trap - EXIT INT TERM
unset -f _zshrc_update_cleanup 2>/dev/null
unset _zshrc_stash_created _zshrc_update_ok _zshrc_update_default_submodules _zshrc_update_rime_submodules remote_ref reslog lock_dir notify_file repo_root old_pwd
