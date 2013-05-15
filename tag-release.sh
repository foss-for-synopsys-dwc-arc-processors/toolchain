#!/bin/sh

# Script to specify versions of tools to use.

# Copyright (C) 2012, 2013 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This script is used to tag a particular release.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.          

# -----------------------------------------------------------------------------

# Tag all the current HEADs of releases for testing.

# Usage:

#     ./tag-release.sh <tagname>

# For each repository, the branch chosen by arc-versions.sh will be tagged,
# and that branch MUST have an associated upstream.

# This does the following steps

#  1. Run arc-versions.sh to checkout the heads of all component trees

#  2. Tags and pushes the tag for all the component trees *except* toolchain.

#  3. Goes into 'detached head' mode for the current head of the toolchain tree.

#  4. Edits arc-versions.sh so it checks out the tagged versions of all
#     components.

#  5. Commits this change, tags that commit and pushes that tag.

# At the end, the toolchain branch will be checked out on that tag. For
# ongoing development we'll need to checkout the dev branch.

# We take a simplistic view of where ARC_GNU is
pushd .. > /dev/null 2>&1
export ARC_GNU=`pwd`
popd > /dev/null 2>&1

# Get the argument
if [ $# != 1 ]
then
    echo "Usage: ./tag-release.sh <tagname>"
    exit 1
else
    tagname=$1
fi

# Check out heads of component trees
echo "Checking out all repos"
if ! ./arc-versions.sh
then
    echo "ERROR: Failed to check out component repos."
    exit 1
fi
echo "All repos checked out"

# Sanity check that each branch has a remote
for repo in cgen binutils gcc gdb newlib uClibc toolchain
do
    pushd ../${repo} > /dev/null 2>&1
    if ! branch=`git symbolic-ref -q HEAD --short`
    then
	echo "ERROR: $repo is in detached head mode"
	exit 1
    fi

    if ! remote=`git config branch.${branch}.remote`
    then
	echo "ERROR: branch ${branch} of ${repo} has no uptream"
	exit 1
    fi
    popd > /dev/null 2>&1
done

# Tag and push the tags for each component (not Linux)
for repo in cgen binutils gcc gdb newlib uClibc
do
    pushd ../${repo} > /dev/null 2>&1
    branch=`git symbolic-ref -q HEAD --short`
    remote=`git config branch.${branch}.remote`

    if ! git tag ${tagname}
    then
	echo "ERROR: Failed to tag ${repo}"
	exit 1
    fi

    if ! git push ${remote} ${tagname}
    then
	echo "ERROR: Failed to push tag for ${repo}"
	exit 1
    fi

    popd  > /dev/null 2>&1
done

# Get the remote for the current toolchain branch
branch=`git symbolic-ref -q HEAD --short`
remote=`git config branch.${branch}.remote`

# Go into detached head mode for the toolchain repo.
git checkout `git log -1 --pretty=format:%H`

# Edit arc-versions.sh and commit it (still detached)
if ! sed -i -e "s/\(^[[:alpha:]]*=[^:]*:\).*/\1${tagname}\"/" \
    arc-versions.sh
then
    echo "ERROR: Failed to edit arc-versions.sh"
    exit 1
fi

if ! git commit -a -m "Create arc-versions.sh for tag ${tagname}"
then
    echo "ERROR: Failed to commit arc-versions.sh"
    exit 1
fi

# Tag and push the commit
if ! git tag ${tagname}
then
    echo "ERROR: Failed to tag toolchain"
    exit 1
fi

if ! git push ${remote} ${tagname}
then
    echo "ERROR: Failed to push tag for toolchain"
    exit 1
fi

echo "All repositories tagged as ${tagname}"
