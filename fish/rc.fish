# Fish rc for this repository.
# Source this from ~/.config/fish/config.fish:
#   source /path/to/zshrc/fish/rc.fish
#
# Fish already provides shared history, autosuggestions, syntax highlighting,
# completions, and good command-line editing, so the zsh-only equivalents are
# intentionally not ported here. macOS-only setup is also omitted.

set -l __fishrc_dir (dirname (status --current-filename))
set -gx FISHRC_DIR "$__fishrc_dir"
set -gx ZSHRC_ROOT (path resolve "$__fishrc_dir/..")
set -q SCR; or set -gx SCR "$ZSHRC_ROOT/scripts"
set -q BASEDIR; or set -gx BASEDIR "$ZSHRC_ROOT"

for include in \
    core \
    aliases \
    functions \
    platform \
    config-sync \
    docker-nix \
    modern \
    session \
    git \
    prompt \
    final
    source "$FISHRC_DIR/includes/$include.fish"
end
