# Git commit wrapper
commit() {
    msg="$@"
    git commit -m "$msg"
}

commitall() {
    git add .
    commit "$@"
}
alias commita="commitall"

compush() {
    commitall "$@"
    git push
}

# Git identity
git-ida() {
    # Zsh only
    TMP_ARR=("${(@f)$(git-id-list get "$1")}")
    git-id "${TMP_ARR[1]}" "${TMP_ARR[2]}"
}
git-id() {
    export GIT_USER="$1"
    export GIT_EMAIL="$2"
    git-id-prompt
}
git-id-prompt() {
    if [[ -z "$GIT_USER" ]] && [[ -z "$GIT_EMAIL" ]]; then
        prompt-reset
    else
        prompt-set 30 "&cGit ID: $GIT_USER | $GIT_EMAIL "
        prompt-update
    fi
}
git-id-prompt
[[ -z $GIT_BIN ]] && GIT_BIN=$(which git)
git() {
    if [[ -z "$GIT_USER" ]]; then 
        $GIT_BIN "$@"
    else
        $GIT_BIN -c "user.name=$GIT_USER" -c "user.email=$GIT_EMAIL" -c "commit.gpgsign=false" "$@"
    fi
}

# Git environment
git-env() {
    git_commands=( add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show status tag )
    for i in "${git_commands[@]}"
    do
        alias "$i"="git $i"
    done
    alias 'grm'='git rm'
    alias 'gmv'='git mv'
}
git-unenv() {
    git_commands=( add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show status tag grm gmv )
    for i in "${git_commands[@]}"
    do
        unalias "$i"
    done
}
