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

#     ${ARC_GNU}/toolchain/arc-versions.sh [--linux-user-spec] [--auto-pull]

# The environment variable ${ARC_GNU} should point to the directory within
# which the GIT trees live.

# We checkout the desired branch for each tool. Note that these must exist or
# we fail.

# Parse options
until
opt=$1
case ${opt} in
    --auto-pull)
	autopull=$1
	;;

    --linux-user-spec)
	linux_user_spec=$1
	;;

    ?*)
	echo "Usage: ./arc-versions.sh [--linux-user-spec] [--auto-pull]"
	exit 1
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done

# Specify the versions to use as a string <tool>:<branch>. These are the
# development versions for the ARC 4.4 tool chain release.
cgen="cgen:arc_4_4-cgen-1_0-dev"
binutils="binutils:arc_4_4-binutils-2_19-dev"
gcc="gcc:arc_4_4-gcc-4_4-dev"
gdb="gdb:arc_4_4-gdb-6_8-dev"
newlib="newlib:arc_4_4-newlib-1_17-dev"
uclibc="uClibc:arc_4_4-uClibc-0_9_30-dev"

# Only checkout the Linux repo if it wasn't specified by the user
if [ "x${linux_user_spec}" = "x" ]
then
    echo "Checking out default Linux"
    linux="linux:stable-arc-3.2"
fi

for version in ${cgen} ${binutils} ${gcc} ${gdb} ${newlib} ${uclibc} ${linux}
do
    tool=`echo ${version} | cut -d ':' -f 1`
    branch=`echo ${version} | cut -d ':' -f 2`

    cd ${ARC_GNU}/${tool}
    if git checkout ${branch}
    then
	if [ "x${autopull}" = "x--auto-pull" ]
	then
	    git pull
	fi
    else
	exit 1
    fi
done
