#!/bin/sh

# Copyright (C) 2012-2015 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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

#  2. Tags all the component trees *except* toolchain.

#  3. Checks out arc-staging branch.

#  4. Merges arc-staging with -dev.

#  5. Edits arc-versions.sh so it checks out the tagged versions of all
#     components.

#  6. Commits this change and tags that commit.

# At the end, the toolchain branch will be checked out on that tag. For
# ongoing development we'll need to checkout the dev branch.

# We take a simplistic view of where ARC_GNU is
d=`pwd`
cd .. > /dev/null 2>&1
ARC_GNU=`pwd`
export ARC_GNU
cd ${d} > /dev/null 2>&1

# Get the argument
if [ $# != 1 ]
then
    echo "Usage: ./tag-release.sh <tagname>"
    exit 1
else
    tagname=$1
fi

# Default Linux directory if not already set.
if [ "x${LINUXDIR}" = "x" ]
then
    if [ -d "${ARC_GNU}"/linux ]
    then
	LINUXDIR="${ARC_GNU}"/linux
    else
	echo "ERROR: Cannot find Linux sources."
	exit 1
    fi
fi
export LINUXDIR

# Make sure we are up to date. It is possible we are detached, so pull will
# fail, but that doesn't matter.
echo "Pulling toolchain repo"
git pull > /dev/null 2>&1 || true

# Check out heads of component trees
echo "Checking out all repos"
if ! ./arc-versions.sh
then
    echo "ERROR: Failed to check out component repos."
    exit 1
fi
echo "All repos checked out"

# Sanity check that each branch has a remote
for repo in cgen binutils gcc gdb newlib uClibc toolchain linux
do
    cd ../${repo} > /dev/null 2>&1
    if ! branch=`git symbolic-ref -q HEAD --short`
    then
	echo "ERROR: $repo is in detached head mode"
	exit 1
    fi

    if ! remote=`git config branch.${branch}.remote`
    then
	echo "ERROR: branch ${branch} of ${repo} has no upstream"
	exit 1
    fi
    cd - > /dev/null 2>&1
done

# Tag each component
for repo in cgen binutils gcc gdb newlib uClibc linux
do
    cd ../${repo} > /dev/null 2>&1

    # Special case for GDB, since we can't have two identical tags in the
    # binutils-gdb repo.
    # And another special case for Linux, since it is a separate product, we
    # don't want it to be clear that this tag is for toolchian.
    case $repo in
	gdb) tag=${tagname}-gdb ;;
	linux) tag=${tag/arc-/arc-gnu-} ;;
	*) tag=$tagname
    esac

    if ! git tag ${tag}
    then
	echo "ERROR: Failed to tag ${repo}"
	exit 1
    fi

    cd - > /dev/null 2>&1
done

branch=`git symbolic-ref -q HEAD --short`

if [[ $branch != *-dev ]] ; then
    echo 'Current branch is not a *-dev branch! Cannot create a tag from it'
    exit 1
fi

# Merge with a releases branch
if ! git checkout arc-staging ; then
    echo "Failed to checkout branch arc-staging"
    exit 1
fi

if ! git merge $branch ; then
    echo "Failed to merge arc-staging with $branch"
    exit 1
fi

# Create toolchain configuration file for release
cat > config/$tagname.sh <<EOF
cgen=cgen:$tagname
binutils=binutils:$tagname
gcc=gcc:$tagname
gdb=gdb:$tagname-gdb
newlib=newlib:$tagname
uclibc=uClibc:$tagname
linux=linux:$tagname
EOF

# Now tell arc-versions.sh to use this file instead of arc-dev:
if ! sed -i \
  -e "s/^default_toolchain_config=.*$/default_toolchain_config=$tagname/" \
  arc-versions.sh
then
    echo "ERROR: Failed to edit arc-versions.sh"
    exit 1
fi

git add config/$tagname.sh

if ! git commit -a -m "Create arc-versions.sh for tag ${tagname}"
then
    echo "ERROR: Failed to commit arc-versions.sh"
    exit 1
fi

# Tag the commit
if ! git tag ${tagname}
then
    echo "ERROR: Failed to tag toolchain"
    exit 1
fi

echo "All repositories tagged as ${tagname}"

# vim: noexpandtab sts=4 ts=8:
