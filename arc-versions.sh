#!/usr/bin/env bash

# Script to specify versions of tools to use.

# Copyright (C) 2012-2017 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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

# Environment variables DO_UCLIBC or DO_GLIBC should be set to `yes' if Linux
# toolchain is being built.

# The environment variable ${LINUXDIR} should point to the Linux root
# directory (only used if DO_UCLIBC or DO_GLIBC is set to `yes').

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

# That should be a separate variable to allow for a straightforward creation of
# new releases, where we want default to point to release, instead of dev
# branch.
default_toolchain_config=arc-2019.03-rc1

# Specify the default versions to use as a string <tool>:<branch>. Those are
# taken from the checkout configuration file. Only actually matters if
# --auto-checkout is set.
if [ -z "$CHECKOUT_CONFIG" ]
then
    CHECKOUT_CONFIG=$default_toolchain_config
fi

if echo "$CHECKOUT_CONFIG" | grep -qFe /
then
    # This is file path
    source "$CHECKOUT_CONFIG"
else
    # This is configuration name
    source "$ARC_GNU/toolchain/config/$CHECKOUT_CONFIG.sh"
fi

# Disable linux if needed
if [ ${DO_UCLIBC:-no} = yes -o ${DO_GLIBC:-no} = yes ]
then
    linux=""
fi

if [ ${DO_GLIBC:-no} = yes ]; then
    libc=$glibc
else
    libc=$uclibc
fi

# It is not safe to "pull" in the initial state, because if repository is
# currently in detached state (e.g. on a tag), then pull will fail. It is also
# not safe to checkout before fetching data, because it might be required to
# checkout branch/tag that hasn't been fetched from remote yet. Thus the
# sequence of actions is following:

# 1. Fetch
# 2. Checkout the branch/tag
# 3. Pull unless we are in a detached HEAD state.

# Steps 1 and 3 are only used if we have --auto-pull enabled.
# Step 2 is only used if we have --auto-checkout enabled.

# All this will go horribly wrong if you leave uncommitted changes lying
# around or if you change the remote. Nothing then but to sort it out by hand!
for version in ${binutils} ${gcc} ${gdb} ${newlib} ${libc} ${linux}
do
    tool=`echo ${version} | cut -d ':' -f 1`
    branch=`echo ${version} | cut -d ':' -f 2`

    echo "Checking out branch/tag ${branch} of ${tool}"

    # Kludge, because Linux has its own environment variable. Note that the
    # tool can only be "linux" if Linux toolchain is being built.
    if [ "${tool}" = "linux" ]
    then
	cd ${LINUXDIR}
    else
	cd ${ARC_GNU}/${tool}
    fi

    if [ "x${autopull}" = "x--auto-pull" ]
    then
	# Fetch any new tags and branches.
	# Note the usage of --all. Without this option and without explicit
	# remote name `git fetch` will succeed only if there is remote named
	# "origin", and it will fetch only it (which might be really not what
	# is desired). And if there is no remote named "origin" then `git
	# fetch` will fail even if there is only a single remote in git
	# configuration.
	echo "  fetching tags"
	if ! git fetch --tags --all
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
	# Only update to latest if we are not in detached HEAD mode.
	# If tree is in detahed state, output differs between Git versions:
	# Git >=2.4 prints: *(HEAD detached at <tag_name>)
	# Git 1.8-2.3 prints: * (detached from <tag_name>)
	# Git <1.8 prints: * (no branch)
	if ! git branch | grep -q -e '\* (HEAD detached at .*)' \
	    -e '\* (detached from .*)' -e '\* (no branch)'
	then
	    echo "  pulling latest version"
	    if ! git pull
	    then
		exit 1
	    fi
	fi
    fi
done

# vim: noexpandtab sts=4 ts=8:
