#!/usr/bin/env python3
import os
import sys
from datetime import datetime

if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) < 2:
        print('Usage: compress [rename/cpu/gpu/cpucmd/gpucmd] <input> [crf=24] [additional args]')

    # Command to rename all screen recordings
    if args[0] == 'rename':
        for file in os.listdir('.'):
            if file.startswith('Screen Recording ') or file.startswith('Screen Shot '):
                pre = 'Rec' if 'Recording' in file else 'Shot'
                endIndex = (file.index('AM') if 'AM' in file else file.index('PM')) + 2
                datestr = file[17 if pre == 'Rec' else 12:endIndex]
                dt = datetime.strptime(datestr, '%Y-%m-%d at %I.%M.%S %p')
                date = dt.strftime(f'{pre} %Y-%m-%d %H-%M' + file[endIndex:])

                print(f'Renaming {file} to {date}')
                os.rename(file, date)

        exit()

    processor = args[0].lower().strip()
    i = args[1]
    crf = args[2] if len(args) > 2 else '24'
    out = i[:i.rindex('.')] + f'.{processor[0]}265'
    cmd = 'cmd' in processor
    if cmd:
        processor = processor.replace('cmd', '')
    if processor == 'cpu':
        out += f'-{crf}'
    out += '.mp4'
    additional_args = ' '.join(args[3:] if len(args) > 3 else [])

    if processor == 'cpu':
        c = f'ffmpeg -i "{i}" -vcodec libx265 -crf {crf} {additional_args} "{out}"'
    if processor == 'gpu':
        c = f'ffmpeg -i "{i}" -c:v hevc_videotoolbox -b:v 1000k {additional_args} "{out}"'
    
    if cmd:
        print(c)
    else:
        os.system()