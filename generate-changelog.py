#!/usr/bin/env python3

import argparse
import os.path
import subprocess
import sys
import re

parser = argparse.ArgumentParser(
        description="Generate a changelog for an engineering build or RC of ARC GNU Toolchain.")
parser.add_argument("--src-dir", required=True,
        help="Root of toolchain source directories.")
parser.add_argument("--tag", required=True,
        help="Git tag of a new build.")
parser.add_argument("--max-commits", default=50, type=int,
        help="Maximum number of commits printed for one project.")

args = parser.parse_args()

repos = ["binutils", "gcc", "gdb", "newlib", "toolchain", "uClibc" ]

new_tag = args.tag

# Build an old tag. RC and eng build has different formats.
build_num_m = re.search("\D*(\d+)$", new_tag)
build_num = int(build_num_m.group(1))
old_tag = new_tag[0:build_num_m.start(1)]
if old_tag.endswith("-eng"):
    old_tag += "{0:03}".format(build_num - 1)
else:
    old_tag += str(build_num - 1)

git="git"

def git_command(*args):
    a = [git, git_dir]
    a.extend(args)
    return subprocess.check_output(a, universal_newlines=True)

for repo in repos:
    git_dir = "--git-dir=" + os.path.join(args.src_dir, repo, ".git")
    # For GDB tag is different.
    new_tag_effective = new_tag if repo != "gdb" else new_tag + "-gdb"
    old_tag_effective = old_tag if repo != "gdb" else old_tag + "-gdb"

    # First get commit ids. Use ^{} to get an ID of an actual commit, not an ID of a tag.
    new_commit_id = git_command("rev-parse", new_tag_effective + "^{}")
    old_commit_id = git_command("rev-parse", old_tag_effective + "^{}")

    # Same? Nothing to do.
    if old_commit_id == new_commit_id:
        continue

    print()
    print(repo)
    # Underline the header.
    print('-' * max(len(repo), 7))

    # Find the common base commit.
    merge_base_id = git_command("merge-base", new_tag_effective, old_tag_effective)

    # If it is the same as "old" then history is linear, no rebases, just use
    # normal `git log --oneline`.
    if merge_base_id == old_commit_id:
        log_cmd = ["log", "--oneline", "{0}..{1}".format(old_tag_effective, new_tag_effective)]
    else:
        log_cmd = ["show-branch", old_tag_effective, new_tag_effective]

    out = git_command(*log_cmd).splitlines()

    if len(out) < args.max_commits:
        print("\n".join(out))
    else:
        print("!!!Output is too long and has been truncated!!!")
        print("\n".join(out[0:args.max_commits]))

# vim: expandtab
