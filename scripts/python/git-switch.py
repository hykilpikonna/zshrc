#!/usr/bin/env python3
import os
import subprocess

print('Checking git repo...')
url = subprocess.check_output('git remote get-url origin'.split()).decode('utf-8').strip()

print(f'Current url: {url}')

if url.startswith('http'):
    print('> HTTP git remote detected, switching to SSH')
    repo = url.split('github.com/')[-1]
    print(f'> Repo detected: {repo}')
    new_url = f'git@github.com:{repo}.git'
    
elif url.startswith('git@'):
    # git@github.com:hykilpikonna/zshrc.git
    print('> SSH git remote detected, switching to HTTP')
    repo = url.split(':')[-1].split('.git')[0]
    print(f'> Repo detected: {repo}')
    new_url = f'https://github.com/{repo}'

else:
    print('Failed to detect protocol, exiting')
    exit(-1)

print(f'New URL: {new_url}')
print('> Setting new url...')
os.system(f'git remote set-url origin {new_url}')
print('> Done!')