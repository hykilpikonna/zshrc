# Nixos only
if command -v nixos-rebuild &> /dev/null; then
    alias rebuild="sudo nixos-rebuild switch"
    alias gc="sudo nix-collect-garbage -d"
    alias rebuild-gc="rebuild; gc"

    # Update git
    nix-git-update() {
        pushd /etc/nixos

        # Make sure there aren't any other changes
        if git diff-index --quiet HEAD --; then
            # No changes
            update-nix-fetchgit *.nix

            # If there are changes after updating
            if ! git diff-index --quiet HEAD --; then
                # Has changes
                rebuild-gc
                git add *.nix
                git commit -m "[U] Update fetchgit refs"
                git push
                echo "Successfully updated fetchgit refs"
            else
                echo "There aren't any updates"
            fi
        else
            # Changes
            echo "Error: There are uncommitted changes"
            git status
        fi

        popd
    }
fi
