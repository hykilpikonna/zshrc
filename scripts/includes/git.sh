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
