#!/bin/sh

# Copyright (C) 2012-2016 Synopsys Inc.

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

# The following environment variables must be supplied

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# ARC_ENDIAN

#     "little" or "big"

# PARALLEL

#     string "-j <jobs> -l <load>" to control parallel make.

# ARC_TEST_BOARD_UCLIBC

#     The Dejagnu board description for the target. This must be a standard
#     DejaGnu baseboard, or in the dejagnu/baseboards directory of the
#     toolchain repository.

# ARC_TEST_ADDR_UCLIBC

#     The IP address for the target if required by the board. Used by the
#     underlying DejaGnu scripts.

# ARC_MULTILIB_OPTIONS

#     May be used by the underlying DejaGnu scripts to specify options for
#     multilib testing.

# DO_BINUTILS
# DO_GAS
# DO_LD
# DO_GCC
# DO_LIBGCC
# DO_LIBGLOSS
# DO_NEWLIB
# DO_LIBSTDCPP
# DO_SIM
# DO_GDB

#     Specify whether the corresponding test should be run.

# Result is 0 if successful, 1 otherwise.


# Standard setup
. "${ARC_GNU}"/toolchain/arc-init.sh

# Run UCLIBC regression and gather results. Gathering results is a separate
# function because of the variation in the location and number of results
# files for each tool.
DEJAGNU=${ARC_GNU}/toolchain/site.exp
export DEJAGNU
echo "Running uClibc Linux tests"

# Create the uClibc log file and results directory
logfile_uclibc="${LOGDIR}/uclibc-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_uclibc}"
res_uclibc="${RESDIR}/uclibc-results-$(date -u +%F-%H%M)"
mkdir ${res_uclibc}
readme=${res_uclibc}/README

# Location of some files depends on endianess
if [ "${ARC_ENDIAN}" = "little" ]
then
    bd_uclibc="${ARC_GNU}/bd-uclibc"
    target_dir=arc-snps-linux-uclibc
else
    bd_uclibc="${ARC_GNU}/bd-uclibceb"
    target_dir=arceb-snps-linux-uclibc
fi

# Create a file of start up commands for GDB
commfile="${ARC_GNU}/commfile"
echo "set sysroot /opt/arc-4.4-gdb-7.5/arc-linux-uclibc" >${commfile}
ARC_GDB_COMMFILE=${commfile}
export ARC_GDB_COMMFILE

# Create a README with info about the test
echo "Test of UCLIBC tool chain run" > ${readme}
echo "=============================" >> ${readme}
echo "" >> ${readme}
echo "Start time:         $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Endianness:         ${ARC_ENDIAN}"                     >> ${readme}
echo "Test board:         ${ARC_TEST_BOARD_UCLIBC}"          >> ${readme}
echo "Test IP address:    ${ARC_TEST_ADDR_UCLIBC}"           >> ${readme}
echo "Multilib options:   ${ARC_MULTILIB_OPTIONS}"           >> ${readme}
echo "Commfile contents:"                                    >> ${readme}
${SED} < ${commfile} -e 's/^/    /'                             >> ${readme}

# Run tests
status=0
# binutils
if [ "x${DO_BINUTILS}" = "xyes" ]
then
    run_check ${bd_uclibc}/binutils \
	binutils \
	"${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/binutils \
	${res_uclibc} \
	binutils/binutils \
	"${logfile_uclibc}" \
	|| status=1
fi
# gas
if [ "x${DO_GAS}" = "xyes" ]
then
    run_check ${bd_uclibc}/binutils \
	gas "${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/binutils \
	${res_uclibc} \
	gas/testsuite/gas \
	"${logfile_uclibc}" \
	|| status=1
fi
# ld
if [ "x${DO_LD}" = "xyes" ]
then
    run_check ${bd_uclibc}/binutils \
	ld "${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/binutils \
	${res_uclibc} \
	ld/ld \
	"${logfile_uclibc}" \
	|| status=1
fi
# gcc and g++
if [ "x${DO_GCC}" = "xyes" ]
then
    run_check ${bd_uclibc}/gcc-stage2 \
	gcc \
	"${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/gcc-stage2 \
	${res_uclibc} \
	gcc/testsuite/gcc/gcc \
	"${logfile_uclibc}" \
	|| status=1
    echo "Testing g++..."
    save_res  ${bd_uclibc}/gcc-stage2 \
	${res_uclibc} \
	gcc/testsuite/g++/g++ \
	"${logfile_uclibc}" \
	|| status=1
fi
# libgcc
if [ "x${DO_LIBGCC}" = "xyes" ]
then
    run_check ${bd_uclibc}/gcc-stage2 \
	target-libgcc \
	"${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res ${bd_uclibc}/gcc-stage2 \
	${res_uclibc} \
	${target_dir}/libgcc/testsuite/libgcc \
	"${logfile_uclibc}" \
	|| status=1
fi
# libstdc++
if [ "x${DO_LIBSTDCPP}" = "xyes" ]
then
    run_check ${bd_uclibc}/gcc-stage2 \
	target-libstdc++-v3 \
	"${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/gcc-stage2 \
	${res_uclibc} \
	${target_dir}/libstdc++-v3/testsuite/libstdc++ \
	"${logfile_uclibc}" \
	|| status=1
fi
# gdb
if [ "x${DO_GDB}" = "xyes" ]
then
    run_check ${bd_uclibc}/gdb \
	gdb "${logfile_uclibc}" \
	${ARC_TEST_BOARD_UCLIBC} \
	|| status=1
    save_res  ${bd_uclibc}/gdb \
	${res_uclibc} \
	gdb/testsuite/gdb \
	"${logfile_uclibc}" \
	|| status=1
fi

exit ${status}

# vim: noexpandtab sts=4 ts=8:
