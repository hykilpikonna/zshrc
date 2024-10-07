#!/usr/bin/env python3
import os
from pathlib import Path
import re
from shutil import which
import subprocess
import argparse
from datetime import datetime

def get_uptime():
    with open('/proc/uptime', 'r') as f:
        uptime_seconds = float(f.readline().split()[0])
        uptime_days = int(uptime_seconds // (60 * 60 * 24))
        return f"{uptime_days}d"

def get_load_average():
    load1, load5, _ = os.getloadavg()
    return f"{load1:.2f} {load5:.2f}"

def get_memory_usage():
    with open('/proc/meminfo', 'r') as f:
        meminfo = f.readlines()
    total_mem = int(meminfo[0].split()[1])
    free_mem = int(meminfo[1].split()[1])
    used_mem = total_mem - free_mem
    used_percent = (used_mem / total_mem) * 100
    return f"{used_percent:.2f}%"

def get_cpu_usage():
    # Parse /proc/stat to calculate CPU usage
    with open('/proc/stat', 'r') as f:
        cpu_line = f.readline().split()
    total_time = sum(map(int, cpu_line[1:]))
    idle_time = int(cpu_line[4])
    usage_time = total_time - idle_time
    cpu_usage_percent = (usage_time / total_time) * 100
    return f"{cpu_usage_percent:.2f}%"

def get_ip_address():
    try:
        # Get the name of the default network interface
        route_output = subprocess.check_output(["ip", "route"]).decode("utf-8")
        
        # Find the line containing "default" and extract the interface name
        for line in route_output.splitlines():
            if line.startswith("default"):
                interface = line.split()[4]  # The interface is the 5th word in the line
        
        # Get the IP address of the default interface
        addr_output = subprocess.check_output(["ip", "addr", "show", interface]).decode("utf-8")
        
        # Find the line containing "inet " and extract the IP address
        for line in addr_output.splitlines():
            if "inet " in line:
                ip_address = line.split()[1].split('/')[0]  # Get the IP address before the "/"
                return ip_address
        
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e}")
        return None

def get_hardware_info(cpu=False, gpu=False):
    # Check if command exist
    fastfetch = which('fastfetch') or Path(__file__).parent / 'fastfetch'
    try:
        cpu_str, gpu_str = '', ''
        if cpu:
            # Fetch CPU info
            cpu_info = subprocess.run([fastfetch, '--logo', 'none', '-s', 'CPU'], stdout=subprocess.PIPE)
            cpu_str = cpu_info.stdout.decode().splitlines()[0].strip()
            # cpu_str = cpu_str.split(':', 1)[1].split('@', 1)[0].strip()
            cpu_str = cpu_str.split(':', 1)[1].strip()

        if gpu:
            # Fetch GPU info
            gpu_info = subprocess.run([fastfetch, '--logo', 'none', '-s', 'GPU'], stdout=subprocess.PIPE)
            gpu_str = gpu_info.stdout.decode().splitlines()[0].strip()
            gpu_str = gpu_str.split(':', 1)[1].strip()
            
            gpu_str = re.sub(r'lite hash rate', 'LHR', gpu_str, flags=re.IGNORECASE)
        
        # Remove manufacturer keywords
        kw = ['Intel', 'AMD', 'NVIDIA', 'GeForce', 'Radeon', '(R)', 'Series', 'Processor', 'Graphics', 'GPU', 'CPU', ',', 'Inc', ' .', '. ', 'Family']
        def norm(str) -> str:
            for k in kw:
                str = str.replace(k, '')
            while '  ' in str:
                str = str.replace('  ', ' ')
            # Remove repeated words
            str = ' '.join(dict.fromkeys(str.split()))
            return str.strip()

        return " ".join(v for v in [norm(cpu_str), norm(gpu_str)] if v)
    except Exception as e:
        return "Unable to fetch hardware info"

def align_length(str1, str2):
    max_len = max(len(str1), len(str2))
    return str1.ljust(max_len), str2.ljust(max_len)


rows = [[
    lambda: datetime.now().strftime("%a %m-%d"),  # Date
    lambda: datetime.now().strftime("%H:%M"),     # Time
    lambda: "",                                   # None
    lambda: "",                                   # None
    lambda: os.uname()[1],                        # Hostname
    lambda: "Be happy!"                           # Fixed message
], [
    lambda: get_cpu_usage(),                      # CPU %
    lambda: get_uptime(),                         # Uptime
    lambda: get_hardware_info(cpu=True),
    lambda: get_hardware_info(gpu=True),
    lambda: get_ip_address(),                     # IP address
    lambda: get_memory_usage()                    # Memory %
]]

def get_row_data(index, row):
    return rows[row - 1][index]()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Status Bar Alignment Tool')
    parser.add_argument('index', type=int, help='Index of the element (0-4)')
    parser.add_argument('row', type=int, help='Row of the element (1 or 2)')
    
    args = parser.parse_args()

    # Fetch data from both rows for alignment
    row1_data = get_row_data(args.index, 1)
    row2_data = get_row_data(args.index, 2)

    # Align both elements to have the same length
    aligned_row1, aligned_row2 = align_length(row1_data, row2_data)

    if args.row == 1:
        print(aligned_row1)
    elif args.row == 2:
        print(aligned_row2)
