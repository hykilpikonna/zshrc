#!/bin/zsh
/home/azalea/.pyenv/shims/python -m jupyter lab \
    --notebook-dir=/home/azalea/Desktop/Replication \
    --no-browser \
    --ServerApp.password='sha1:c63de8bd7c4a:c1f4a1234608b7032f51277abf7d9da8703d24d6' \
    --ServerApp.port=8349 \
    --ServerApp.allow_origin='*'