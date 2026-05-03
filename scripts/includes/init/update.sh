if [[ -n "$ZSHRC_UPDATING" ]]; then
    return
fi

cd "$SCR" || return

prefix="&7[&3zshrc&7]"
remote_ref="${ZSHRC_UPDATE_REF:-origin/master}"

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
        git stash pop >/dev/null || color "$prefix &cUpdated, but saved local changes need manual conflict resolution."
    fi
}

# Check for updates
if git fetch origin --quiet && git rev-parse --verify --quiet "$remote_ref" >/dev/null; then

    # Handle rewritten or force-pushed history. This keeps auto-update working
    # after repository cleanup that removes old large objects.
    if ! git merge-base --is-ancestor HEAD "$remote_ref" 2>/dev/null; then
        color "$prefix &cRepo history changed. Resetting local zshrc to $remote_ref..."

        _zshrc_stash_if_needed
        if git reset --hard "$remote_ref" && git submodule update --init --recursive --depth 1; then
            _zshrc_restore_stash
            ZSHRC_UPDATING=1 . "$SCR/zshrc.sh"
            color "$prefix &aUpdated after history rewrite!"
        else
            color "$prefix &cUpdate failed!"
        fi
    else
        reslog=$(git log HEAD.."$remote_ref" --oneline)
        if [[ "${reslog}" != "" ]] ; then

            # Has updates
            color "$prefix &cYour zshrc is outdated. Automatically updating..."

            # Try to fast-forward without invoking git pull's merge/rebase behavior.
            _zshrc_stash_if_needed
            if git merge --ff-only "$remote_ref" && git submodule update --init --recursive --depth 1; then
                _zshrc_restore_stash
                ZSHRC_UPDATING=1 . "$SCR/zshrc.sh"
                color "$prefix &aUpdated!"
            else
                color "$prefix &cUpdate failed!"
            fi
        fi
    fi
elif [[ -n "$ZSHRC_UPDATE_VERBOSE" ]]; then
    color "$prefix &cUpdate check failed!"
fi

unset -f _zshrc_stash_if_needed _zshrc_restore_stash 2>/dev/null
unset _zshrc_stash_created remote_ref reslog
cd - &> /dev/null
