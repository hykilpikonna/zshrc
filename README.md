# zshrc
My zshrc

## Installation
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hykilpikonna/zshrc/HEAD/fastinstall.sh)"
```

## Ubuntu fast setup
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hykilpikonna/zshrc/HEAD/ubuntu_setup.sh)"
```

Ubuntu Install Docker:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Hykilpikonna/zshrc/HEAD/ubuntu_docker.sh)"
```

## Add SSH Keys

```sh
curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys
```

# Powershell

Run this as administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install gsudo
choco install git
```

Then, run the following:

```powershell
git clone https://github.com/hykilpikonna/zshrc
.\zshrc\pwsh.install.ps1
```
