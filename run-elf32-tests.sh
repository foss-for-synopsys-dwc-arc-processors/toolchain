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

#		   SCRIPT TO RUN ARC-ELF32 REGRESSION TESTS
#                  ========================================

# Usage:

#   ./run-elf32-tests.sh

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

# Run ELF32 regression and gather results. Gathering results is a separate
# function because of the variation in the location and number of results
# files for each tool.
export DEJAGNU=${ARC_GNU}/toolchain/site.exp
echo "Running elf32 tests"

# Set the build directories
bd_elf_gdb=${ARC_GNU}/bd-elf32-gdb

# Create the ELF log file and results directory
logfile_elf="$(echo "${ARC_GNU}")/logs/elf32-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_elf}"
res_elf="$(echo "${ARC_GNU}")/results/elf32-results-$(date -u +%F-%H%M)"
mkdir ${res_elf}

# Location of some files depends on endianess. For now with ELF this is
# ignored, but this code is a holding position.
if [ "${ARC_ENDIAN}" = "little" ]
then
    target_dir=arc-elf32
    bd_elf=${ARC_GNU}/bd-4.8-elf32
else
    target_dir=arceb-elf32
    bd_elf=${ARC_GNU}/bd-4.8-elf32eb
fi

# The target board to use
board=arc-sim

# Run the tests
status=0
run_check ${bd_elf}     binutils            "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} binutils/binutils     "${logfile_elf}" \
    || status=1
run_check ${bd_elf}     gas                 "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} gas/testsuite/gas     "${logfile_elf}" \
    || status=1
run_check ${bd_elf}     ld                  "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} ld/ld                 "${logfile_elf}" \
    || status=1
run_check ${bd_elf}     gcc                 "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} gcc/testsuite/gcc/gcc "${logfile_elf}" \
    || status=1
echo "Testing g++..."
save_res  ${bd_elf}     ${res_elf} gcc/testsuite/g++/g++ "${logfile_elf}" \
    || status=1
# libgcc and libgloss tests are currently empty, so nothing to run or save.
# run_check ${bd_elf}     target-libgcc       "${logfile_elf}"
# run_check ${bd_elf}     target-libgloss     "${logfile_elf}"
run_check ${bd_elf}     target-newlib       "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} ${target_dir}/newlib/testsuite/newlib \
    "${logfile_elf}" || status=1
run_check ${bd_elf}     target-libstdc++-v3 "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf}     ${res_elf} \
    ${target_dir}/libstdc++-v3/testsuite/libstdc++ "${logfile_elf}" \
    || status=1
run_check ${bd_elf_gdb} sim                 "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf_gdb} ${res_elf} sim/testsuite/sim     "${logfile_elf}" \
    || status=1
run_check ${bd_elf_gdb} gdb                 "${logfile_elf}" ${board} \
    || status=1
save_res  ${bd_elf_gdb} ${res_elf} gdb/testsuite/gdb     "${logfile_elf}" \
    || status=1

exit ${status}
