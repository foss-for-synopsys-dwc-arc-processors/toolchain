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

#	       SCRIPT TO RUN ARC-UCLIBC-LINUX REGRESSION TESTS
#              ===============================================

# Usage:

#   ./run-uclibc-tests.sh

# Prerequisites (NOT tested for):

#   ARC_GNU environment variable must be the absolute address of the default
#   source directory.

#   ${ARC_GNU}/logs must exist and be writable

#   ${ARC_GNU}/results must exist and be writable

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

# Set the build directories
bd_linux=${ARC_GNU}/bd-uclibc
bd_linux_gdb=${ARC_GNU}/bd-uclibc-gdb

# Create the Linux log file and results directory
logfile_linux="$(echo "${ARC_GNU}")/logs/linux-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_linux}"
res_linux="$(echo "${ARC_GNU}")/results/linux-results-$(date -u +%F-%H%M)"
mkdir ${res_linux}

# Run tests
status=0
run_check ${bd_linux}     binutils            "${logfile_linux}" || status=1
save_res  ${bd_linux}     ${res_linux} binutils/binutils     "${logfile_linux}" \
    || status=1
run_check ${bd_linux}     gas                 "${logfile_linux}" || status=1
save_res  ${bd_linux}     ${res_linux} gas/testsuite/gas     "${logfile_linux}" \
    || status=1
run_check ${bd_linux}     ld                  "${logfile_linux}" || status=1
save_res  ${bd_linux}     ${res_linux} ld/ld                 "${logfile_linux}" \
    || status=1
run_check ${bd_linux}     gcc                 "${logfile_linux}" || status=1
save_res  ${bd_linux}     ${res_linux} gcc/testsuite/gcc/gcc "${logfile_linux}" \
    || status=1
echo "Testing g++..."
save_res  ${bd_linux}     ${res_linux} gcc/testsuite/g++/g++ "${logfile_linux}" \
    || status=1
# libgcc tests are currently empty, so nothing to run or save.
# run_check ${bd_linux}     target-libgcc       "${logfile_linux}"
run_check ${bd_linux}     target-libstdc++-v3 "${logfile_linux}" || status=1
save_res  ${bd_linux}     ${res_linux} \
    arc-linux-uclibc/libstdc++-v3/testsuite/libstdc++ "${logfile_linux}" \
    || status=1
run_check ${bd_linux_gdb} gdb                 "${logfile_linux}" || status=1
save_res  ${bd_linux_gdb} ${res_linux} gdb/testsuite/gdb     "${logfile_linux}" \
    || status=1

exit ${status}
