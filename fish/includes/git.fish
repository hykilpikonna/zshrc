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

function git-fetch-main --description 'Fetch the latest main branch from origin'
    set -l main_branch $argv[1]
    if test -z "$main_branch"
        set main_branch (git-main-branch); or return 1
    end

    command git fetch origin "+refs/heads/$main_branch:refs/remotes/origin/$main_branch"; or return 1
    printf '%s\n' "$main_branch"
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

function brup --description 'Merge the latest origin main branch into the current branch'
    set -l current_branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$current_branch"
        echo 'Could not determine current branch.'
        return 1
    end

    git-require-clean; or return 1

    set -l main_branch (git-fetch-main); or return 1
    command git merge "refs/remotes/origin/$main_branch"
end

set -g __fishrc_git_env_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag grm gmv st
set -q __fishrc_git_env_active; or set -g __fishrc_git_env_active 0
set -q __fishrc_git_env_auto_active; or set -g __fishrc_git_env_auto_active 0
set -q __fishrc_git_env_auto; or set -g __fishrc_git_env_auto on

function __fishrc_git_env_save_function --description 'Save an existing function before git-env replaces it'
    set -l name "$argv[1]"
    set -l had_var "__fishrc_git_env_had_$name"
    set -l def_var "__fishrc_git_env_def_$name"

    if functions -q "$name"
        set -g $had_var 1
        set -g $def_var (functions "$name" | string collect)
    else
        set -g $had_var 0
        set -e $def_var
    end
end

function __fishrc_git_env_restore_function --description 'Restore a function replaced by git-env'
    set -l name "$argv[1]"
    set -l had_var "__fishrc_git_env_had_$name"
    set -l def_var "__fishrc_git_env_def_$name"

    functions -q "$name"; and functions -e "$name"
    if test "$$had_var" = 1
        printf '%s\n' $$def_var | source
    end

    set -e $had_var
    set -e $def_var
end

function git-env --description 'Alias common git subcommands into the shell'
    if test "$__fishrc_git_env_active" = 1
        return 0
    end

    for cmd in $__fishrc_git_env_commands
        __fishrc_git_env_save_function "$cmd"
    end

    set -l git_commands add bisect branch checkout clone commit diff fetch grep init log merge pull push rebase reset restore show stash tag
    for cmd in $git_commands
        alias "$cmd" "git $cmd"
    end
    alias grm 'git rm'
    alias gmv 'git mv'
    alias st 'git status'

    set -g __fishrc_git_env_active 1
end

function git-unenv --description 'Remove aliases created by git-env'
    if test "$__fishrc_git_env_active" != 1
        return 0
    end

    for cmd in $__fishrc_git_env_commands
        __fishrc_git_env_restore_function "$cmd"
    end

    set -g __fishrc_git_env_active 0
    set -g __fishrc_git_env_auto_active 0
end

function __fishrc_git_env_auto_in_repo --description 'Return success inside a git worktree'
    command -sq git; and command git rev-parse --is-inside-work-tree >/dev/null 2>&1
end

function __fishrc_git_env_auto_update --description 'Refresh automatic git-env state'
    status is-interactive; or return 0

    if test "$__fishrc_git_env_auto" != on
        if test "$__fishrc_git_env_auto_active" = 1
            git-unenv
        end
        set -g __fishrc_git_env_auto_active 0
        return 0
    end

    if __fishrc_git_env_auto_in_repo
        git-env
        set -g __fishrc_git_env_auto_active 1
    else if test "$__fishrc_git_env_auto_active" = 1
        git-unenv
    end
end

function __fishrc_git_env_auto_on_pwd --on-variable PWD --description 'Refresh automatic git-env after cd'
    __fishrc_git_env_auto_update
end

function __fishrc_git_env_auto_on_prompt --on-event fish_prompt --description 'Refresh automatic git-env before each prompt'
    __fishrc_git_env_auto_update
end

function git-env-auto --description 'Toggle automatic git-env in git worktrees'
    if test (count $argv) -eq 0
        echo "git-env-auto $__fishrc_git_env_auto"
        return 0
    end

    if test (count $argv) -ne 1
        echo 'Usage: git-env-auto {on|off|status}'
        return 1
    end

    switch "$argv[1]"
        case on
            set -g __fishrc_git_env_auto on
            set -U __fishrc_git_env_auto on
            __fishrc_git_env_auto_update
        case off
            set -g __fishrc_git_env_auto off
            set -U __fishrc_git_env_auto off
            if test "$__fishrc_git_env_auto_active" = 1
                git-unenv
            end
            set -g __fishrc_git_env_auto_active 0
        case status
            echo "git-env-auto $__fishrc_git_env_auto"
        case '*'
            echo 'Usage: git-env-auto {on|off|status}'
            return 1
    end
end

__fishrc_git_env_auto_update
git-id-prompt
