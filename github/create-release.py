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
parser.add_argument("assets", nargs="+")
parser.add_argument("--owner", required=True)
parser.add_argument("--project", required=True)
parser.add_argument("--tag", required=True)
parser.add_argument("--name", required=True)
parser.add_argument("--description", default="")
parser.add_argument("--md5sum-file", help="File with md5sums for uploaded assets")
parser.add_argument("--draft", action="store_true", default=False)
parser.add_argument("--prerelease", action="store_true", default=False)
parser.add_argument("--oauth-token", required=True)

args = parser.parse_args()

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
