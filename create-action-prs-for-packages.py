#!/usr/bin/env python3
import json, subprocess
import sys

# https://api.github.com/users/gap-packages/repos?per_page=100&page=1
repos1 = '/home/sergio/projects/gap-actions/gap-packages-repos.json'
# https://api.github.com/users/gap-packages/repos?per_page=100&page=2
repos2 = '/home/sergio/projects/gap-actions/gap-packages-repos2.json'

with open(repos1, mode='r') as packages_file:
    table = json.load(packages_file)
with open(repos2, mode='r') as packages_file:
    table = table + json.load(packages_file)

# TODO make this into a for loop
entry = table[0]
subprocess.check_call('./create-action-pr.sh', entry['owner']['login'],
                      entry['name'])
