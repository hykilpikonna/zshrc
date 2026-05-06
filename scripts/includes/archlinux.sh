if command -v pacman &> /dev/null; then
    alias upgrade="${ZSHRC_SUDO}pacman -Syu"
    alias install='pacman -Sy'
    alias uninstall='pacman -Rsn'
    alias list-unused='pacman -Qdtq'
fi

if [ -f "/etc/arch-release" ]; then
    export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

    # GPG Init
    alias gpg-init="echo 'hi' | gpg --status-fd=2 -bsau E289FAC0DA92DD2B"
    alias ibus-init="ibus-daemon -drxR"

    # Remove orphan packages
    alias autoremove='yay -c'

    # Free up cache
    clean-cache() {
        has yay && yay -Sc --noconfirm
        has pacman && _zshrc_as_root pacman -Sc --noconfirm
        has pacman && _zshrc_as_root rm -rf /var/cache/pacman
        has paru && rm -rf "$HOME/.cache/paru"
        has yarn && yarn cache clean
        has conda && conda clean -a
        has pip && pip cache remove '*'
    }

    # Command-not-found install prompt
    SCRIPTS_DIR="$(dirname "$(dirname "$0")")"
    source "$SCRIPTS_DIR/../plugins/find-the-command/usr/share/doc/find-the-command/ftc.zsh"
fi
