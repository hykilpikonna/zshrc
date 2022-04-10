# Sync config
check-config()
{
    file=$1
    sync=$2

    if ! [[ -L "$file" && -f "$file" ]]
    then
        set -e
        echo "[Config Sync] $file is not a symlink, creating symlink"
        if [[ -f "$file" ]]
        then
            echo "> Original file $file exists."
            echo "> Diff:"
            diff $file $sync
            bak="$file.bak"
            echo "> Moving $file to $bak..."
            mv $file $bak
        fi
        echo "> Creating symlink from $file to $sync..."
        ln -s $sync $file
        echo "> Done!"
    fi
}

# Sync SSH Config
alias check-ssh-config="check-config ~/.ssh/config $SCR/../config-sync/ssh-config"
check-ssh-config