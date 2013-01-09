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

# Function to run a particular test in a particular directory

# $1 - build directory
# $2 - tool to test (e.g. "binutils" will run "check-binutils"
# $3 - log file
function run_check {
    bd=$1
    tool=$2
    logfile=$3
    echo -n "Testing ${tool}..."
    echo "Regression test ${tool}" >> "${logfile}"
    echo "=======================" >> "${logfile}"

    cd ${bd}
    if make ${PARALLEL} "check-${tool}" >>  "${logfile}" 2>&1
    then
	echo " passed"
    else
	echo " failed"
    fi
    cd - > /dev/null 2>&1
}

# Save the results files to the results directory, removing spare line feed
# characters at the end of lines and marking as not writable or executable.

# $1 - build directory
# $2 - results directory
# $3 - results file name w/o suffix
# $4 - logfile
function save_res {
    bd=$1
    rd=$2
    resfile=$3
    logfile=$4
    resbase=`basename $resfile`

    dos2unix --newfile ${bd}/${resfile}.log \
	               ${rd}/${resbase}.log >> ${logfile} 2>&1
    chmod ugo-wx ${rd}/${resbase}.log
    dos2unix --newfile ${bd}/${resfile}.sum \
                       ${rd}/${resbase}.sum >> ${logfile} 2>&1
    chmod ugo-wx ${rd}/${resbase}.sum

    # Report the summary to the user
    sed -n -e '/Summary/,$p' < ${rd}/${resbase}.sum
    echo
}
    

# Default source directory if not already set.
if [ "x${ARC_GNU}" = "x" ]
then
    d=`dirname "$0"`
    ARC_GNU=`(cd "$d/.." && pwd)`
fi

# Standard setup
. "${ARC_GNU}"/toolchain/arc-init.sh

# Set the build directories
bd_elf=${ARC_GNU}/bd-elf32
bd_elf_gdb=${ARC_GNU}/bd-elf32-gdb
bd_linux=${ARC_GNU}/bd-uclibc
bd_linux_gdb=${ARC_GNU}/bd-uclibc-gdb

# Set up logfiles
mkdir -p ${ARC_GNU}/logs
logfile_elf="$(echo "${ARC_GNU}")/logs/elf32-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_elf}"
logfile_linux="$(echo "${ARC_GNU}")/logs/linux-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_linux}"

# Create build results directories
mkdir -p ${ARC_GNU}/results
res_elf="$(echo "${ARC_GNU}")/results/elf32-results-$(date -u +%F-%H%M)"
mkdir ${res_elf}
res_linux="$(echo "${ARC_GNU}")/results/linux-results-$(date -u +%F-%H%M)"
mkdir ${res_linux}

# Run each regression in turn and gather results. Gathering results is a
# separate function because of the variation in the location and number of
# results files for each tool.
export DEJAGNU=${ARC_GNU}/toolchain/site.exp

# ELF tool chain tests
echo "Running elf32 tests"

run_check ${bd_elf}     binutils            "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} binutils/binutils     "${logfile_elf}"
run_check ${bd_elf}     gas                 "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} gas/testsuite/gas     "${logfile_elf}"
run_check ${bd_elf}     ld                  "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} ld/ld                 "${logfile_elf}"
run_check ${bd_elf}     gcc                 "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} gcc/testsuite/gcc/gcc "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} gcc/testsuite/g++/g++ "${logfile_elf}"
# libgcc and libgloss tests are currently empty, so nothing to run or save.
# run_check ${bd_elf}     target-libgcc       "${logfile_elf}"
# run_check ${bd_elf}     target-libgloss     "${logfile_elf}"
run_check ${bd_elf}     target-newlib       "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} arc-elf32/newlib/testsuite/newlib \
    "${logfile_elf}"
run_check ${bd_elf}     target-libstdc++-v3 "${logfile_elf}"
save_res  ${bd_elf}     ${res_elf} arc-elf32/libstdc++-v3/testsuite/libstdc++ \
    "${logfile_elf}"
run_check ${bd_elf_gdb} sim                 "${logfile_elf}"
save_res  ${bd_elf_gdb} ${res_elf} sim/testsuite/sim     "${logfile_elf}"
run_check ${bd_elf_gdb} gdb                 "${logfile_elf}"
save_res  ${bd_elf_gdb} ${res_elf} gdb/testsuite/gdb     "${logfile_elf}"

# Linux tool chain tests
echo "Running uClibc Linux tests"

run_check ${bd_uclibc}     binutils            "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} binutils/binutils     "${logfile_linux}"
run_check ${bd_uclibc}     gas                 "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} gas/testsuite/gas     "${logfile_linux}"
run_check ${bd_uclibc}     ld                  "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} ld/ld                 "${logfile_linux}"
run_check ${bd_uclibc}     gcc                 "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} gcc/testsuite/gcc/gcc "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} gcc/testsuite/g++/g++ "${logfile_linux}"
# libgcc tests are currently empty, so nothing to run or save.
# run_check ${bd_uclibc}     target-libgcc       "${logfile_linux}"
run_check ${bd_uclibc}     target-libstdc++-v3 "${logfile_linux}"
save_res  ${bd_uclibc}     ${res_linux} \
    arc-linux32/libstdc++-v3/testsuite/libstdc++ "${logfile_linux}"
run_check ${bd_uclibc_gdb} sim                 "${logfile_linux}"
save_res  ${bd_uclibc_gdb} ${res_linux} sim/testsuite/sim     "${logfile_linux}"
run_check ${bd_uclibc_gdb} gdb                 "${logfile_linux}"
save_res  ${bd_uclibc_gdb} ${res_linux} gdb/testsuite/gdb     "${logfile_linux}"
