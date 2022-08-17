if command -v pacman &> /dev/null; then
    alias install='pacman -S'
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

    # GPG Init
    alias gpg-init="echo 'hi' | gpg --status-fd=2 -bsau E289FAC0DA92DD2B"
fi