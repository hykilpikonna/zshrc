alias rebuild="nixos-rebuild switch"
alias gc="nix-collect-garbage -d"
alias rebuild-gc="rebuild; gc"

# Update git
nix-git-update() {
    # Make sure there aren't any other changes
    if git diff-index --quiet HEAD --; then
        # No changes
        pushd /etc/nixos
        update-nix-fetchgit *.nix
        rebuild-gc
        git add *.nix
        git commit -m "[U] Update fetchgit refs"
        git push
        popd
    else
        # Changes
        echo "Error: There are uncommitted changes"
        git status
    fi
}
