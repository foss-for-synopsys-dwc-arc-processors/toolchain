#!/bin/sh

# Copyright (C) 2012,2013 Synopsys Inc.

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

# Invocation Syntax

#     run-tests.sh [--source-dir <source_dir>]  [--target <address>]
#                  [--jobs <count>] [--load <load>][--single-thread]
#                  [--elf32 | --no-elf32] [--uclibc | --no-uclibc]
#                  [--big-endian]

# --source-dir <source_dir>

#     The location of the ARC GNU tools source tree. If not specified, the
#     script will use the value of the ARC_GNU environment variable if
#     available.

#     If this argument is not specified, and the ARC_GNU environment variable
#     is also not set, the script will use the parent of the directory where
#     this script is installed.

# --elf32-target-board <board>

#     The board description for the ELF32 target. This should either be a
#     standard DejaGnu board, or a board in the dejagnu/baseboards directory
#     of the toolchain repository. Default value arc-sim

# --uclibc-target-board <board>

#     The board description for the UCLIBC target. This should either be a
#     standard DejaGnu board, or a board in the dejagnu/baseboards directory
#     of the toolchain repository. Default value arc-linux-aa4

# --elf32-target-addr <address>

#     The address of the ELF32 target, either symbolic, or as an IP
#     address. By default no value is set.

# --uclibc-target-addr <address>

#     The address of the UCLIBC target, either symbolic, or as an IP
#     address. The default is aa4-32.

# --jobs <count>

#     Specify that parallel make should run at most <count> jobs. The default
#     is <count> equal to one more than the number of processor cores shown by
#     /proc/cpuinfo.

# --load <load>

#     Specify that parallel make should not start a new job if the load
#     average exceed <load>. The default is <load> equal to one more than the
#     number of processor cores shown by /proc/cpuinfo.

# --single-thread

#     Equivalent to --jobs 1 --load 1000. Only run one job at a time, but run
#     whatever the load average.

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
ARC_TEST_BOARD_ELF32=arc-sim
ARC_TEST_BOARD_UCLIBC=arc-linux-aa4
ARC_TEST_ADDR_ELF32=
ARC_TEST_ADDR_UCLIBC=aa4_32
make_load="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
jobs=${make_load}
load=${make_load}
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

    --elf32-target-board)
	shift
	ARC_TEST_BOARD_ELF32=$1
	;;

    --uclibc-target-board)
	shift
	ARC_TEST_BOARD_UCLIBC=$1
	;;

    --elf32-target-addr)
	shift
	ARC_TEST_ADDR_ELF32=$1
	;;

    --uclibc-target-addr)
	shift
	ARC_TEST_ADDR_UCLIBC=$1
	;;

    --jobs)
	shift
	jobs=$1
	;;

    --load)
	shift
	load=$1
	;;

    --single-thread)
	jobs=1
	load=1000
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
        echo "                      [--elf32-target-board <board>]"
        echo "                      [--uclibc-target-board <board>]"
        echo "                      [--elf32-target-addr <address>]"
        echo "                      [--uclibc-target-addr <address>]"
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

# Parallelism
PARALLEL="-j ${jobs} -l ${load}"

# Generic release set up, which we'll share with sub-scripts. This defines
# (and exports RELEASE, LOGDIR and RESDIR, creating directories named $LOGDIR
# and $RESDIR if they don't exist.
. "${ARC_GNU}"/toolchain/define-release.sh

# Export everything needed by sub-scripts
export ARC_TEST_BOARD_ELF32
export ARC_TEST_BOARD_UCLIBC
export ARC_TEST_ADDR_ELF32
export ARC_TEST_ADDR_UCLIBC

export ARC_GNU
export ARC_ENDIAN
export PARALLEL

status=0

# Run the ELF32 tests
if [ "${elf32}" = "--elf32" ]
then
    if ! "${ARC_GNU}"/toolchain/run-elf32-tests.sh
    then
        echo "ERROR: arc-elf32- tests failed to run"
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

