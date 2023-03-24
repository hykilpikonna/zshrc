# Mac-only commands 
if [[ $OSTYPE == 'darwin'* ]]; then
    modern-replace 'ls' 'exa' 'ls -hG'
    alias ports="netstat -ap tcp | grep -i \"listen\""
    alias ports2="sudo lsof -i -P | grep LISTEN"
    alias trash="rmtrash"
    
    alias checkrain="/Applications/checkra1n.app/Contents/MacOS/checkra1n"
    alias obs="open -n -a OBS.app"
    alias idea="open -a Intellij\ IDEA.app"
    alias xcode="open -a Xcode.app"

    # Java
    export JDK8="/usr/local/opt/openjdk@8/libexec/openjdk.jdk/Contents/Home"
    export JDK11="/usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home"
    export JDK16="/usr/local/opt/openjdk@16/libexec/openjdk.jdk/Contents/Home"
    export JDK17="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
    alias java8="${JDK8}/bin/java"
    alias java11="${JDK11}/bin/java"
    alias java16="${JDK16}/bin/java"
    alias java17="${JDK17}/bin/java"
    export JAVA_HOME=${JDK11}
    export PATH="${JDK11}/bin:$PATH"

    # Mac hostname
    mac-hostname() {
        name="$@"
        sudo scutil --set HostName "$name"
        sudo scutil --set LocalHostName "$name"
        sudo scutil --set ComputerName "$name"
    }

    # Anaconda
    export CONDA_PATH="/usr/local/anaconda3"
    export PATH="$CONDA_PATH/bin:$PATH"
    conda-init() {
        # >>> conda initialize >>>
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
        # <<< conda initialize <<<
    }

    # Clear cache to free up disk space
    clean-cache() {
        sudo rm -rf "/Users/hykilpikonna/Library/Caches/Homebrew/downloads"
        sudo rm -rf "/Users/hykilpikonna/Library/Caches/Yarn"
        sudo rm -rf "/Users/hykilpikonna/Library/Caches/JetBrains/Toolbox/download"

    }
fi
