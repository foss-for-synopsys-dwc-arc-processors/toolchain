#!/bin/sh

# Copyright (C) 2012, 2013 Synopsys Inc.

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

#	       SCRIPT TO RUN ARC-UCLIBC-LINUX REGRESSION TESTS
#              ===============================================

# Usage:

#   ./run-uclibc-tests.sh

# Prerequisites (NOT tested for):

#   ARC_GNU environment variable must be the absolute address of the default
#   source directory.

#   ${ARC_GNU}/logs must exist and be writable

#   ${ARC_GNU}/results must exist and be writable

#   ARC_ENDIAN environment variable must be either "big" or "little" to
#   identify which type of toolchain tool chain to test.

# Result is 0 if successful, 1 otherwise.


# Standard setup
. "${ARC_GNU}"/toolchain/arc-init.sh

# Set up logfile and results directories if either does not exist
mkdir -p ${ARC_GNU}/logs
mkdir -p ${ARC_GNU}/results

# Run UCLIBC regression and gather results. Gathering results is a separate
# function because of the variation in the location and number of results
# files for each tool.
export DEJAGNU=${ARC_GNU}/toolchain/site.exp
echo "Running uClibc Linux tests"

# Create the Uclibc log file and results directory
logfile_uclibc="$(echo "${ARC_GNU}")/logs/uclibc-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_uclibc}"
res_uclibc="$(echo "${ARC_GNU}")/results/uclibc-results-$(date -u +%F-%H%M)"
mkdir ${res_uclibc}

# Location of some files depends on endianess
if [ "${ARC_ENDIAN}" = "little" ]
then
    bd_uclibc=${ARC_GNU}/bd-4.8-uclibc
    target_dir=arc-linux-uclibc
else
    bd_uclibc=${ARC_GNU}/bd-4.8-uclibceb
    target_dir=arceb-linux-uclibc
fi

# The target board to use
board=arc-linux-aa4

# Create a file of start up commands for GDB
commfile="${ARC_GNU}/commfile"
echo "set sysroot /opt/arc-4.4-gdb-7.5/arc-linux-uclibc" >${commfile}
export ARC_GDB_COMMFILE=${commfile}

# Run tests
status=0
run_check ${bd_uclibc} binutils "${logfile_uclibc}" ${board} || status=1
save_res  ${bd_uclibc} ${res_uclibc} binutils/binutils "${logfile_uclibc}" \
    || status=1
run_check ${bd_uclibc} gas "${logfile_uclibc}" ${board} || status=1
save_res  ${bd_uclibc} ${res_uclibc} gas/testsuite/gas "${logfile_uclibc}" \
    || status=1
run_check ${bd_uclibc} ld "${logfile_uclibc}" ${board} || status=1
save_res  ${bd_uclibc} ${res_uclibc} ld/ld "${logfile_uclibc}" \
    || status=1
run_check ${bd_uclibc} gcc "${logfile_uclibc}" ${board} || status=1
save_res  ${bd_uclibc} ${res_uclibc} gcc/testsuite/gcc/gcc "${logfile_uclibc}" \
    || status=1
echo "Testing g++..."
save_res  ${bd_uclibc} ${res_uclibc} gcc/testsuite/g++/g++ "${logfile_uclibc}" \
    || status=1
# libgcc tests are currently empty, so nothing to run or save.
# run_check ${bd_uclibc} target-libgcc       "${logfile_uclibc}"
run_check ${bd_uclibc} target-libstdc++-v3 "${logfile_uclibc}" ${board} \
    || status=1
save_res  ${bd_uclibc} ${res_uclibc} \
    ${target_dir}/libstdc++-v3/testsuite/libstdc++ "${logfile_uclibc}" \
    || status=1
run_check ${bd_uclibc} gdb "${logfile_uclibc}" ${board} || status=1
save_res  ${bd_uclibc} ${res_uclibc} gdb/testsuite/gdb "${logfile_uclibc}" \
    || status=1

exit ${status}
