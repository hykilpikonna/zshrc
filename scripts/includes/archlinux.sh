if command -v pacman &> /dev/null; then
    alias upgrade='sudo pacman -Syu'
    alias install='pacman -Sy'
    alias uninstall='pacman -Rsn'
    alias list-unused='pacman -Qdtq'
fi

if [ -f "/etc/arch-release" ]; then
    # Java paths
    export JDK8="/usr/lib/jvm/java-8-openjdk/"
    export JDK11="/usr/lib/jvm/java-11-openjdk/"
    export JDK17="/usr/lib/jvm/java-17-openjdk/"
    export JDK18="/usr/lib/jvm/java-18-j9/"
    export JDK19="/usr/lib/jvm/java-19-openjdk/"
    alias java8="${JDK8}/bin/java"
    alias java11="${JDK11}/bin/java"
    alias java17="${JDK17}/bin/java"
    alias java18="${JDK18}/bin/java"
    alias java19="${JDK19}/bin/java"
    export JAVA_HOME=${JDK17}
    export PATH="${JDK17}/bin:$PATH"

    export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

    # GPG Init
    alias gpg-init="echo 'hi' | gpg --status-fd=2 -bsau E289FAC0DA92DD2B"
    alias ibus-init="ibus-daemon -drxR"

    # Remove orphan packages
    alias autoremove='yay -c'

    # Free up cache
    clean-cache() {
        has yay && yay -Sc --noconfirm
        has pacman && sudo pacman -Sc --noconfirm
        has pacman && rm -rf /var/cache/pacman
        has paru && rm -rf "$HOME/.cache/paru"
        has yarn && yarn cache clean
        has conda && conda clean -a
        has pip && pip cache remove '*'
    }

    # Command-not-found install prompt
    SCRIPTS_DIR="$(dirname "$(dirname "$0")")"
    source "$SCRIPTS_DIR/../plugins/find-the-command/usr/share/doc/find-the-command/ftc.zsh"
fi
