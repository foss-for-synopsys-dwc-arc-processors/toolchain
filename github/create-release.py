#!/usr/bin/env python3

# Copyright (C) 2015-2016 Synopsys Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

import argparse
import logging

import ghapi

logging.basicConfig(level=logging.INFO)

parser = argparse.ArgumentParser()
parser.add_argument("assets", nargs="*")
parser.add_argument("--owner", required=True)
parser.add_argument("--project", required=True)
parser.add_argument("--tag", required=True)
parser.add_argument("--release-id", help="Tag name without prefix and suffix")
parser.add_argument("--name", required=True)
parser.add_argument("--description", default="")
parser.add_argument("--md5sum-file", help="File with md5sums for uploaded assets")
parser.add_argument("--draft", action="store_true", default=False)
parser.add_argument("--prerelease", action="store_true", default=False)
parser.add_argument("--oauth-token", required=True)

args = parser.parse_args()

# Download table.
if args.release_id is not None:
    url = "//github.com/{0}/{1}/releases/download/{2}".format(args.owner, args.project, args.tag)
    fformat = "[{t}](" + url + "/arc_gnu_{release}_prebuilt_{type}_{cpu}_{host}_install.tar.gz)"
    ide_fformat = "[{t}](" + url + "/arc_gnu_{release}_ide_{host}_install.{ext})"
    le = "Little endian"
    be = "Big endian"

    args.description += """
|                     | Linux x86_64 | Windows x86_64 | macOS x86_64 | Linux ARC HS |
| ------------------- | ------------ | -------------- | ------------ | ------------ |
| Baremetal           | {0} \ {1}    |                | {2} \ {3}    | |
| Linux/uClibc ARC700 | {4} \ {5}    | | | |
| Linux/uClibc ARC HS | {6} \ {7}    |                | {8} \ {9}    | {10}         |
| IDE                 | {11}         | {12}           | | |
    """.format(
            fformat.format(t=le, release=args.release_id, type="baremetal", cpu="le", host="linux"),
            fformat.format(t=be, release=args.release_id, type="baremetal", cpu="be", host="linux"),
            fformat.format(t=le, release=args.release_id, type="baremetal", cpu="le", host="macos"),
            fformat.format(t=be, release=args.release_id, type="baremetal", cpu="be", host="macos"),
            fformat.format(t=le, release=args.release_id, type="uclibc", cpu="le_arc700",
                host="linux"),
            fformat.format(t=be, release=args.release_id, type="uclibc", cpu="be_arc700",
                host="linux"),
            fformat.format(t=le, release=args.release_id, type="uclibc", cpu="le_archs",
                host="linux"),
            fformat.format(t=be, release=args.release_id, type="uclibc", cpu="be_archs",
                host="linux"),
            fformat.format(t=le, release=args.release_id, type="uclibc", cpu="le_archs",
                host="macos"),
            fformat.format(t=be, release=args.release_id, type="uclibc", cpu="be_archs",
                host="macos"),
            fformat.format(t=le, release=args.release_id, type="uclibc", cpu="le_archs",
                host="native"),
            ide_fformat.format(t="Download", release=args.release_id, host="linux", ext="tar.gz"),
            ide_fformat.format(t="Download", release=args.release_id, host="win", ext="exe"))

if args.md5sum_file is not None:
    with open(args.md5sum_file, "r") as f:
        text = f.read()
        args.description = args.description + "\n```\n" + text + "\n```"

gh_conn = ghapi.GitHubApi(args.owner, args.project, args.oauth_token)
release_id = gh_conn.create_release(args.tag, args.name, args.description,
        args.draft, args.prerelease)

for asset in args.assets:
    gh_conn.upload_asset(release_id, asset)

# vi: set expandtab sw=4:
