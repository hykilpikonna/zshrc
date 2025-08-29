#!/usr/bin/env python3
"""
Use ffmpeg to compress one or more video files.

This script takes a list of video files and compresses them using the
libsvtav1 codec for video and libopus for audio. The original files
are removed after successful compression.

Usage:
    python comp.py [options] file1.mp4 file2.mov ...

Examples:
    # Compress two files with default settings (crf=36, preset=6)
    python comp.py "Screen Recording 1.mp4" "Screen Recording 2.mp4"

    # Compress all mp4 files in the current directory with a different crf
    python comp.py --crf 40 *.mp4

    # Compress a file with a different preset and crf
    python comp.py --preset 8 --crf 32 my_video.mkv
"""
from subprocess import check_call
from pathlib import Path
import argparse
import sys

def main():
    """Main function to parse arguments and compress videos."""
    parser = argparse.ArgumentParser(
        description="Compress video files using ffmpeg with libsvtav1.",
        formatter_class=argparse.RawTextHelpFormatter # To keep usage examples formatted
    )

    # Required positional argument for input files.
    # nargs='+' means one or more arguments.
    parser.add_argument(
        'files',
        nargs='+',
        help="One or more video files to compress."
    )

    # Optional, overwritable argument for CRF
    parser.add_argument(
        '--crf',
        type=int,
        default=36,
        help="Constant Rate Factor (CRF) for video quality.\n"
             "Lower is better quality. Default: 36."
    )

    # Optional, overwritable argument for preset
    parser.add_argument('--preset',
        type=int,
        default=8,
        help="Encoding preset for speed/quality trade-off.\n"
             "Higher is faster. Default: 6."
    )

    args = parser.parse_args()

    # Process each file provided on the command line
    for file_str in args.files:
        video_path = Path(file_str)

        if not video_path.exists():
            print(f"Error: File not found, skipping: {video_path}", file=sys.stderr)
            continue

        output_filename = f'{video_path.stem}.comp.av1-crf{args.crf}.mp4'
        print(f"-> Compressing '{video_path.name}'...")
        print(f"   CRF: {args.crf}, Preset: {args.preset}, Output: '{output_filename}'")

        try:
            # Construct and run the ffmpeg command
            check_call([
                'ffmpeg',
                '-hide_banner', '-i', video_path,
                '-c:v', 'libsvtav1',
                '-crf', str(args.crf),
                '-preset', str(args.preset),
                '-c:a', 'libopus',
                '-b:a', '96k', '-vbr', 'on',
                output_filename
            ])

            print(f"   Compression successful.")

            # Remove the original video after successful compression
            video_path.unlink()
            print(f"   Removed original file: '{video_path.name}'\n")

        except Exception as e:
            print(f"An error occurred while processing {video_path.name}: {e}", file=sys.stderr)
            print("   Leaving original file intact.\n", file=sys.stderr)


if __name__ == "__main__":
    main()
