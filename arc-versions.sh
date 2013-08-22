#!/bin/sh

# Script to specify versions of tools to use.

# Copyright (C) 2012, 2013 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <akolesov@synopsys.com>

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
#                     [--auto-download | --no-auto-download]

# The environment variable ${ARC_GNU} should point to the directory within
# which the GIT trees live.

# The environment variable ${LINUXDIR} should point to the Linux root
# directory.

# We checkout the desired branch for each tool. Note that these must exist or
# we fail.

# Default options
autocheckout="--auto-checkout"
autopull="--auto-pull"
autodownload="--auto-download"

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

    --auto-download | --no-auto-download)
    autodownload=$1
    ;;

    ?*)
	echo "Usage: arc-versions.sh  [--auto-checkout | --no-auto-checkout]"
        echo "                        [--auto-pull | --no-auto-pull]"
        echo "                        [--auto-download | --no-auto-download]"
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
# the versions for the ARC tool chain release corresponding to this branch of
# the toolchain repository. Only actually matters if --auto-checkout is set.

# TODO: At present only binutils has been migrated to mainline.
cgen="cgen:arc_4_4-cgen-1_0-dev"
binutils="binutils:arc-binutils-mainline"
gcc="gcc:arc_4_8-gcc-4_8-dev"
gdb="gdb:arc-gdb-mainline"
newlib="newlib:arc_4_8-newlib-2_0-dev"
uclibc="uClibc:arc_4_8-uclibc-mainline-dev"
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

# Download dependencies if we have been asked to
if [ "x${autodownload}" = "x--auto-download" ]
then

    echo "Downloading dependencies..."
    cd ${ARC_GNU}/gcc

    # GMP 4.3.2
    if [ ! -d gmp ]; then
        echo "Getting GMP 4.3.2"
        gmp_tar=gmp-4.3.2.tar.bz2
        if [ ! -f $gmp_tar ]; then
            wget -nv ftp://ftp.gmplib.org/pub/gmp/$gmp_tar
            tar xjf $gmp_tar
        fi
        mv gmp-4.3.2 gmp
    fi
    
    # MPFR 2.4.2
    if [ ! -d mpfr ]; then
        echo "Getting MPFR 2.4.2"
        mpfr_tar=mpfr-2.4.2.tar.bz2
        if [ ! -f $mpfr_tar ]; then
            wget -nv http://www.mpfr.org/mpfr-2.4.2/$mpfr_tar
        fi
        tar xjf $mpfr_tar
        mv mpfr-2.4.2 mpfr
    fi
    
    # MPC 1.0.1
    if [ ! -d mpc ]; then
        echo "Getting MPC 1.0.1"
        mpc_tar=mpc-1.0.1.tar.gz
        if [ ! -f $mpc_tar ]; then
            wget -nv http://www.multiprecision.org/mpc/download/$mpc_tar
        fi
        tar xzf $mpc_tar
        mv mpc-1.0.1 mpc
    fi

fi

