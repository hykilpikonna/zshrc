#!/usr/bin/env python3
import json
import os

import click


def color(msg: str) -> str:
    replacements = ["&0/\033[0;30m", "&1/\033[0;34m", "&2/\033[0;32m", "&3/\033[0;36m", "&4/\033[0;31m", "&5/\033[0;35m", "&6/\033[0;33m", "&7/\033[0;37m", "&8/\033[1;30m", "&9/\033[1;34m", "&a/\033[1;32m", "&b/\033[1;36m", "&c/\033[1;31m", "&d/\033[1;35m", "&e/\033[1;33m", "&f/\033[1;37m", "&r/\033[0m", "&n/\n"]
    for r in replacements:
        msg = msg.replace(r[:2], r[3:])
    return msg


@click.group()
def cli():
    pass


@cli.command()
def show():
    print(parts)


@cli.command()
def add():
    print("todo")


if __name__ == '__main__':
    # Get saved parts
    key = 'prompt-part-list'
    os.environ.setdefault(key, '{}')
    parts = os.environ.get(key)

    # Parse saved parts
    parts = json.loads(parts)

    cli()
