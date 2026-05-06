alias prompt "$SCR/helpers/prompt.py"

function pcolor --description 'Colorize text using the repository prompt helper'
    "$SCR/helpers/prompt.py" (string join ' ' -- $argv) color
end

function prompt-reset --description 'Reset fish prompt state used by this rc'
    set -g __fishrc_proxy_segment ''
    git-id-prompt
end

function __fishrc_prompt_pr_state --description 'Set GitHub PR prompt state for a branch'
    set -l branch $argv[1]
    test -n "$branch"; or return 1
    command -sq gh; or return 1

    set -l repo_key (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_key"
        set repo_key (command jj root --ignore-working-copy 2>/dev/null)
    end
    set -l cache_key "$repo_key:$branch"
    set -l now (date +%s)

    if test "$__fishrc_prompt_pr_cache_key" = "$cache_key"
        if string match -qr '^[0-9]+$' -- "$__fishrc_prompt_pr_cache_time"
            set -l cache_age (math "$now - $__fishrc_prompt_pr_cache_time" 2>/dev/null)
            if string match -qr '^[0-9]+$' -- "$cache_age"
                if test "$cache_age" -lt 300
                    set -l cached_pr $__fishrc_prompt_pr_cache_value
                    test "$cached_pr[1]" != __none; or return 1
                    if test -z "$cached_pr[2]"
                        set cached_pr[2] green
                    end
                    set -g __fishrc_vcs_pr_number "$cached_pr[1]"
                    set -g __fishrc_vcs_pr_color "$cached_pr[2]"
                    return 0
                end
            end
        end
    end

    set -l pr_line
    if command -sq timeout
        set pr_line (command timeout 1s gh pr list --head "$branch" --state all --limit 20 --json number,state,updatedAt --jq 'map(select(.state == "OPEN" or .state == "MERGED")) | sort_by(.updatedAt) | reverse | .[0] | select(.number != null) | .number, .state' 2>/dev/null)
    else
        set pr_line (command gh pr list --head "$branch" --state all --limit 20 --json number,state,updatedAt --jq 'map(select(.state == "OPEN" or .state == "MERGED")) | sort_by(.updatedAt) | reverse | .[0] | select(.number != null) | .number, .state' 2>/dev/null)
    end

    set -l pr_number (string trim -- "$pr_line[1]")
    set -l pr_state (string trim -- "$pr_line[2]")
    set -l pr_color green
    if test "$pr_state" = MERGED
        set pr_color purple
    end

    set -g __fishrc_prompt_pr_cache_key "$cache_key"
    set -g __fishrc_prompt_pr_cache_time "$now"

    if not string match -qr '^[0-9]+$' -- "$pr_number"
        set -g __fishrc_prompt_pr_cache_value __none
        return 1
    end

    set -g __fishrc_prompt_pr_cache_value "$pr_number" "$pr_color"
    set -g __fishrc_vcs_pr_number "$pr_number"
    set -g __fishrc_vcs_pr_color "$pr_color"
end

function __fishrc_git_unpushed_count --description 'Print commits ahead of the git upstream or remotes'
    set -l upstream (command git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
    if test -n "$upstream"
        command git rev-list --count "$upstream"..HEAD 2>/dev/null
        return
    end

    command git rev-list --count HEAD --not --remotes 2>/dev/null
end

function __fishrc_git_prompt_state --description 'Set compact git repository state for the prompt'
    command -sq git; or return 1
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return 1

    set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    set -l pr_branch "$branch"
    if test -z "$branch"
        set branch (command git rev-parse --short HEAD 2>/dev/null)
    end
    test -n "$branch"; or return 1

    set -l git_status (command git status --porcelain=v1 --branch 2>/dev/null)
    set -l flags
    set -l changed 0

    set -l header $git_status[1]
    set -l behind (string match -r 'behind [0-9]+' -- "$header" | string replace 'behind ' 'v')

    set -l ahead_count (__fishrc_git_unpushed_count)
    if string match -qr '^[0-9]+$' -- "$ahead_count"
        if test "$ahead_count" -gt 0
            set -a flags ^$ahead_count
            set changed 1
        end
    end

    test -n "$behind"; and set -a flags $behind

    for line in $git_status[2..-1]
        set changed 1
        set -l index (string sub -s 1 -l 1 -- "$line")
        set -l worktree (string sub -s 2 -l 1 -- "$line")

        switch "$line"
            case 'UU*' 'AA*' 'DD*' 'AU*' 'UA*' 'DU*' 'UD*'
                contains x $flags; or set -a flags x
                continue
            case '??*'
                contains '?' $flags; or set -a flags '?'
                continue
        end

        if test "$index" != ' '
            contains + $flags; or set -a flags +
        end

        if test "$worktree" != ' '
            contains '!' $flags; or set -a flags '!'
        end
    end

    set -l segment "git:$branch"
    if test (count $flags) -gt 0
        set segment "$segment "(string join '' -- $flags)
    end

    set -g __fishrc_vcs_segment "$segment"
    set -g __fishrc_vcs_color 777777
    if test "$changed" -eq 1
        set -g __fishrc_vcs_color yellow
    end

    __fishrc_prompt_pr_state "$pr_branch"
    return 0
end

function __fishrc_jj_prompt_state --description 'Set compact jj workspace state for the prompt'
    command -sq jj; or return 1
    command jj root --ignore-working-copy >/dev/null 2>&1; or return 1

    set -l info (command jj log --no-graph --ignore-working-copy --color=never -r @ --template 'separate(" ", change_id.shortest(8), bookmarks.join("|"), if(conflict, "x")) ++ "\n"' 2>/dev/null)
    test -n "$info"; or return 1

    set -g __fishrc_vcs_segment "jj:$info"
    set -g __fishrc_vcs_color 777777

    set -l diff_summary (command jj diff --summary --ignore-working-copy 2>/dev/null)
    if test -n "$diff_summary"
        set -g __fishrc_vcs_color yellow
    end

    set -l pr_branch (command jj log --no-graph --ignore-working-copy --color=never -r 'bookmarks() & @' --template 'bookmarks.join("\n") ++ "\n"' 2>/dev/null)[1]
    set pr_branch (string replace -r '\*$' '' -- "$pr_branch")
    __fishrc_prompt_pr_state "$pr_branch"
    return 0
end

function __fishrc_vcs_prompt_state --description 'Set prompt VCS segment state'
    set -g __fishrc_vcs_segment ''
    set -g __fishrc_vcs_color 777777
    set -g __fishrc_vcs_pr_number ''
    set -g __fishrc_vcs_pr_color green

    __fishrc_jj_prompt_state; or __fishrc_git_prompt_state
end

function fish_prompt --description 'Repository fish prompt'
    set -l host (prompt_hostname)
    set host (string replace -r '^HyDEV-' '' -- "$host")

    printf '\n'

    if test "$host" = HyDEV
        set_color magenta
        printf '%s ' (date '+%a %m-%d %H:%M')
    else
        set_color 55CDFC
        printf '%s ' (date '+%a')
        set_color F7A8B8
        printf '%s' (date '+%m-')
        set_color FFFFFF
        printf '%s ' (date '+%d')
        set_color F7A8B8
        printf '%s' (date '+%H:')
        set_color 55CDFC
        printf '%s ' (date '+%M')
    end

    set_color blue
    if test "$host" = HyDEV
        set_color 55CDFC
        printf H
        set_color F7A8B8
        printf y
        set_color FFFFFF
        printf D
        set_color F7A8B8
        printf E
        set_color 55CDFC
        printf 'V '
    else
        printf '%s ' "$host"
    end

    set_color yellow
    if test -n "$__fishrc_git_id_segment"
        printf '%s' "$__fishrc_git_id_segment"
    else
        printf '%s ' "$USER"
    end
    set_color brgreen
    printf '%s' "$__fishrc_proxy_segment"

    set_color normal
    printf '%s' (prompt_pwd)

    __fishrc_vcs_prompt_state
    if test -n "$__fishrc_vcs_segment"
        printf ' '
        set_color $__fishrc_vcs_color
        printf '[%s' "$__fishrc_vcs_segment"
        if test -n "$__fishrc_vcs_pr_number"
            printf ' '
            set_color $__fishrc_vcs_pr_color
            printf '#%s' "$__fishrc_vcs_pr_number"
            set_color $__fishrc_vcs_color
        end
        printf ']'
        set_color normal
    end

    printf '\n> '
end
