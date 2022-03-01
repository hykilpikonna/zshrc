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

# Powershell
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Hykilpikonna/zshrc/HEAD/pwsh.install.ps1'))
```
