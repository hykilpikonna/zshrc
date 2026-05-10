$script:PwshRcRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $script:PwshRcRoot) {
    $script:PwshRcRoot = Join-Path $HOME 'zshrc'
}
if (-not (Test-Path -LiteralPath (Join-Path $script:PwshRcRoot 'scripts') -PathType Container)) {
    $homeRepo = Join-Path $HOME 'zshrc'
    if (Test-Path -LiteralPath (Join-Path $homeRepo 'scripts') -PathType Container) {
        $script:PwshRcRoot = $homeRepo
    }
}

$env:ZSHRC_ROOT = $script:PwshRcRoot
if (-not $env:SCR) { $env:SCR = Join-Path $env:ZSHRC_ROOT 'scripts' }
if (-not $env:BASEDIR) { $env:BASEDIR = $env:ZSHRC_ROOT }
if (-not $env:LANG) { $env:LANG = 'en_US.UTF-8' }
if (-not $env:LC_ALL) { $env:LC_ALL = 'en_US.UTF-8' }

$global:__PwshRcProxySegment = ''
$global:__PwshRcGitIdSegment = ''
$global:__PwshRcPromptPrCacheKey = ''
$global:__PwshRcPromptPrCacheTime = 0
$global:__PwshRcPromptPrCacheValue = @('__none')

