set-alias ll ls
set-alias mamba micromamba

function su { powershell Start-Process powershell -Verb runAs }
function pwdd { $("$PWD".replace($HOME, '~')) }

# ln -s
function ln-s ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

# Paths
$env:path = "$env:path" + 
    ";C:\users\me\appdata\roaming\python\python39\scripts" + 
    ";C:\Users\me\AppData\Roaming\npm" +
    ";C:\Users\me\AppData\Local\Yarn\bin" +
    ";C:\Programs\bin"


# Python versions
set-alias python3.9 C:\"Program Files"\Python39\python.exe
set-alias pip3.9 C:\"Program Files"\Python39\Scripts\pip3.exe
set-alias python3.10 C:\Python310\python.exe
set-alias python3.10 C:\Python310\Scripts\pip3.exe

# Video tools
function vcompy() {
    ipython -i $HOME\zshrc\scripts\helpers\video.py
}

# Minecraft coloring
function color($tmp) {
    $033 = [char]27 
    $tmp = "$tmp&r"
    $tmp = $tmp.replace("&0", "$033[0;30m")
    $tmp = $tmp.replace("&1", "$033[0;34m")
    $tmp = $tmp.replace("&2", "$033[0;32m")
    $tmp = $tmp.replace("&3", "$033[0;36m")
    $tmp = $tmp.replace("&4", "$033[0;31m")
    $tmp = $tmp.replace("&5", "$033[0;35m")
    $tmp = $tmp.replace("&6", "$033[0;33m")
    $tmp = $tmp.replace("&7", "$033[0;37m")
    $tmp = $tmp.replace("&8", "$033[1;30m")
    $tmp = $tmp.replace("&9", "$033[1;34m")
    $tmp = $tmp.replace("&a", "$033[1;32m")
    $tmp = $tmp.replace("&b", "$033[1;36m")
    $tmp = $tmp.replace("&c", "$033[1;31m")
    $tmp = $tmp.replace("&d", "$033[1;35m")
    $tmp = $tmp.replace("&e", "$033[1;33m")
    $tmp = $tmp.replace("&f", "$033[1;37m")
    $tmp = $tmp.replace("&r", "$033[0m")
    $tmp = $tmp.replace("&n", "`r`n")
    $tmp
}

function prompt
{
    color ("&n" +
    "&5$(get-date -UFormat "%a %m-%d %H:%M") &1$($env:computername) &eAzalea &r$(pwdd)&n" +
    "> ")
}

function cropv($file, $len)
{
    ffmpeg -i $file -filter:v "crop=$(len):1440:$([math]::floor((2560-$len)/2)):0" out.mp4
}

function mp3v0 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$inputFile
    )

    # Extract file name without extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)

    # Set output filename
    $outputFile = "$baseName.mp3"

    # Run ffmpeg with specified arguments
    ffmpeg -i "$inputFile" -c:a libmp3lame -q:a 0 "$outputFile"
}


# ls coloring
if (Get-Module -ListAvailable -Name PSColor) {
    Import-Module PSColor
    $global:PSColor = @{
        File = @{
            Default    = @{ Color = 'White' }
            Directory  = @{ Color = 'Blue'}
            Hidden     = @{ Color = 'DarkGray'; Pattern = '^\.' } 
            Code       = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html)$' }
            Executable = @{ Color = 'Red'; Pattern = '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$' }
            Text       = @{ Color = 'Yellow'; Pattern = '\.(txt|cfg|conf|ini|csv|log|config|xml|yml|md|markdown)$' }
            Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war)$' }
        }
        Service = @{
            Default = @{ Color = 'White' }
            Running = @{ Color = 'DarkGreen' }
            Stopped = @{ Color = 'DarkRed' }     
        }
        Match = @{
            Default    = @{ Color = 'White' }
            Path       = @{ Color = 'Cyan'}
            LineNumber = @{ Color = 'Yellow' }
            Line       = @{ Color = 'White' }
        }
        NoMatch = @{
            Default    = @{ Color = 'White' }
            Path       = @{ Color = 'Cyan'}
            LineNumber = @{ Color = 'Yellow' }
            Line       = @{ Color = 'White' }
        }
    }
}
