# Home mac only
if [[ $OSTYPE == 'darwin'* ]] && [ -d "/Volumes/External" ]; then
    # Minecraft
    export MC_DIR="/Volumes/External/Minecraft"
    alias minecraft="pushd $MC_DIR; java8 -jar $MC_DIR/HMCL-*.jar; popd"

    # Paths
    export PATH="$PATH:/Users/hykilpikonna/.pyenv/versions/3.8.0/bin"
    export DOTNET_ROOT="/usr/local/opt/dotnet/libexec"
    # export PATH="/Volumes/MacData/SageMath:$PATH"
    export PATH="$PATH:/Users/hykilpikonna/.gem/ruby/2.6.0/bin" # https://stackoverflow.com/a/53388305/7346633
    export PATH="/Users/hykilpikonna/Resources/flutter/bin:$PATH"
    export ANDROID_HOME="~/Resources/AndroidSDK"
    export PATH="${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
    export NDK_HOME="/Volumes/MacData/Resources/android-ndk-r21d"
    export NDK_ROOT=$NDK_HOME
fi
