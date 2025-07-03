#!/usr/bin/env python3
import argparse
from datetime import datetime, timedelta
from pathlib import Path

def parse_time(s):
    return datetime.strptime(s, "%H:%M:%S,%f")

def format_time(t):
    return t.strftime("%H:%M:%S,%f")[:-3]

def shift_srt_in_memory(input_path: Path, offset_seconds: float, output_path: Path = None):
    offset = timedelta(seconds=offset_seconds)

    lines = input_path.read_text(encoding="utf-8").splitlines(keepends=True)

    shifted_lines = []
    for line in lines:
        if "-->" in line:
            start, end = line.strip().split(" --> ")
            new_start = format_time(parse_time(start) + offset)
            new_end = format_time(parse_time(end) + offset)
            shifted_lines.append(f"{new_start} --> {new_end}\n")
        else:
            shifted_lines.append(line)

    target_path = output_path if output_path else input_path
    target_path.write_text("".join(shifted_lines), encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(description="Shift subtitle timings in an SRT file.")
    parser.add_argument("input", type=Path, help="Path to the input .srt file")
    parser.add_argument("offset", type=float, help="Time offset in seconds (e.g., 2.5 or -1.25)")
    parser.add_argument("-o", "--output", type=Path, help="Optional output file. If not provided, input file is overwritten.")

    args = parser.parse_args()
    shift_srt_in_memory(args.input, args.offset, args.output)

if __name__ == "__main__":
    main()
