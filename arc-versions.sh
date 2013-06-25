#!/bin/sh

# Script to specify versions of tools to use.

# Copyright (C) 2012, 2013 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This script is sourced to specify the versions of tools to be built.

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
# Usage:

#     arc-versions.sh [--auto-checkout | --no-auto-checkout]
#                     [--auto-pull | --no-auto-pull]

# The environment variable ${ARC_GNU} should point to the directory within
# which the GIT trees live.

# The environment variable ${LINUXDIR} should point to the Linux root
# directory.

# We checkout the desired branch for each tool. Note that these must exist or
# we fail.

# Default options
autocheckout="--auto-checkout"
autopull="--auto-pull"

# Parse options
until
opt=$1
case ${opt} in
    --auto-checkout | --no-auto-checkout)
	autocheckout=$1
	;;

    --auto-pull | --no-auto-pull)
	autopull=$1
	;;

    ?*)
	echo "Usage: arc-versions.sh  [--auto-checkout | --no-auto-checkout]"
        echo "                        [--auto-pull | --no-auto-pull]"
	exit 1
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done

# Specify the default versions to use as a string <tool>:<branch>. These are
# the development versions for the ARC 4.4 tool chain release. Only actually
# matters if --auto-checkout is set.
cgen="cgen:arc_4_8-evb5"
binutils="binutils:arc_4_8-evb5"
gcc="gcc:arc_4_8-evb5"
gdb="gdb:arc_4_8-evb5"
newlib="newlib:arc_4_8-evb5"
uclibc="uClibc:arc_4_8-evb5"
linux="linux:arc-3.9"

# We have to deal with some awkward cases here, because we have to deal with
# the possibility that we may currently be on a detached HEAD (so cannot
# fetch), or we will to checkout a detached HEAD (e.g. a tag). We also need to
# deal with the case that the branch we wish to checkout is not yet in the
# local repo, so we need to fetch before checking out.

# The particularly awkward case is when we are detached, and want to checkout
# a branch which is not yet in the local repo. In this case we must checkout
# some other branch, then fetch, then checkout the branch we want. This has a
# performance penalty, but only when coming from a detached branch.

# In summary the steps are:
# 1. If we are in detached HEAD state, checkout some arbitrary branch.
# 2. Fetch (in case new branch)
# 3. Checkout the branch
# 4. Pull unless we are in a detached HEAD state.

# Steps 1, 2 and 4 are only used if we have --auto-pull enabled.

# All this will go horribly wrong if you leave uncommitted changes lying
# around or if you change the remote. Nothing then but to sort it out by hand!
for version in ${cgen} ${binutils} ${gcc} ${gdb} ${newlib} ${uclibc} ${linux}
do
    tool=`echo ${version} | cut -d ':' -f 1`
    branch=`echo ${version} | cut -d ':' -f 2`

    echo "Checking out branch/tag ${branch} of ${tool}"

    # Kludge, because Linux has its own environment variable
    if [ "${tool}" = "linux" ]
    then
	cd ${LINUXDIR}
    else
	cd ${ARC_GNU}/${tool}
    fi

    if [ "x${autopull}" = "x--auto-pull" ]
    then
	if git branch | grep '\* (no branch)' > /dev/null 2>&1
	then
	    # Detached head. Checkout an arbitrary branch
	    arb_br=`git branch | grep -v '^\*' | head -1`
	    echo "  detached HEAD, interim checkout of ${arb_br}"
	    if ! git checkout ${arb_br} > /dev/null 2>&1
	    then
		exit 1
	    fi
	fi
	# Fetch any new branches
	echo "  fetching branches"
	if ! git fetch
	then
	    exit 1
	fi
	# Fetch any new tags
	echo "  fetching tags"
	if ! git fetch --tags
	then
	    exit 1
	fi
    fi

    if [ "x${autocheckout}" = "x--auto-checkout" ]
    then
	echo "  checking out ${branch}"
	if ! git checkout ${branch}
	then
	    exit 1
	fi
    fi

    if [ "x${autopull}" = "x--auto-pull" ]
    then
	if ! git branch | grep '\* (no branch)' >> /dev/null 2>&1
	then
	    # Only update to latest if we are not in detached HEAD mode.
	    echo "  pulling latest version"
	    if ! git pull
	    then
		exit 1
	    fi
	fi
    fi
done