function has {
    param([Parameter(Mandatory = $true)][string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-ExternalCommandPath {
    param([Parameter(Mandatory = $true)][string]$Command)
    $cmd = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    return $null
}

function Remove-AliasIfExists {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (Get-Alias -Name $Name -ErrorAction SilentlyContinue) {
        Remove-Item -Path "Alias:$Name" -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-ExternalCommand {
    if ($args.Count -lt 1) {
        Write-Error 'Invoke-ExternalCommand requires a command name.'
        return 127
    }

    $Command = [string]$args[0]
    $CommandArgs = @()
    for ($i = 1; $i -lt $args.Count; $i++) {
        $CommandArgs += ,$args[$i]
    }
    $cmd = Get-ExternalCommandPath $Command
    if (-not $cmd) {
        Write-Error "$Command is not installed."
        return 127
    }

    & $cmd @CommandArgs
}

function Add-PathIfExists {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Paths)
    $separator = [IO.Path]::PathSeparator
    $current = @($env:Path -split [regex]::Escape($separator) | Where-Object { $_ })

    foreach ($path in $Paths) {
        if (-not $path) { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($path)
        if (-not (Test-Path -LiteralPath $expanded -PathType Container)) { continue }
        if ($current -notcontains $expanded) {
            $current = @($expanded) + $current
        }
    }

    $env:Path = ($current -join $separator)
}

Add-PathIfExists `
    (Join-Path $env:SCR 'bin') `
    (Join-Path $HOME '.local/bin') `
    (Join-Path $HOME '.cargo/bin') `
    (Join-Path $HOME 'AppData/Roaming/Python/Python39/Scripts') `
    (Join-Path $HOME 'AppData/Roaming/npm') `
    (Join-Path $HOME 'AppData/Local/Yarn/bin') `
    'C:\Programs\bin'

if ($IsLinux -and [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::X64) {
    Add-PathIfExists (Join-Path $env:SCR 'bin/linux-x64')
}

function pwdd {
    $path = $PWD.ProviderPath
    if ($path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        return ('~' + $path.Substring($HOME.Length))
    }
    return $path
}

function ln-s {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$Link
    )
    New-Item -Path $Link -ItemType SymbolicLink -Value $Target
}

function su {
    if ($IsWindows -or -not (Get-Variable IsWindows -ErrorAction SilentlyContinue)) {
        $shell = Get-ExternalCommandPath pwsh
        if (-not $shell) { $shell = Get-ExternalCommandPath powershell }
        if (-not $shell) { $shell = 'powershell' }
        Start-Process $shell -Verb RunAs
    } else {
        Write-Error 'su is only configured for Windows PowerShell sessions.'
    }
}

function Set-AliasIfCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Command
    )
    if (has $Command) {
        Set-Alias -Scope Global -Name $Name -Value $Command -Force
    }
}

function Register-ForwardingFunction {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Command,
        [object[]]$PrefixArgs = @()
    )

    $scriptBlock = {
        Invoke-ExternalCommand $Command @PrefixArgs @args
    }.GetNewClosure()
    Remove-AliasIfExists $Name
    Set-Item -Path "function:global:$Name" -Value $scriptBlock
}

function modern-replace {
    param(
        [Parameter(Mandatory = $true)][string]$OriginalCommand,
        [Parameter(Mandatory = $true)][string]$NewCommand,
        [object[]]$NewCommandArgs = @()
    )

    if (has $NewCommand) {
        Register-ForwardingFunction -Name $OriginalCommand -Command $NewCommand -PrefixArgs $NewCommandArgs
    }
}

foreach ($name in @('ll', 'l', 'lla', 'llg', 'open', 'gradle', 'git', '7z', 'ssh', 'ffmpeg', 'ffprobe')) {
    Remove-AliasIfExists $name
}

function ll {
    if (has eza) { Invoke-ExternalCommand eza -l @args }
    else { Get-ChildItem @args }
}

function l { ll @args }

function lla {
    if (has eza) { Invoke-ExternalCommand eza -la @args }
    else { Get-ChildItem -Force @args }
}

function llg {
    if (has eza) { Invoke-ExternalCommand eza -l --git --git-repos @args }
    else { ll @args }
}

function mkdirs {
    param([Parameter(Mandatory = $true)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path
}

function open { Invoke-Item @args }
Set-Alias -Scope Global -Name clr -Value Clear-Host -Force

function colors {
    color '&000&111&222&333&444&555&666&777&888&999&aaa&bbb&ccc&ddd&eee&fff'
}

function ports {
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess
    } elseif (has netstat) {
        Invoke-ExternalCommand netstat -ano | Select-String -Pattern 'LISTEN|Listen'
    } else {
        Write-Error 'Neither Get-NetTCPConnection nor netstat is available.'
    }
}

function clean-empty-dir {
    Get-ChildItem -Directory -Recurse -Force | Sort-Object FullName -Descending | Where-Object {
        -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    } | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force
        $_.FullName
    }
}

function addline {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][string]$Line
    )

    if (-not (Test-Path -LiteralPath $File)) {
        New-Item -ItemType File -Path $File -Force | Out-Null
    }

    $exists = Select-String -LiteralPath $File -SimpleMatch -Pattern $Line -Quiet -ErrorAction SilentlyContinue
    if (-not $exists) {
        Add-Content -LiteralPath $File -Value $Line
    }
}

function mkcd {
    param([Parameter(Mandatory = $true)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location -LiteralPath $Path
}

function spushd { Push-Location @args | Out-Null }
function spopd { Pop-Location @args | Out-Null }

function set-java {
    param([Parameter(Mandatory = $true)][string]$Version)

    $candidates = @()
    if ($IsWindows -or -not (Get-Variable IsWindows -ErrorAction SilentlyContinue)) {
        $candidates += Get-ChildItem 'C:\Program Files\Java', 'C:\Program Files\Eclipse Adoptium', 'C:\Program Files\Microsoft' -Directory -ErrorAction SilentlyContinue
    } else {
        $candidates += Get-ChildItem '/usr/lib/jvm' -Directory -ErrorAction SilentlyContinue
    }

    $javaHome = $candidates | Where-Object { $_.Name -like "*$Version*" -and $_.Name -match 'jdk|java' } | Select-Object -First 1
    if (-not $javaHome) {
        Write-Error "Java version $Version was not found."
        return 1
    }

    $env:JAVA_HOME = $javaHome.FullName
    Add-PathIfExists (Join-Path $env:JAVA_HOME 'bin')
}

function upload-daisy {
    param([Parameter(Mandatory = $true)][string]$File)
    if (-not (has curl.exe)) {
        Write-Error 'curl.exe is required for upload-daisy.'
        return 1
    }
    Invoke-ExternalCommand curl.exe -u azalea -F "path=@$File" 'https://daisy-ddns.hydev.org/upload?path=/'
}

if (has micro) { $env:EDITOR = 'micro' }
elseif (has nano) { $env:EDITOR = 'nano' }

if (-not $env:GRADLE -and (has gradle)) {
    $env:GRADLE = (Get-ExternalCommandPath gradle)
}

function gradle {
    $wrapper = if ($IsWindows -or -not (Get-Variable IsWindows -ErrorAction SilentlyContinue)) { '.\gradlew.bat' } else { './gradlew' }
    if (Test-Path -LiteralPath $wrapper) {
        & $wrapper @args
    } elseif ($env:GRADLE) {
        & $env:GRADLE @args
    } else {
        Write-Error 'Neither gradle nor ./gradlew is found, please install it and restart PowerShell.'
        return 1
    }
}

function global:7z {
    if ($args.Count -gt 0 -and $args[0] -eq 'd') {
        Write-Host '7z d is blocked. It does not stand for decompress, it stands for delete.'
    } else {
        Invoke-ExternalCommand 7z @args
    }
}

function lisp {
    param([Parameter(Mandatory = $true)][string]$File)
    Invoke-ExternalCommand ros run --load $File --quit
}

function adblan {
    param([Parameter(Mandatory = $true)][string]$HostName)
    Invoke-ExternalCommand adb connect "$HostName`:16523"
}

function adblan-start { Invoke-ExternalCommand adb tcpip 16523 }

function setproxy {
    param(
        [string]$Address = '127.0.0.1',
        [int]$Port = 7890
    )

    $full = "$Address`:$Port"
    $proxy = "http://$full"
    $env:https_proxy = $proxy
    $env:http_proxy = $proxy
    $env:all_proxy = $proxy
    $env:HTTPS_PROXY = $proxy
    $env:HTTP_PROXY = $proxy
    $env:ALL_PROXY = $proxy
    $global:__PwshRcProxySegment = "proxy $full "
    Write-Host "Using proxy! $full" -ForegroundColor Green
}

function global:ssh {
    $sshExe = Get-ExternalCommandPath ssh
    if (-not $sshExe) {
        Write-Error 'ssh is not installed.'
        return 127
    }

    if ($env:TERM -eq 'xterm-kitty') {
        $oldTerm = $env:TERM
        $env:TERM = 'xterm-256color'
        try { & $sshExe @args }
        finally { $env:TERM = $oldTerm }
    } else {
        & $sshExe @args
    }
}

function subtitle {
    param([Parameter(Mandatory = $true)][string]$File)
    $oldCuda = $env:CUDA_VISIBLE_DEVICES
    $env:CUDA_VISIBLE_DEVICES = '1'
    try { Invoke-ExternalCommand auto_subtitle --srt_only True --model large $File }
    finally { $env:CUDA_VISIBLE_DEVICES = $oldCuda }
}

function upload {
    param([Parameter(Mandatory = $true)][string]$File)
    if (-not $env:UP_PASSWORD) {
        Write-Error 'Password not set, please set $env:UP_PASSWORD = "xxx".'
        return 1
    }
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Error 'File not found.'
        return 1
    }
    if (-not (has curl.exe)) {
        Write-Error 'curl.exe is required for upload.'
        return 1
    }

    $credential = 'azalea:{0}' -f $env:UP_PASSWORD
    Invoke-ExternalCommand curl.exe -u $credential -F "path=@$File" 'https://daisy.hydev.org/upload?path=/'
}

function global:ffmpeg { Invoke-ExternalCommand ffmpeg -hide_banner @args }
function global:ffprobe { Invoke-ExternalCommand ffprobe -hide_banner @args }

function vcompy {
    $videoHelper = Join-Path $env:SCR 'helpers/video.py'
    Invoke-ExternalCommand ipython -i $videoHelper
}

function cropv {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][int]$Length
    )
    $x = [math]::Floor((2560 - $Length) / 2)
    ffmpeg -i $File -filter:v "crop=$Length`:1440:$x`:0" out.mp4
}

function mp3v0 {
    param([Parameter(Mandatory = $true)][string]$InputFile)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    ffmpeg -i $InputFile -c:a libmp3lame -q:a 0 "$baseName.mp3"
}

function dc {
    if (has docker-compose) { Invoke-ExternalCommand docker-compose @args }
    else { Invoke-ExternalCommand docker compose @args }
}

if (-not (has docker) -and (has podman)) {
    Set-Alias -Scope Global -Name docker -Value podman -Force
    if (has podman-compose) {
        Set-Alias -Scope Global -Name docker-compose -Value podman-compose -Force
    }
}

function docker-ip {
    param([Parameter(Mandatory = $true)][string]$Container)
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $Container
}

function dockers {
    docker ps --format 'table {{.Names}}	{{.Image}}	{{.Status}}'
}

function docker-compose-path {
    param([Parameter(Mandatory = $true)][string]$Container)
    docker inspect $Container | Select-String -Pattern 'com.docker.compose.project.working_dir'
}

modern-replace ls eza
modern-replace cat bat
modern-replace man tldr
modern-replace top btop
modern-replace nano micro
modern-replace curl curlie
modern-replace vi nvim
modern-replace vim nvim

if (Test-Path 'C:\Program Files\Python39\python.exe') {
    Set-Alias -Scope Global -Name python3.9 -Value 'C:\Program Files\Python39\python.exe' -Force
}
if (Test-Path 'C:\Program Files\Python39\Scripts\pip3.exe') {
    Set-Alias -Scope Global -Name pip3.9 -Value 'C:\Program Files\Python39\Scripts\pip3.exe' -Force
}
if (Test-Path 'C:\Python310\python.exe') {
    Set-Alias -Scope Global -Name python3.10 -Value 'C:\Python310\python.exe' -Force
}
if (Test-Path 'C:\Python310\Scripts\pip3.exe') {
    Set-Alias -Scope Global -Name pip3.10 -Value 'C:\Python310\Scripts\pip3.exe' -Force
}

if (has micromamba) {
    Set-Alias -Scope Global -Name mamba -Value micromamba -Force
    if (-not $env:MAMBA_ROOT_PREFIX) { $env:MAMBA_ROOT_PREFIX = Join-Path $HOME '.conda' }
    $mambaExe = Get-ExternalCommandPath micromamba
    $mambaHook = & $mambaExe shell hook --shell powershell --root-prefix (Join-Path $HOME 'micromamba') 2>$null
    if ($LASTEXITCODE -eq 0 -and $mambaHook) {
        Invoke-Expression ($mambaHook -join [Environment]::NewLine)
        if (-not (has conda)) { Set-Alias -Scope Global -Name conda -Value mamba -Force }
    }
}

if (has pyenv) {
    $pyenvHook = Invoke-ExternalCommand pyenv init - powershell 2>$null
    if ($LASTEXITCODE -eq 0 -and $pyenvHook) {
        Invoke-Expression ($pyenvHook -join [Environment]::NewLine)
    }
    try {
        $pyenvRoot = Invoke-ExternalCommand pyenv root 2>$null
        if ($LASTEXITCODE -eq 0 -and $pyenvRoot) { Add-PathIfExists (Join-Path ($pyenvRoot | Select-Object -First 1) 'shims') }
    } catch {}
}

function Invoke-RawGit {
    $GitArgs = @($args)
    $gitExe = Get-ExternalCommandPath git
    if (-not $gitExe) {
        Write-Error 'git is not installed.'
        return 127
    }
    & $gitExe @GitArgs
}

function Invoke-GitCommand {
    $GitArgs = @($args)
    if ($env:GIT_USER) {
        Invoke-RawGit -c "user.name=$env:GIT_USER" -c "user.email=$env:GIT_EMAIL" -c commit.gpgsign=false @GitArgs
    } else {
        Invoke-RawGit @GitArgs
    }
}

function global:git { Invoke-GitCommand @args }

function commit {
    if ($args.Count -eq 0) { git commit }
    else { git commit -m ($args -join ' ') }
}

function commitall {
    git add .
    commit @args
}

Set-Alias -Scope Global -Name commita -Value commitall -Force

function compush {
    commitall @args
    git push
}

function git-id-prompt {
    if (-not $env:GIT_USER -and -not $env:GIT_EMAIL) {
        $global:__PwshRcGitIdSegment = ''
    } else {
        $global:__PwshRcGitIdSegment = "Git ID: $env:GIT_USER | $env:GIT_EMAIL "
    }
}

function git-id {
    param(
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Email
    )
    $env:GIT_USER = $User
    $env:GIT_EMAIL = $Email
    git-id-prompt
}

function git-ida {
    param([Parameter(Mandatory = $true)][string]$Identity)
    $identityParts = Invoke-ExternalCommand git-id-list get $Identity
    if ($LASTEXITCODE -ne 0 -or -not $identityParts) { return $LASTEXITCODE }
    git-id $identityParts[0] $identityParts[1]
}

function Test-GitCleanWorktree {
    Invoke-RawGit rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { return $false }

    $statusLines = Invoke-RawGit status --porcelain 2>$null
    if ($statusLines) {
        Write-Host 'Workspace is not clean.'
        Invoke-RawGit status --short
        return $false
    }

    return $true
}

function git-require-clean {
    if (-not (Test-GitCleanWorktree)) { return 1 }
}

function Test-GitRef {
    param([Parameter(Mandatory = $true)][string]$Ref)

    $gitExe = Get-ExternalCommandPath git
    if (-not $gitExe) { return $false }

    & $gitExe rev-parse --verify --quiet $Ref *> $null
    return $LASTEXITCODE -eq 0
}

function git-main-branch {
    $remoteHead = Invoke-RawGit symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $remoteHead) {
        return (($remoteHead | Select-Object -First 1) -replace '^origin/', '')
    }

    foreach ($branch in @('main', 'master', 'trunk', 'develop')) {
        if (Test-GitRef "refs/heads/$branch") { return $branch }
        if (Test-GitRef "refs/remotes/origin/$branch") { return $branch }
    }

    Write-Error 'Could not determine main branch.'
    return
}

