#!/usr/bin/env python3
import json
import sys
import time
from typing import Tuple, List


def replace_color(msg: str) -> str:
    replacements = ["&0/\033[0;30m", "&1/\033[0;34m", "&2/\033[0;32m", "&3/\033[0;36m", "&4/\033[0;31m", "&5/\033[0;35m", "&6/\033[0;33m", "&7/\033[0;37m", "&8/\033[1;30m", "&9/\033[1;34m", "&a/\033[1;32m", "&b/\033[1;36m", "&c/\033[1;31m", "&d/\033[1;35m", "&e/\033[1;33m", "&f/\033[1;37m", "&r/\033[0m", "&n/\n"]
    for r in replacements:
        msg = msg.replace(r[:2], r[3:])
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
    start_time = time.time()

    args = sys.argv[1:]
    parts_raw = args.pop(0)
    parts: List[Tuple[int, str]] = json.loads(parts_raw) if parts_raw != '' else []
    cmd = args.pop(0).lower()

    if cmd == 'show':
        show()
    elif cmd == 'debug':
        print(parts)
    elif cmd == 'set':
        order = int(args.pop(0))
        format = ' '.join(args)
        set()
    # print("--- %s seconds ---" % (time.time() - start_time), file=sys.stderr)

