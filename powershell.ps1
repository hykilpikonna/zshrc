set-alias ll ls

function su
{
    powershell Start-Process powershell -Verb runAs
}

# Minecraft coloring
function color($tmp) {
    $033 = [char]27 
    $tmp = "$tmp&r"
    $tmp = $tmp -replace "&0", "$033[0;30m"
    $tmp = $tmp -replace "&1", "$033[0;34m"
    $tmp = $tmp -replace "&2", "$033[0;32m"
    $tmp = $tmp -replace "&3", "$033[0;36m"
    $tmp = $tmp -replace "&4", "$033[0;31m"
    $tmp = $tmp -replace "&5", "$033[0;35m"
    $tmp = $tmp -replace "&6", "$033[0;33m"
    $tmp = $tmp -replace "&7", "$033[0;37m"
    $tmp = $tmp -replace "&8", "$033[1;30m"
    $tmp = $tmp -replace "&9", "$033[1;34m"
    $tmp = $tmp -replace "&a", "$033[1;32m"
    $tmp = $tmp -replace "&b", "$033[1;36m"
    $tmp = $tmp -replace "&c", "$033[1;31m"
    $tmp = $tmp -replace "&d", "$033[1;35m"
    $tmp = $tmp -replace "&e", "$033[1;33m"
    $tmp = $tmp -replace "&f", "$033[1;37m"
    $tmp = $tmp -replace "&r", "$033[0m"
    $tmp = $tmp -replace "&n", "`r`n"
    $tmp
}

function prompt
{
    color ("&n" +
    "&5$(get-date -UFormat "%a %m-%d %H:%M") &1Kevin-PC &eAzalea &r$(get-location)&n" +
    "> ")
}