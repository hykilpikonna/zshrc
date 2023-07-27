prefix="&7[&3zshrc&7]"

# Sync config
check-config()
{
    file=$1
    sync=$2

    if ! [[ -L "$file" ]]
    then
        set -e
        color "$prefix &c$file is not a symlink, creating symlink"
        if [[ -f "$file" ]] || [[ -d "$file" ]]
        then
            echo "> Original file $file exists."
            echo "> Diff:"
            diff $file $sync
            bak="$file.bak"
            echo "> Moving $file to $bak..."
            mv $file $bak
        fi
        echo "> Creating symlink from $sync to $file..."
        mkdir -p "$(dirname "$file")"
        ln -sf "$sync" "$file"
        color "$prefix &aDone!"
        set +e
    fi
}

# Sync inject
check-inject()
{
    file=$1
    config=$2
    
    if ! grep -Fxq "$config" "$file"; then
        echo "$config" >> "$file"
        color "$prefix &aLines injected for $file"
    fi
}

CFGSYNC="$SCR/../config-sync"

# Sync SSH Config
check-config $HOME/.ssh/config $CFGSYNC/ssh-config

# Check nanorc includes
# check-inject "$HOME/.nanorc" "include $SCR/../config-sync/nanorc"
check-config "$HOME/.nanorc" "$CFGSYNC/nanorc"
check-config "$HOME/.condarc" "$CFGSYNC/.condarc"
check-config "$HOME/.java/.userPrefs/com/cburch/logisim/prefs.xml" "$CFGSYNC/.java/.userPrefs/com/cburch/logisim/prefs.xml"
check-config "$HOME/.config/micro/settings.json" "$CFGSYNC/.config/micro/settings.json"

check-config "$HOME/.config/kitty" "$CFGSYNC/.config/kitty"
# check-config "$HOME/.config/ibus/rime" "$CFGSYNC/.config/ibus/rime"
# check-config "$HOME/.local/share/fcitx5/rime" "$CFGSYNC/.config/ibus/rime"

# macOS only
if [[ $OSTYPE == 'darwin'* ]]; then
    check-config "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$CFGSYNC/macOS/com.googlecode.iterm2.plist"
    check-config "$HOME/Library/Rime" "$CFGSYNC/.config/ibus/rime"
fi
