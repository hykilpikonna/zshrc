# Mamba (conda replacement)
alias mamba-install="zsh <(curl -L micro.mamba.pm/install.sh)"
export MAMBA_ROOT_PREFIX="$HOME/.conda"

# Mamba initialize function
mamba-init()
{
    MAMBA_EXE="$(which micromamba)";
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$HOME/micromamba" 2> /dev/null)"
    ret=$?
    if [ $ret -eq 0 ]; then
        eval "$__mamba_setup"
    else 
        echo "Failed to initialize mamba: Return code $ret."
        echo "(Note: I just updated the mamba arguments to use '--root-prefix' instead of '--prefix'.)"
        echo "(This is a change on mamba 2.0, if you're having issues please upgrade using mamba-install!)"
    fi
    unset __mamba_setup
}

# Auto init mamba
if command -v 'micromamba' &> /dev/null; then
    mamba-init
    
    if ! command -v 'conda' &> /dev/null; then
        alias conda="mamba"
    fi
fi

# Pyenv
if command -v 'pyenv' &> /dev/null; then
    eval "$(pyenv init -)"
    PATH=$(pyenv root)/shims:$PATH
fi

# This alias needs to be added after mamba-init
alias mamba="micromamba"