function git-update-main {
    param([string]$MainBranch)
    if (-not $MainBranch) { $MainBranch = git-main-branch }
    if (-not $MainBranch) { return 1 }

    Invoke-RawGit checkout $MainBranch
    if ($LASTEXITCODE -ne 0) { return $LASTEXITCODE }
    Invoke-RawGit pull --ff-only
}

function git-fetch-main {
    param([string]$MainBranch)
    if (-not $MainBranch) { $MainBranch = git-main-branch | Select-Object -First 1 }
    if (-not $MainBranch) { return }

    Invoke-RawGit fetch origin "+refs/heads/${MainBranch}:refs/remotes/origin/${MainBranch}"
    if ($LASTEXITCODE -ne 0) { return }
    Write-Output $MainBranch
}

function br {
    param([Parameter(Mandatory = $true)][string]$Branch)
    if (-not (Test-GitCleanWorktree)) { return 1 }

    if ((Test-GitRef "refs/heads/$Branch") -or (Test-GitRef "refs/remotes/origin/$Branch")) {
        Invoke-RawGit checkout $Branch
        return $LASTEXITCODE
    }

    $mainBranch = git-main-branch
    if (-not $mainBranch) { return 1 }
    git-update-main $mainBranch
    if ($LASTEXITCODE -ne 0) { return $LASTEXITCODE }
    Invoke-RawGit checkout -b $Branch
}

