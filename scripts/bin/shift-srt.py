#!/usr/bin/env python3
import argparse
from datetime import datetime, timedelta

def parse_time(s):
    return datetime.strptime(s, "%H:%M:%S,%f")

def format_time(t):
    return t.strftime("%H:%M:%S,%f")[:-3]

def shift_srt(input_path, output_path, offset_seconds):
    offset = timedelta(seconds=offset_seconds)

    with open(input_path, "r", encoding="utf-8") as infile, open(output_path, "w", encoding="utf-8") as outfile:
        for line in infile:
            if "-->" in line:
                start, end = line.strip().split(" --> ")
                new_start = format_time(parse_time(start) + offset)
                new_end = format_time(parse_time(end) + offset)
                outfile.write(f"{new_start} --> {new_end}\n")
            else:
                outfile.write(line)

def main():
    parser = argparse.ArgumentParser(description="Shift subtitle timings in an SRT file.")
    parser.add_argument("input", help="Path to the input .srt file")
    parser.add_argument("output", help="Path to the output .srt file")
    parser.add_argument("offset", type=float, help="Time offset in seconds (e.g., 2.5 or -1.25)")

    args = parser.parse_args()
    shift_srt(args.input, args.output, args.offset)

if __name__ == "__main__":
    main()
