# Sync Rime user config on Windows (Weasel)

Rime user data on Windows (Weasel frontend) lives in a directory chosen at
first deployment, recorded in the registry:

    HKCU\Software\Rime\Weasel  ->  RimeUserDir (REG_SZ)

Fallback (when the key/value is missing): `%APPDATA%\Rime`
(see `WeaselUtility.cpp` in rime/weasel: `WeaselUserDataPath()`).

This repo keeps the Rime config (shared with Linux/macOS) in
`<repo>/config-sync/.config/ibus/rime`. On Windows we link the Weasel user
dir to it with a directory junction (no admin rights needed, unlike
symbolic links).

## Manual setup

```powershell
# 1. Read the current user dir (or use the fallback)
$reg = Get-ItemProperty -Path 'HKCU:\Software\Rime\Weasel' -Name RimeUserDir -ErrorAction SilentlyContinue
$rimeDir = if ($reg -and $reg.RimeUserDir) { $reg.RimeUserDir } else { Join-Path $env:APPDATA 'Rime' }

# 2. Move any existing data aside, then create the junction
Move-Item $rimeDir "$rimeDir.bak"
New-Item -ItemType Junction -Path $rimeDir -Value '<repo>\config-sync\.config\ibus\rime'

# 3. Restart Weasel (right-click tray icon -> Exit, then start "WeaselServer")
```

`powershell.ps1` automates this at startup via `Sync-WeaselRimeConfig`
(Windows only): it resolves the user dir from the registry, backs up an
existing real directory as `Rime.bak`, and creates the junction when the
path is not already a reparse point. It is skipped when the repo checkout
does not exist (e.g. minimal Windows accounts without the zshrc repo).