function bru {
    $currentBranch = Invoke-RawGit symbolic-ref --quiet --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $currentBranch) {
        Write-Error 'Could not determine current branch.'
        return 1
    }
    $currentBranch = $currentBranch | Select-Object -First 1

    if (-not (Test-GitCleanWorktree)) { return 1 }

    $mainBranch = git-main-branch
    if (-not $mainBranch) { return 1 }
    if ($currentBranch -eq $mainBranch) {
        Write-Error "Already on $mainBranch."
        return 1
    }

    git-update-main $mainBranch
    if ($LASTEXITCODE -ne 0) { return $LASTEXITCODE }
    Invoke-RawGit checkout $currentBranch
    if ($LASTEXITCODE -ne 0) { return $LASTEXITCODE }
    Invoke-RawGit rebase $mainBranch
}

function brup {
    $currentBranch = Invoke-RawGit symbolic-ref --quiet --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $currentBranch) {
        Write-Error 'Could not determine current branch.'
        return 1
    }

    if (-not (Test-GitCleanWorktree)) { return 1 }

    $mainBranch = git-fetch-main | Select-Object -First 1
    if (-not $mainBranch) { return 1 }
    Invoke-RawGit merge "refs/remotes/origin/$mainBranch"
}

function git-env {
    foreach ($cmd in @('add', 'bisect', 'branch', 'checkout', 'clone', 'commit', 'diff', 'fetch', 'grep', 'init', 'log', 'merge', 'pull', 'push', 'rebase', 'reset', 'restore', 'show', 'stash', 'tag')) {
        $name = $cmd
        Set-Item -Path "function:global:$name" -Value { git $name @args }.GetNewClosure()
    }

    Set-Item -Path 'function:global:grm' -Value { git rm @args }
    Set-Item -Path 'function:global:gmv' -Value { git mv @args }
    Set-Item -Path 'function:global:st' -Value { git status @args }
}

