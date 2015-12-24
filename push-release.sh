#!/usr/bin/env bash

# Script to specify versions of tools to use.

# Copyright (C) 2012-2015 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

# This script is used to push tag for a particular release.

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

# Push tag to github.

# Usage:

#     ./push-release.sh <tagname>

# Tags should be already created either with tag-release.sh or manually. This
# scrips used to be part of tag-release.sh, but has been extracted, because
# sometimes it is required to do some changes after tag has been created and it
# is easier to do so without pushing.

# Get the argument
if [ $# != 1 ]
then
    echo "Usage: ./push-release.sh <tagname>"
    exit 1
else
    tagname=$1
fi

# Push the tags for each component
for repo in cgen binutils gcc gdb newlib uClibc toolchain linux
do
    cd ../${repo} > /dev/null 2>&1
    # Repositories are likely to be in detached state and `git symbolic-ref
    # HEAD` will show nothing. So unlike ./tag-release.sh we use much uglier
    # way to find remote name. Don't forget to cut off first two chars off
    # "branch" output. Better solutions here are welcomed!
    branch=`git branch --contains HEAD | grep -v '* (' | head -n1`
    remote=`git config branch.${branch:2}.remote`

    # Special case for GDB, since we can't have two identical tags in the
    # binutils-gdb repo.
    # For toolchain we also want to push the branch itself, because
    # tag-release.sh updates it.
    case $repo in
	gdb) to_push=${tagname}-gdb ;;
	linux) to_push=${tagname/arc-/arc-gnu-} ;;
	toolchain) to_push="$tagname arc-staging" ;;
	*) to_push=$tagname ;;
    esac

    if ! git push $remote $to_push
    then
	echo "ERROR: Failed to push tag for ${repo}"
	exit 1
    fi

    cd - > /dev/null 2>&1
done

echo "Pushed tag $tagname for all repositories"

# vim: noexpandtab sts=4 ts=8:
