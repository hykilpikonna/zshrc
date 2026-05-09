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

function git-require-clean --description 'Require a clean git worktree'
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return 1

    set -l status_lines (command git status --porcelain 2>/dev/null)
    if test (count $status_lines) -ne 0
        echo 'Workspace is not clean.'
        command git status --short
        return 1
    end
end

function git-ref-exists --description 'Return success if a git ref exists'
    test (count $argv) -eq 1; or return 1
    command git rev-parse --verify --quiet "$argv[1]" >/dev/null 2>&1
end

function git-main-branch --description 'Print the repository main branch name'
    set -l remote_head (command git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if test -n "$remote_head"
        string replace -r '^origin/' '' -- "$remote_head"
        return 0
    end

    for branch in main master trunk develop
        if git-ref-exists refs/heads/$branch
            printf '%s\n' "$branch"
            return 0
        end
        if git-ref-exists refs/remotes/origin/$branch
            printf '%s\n' "$branch"
            return 0
        end
    end

    echo 'Could not determine main branch.' >&2
    return 1
end

function git-update-main --description 'Checkout and fast-forward the main branch'
    set -l main_branch $argv[1]
    if test -z "$main_branch"
        set main_branch (git-main-branch); or return 1
    end

    command git checkout "$main_branch"; or return 1
    command git pull --ff-only
end

function br --description 'Switch to an existing branch, or create one from updated main'
    if test (count $argv) -ne 1
        echo 'Usage: br <branch-name>'
        return 1
    end

    set -l branch "$argv[1]"
    git-require-clean; or return 1

    if git-ref-exists "refs/heads/$branch"; or git-ref-exists "refs/remotes/origin/$branch"
        command git checkout "$branch"
        return $status
    end

    set -l main_branch (git-main-branch); or return 1
    git-update-main "$main_branch"; or return 1
    command git checkout -b "$branch"
end

function bru --description 'Update the current branch by rebasing it on updated main'
    set -l current_branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$current_branch"
        echo 'Could not determine current branch.'
        return 1
    end

    git-require-clean; or return 1

    set -l main_branch (git-main-branch); or return 1
    if test "$current_branch" = "$main_branch"
        echo "Already on $main_branch."
        return 1
    end

    git-update-main "$main_branch"; or return 1
    command git checkout "$current_branch"; or return 1
    command git rebase "$main_branch"
end

function git-env --description 'Alias common git subcommands into the shell'
    set -l git_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag
    for cmd in $git_commands
        alias "$cmd" "git $cmd"
    end
    alias grm 'git rm'
    alias gmv 'git mv'
    alias st 'git status'
end

function git-unenv --description 'Remove aliases created by git-env'
    set -l git_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag grm gmv st
    for cmd in $git_commands
        functions -q "$cmd"; and functions -e "$cmd"
    end
end

git-id-prompt