function git-unenv {
    foreach ($cmd in @('add', 'bisect', 'branch', 'checkout', 'clone', 'commit', 'diff', 'fetch', 'grep', 'init', 'log', 'merge', 'pull', 'push', 'rebase', 'reset', 'restore', 'show', 'stash', 'tag', 'grm', 'gmv', 'st')) {
        Remove-Item -Path "function:global:$cmd" -ErrorAction SilentlyContinue
    }
}

function prompt-reset {
    $global:__PwshRcProxySegment = ''
    git-id-prompt
}

function Get-GithubOwnerFromRemoteUrl {
    param([string]$Url)
    if (-not $Url) { return $null }

    foreach ($pattern in @(
        '^https?://[^/]+/([^/]+)/.*$',
        '^ssh://[^@]+@[^/]+/([^/]+)/.*$',
        '^[^@]+@[^:]+:([^/]+)/.*$'
    )) {
        if ($Url -match $pattern) { return $Matches[1] }
    }

    return $null
}

function Get-GitRemoteUrl {
    param([string]$Remote)
    if (-not $Remote) { return $null }

    if ($Remote -match '://|^[^@]+@[^:]+:') { return $Remote }
    Invoke-RawGit remote get-url $Remote 2>$null | Select-Object -First 1
}

function Get-PromptPrByHead {
    param(
        [string]$HeadOwner,
        [string]$HeadBranch
    )
    if (-not $HeadOwner -or -not $HeadBranch) { return $null }

    $jq = 'map(select(.state == "OPEN" or .state == "MERGED")) | sort_by(.updatedAt) | reverse | .[] | [.number, .state, .headRepositoryOwner.login, .headRefName] | @tsv'
    $prLines = Invoke-ExternalCommand gh pr list --head $HeadBranch --state all --limit 50 --json number,state,updatedAt,headRefName,headRepositoryOwner --jq $jq 2>$null
    foreach ($line in $prLines) {
        $fields = $line -split "`t", 4
        if ($fields.Count -eq 4 -and $fields[2] -eq $HeadOwner -and $fields[3] -eq $HeadBranch) {
            return [pscustomobject]@{ Number = $fields[0]; State = $fields[1] }
        }
    }

    return $null
}

