cd $SCR

prefix="&7[&3zshrc&7]"

# Check for updates
git fetch origin --quiet
reslog=$(git log HEAD..origin/master --oneline)
if [[ "${reslog}" != "" ]] ; then

    # Has updates
    color "$prefix &cYour zshrc is outdated. Automatically updating..."

    # Try to pull
    if git stash & git pull & git stash pop; then
        . $SCR/zshrc.sh
        color "$prefix &aUpdated!"
    else
        color "$prefix &cUpdate failed!"
    fi
fi

cd -
