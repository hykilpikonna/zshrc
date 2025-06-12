## Notes to myself

```sh
bash <(curl -sL hydev.org/zsh)
curl -L https://github.com/Hykilpikonna.keys > ~/.ssh/authorized_keys
```

## Powershell

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