function Get-PromptPrState {
    param([string]$Branch)
    if (-not $Branch -or -not (has gh)) { return $null }

    $repoKey = Invoke-RawGit rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $repoKey) {
        if (has jj) { $repoKey = Invoke-ExternalCommand jj root --ignore-working-copy 2>$null }
    }
    if (-not $repoKey) { return $null }
    $repoKey = $repoKey | Select-Object -First 1

    $cacheKey = "$repoKey`:$Branch`:pr-v2"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($global:__PwshRcPromptPrCacheKey -eq $cacheKey -and ($now - [int64]$global:__PwshRcPromptPrCacheTime) -lt 300) {
        if ($global:__PwshRcPromptPrCacheValue[0] -eq '__none') { return $null }
        return [pscustomobject]@{ Number = $global:__PwshRcPromptPrCacheValue[0]; Color = $global:__PwshRcPromptPrCacheValue[1] }
    }

    $repoOwner = Invoke-ExternalCommand gh repo view --json owner --jq '.owner.login' 2>$null | Select-Object -First 1
    if (-not $repoOwner) { return $null }

    $pr = Get-PromptPrByHead $repoOwner $Branch

    if (-not $pr) {
        $branchRemote = Invoke-RawGit config --get "branch.$Branch.remote" 2>$null | Select-Object -First 1
        $branchMerge = Invoke-RawGit config --get "branch.$Branch.merge" 2>$null | Select-Object -First 1
        if ($branchRemote -and $branchMerge -and $branchMerge.StartsWith('refs/heads/')) {
            $branchHead = $branchMerge.Substring('refs/heads/'.Length)
            $remoteUrl = Get-GitRemoteUrl $branchRemote
            $remoteOwner = Get-GithubOwnerFromRemoteUrl $remoteUrl
            if ($remoteOwner) { $pr = Get-PromptPrByHead $remoteOwner $branchHead }
        }
    }

    $prNumber = if ($pr) { $pr.Number } else { $null }
    $prState = if ($pr) { $pr.State } else { $null }
    $prColor = if ($prState -eq 'MERGED') { 'AF87FF' } else { '00FF00' }

    $global:__PwshRcPromptPrCacheKey = $cacheKey
    $global:__PwshRcPromptPrCacheTime = $now
    if (-not ($prNumber -match '^[0-9]+$')) {
        $global:__PwshRcPromptPrCacheValue = @('__none')
        return $null
    }

    $global:__PwshRcPromptPrCacheValue = @($prNumber, $prColor)
    return [pscustomobject]@{ Number = $prNumber; Color = $prColor }
}

function Get-GitUnpushedCount {
    $upstream = Invoke-RawGit rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $upstream) { return $null }
    $upstream = $upstream | Select-Object -First 1
    Invoke-RawGit rev-list --count "$upstream..HEAD" 2>$null
}

function Get-GitPromptState {
    if (-not (Get-ExternalCommandPath git)) { return $null }
    Invoke-RawGit rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { return $null }

    $branch = Invoke-RawGit symbolic-ref --quiet --short HEAD 2>$null
    $prBranch = $branch | Select-Object -First 1
    if (-not $branch) { $branch = Invoke-RawGit rev-parse --short HEAD 2>$null }
    if (-not $branch) { return $null }
    $branch = $branch | Select-Object -First 1

    $gitStatus = @(Invoke-RawGit status --porcelain=v1 --branch 2>$null)
    $flags = New-Object System.Collections.Generic.List[string]
    $changed = $false

    $header = $gitStatus | Select-Object -First 1
    if ($header -match 'behind ([0-9]+)') { $flags.Add("v$($Matches[1])") }

    $aheadCount = Get-GitUnpushedCount | Select-Object -First 1
    if ($aheadCount -match '^[0-9]+$' -and [int]$aheadCount -gt 0) {
        $flags.Add("^$aheadCount")
        $changed = $true
    }

    foreach ($line in ($gitStatus | Select-Object -Skip 1)) {
        if (-not $line) { continue }
        $changed = $true
        $index = if ($line.Length -ge 1) { $line.Substring(0, 1) } else { ' ' }
        $worktree = if ($line.Length -ge 2) { $line.Substring(1, 1) } else { ' ' }

        if ($line -match '^(UU|AA|DD|AU|UA|DU|UD)') {
            if (-not $flags.Contains('x')) { $flags.Add('x') }
            continue
        }
        if ($line -like '??*') {
            if (-not $flags.Contains('?')) { $flags.Add('?') }
            continue
        }
        if ($index -ne ' ' -and -not $flags.Contains('+')) { $flags.Add('+') }
        if ($worktree -ne ' ' -and -not $flags.Contains('!')) { $flags.Add('!') }
    }

    $segment = "git:$branch"
    if ($flags.Count -gt 0) { $segment = "$segment $($flags -join '')" }
    $pr = Get-PromptPrState $prBranch

    return [pscustomobject]@{
        Segment = $segment
        Color = if ($changed) { 'FFFF00' } else { '777777' }
        Pr = $pr
    }
}

function Get-JjPromptState {
    if (-not (has jj)) { return $null }
    Invoke-ExternalCommand jj root --ignore-working-copy *> $null
    if ($LASTEXITCODE -ne 0) { return $null }

    $info = Invoke-ExternalCommand jj log --no-graph --ignore-working-copy --color=never -r '@' --template 'separate(" ", change_id.shortest(8), bookmarks.join("|"), if(conflict, "x")) ++ "\n"' 2>$null
    if (-not $info) { return $null }
    $info = $info | Select-Object -First 1

    $diffSummary = Invoke-ExternalCommand jj diff --summary --ignore-working-copy 2>$null
    $bookmark = Invoke-ExternalCommand jj log --no-graph --ignore-working-copy --color=never -r 'bookmarks() & @' --template 'bookmarks.join("\n") ++ "\n"' 2>$null | Select-Object -First 1
    if ($bookmark) { $bookmark = $bookmark -replace '\*$', '' }

    return [pscustomobject]@{
        Segment = "jj:$info"
        Color = if ($diffSummary) { 'FFFF00' } else { '777777' }
        Pr = Get-PromptPrState $bookmark
    }
}

