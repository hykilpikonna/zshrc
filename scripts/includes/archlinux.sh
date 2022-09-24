if command -v pacman &> /dev/null; then
    alias install='pacman -Sy'
    alias uninstall='pacman -Rsn'
    alias listunused='pacman -Qdtq'
    alias aurinst='yay -S'
fi

if [ -f "/etc/arch-release" ]; then
    # Java paths
    export JDK8="/usr/lib/jvm/java-8-openjdk/"
    export JDK11="/usr/lib/jvm/java-11-openjdk/"
    export JDK17="/usr/lib/jvm/java-17-openjdk/"
    alias java8="${JDK8}/bin/java"
    alias java11="${JDK11}/bin/java"
    alias java17="${JDK17}/bin/java"
    export JAVA_HOME=${JDK11}
    export PATH="${JDK11}/bin:$PATH"

    export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

    # GPG Init
    alias gpg-init="echo 'hi' | gpg --status-fd=2 -bsau E289FAC0DA92DD2B"

    CONDA_PATH="/opt/miniconda3"

    # Conda initialize
    conda-init() {
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$("$CONDA_PATH/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]; then
                . "$CONDA_PATH/etc/profile.d/conda.sh"
            else
                export PATH="$CONDA_PATH/bin:$PATH"
            fi
        fi
        unset __conda_setup
    }

    # Remove orphan packages
    alias autoremove='yay -c'

    # Free up cache
    clean-cache() {
        yay -Sc --noconfirm
        sudo pacman -Sc --noconfirm
    }
fi