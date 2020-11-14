#!/usr/bin/env python3
import json, subprocess
import sys

CI_file_location = \
    '/home/sergio/projects/gap-actions/template-workflow-ci-file/CI.yml'
# TODO: get the json files from
# https://api.github.com/users/gap-packages/repos?per_page=100&page=1
# etc
repos1 = '/home/sergio/projects/gap-actions/gap-packages-repos.json'
repos2 = '/home/sergio/projects/gap-actions/gap-packages-repos2.json'

with open(repos1, mode='r') as packages_file:
    table = json.load(packages_file)
with open(repos2, mode='r') as packages_file:
    table = table + json.load(packages_file)

entry = table[0]
subprocess.check_call('./create-action-pr.sh', CI_file_location,
                      entry['name'], entry['full_name'])