function Get-VcsPromptState {
    $jj = Get-JjPromptState
    if ($jj) { return $jj }
    Get-GitPromptState
}

function color {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Text)
    $esc = [char]27
    $tmp = (($Text -join ' ') + '&r')
    $replacements = [ordered]@{
        '&0' = "$esc[0;30m"; '&1' = "$esc[0;34m"; '&2' = "$esc[0;32m"; '&3' = "$esc[0;36m"
        '&4' = "$esc[0;31m"; '&5' = "$esc[0;35m"; '&6' = "$esc[0;33m"; '&7' = "$esc[0;37m"
        '&8' = "$esc[1;30m"; '&9' = "$esc[1;34m"; '&a' = "$esc[1;32m"; '&b' = "$esc[1;36m"
        '&c' = "$esc[1;31m"; '&d' = "$esc[1;35m"; '&e' = "$esc[1;33m"; '&f' = "$esc[1;37m"
        '&r' = "$esc[0m"; '&n' = "`r`n"
    }
    foreach ($key in $replacements.Keys) { $tmp = $tmp.Replace($key, $replacements[$key]) }
    $tmp
}

function pcolor {
    $promptHelper = Join-Path $env:SCR 'helpers/prompt.py'
    if (Test-Path -LiteralPath $promptHelper) {
        & $promptHelper ($args -join ' ') color
    } else {
        color ($args -join ' ')
    }
}

function Convert-PromptRgbColor {
    param([Parameter(Mandatory = $true)][string]$Color)

    $namedColors = @{
        blue = '0000FF'
        cyan = '55CDFC'
        green = '00FF00'
        gray = '777777'
        magenta = 'F7A8B8'
        pink = 'F7A8B8'
        purple = 'AF87FF'
        white = 'FFFFFF'
        yellow = 'FFFF00'
    }

    $normalized = $Color.Trim().TrimStart([char]'#')
    $lower = $normalized.ToLowerInvariant()
    if ($namedColors.ContainsKey($lower)) {
        $normalized = $namedColors[$lower]
    }

    if ($normalized -notmatch '^[0-9A-Fa-f]{6}$') { return $null }

    return [pscustomobject]@{
        R = [Convert]::ToInt32($normalized.Substring(0, 2), 16)
        G = [Convert]::ToInt32($normalized.Substring(2, 2), 16)
        B = [Convert]::ToInt32($normalized.Substring(4, 2), 16)
    }
}

function Write-PromptText {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Color
    )

    $rgb = Convert-PromptRgbColor $Color
    if (-not $rgb) {
        [Console]::Write($Text)
        return
    }

    $esc = [char]27
    [Console]::Write("$esc[38;2;$($rgb.R);$($rgb.G);$($rgb.B)m$Text$esc[0m")
}

function Write-PromptAnsiText {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][int]$Code
    )

    $esc = [char]27
    [Console]::Write("$esc[$($Code)m$Text$esc[0m")
}

function global:prompt {
    $hostName = [System.Net.Dns]::GetHostName() -replace '^HyDEV-', ''
    $date = Get-Date

    [Console]::WriteLine()
    if ($hostName -eq 'HyDEV') {
        Write-PromptText ($date.ToString('ddd MM-dd HH:mm')) 'F7A8B8'
        [Console]::Write(' ')
    } else {
        Write-PromptText ($date.ToString('ddd ')) '55CDFC'
        Write-PromptText ($date.ToString('MM-')) 'F7A8B8'
        Write-PromptText ($date.ToString('dd ')) 'FFFFFF'
        Write-PromptText ($date.ToString('HH:')) 'F7A8B8'
        Write-PromptText ($date.ToString('mm ')) '55CDFC'
    }

    Write-PromptAnsiText "$hostName " 34

    if ($global:__PwshRcGitIdSegment) {
        Write-PromptAnsiText $global:__PwshRcGitIdSegment 33
    } else {
        $userName = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
        Write-PromptAnsiText "$userName " 33
    }

    if ($global:__PwshRcProxySegment) {
        Write-PromptText $global:__PwshRcProxySegment '00FF00'
    }

    [Console]::Write((pwdd))

    $vcs = Get-VcsPromptState
    if ($vcs) {
        [Console]::Write(' ')
        Write-PromptText '[' $vcs.Color
        Write-PromptText $vcs.Segment $vcs.Color
        if ($vcs.Pr) {
            Write-PromptText ' ' $vcs.Color
            Write-PromptText "#$($vcs.Pr.Number)" $vcs.Pr.Color
        }
        Write-PromptText ']' $vcs.Color
    }

    return "`n> "
}

