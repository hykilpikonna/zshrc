# # Install chocolatey
# if (Get-Command choco -errorAction SilentlyContinue)
# {
#     echo "Choco exists"
# }
# else
# {
#     echo "Installing choco..."
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 
#     iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# }

# function install-cmd($cmd, $pack)
# {
#     if (!$pack) { $pack = $cmd }

#     if (-Not (Get-Command $cmd -errorAction SilentlyContinue))
#     {
#         echo "$cmd doesn't exist, installing $pack..."
#         choco install $pack -y
#     } 
# }

# function install-module-safe($module)
# {
#     if (!(Get-Module -ListAvailable -Name $module)) {
#         Install-Module $module
#     }
# }

# # Install gsudo
# install-cmd gsudo
# install-cmd git
# install-cmd nano
# install-module-safe PSColor

# ln -s
function ln-s ($target, $link) {
    gsudo New-Item -Path $link -ItemType SymbolicLink -Value $target
}

# Install 
$docs = [Environment]::GetFolderPath("MyDocuments")
mkdir "$docs\WindowsPowerShell" -Force
rm "$docs\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -ErrorAction Ignore
ln-s "$HOME\zshrc\powershell.ps1" "$docs\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
mkdir "$docs\PowerShell" -Force
rm "$docs\PowerShell\Microsoft.PowerShell_profile.ps1" -ErrorAction Ignore
ln-s "$HOME\zshrc\powershell.ps1" "$docs\PowerShell\Microsoft.PowerShell_profile.ps1"