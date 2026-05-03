# Application aliases.
alias va-restart 'sctl restart va'
alias va-log-all 'jctl -u va --output cat'
alias va-log 'va-log-all -f'
alias jctlog 'jctl --output cat -f -u'

# Arch Linux setup.
if has pacman
    if test (id -u) -eq 0
        alias upgrade 'pacman -Syu'
    else
        alias upgrade 'sudo pacman -Syu'
    end
    alias install 'pacman -Sy'
    alias uninstall 'pacman -Rsn'
    alias list-unused 'pacman -Qdtq'
end

if test -f /etc/arch-release
    __fishrc_prepend_path "$HOME/.local/share/JetBrains/Toolbox/scripts"

    alias gpg-init "echo hi | gpg --status-fd=2 -bsau E289FAC0DA92DD2B"
    alias ibus-init 'ibus-daemon -drxR'
    alias autoremove 'yay -c'

    function clean-cache --description 'Clean common package manager caches'
        has yay; and yay -Sc --noconfirm
        has pacman; and __fishrc_as_root pacman -Sc --noconfirm
        has pacman; and __fishrc_as_root rm -rf /var/cache/pacman
        has paru; and rm -rf "$HOME/.cache/paru"
        has yarn; and yarn cache clean
        has conda; and conda clean -a
        has pip; and pip cache remove '*'
    end

    if test -f "$ZSHRC_ROOT/plugins/find-the-command/usr/share/doc/find-the-command/ftc.fish"
        source "$ZSHRC_ROOT/plugins/find-the-command/usr/share/doc/find-the-command/ftc.fish"
    end
end

# Mamba and Python environment setup.
alias mamba-install 'curl -L micro.mamba.pm/install.sh | bash'
set -q MAMBA_ROOT_PREFIX; or set -gx MAMBA_ROOT_PREFIX "$HOME/.conda"

function mamba-init --description 'Initialize micromamba for fish'
    set -l mamba_exe (command -s micromamba)
    if test -z "$mamba_exe"
        echo 'Failed to initialize mamba: micromamba not found.'
        return 1
    end

    $mamba_exe shell hook --shell fish --root-prefix "$HOME/micromamba" | source
    set -l ret $pipestatus[1]
    if test $ret -ne 0
        echo "Failed to initialize mamba: Return code $ret."
        echo "Note: this uses '--root-prefix' for mamba 2.0+. Upgrade with mamba-install if needed."
        return $ret
    end
end

if has micromamba
    mamba-init
    if not has conda
        alias conda mamba
    end
end

if has pyenv
    pyenv init - fish | source
    __fishrc_prepend_path (pyenv root)/shims
end

alias mamba micromamba
