if has thefuck
    thefuck --alias | source
end

# Reuse the existing zsh updater if zsh is installed. It runs in the background
# and preserves the repository's current update semantics without duplicating it.
if status is-interactive; and has zsh; and not set -q FISHRC_UPDATE_DISABLED
    set -l __fishrc_update_path (string join : "$SCR/bin" $PATH)
    env SCR="$SCR" ZSHRC_UPDATE_ASYNC_CHILD=1 PATH="$__fishrc_update_path" zsh -f "$SCR/includes/init/update.sh" >/dev/null 2>&1 &
end

if test -f "$HOME/extra.rc.fish"
    source "$HOME/extra.rc.fish"
end
