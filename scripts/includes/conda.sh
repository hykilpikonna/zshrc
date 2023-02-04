# Mamba (conda replacement)
alias mamba="micromamba"
alias mamba-install="curl micro.mamba.pm/install.sh | zsh"
export MAMBA_ROOT_PREFIX="$HOME/.conda"

# Mamba initialize function
mamba-init()
{
    export MAMBA_EXE="$(which micromamba)";
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --prefix "$HOME/micromamba" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        if [ -f "$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh" ]; then
            . "$MAMBA_ROOT_PREFIX/etc/profile.d/micromamba.sh"
        else
            export PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
        fi
    fi
    unset __mamba_setup
}

# Auto init mamba
if command -v 'micromamba' &> /dev/null; then
    mamba-init
fi

# Pyenv
if command -v 'pyenv' &> /dev/null; then
    eval "$(pyenv init -)"
    PATH=$(pyenv root)/shims:$PATH
fi