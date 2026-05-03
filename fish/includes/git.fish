# Git helpers.
function commit --description 'git commit wrapper'
    if test (count $argv) -eq 0
        git commit
    else
        git commit -m (string join ' ' -- $argv)
    end
end

function commitall --description 'git add . and commit'
    git add .
    commit $argv
end
alias commita commitall

function compush --description 'commitall and push'
    commitall $argv
    git push
end

function git-ida --description 'Set git identity from git-id-list'
    if test (count $argv) -eq 0
        echo 'Usage: git-ida <identity>'
        return 1
    end

    set -l identity (git-id-list get "$argv[1]")
    git-id $identity[1] $identity[2]
end

function git-id --description 'Set git identity for this shell'
    set -gx GIT_USER "$argv[1]"
    set -gx GIT_EMAIL "$argv[2]"
    git-id-prompt
end

function git-id-prompt --description 'Refresh git identity prompt segment'
    if test -z "$GIT_USER"; and test -z "$GIT_EMAIL"
        set -g __fishrc_git_id_segment ''
    else
        set -g __fishrc_git_id_segment "Git ID: $GIT_USER | $GIT_EMAIL "
    end
end

function git --description 'git wrapper with per-shell identity override'
    if test -z "$GIT_USER"
        command git $argv
    else
        command git -c "user.name=$GIT_USER" -c "user.email=$GIT_EMAIL" -c commit.gpgsign=false $argv
    end
end

function git-env --description 'Alias common git subcommands into the shell'
    set -l git_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag
    for cmd in $git_commands
        alias "$cmd" "git $cmd"
    end
    alias grm 'git rm'
    alias gmv 'git mv'
    alias st 'git status'
    function br --description 'Create and checkout a new branch'
        git checkout -b $argv
    end
end

function git-unenv --description 'Remove aliases created by git-env'
    set -l git_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag grm gmv st br
    for cmd in $git_commands
        functions -q "$cmd"; and functions -e "$cmd"
    end
end

git-id-prompt
