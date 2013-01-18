#!/bin/sh

# Copyright (C) 2012 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a master script for building ARC tool chains.

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

#	SCRIPT TO RUN ARC-ELF32 and ARC-LINUX-UCLIBC REGRESSION TESTS
#       =============================================================

# This script runs the ARC regression tests for the arc-elf32- and/or
# arc-uclibc-linux- tool chains. It is designed to work with the source tree
# as organized in GitHub. The arguments have the followign meaning.

# --source-dir <source_dir>

#     The location of the ARC GNU tools source tree. If not specified, the
#     script will use the value of the ARC_GNU environment variable if
#     available.

#     If this argument is not specified, and the ARC_GNU environment variable
#     is also not set, the script will use the parent of the directory where
#     this script is installed.

# --elf32 | --no-elf32

#     If specified, run the arc-elf32- tests (default is --elf32).

# --uclibc | --no-uclibc

#     If specified, run the arc-uclibc-linux- tests (default is --uclibc).

# --big-endian

#     If specified, test the big-endian version of the tool chains
#     (i.e. arceb-elf32- and arceb-linux-uclibc-). At present this is only
#     implemented for the Linux tool chain.

# This script exits with zero if every test has passed and with non-zero value
# otherwise.

# ------------------------------------------------------------------------------
# Set default values for some options
elf32="--elf32"
uclibc="--uclibc"

# Parse options
until
opt=$1
case ${opt} in
    --source-dir)
	shift
	ARC_GNU=`(cd "$1" && pwd)`
	;;

    --elf32 | --no-elf32)
	elf32=$1
	;;

    --uclibc | --no-uclibc)
	uclibc=$1
	;;

    --big-endian)
        ARC_ENDIAN=big
        ;;
    ?*)
	echo "Usage: ./run-tests.sh [--source-dir <source_dir>]"
        echo "                      [--elf32 | --no-elf32]"
        echo "                      [--uclibc | --no-uclibc]"
        echo "                      [--big-endian]"
	exit 1
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done


# Default source directory if not already set.
if [ "x${ARC_GNU}" = "x" ]
then
    d=`dirname "$0"`
    ARC_GNU=`(cd "$d/.." && pwd)`
fi

# Little endian is default
if [ "x${ARC_ENDIAN}" = "x" ]
then
    ARC_ENDIAN=little
fi

# Set up logfile and results directories if either does not exist
mkdir -p ${ARC_GNU}/logs
mkdir -p ${ARC_GNU}/results

# Export everything needed by sub-scripts
export ARC_GNU
export ARC_ENDIAN

status=0

# Run the ELF32 tests
if [ "${elf32}" = "--elf32" ]
then
    if ! "${ARC_GNU}"/toolchain/run-elf32-tests.sh
    then
        echo "ERROR: arc-elf32- tests failed to run."
        status=1
    fi
fi

# Run the UCLIBC tests
if [ "${uclibc}" = "--uclibc" ]
then
    if ! "${ARC_GNU}"/toolchain/run-uclibc-tests.sh
    then
        echo "ERROR: arc-linux-uclibc- tests failed to run."
        status=1
    fi
fi

exit ${status}

