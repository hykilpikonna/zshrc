#!/usr/bin/env python3
from __future__ import annotations
import json
import sys


def ansirgb(r: int, g: int, b: int, foreground: bool = True) -> str:
    c = '38' if foreground else '48'
    return f'\033[{c};2;{r};{g};{b}m'


def replace_color(msg: str) -> str:
    replacements = ["&0/\033[0;30m", "&1/\033[0;34m", "&2/\033[0;32m", "&3/\033[0;36m", "&4/\033[0;31m", "&5/\033[0;35m", "&6/\033[0;33m", "&7/\033[0;37m", "&8/\033[1;30m", "&9/\033[1;34m", "&a/\033[1;32m", "&b/\033[1;36m", "&c/\033[1;31m", "&d/\033[1;35m", "&e/\033[1;33m", "&f/\033[1;37m", "&r/\033[0m", "&n/\n"]
    for r in replacements:
        msg = msg.replace(r[:2], r[3:])
    
    while '&gf(' in msg or '&gb(' in msg:
        i = msg.index('&gf(') if '&gf(' in msg else msg.index('&gb(')
        end = msg.index(')', i)
        code = msg[i + 4:end]
        fore = msg[i + 2] == 'f'

        if code.startswith('#'):
            rgb = tuple(int(code.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))
        else:
            code = code.replace(',', ' ').replace(';', ' ').replace('  ', ' ')
            rgb = tuple(int(c) for c in code.split(' '))

        msg = msg[:i] + ansirgb(*rgb, foreground=fore) + msg[end + 1:]

    return msg


def show():
    parts.sort(key=lambda p: p[0])
    s = ''.join([p[1] for p in parts])
    print(replace_color(s))


def set():
    # Create new parts list
    existing = [p for p in parts if p[0] == order]
    if existing:
        parts.remove(existing[0])
    parts.append((order, format))
    print(json.dumps(parts))


if __name__ == '__main__':
    # start_time = time.time()
    args = sys.argv[1:]
    parts_raw = args.pop(0)
    cmd = args.pop(0).lower()

    if cmd == 'color':
        print(replace_color(parts_raw))
        exit()

    parts: list[tuple[int, str]] = json.loads(parts_raw) if parts_raw != '' else []

    if cmd == 'show':
        show()
    elif cmd == 'debug':
        print(parts)
    elif cmd == 'set':
        order = int(args.pop(0))
        format = ' '.join(args)
        set()
    # print("--- %s seconds ---" % (time.time() - start_time), file=sys.stderr)