function Start-ZshrcAutoUpdate {
    if (-not (Get-ExternalCommandPath git)) { return }
    if ($env:PWSHRC_UPDATE_DISABLED -or $env:ZSHRC_UPDATE_DISABLED) { return }
    if (-not (Test-Path -LiteralPath (Join-Path $env:ZSHRC_ROOT '.git') -PathType Container)) { return }

    $root = $env:ZSHRC_ROOT
    $remoteRef = if ($env:ZSHRC_UPDATE_REF) { $env:ZSHRC_UPDATE_REF } else { 'origin/master' }
    $verboseUpdate = [bool]$env:ZSHRC_UPDATE_VERBOSE

    Start-Job -Name "zshrc-auto-update-$PID" -ArgumentList $root, $remoteRef, $verboseUpdate -ScriptBlock {
        param([string]$Root, [string]$RemoteRef, [bool]$VerboseUpdate)

        $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $git) { return }
        $git = $git.Source

        $oldLocation = Get-Location
        Set-Location -LiteralPath $Root
        $lockDir = Join-Path $Root '.git/zshrc-update.lock'

        try {
            New-Item -ItemType Directory -Path $lockDir -ErrorAction Stop | Out-Null
        } catch {
            Set-Location -LiteralPath ($oldLocation.Path)
            return
        }

        $stashCreated = $false
        function Invoke-UpdateGit { & $git @args }
        function Test-UpdateDirty {
            Invoke-UpdateGit diff --quiet --ignore-submodules -- *> $null
            if ($LASTEXITCODE -ne 0) { return $true }
            Invoke-UpdateGit diff --cached --quiet --ignore-submodules -- *> $null
            if ($LASTEXITCODE -ne 0) { return $true }
            $others = Invoke-UpdateGit ls-files --others --exclude-standard
            return [bool]$others
        }
        function Save-UpdateStash {
            if (Test-UpdateDirty) {
                Invoke-UpdateGit stash push -u -m "zshrc auto-update before applying $RemoteRef" *> $null
                if ($LASTEXITCODE -eq 0) { $script:stashCreated = $true }
            }
        }
        function Restore-UpdateStash {
            if ($script:stashCreated) { Invoke-UpdateGit stash pop *> $null }
        }

        try {
            Invoke-UpdateGit fetch origin --quiet *> $null
            $fetched = $LASTEXITCODE -eq 0
            Invoke-UpdateGit rev-parse --verify --quiet $RemoteRef *> $null
            if ($fetched -and $LASTEXITCODE -eq 0) {
                Invoke-UpdateGit merge-base --is-ancestor HEAD $RemoteRef *> $null
                if ($LASTEXITCODE -ne 0) {
                    Save-UpdateStash
                    Invoke-UpdateGit reset --hard $RemoteRef *> $null
                    if ($LASTEXITCODE -eq 0) {
                        Invoke-UpdateGit submodule update --init --recursive --depth 1 *> $null
                        Restore-UpdateStash
                    }
                } else {
                    $updates = Invoke-UpdateGit log "HEAD..$RemoteRef" --oneline
                    if ($updates) {
                        Save-UpdateStash
                        Invoke-UpdateGit merge --ff-only $RemoteRef *> $null
                        if ($LASTEXITCODE -eq 0) {
                            Invoke-UpdateGit submodule update --init --recursive --depth 1 *> $null
                            Restore-UpdateStash
                        }
                    }
                }
            } elseif ($VerboseUpdate) {
                Write-Output 'Update check failed.'
            }
        } finally {
            Remove-Item -LiteralPath $lockDir -Force -ErrorAction SilentlyContinue
            Set-Location -LiteralPath ($oldLocation.Path)
        }
    } | Out-Null
}

if (has thefuck) {
    $thefuckAlias = Invoke-ExternalCommand thefuck --alias 2>$null
    if ($LASTEXITCODE -eq 0 -and $thefuckAlias) { Invoke-Expression ($thefuckAlias -join [Environment]::NewLine) }
}

if (Get-Module -ListAvailable -Name PSColor) {
    Import-Module PSColor
    $global:PSColor = @{
        File = @{
            Default = @{ Color = 'White' }
            Directory = @{ Color = 'Blue' }
            Hidden = @{ Color = 'DarkGray'; Pattern = '^\.' }
            Code = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html|ps1)$' }
            Executable = @{ Color = 'Red'; Pattern = '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$' }
            Text = @{ Color = 'Yellow'; Pattern = '\.(txt|cfg|conf|ini|csv|log|config|xml|yml|yaml|md|markdown)$' }
            Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war|7z)$' }
        }
        Service = @{
            Default = @{ Color = 'White' }
            Running = @{ Color = 'DarkGreen' }
            Stopped = @{ Color = 'DarkRed' }
        }
        Match = @{
            Default = @{ Color = 'White' }
            Path = @{ Color = 'Cyan' }
            LineNumber = @{ Color = 'Yellow' }
            Line = @{ Color = 'White' }
        }
        NoMatch = @{
            Default = @{ Color = 'White' }
            Path = @{ Color = 'Cyan' }
            LineNumber = @{ Color = 'Yellow' }
            Line = @{ Color = 'White' }
        }
    }
}

git-id-prompt
Start-ZshrcAutoUpdate

$extraRc = Join-Path $HOME 'extra.rc.ps1'
if (Test-Path -LiteralPath $extraRc) {
    . $extraRc
}
