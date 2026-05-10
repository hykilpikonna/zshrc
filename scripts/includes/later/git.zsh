# Git commit wrapper
commit() {
    if [[ $# -eq 0 ]]; then
        git commit
    else
        msg="$@"
        git commit -m "$msg"
    fi
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

git-require-clean() {
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

    if [[ -n "$(command git status --porcelain 2>/dev/null)" ]]; then
        echo 'Workspace is not clean.'
        command git status --short
        return 1
    fi
}

git-ref-exists() {
    [[ $# -eq 1 ]] || return 1
    command git rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

git-main-branch() {
    local remote_head
    remote_head=$(command git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if [[ -n "$remote_head" ]]; then
        echo "${remote_head#origin/}"
        return 0
    fi

    local branch
    for branch in main master trunk develop; do
        if git-ref-exists "refs/heads/$branch"; then
            echo "$branch"
            return 0
        fi
        if git-ref-exists "refs/remotes/origin/$branch"; then
            echo "$branch"
            return 0
        fi
    done

    echo 'Could not determine main branch.' >&2
    return 1
}

git-update-main() {
    local main_branch="$1"
    if [[ -z "$main_branch" ]]; then
        main_branch=$(git-main-branch) || return 1
    fi

    command git checkout "$main_branch" || return 1
    command git pull --ff-only
}

git-fetch-main() {
    local main_branch="$1"
    if [[ -z "$main_branch" ]]; then
        main_branch=$(git-main-branch) || return 1
    fi

    command git fetch origin "+refs/heads/${main_branch}:refs/remotes/origin/${main_branch}" || return 1
    echo "$main_branch"
}

br() {
    if [[ $# -ne 1 ]]; then
        echo 'Usage: br <branch-name>'
        return 1
    fi

    local branch="$1"
    git-require-clean || return 1

    if git-ref-exists "refs/heads/$branch" || git-ref-exists "refs/remotes/origin/$branch"; then
        command git checkout "$branch"
        return $?
    fi

    local main_branch
    main_branch=$(git-main-branch) || return 1
    git-update-main "$main_branch" || return 1
    command git checkout -b "$branch"
}

bru() {
    local current_branch
    current_branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
        echo 'Could not determine current branch.'
        return 1
    fi

    git-require-clean || return 1

    local main_branch
    main_branch=$(git-main-branch) || return 1
    if [[ "$current_branch" == "$main_branch" ]]; then
        echo "Already on $main_branch."
        return 1
    fi

    git-update-main "$main_branch" || return 1
    command git checkout "$current_branch" || return 1
    command git rebase "$main_branch"
}

brup() {
    local current_branch
    current_branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
        echo 'Could not determine current branch.'
        return 1
    fi

    git-require-clean || return 1

    local main_branch
    main_branch=$(git-fetch-main) || return 1
    command git merge "refs/remotes/origin/$main_branch"
}

# Git environment
git-env() {
    git_commands=( add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag )
    for i in "${git_commands[@]}"
    do
        alias "$i"="git $i"
    done
    alias 'grm'='git rm'
    alias 'gmv'='git mv'
    alias 'st'='git status'
}
git-unenv() {
    git_commands=( add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag grm gmv st )
    for i in "${git_commands[@]}"
    do
        unalias "$i"
    done
}
