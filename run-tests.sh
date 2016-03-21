#!/bin/sh

# Copyright (C) 2012-2016 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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
#                  [--big-endian | --little-endian]
#                  [--multilib-options <options>]

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

# --elf32-nsim-props <path/to/nsim/props/file>

#    Path to file with nSIM properties. Examples can be found in
#    $NSIM_HOME/systemc/configs. The default value is
#    $NSIM_HOME/systemc/configs/nsim_a700.props. Make sure that props files
#    matches multilib and endian options. This option makes sense only when
#    target board is arc-nsim.

# --elf32-nsim-tcf <path/to/nsim/tcf/file>

#    Kind of like the --elf32-nsim-props, but specifies tcf file instead. If
#    this option is set, then --elf32-nsim-props will be ignored.

# --elf32-hostlink-library <path/to/hostlink/library>

#    Path to hostlink library archive. Required for test runs with Metaware.

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

# --big-endian | --little-endian

#     If --big-endian is specified, test the big-endian version of the tool
#     chains (i.e. arceb-elf32- and arceb-linux-uclibc-), otherwise test the
#     little endin versions.

# --multilib-options <options>

#     Additional options for compiling to allow multilib variants to be
#     tested.

# --binutils | --no-binutils
# --gas | --no-gas
# --ld | --no-ld
# --gcc | --no-gcc
# --libgcc | --no-libgcc
# --libgloss | --no-libgloss
# --newlib | --no-newlib
# --libstdc++ | --no-libstdc++
# --sim | --no-sim
# --gdb | --no-gdb

#     Specify which tests are to be run. By default all are enabled except
#     libgcc, libgloss and sim, for which no tests currently exist.

# This script exits with zero if every test has passed and with non-zero value
# otherwise.

# ------------------------------------------------------------------------------
# Set default values for some options
ARC_TEST_BOARD_ELF32=arc-sim
ARC_TEST_BOARD_UCLIBC=arc-linux-aa4
ARC_TEST_ADDR_ELF32=
ARC_TEST_ADDR_UCLIBC=aa4_32
ARC_MULTILIB_OPTIONS=""
ARC_NSIM_PROPS="${NSIM_HOME}/systemc/configs/nsim_a700.props"
ARC_NSIM_TCF="${NSIM_HOME}/etc/tcf/templates/hs36.tcf"
ARC_HOSTLINK_LIBRARY=
make_load="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
jobs=${make_load}
load=${make_load}
elf32="--elf32"
uclibc="--uclibc"
DO_BINUTILS="yes"
DO_GAS="yes"
DO_LD="yes"
DO_GCC="yes"
DO_LIBGCC="no"
DO_LIBGLOSS="no"
DO_NEWLIB="yes"
DO_LIBSTDCPP="yes"
DO_SIM="no"
DO_GDB="yes"

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

    --elf32-nsim-props)
	shift
	ARC_NSIM_PROPS=$1
	;;

    --elf32-nsim-tcf)
	shift
	ARC_NSIM_TCF=$1
	;;

    --elf32-hostlink-library)
	shift
	ARC_HOSTLINK_LIBRARY=$1
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

    --little-endian)
        ARC_ENDIAN=little
        ;;

    --multilib-options)
        shift
        ARC_MULTILIB_OPTIONS="$1"
	;;

    --binutils)
	DO_BINUTILS="yes"
	;;

    --no-binutils)
	DO_BINUTILS="no"
	;;

    --gas)
	DO_GAS="yes"
	;;

    --no-gas)
	DO_GAS="no"
	;;

    --ld)
	DO_LD="yes"
	;;

    --no-ld)
	DO_LD="no"
	;;

    --gcc)
	DO_GCC="yes"
	;;

    --no-gcc)
	DO_GCC="no"
	;;

    --libgcc)
	DO_LIBGCC="yes"
	;;

    --no-libgcc)
	DO_LIBGCC="no"
	;;

    --libgloss)
	DO_LIBGLOSS="yes"
	;;

    --no-libgloss)
	DO_LIBGLOSS="no"
	;;

    --newlib)
	DO_LIBGLOSS="yes"
	;;

    --no-newlib)
	DO_NEWLIB="no"
	;;

    --libstdc++)
	DO_LIBSTDCPP="yes"
	;;

    --no-libstdc++)
	DO_LIBSTDCPP="no"
	;;

    --sim)
	DO_SIM="yes"
	;;

    --no-sim)
	DO_SIM="no"
	;;

    --gdb)
	DO_GDB="yes"
	;;

    --no-gdb)
	DO_GDB="no"
	;;

    ?*)
        echo "Unknown option \`$opt' specified."
        echo "Usage: ./run-tests.sh [--source-dir <source_dir>]"
        echo "                      [--elf32-target-board <board>]"
        echo "                      [--uclibc-target-board <board>]"
        echo "                      [--elf32-target-addr <address>]"
        echo "                      [--uclibc-target-addr <address>]"
        echo "                      [--elf32-nsim-props <path>]"
        echo "                      [--elf32-nsim-tcf <path>]"
        echo "                      [--elf32-hostlink-library <path>]"
        echo "                      [--elf32 | --no-elf32]"
        echo "                      [--uclibc | --no-uclibc]"
        echo "                      [--big-endian | --little-endian]"
        echo "                      [--multilib-options <options>]"
        echo "                      [--binutils | --no-binutils]"
        echo "                      [--gas | --no-gas]"
        echo "                      [--ld | --no-ld]"
        echo "                      [--gcc | --no-gcc]"
        echo "                      [--libgcc | --no-libgcc]"
        echo "                      [--libgloss | --no-libgloss]"
        echo "                      [--newlib | --no-newlib]"
        echo "                      [--libstdc++ | --no-libstdc++]"
        echo "                      [--sim | --no-sim]"
        echo "                      [--gdb | --no-gdb]"

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

# Export everything needed by sub-scripts
export ARC_TEST_BOARD_ELF32
export ARC_TEST_BOARD_UCLIBC
export ARC_TEST_ADDR_ELF32
export ARC_TEST_ADDR_UCLIBC
export ARC_MULTILIB_OPTIONS
export ARC_NSIM_PROPS

export ARC_GNU
export ARC_ENDIAN
export PARALLEL

export DO_BINUTILS
export DO_GAS
export DO_LD
export DO_GCC
export DO_LIBGCC
export DO_LIBGLOSS
export DO_NEWLIB
export DO_LIBSTDCPP
export DO_SIM
export DO_GDB

if [ "x$ARC_NSIM_TCF" != x ]
then
    export ARC_NSIM_TCF
fi

if [ "x${ARC_HOSTLINK_LIBRARY}" != x ]
then
    export ARC_HOSTLINK_LIBRARY
fi

status=0

# Run the ELF32 tests
if [ "${elf32}" = "--elf32" ]
then
    if ! "${ARC_GNU}"/toolchain/run-elf32-tests.sh
    then
        echo "ERROR: arc-elf32- some tests failed."
        status=1
    fi
fi

# Run the UCLIBC tests
if [ "${uclibc}" = "--uclibc" ]
then
    if ! "${ARC_GNU}"/toolchain/run-uclibc-tests.sh
    then
        echo "ERROR: arc-linux-uclibc- some tests failed."
        status=1
    fi
fi

exit ${status}

