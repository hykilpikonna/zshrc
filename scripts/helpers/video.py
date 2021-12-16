#!/usr/bin/env python3
import os
import sys
from datetime import datetime


def comp(input: str = 'latest', proc: str = 'cpu', codec: str = 'x264', crf: int = 24, br: int = 500,
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

    if proc == 'c':
        c = f'ffmpeg -i "{i}" -vcodec lib{codec} -crf {crf} {aargs} "{out}"'
    elif proc == 'g':
        c = f'ffmpeg -i "{i}" -c:v {codec}_videotoolbox -b:v {br}k {aargs} "{out}"'
    else:
        raise AssertionError(f'Processor is invalid ({codec}[0] not in "cg")')
    
    if cmd:
        print(c)
    else:
        os.system(c)


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
