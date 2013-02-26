# Script to specify versions of tools to use.

# Copyright (C) 2012 Synopsys Inc.

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
cgen="cgen:arc_4_4-cgen-1_0-dev"
binutils="binutils:arc_4_8-binutils-2_23_1-dev"
gcc="gcc:arc_4_8-gcc-4_8-dev"
gdb="gdb:arc_4_8-gdb-7_5_1-dev"
newlib="newlib:arc_4_8-newlib-2_0-dev"
uclibc="uClibc:arc_4_8-uClibc-0_9_30-dev"
linux="linux:stable-arc-3.2"

for version in ${cgen} ${binutils} ${gcc} ${gdb} ${newlib} ${uclibc} ${linux}
do
    tool=`echo ${version} | cut -d ':' -f 1`
    branch=`echo ${version} | cut -d ':' -f 2`

    cd ${ARC_GNU}/${tool}

    if [ "x${autopull}" = "x--auto-pull" ]
    then
	# Need to fetch first, in case it is a branch that is new. But only do
	# this if we have auto-pull enabled (so we can still work if not
	# online). Assumes the remote has not changed (if it has, you'll need
	# to sort it out by hand).
	if ! git fetch
	then
	    exit 1
	fi
    fi

    if [ "x${autocheckout}" = "x--auto-checkout" ]
    then
	if ! git checkout ${branch}
	then
	    exit 1
	fi
    fi

    if [ "x${autopull}" = "x--auto-pull" ]
    then
	if ! git pull
	then
	    exit 1
	fi
    fi
done
