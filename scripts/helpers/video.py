#!/usr/bin/env python3
from __future__ import annotations

import os
import platform
import re
from subprocess import Popen
import sys
import shlex
from datetime import datetime
from pathlib import Path


def comp(input: str = 'latest', proc: str = 'cpu', codec: str = 'x264', crf: int = 24, br: int = None,
         cmd: bool = False, aargs: str = '', suffix: str = 'mp4'):
    """
    Compress video

    :param input: Input file (Default: latest)
    :param proc: cpu (c) or gpu (g)
    :param codec: x264 (4) or x265 (5)
    :param crf: CRF (quality) for cpu encoding
    :param cmd: Whether to output command directly
    :param aargs: Additional args
    :param suffix: File suffix (Default mp4)
    :return:
    """
    if input == 'latest':
        rename()
        i = sorted([s for s in os.listdir('.') if s.startswith('Rec') and s.endswith('mov')])[-1]
    else:
        i = input

    proc = proc[0]
    codec = {'4': {'c': 'x264', 'g': 'h264'}, '5': {'c': 'x265', 'g': 'hevc'}}[codec[-1]][proc]

    out = i[:i.rindex('.')] + f'.{codec}'
    if proc == 'c':
        out += f'-{crf}'
    out += f'.{suffix}'

    c = ['ffmpeg', '-i', i]

    if proc == 'c':
        c += ['-c:v', f'lib{codec}', '-crf', str(crf)]
    elif proc == 'g':
        if platform.system() == 'Darwin':
            c += ['-c:v', f'{codec}_videotoolbox']
        else:
            c += ['-c:v', f'{codec}_nvenc', '-cq', str(crf)]
    else:
        raise AssertionError(f'Processor is invalid ({codec}[0] not in "cg")')

    if br:
        c += ['-b:v', f'{br}k', '-maxrate', f'{br}k', '-bufsize', f'2M']

    c += shlex.split(aargs) + [out]
    
    print(c)
    if not cmd:
        Popen(c).wait()


def combine(format: str, output: str | Path):
    """
    Combine videos

    :param format: Regex pattern
    :param output: Output file name
    """
    pattern = re.compile(format)

    # Find video files
    print()
    files = [f for f in os.listdir('.') if pattern.match(f)]
    print(f'Combining these files: {files}')

    if len(files) == 0:
        return print('No files to combine')

    # Write files to text
    txt = Path('./temp.txt')
    txt.write_text('\n'.join(f"file '{f}'" for f in files))

    # Infer extension
    if '.' not in output:
        output = str(Path(output).with_suffix(Path(files[0]).suffix))

    # Run FFmpeg
    print('Running FFmpeg')
    os.system(f'ffmpeg -f concat -safe 0 -i temp.txt -c copy {output}')

    # Remove temprary file
    os.remove(txt)


def rename():
    for file in os.listdir('.'):
        if file.startswith('Screen Recording ') or file.startswith('Screen Shot '):
            pre = 'Rec' if 'Recording' in file else 'Shot'
            end_index = (file.index('AM') if 'AM' in file else file.index('PM')) + 2
            datestr = file[17 if pre == 'Rec' else 12:end_index]
            dt = datetime.strptime(datestr, '%Y-%m-%d at %I.%M.%S %p')
            date = dt.strftime(f'{pre} %Y-%m-%d %H-%M' + file[end_index:])

            print(f'Renaming {file} to {date}')
            os.rename(file, date)


if __name__ == '__main__':
    if not hasattr(sys, 'ps1'):
        args = sys.argv[1:]
        if len(args) < 1:
            print('Usage: compress [rename/python code]')

        # Command to rename all screen recordings
        if args[0] == 'rename':
            rename()
            exit()

        # processor = args[0].lower().strip()
        # i = args[1]
        # crf = args[2] if len(args) > 2 else '24'
        # cmd = 'cmd' in processor
        # if cmd:
        #     processor = processor.replace('cmd', '')

        # additional_args = ' '.join(args[3:] if len(args) > 3 else [])
        print(eval(' '.join(args[0:])))
