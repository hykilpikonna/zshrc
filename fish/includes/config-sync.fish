# Config sync, matching the zsh setup for Linux-relevant files.
set -g __fishrc_config_prefix '&7[&3fishrc&7]'

function __fishrc_check_config --description 'Ensure a config path is a symlink to this repo'
    set -l file $argv[1]
    set -l sync $argv[2]

    if test -z "$file"; or test -z "$sync"
        return 1
    end

    if not test -L "$file"
        if has color
            color "$__fishrc_config_prefix &c$file is not a symlink, creating symlink"
        else
            echo "$file is not a symlink, creating symlink"
        end

        if test -f "$file"; or test -d "$file"
            echo "> Original file $file exists."
            echo '> Diff:'
            diff "$file" "$sync"
            set -l bak "$file.bak"
            echo "> Moving $file to $bak..."
            mv "$file" "$bak"
        end

        echo "> Creating symlink from $sync to $file..."
        mkdir -p (dirname "$file")
        ln -sf "$sync" "$file"

        if has color
            color "$__fishrc_config_prefix &aDone!"
        end
    end
end

function __fishrc_check_inject --description 'Append a config line if it is missing'
    set -l file $argv[1]
    set -l config $argv[2]
    grep -Fxq "$config" "$file"; or begin
        echo "$config" >>"$file"
        has color; and color "$__fishrc_config_prefix &aLines injected for $file"
    end
end

set -gx CFGSYNC "$ZSHRC_ROOT/config-sync"
if status is-interactive
    __fishrc_check_config "$HOME/.ssh/config" "$CFGSYNC/ssh-config"
    __fishrc_check_config "$HOME/.ssh/rc" "$CFGSYNC/ssh-rc"
    chmod +x "$CFGSYNC/ssh-rc"
    __fishrc_check_config "$HOME/.nanorc" "$CFGSYNC/nanorc"
    __fishrc_check_config "$HOME/.condarc" "$CFGSYNC/.condarc"
    __fishrc_check_config "$HOME/.java/.userPrefs/com/cburch/logisim/prefs.xml" "$CFGSYNC/.java/.userPrefs/com/cburch/logisim/prefs.xml"
    __fishrc_check_config "$HOME/.config/micro" "$CFGSYNC/.config/micro"
    __fishrc_check_config "$HOME/.config/mako" "$CFGSYNC/.config/mako"
    __fishrc_check_config "$HOME/.config/kitty" "$CFGSYNC/.config/kitty"
    __fishrc_check_config "$HOME/.config/tmux" "$CFGSYNC/.config/tmux"
    __fishrc_check_config "$HOME/.ipython/profile_default/startup/ipython_init.py" "$CFGSYNC/ipython_init.py"
    __fishrc_check_config "$HOME/.local/share/fcitx5/rime" "$CFGSYNC/.config/ibus/rime"
    __fishrc_check_config "$HOME/.local/share/fcitx5/themes" "$CFGSYNC/.config/fcitx5/themes"
end
