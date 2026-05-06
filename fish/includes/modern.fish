# Modern unix replacements.
modern-replace ls eza 'ls -h --color=auto' eza
modern-replace df duf 'df -h' duf
modern-replace cat bat cat bat
modern-replace man tldr man tldr
modern-replace top btop top btop
modern-replace nano micro nano micro
modern-replace curl curlie curl curlie
modern-replace pacman paru 'pacman --color always' 'paru --color always'
modern-replace vi nvim vi nvim
modern-replace vim nvim vim nvim
modern-replace code visual-studio-code-electron code visual-studio-code-electron

if not has docker; and has podman
    alias docker podman
    if has podman-compose
        alias docker-compose podman-compose
    end
end
