#!/bin/sh

# Copyright (C) 2012-2015 Synopsys Inc.

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

# The following environment variables must be supplied

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# ARC_ENDIAN

#     "little" or "big"

# PARALLEL

#     string "-j <jobs> -l <load>" to control parallel make.

# ARC_TEST_BOARD_ELF32

#     The Dejagnu board description for the target. This must be a standard
#     DejaGnu baseboard, or in the dejagnu/baseboards directory of the
#     toolchain repository.

# ARC_TEST_ADDR_ELF32

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

# Run ELF32 regression and gather results. Gathering results is a separate
# function because of the variation in the location and number of results
# files for each tool.
DEJAGNU=${ARC_GNU}/toolchain/site.exp
export DEJAGNU
echo "Running elf32 tests"

# Create the ELF log file and results directory
logfile_elf="${LOGDIR}/elf32-check-$(date -u +%F-%H%M).log"
rm -f "${logfile_elf}"
res_elf="${RESDIR}/elf32-results-$(date -u +%F-%H%M)"
mkdir ${res_elf}
readme=${res_elf}/README

# Location of some files depends on endianess. For now with ELF this is
# ignored, but this code is a holding position.
if [ "${ARC_ENDIAN}" = "little" ]
then
    target_dir=arc-elf32
    bd_elf="${ARC_GNU}/bd-elf32"
else
    target_dir=arceb-elf32
    bd_elf="${ARC_GNU}/bd-elf32eb"
fi

# Create a README with info about the test
echo "Test of ELF32 tool chain run" > ${readme}
echo "============================" >> ${readme}
echo "" >> ${readme}
echo "Start time:         $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Endianness:         ${ARC_ENDIAN}"                     >> ${readme}
echo "Test board:         ${ARC_TEST_BOARD_ELF32}"           >> ${readme}
echo "Test IP address:    ${ARC_TEST_ADDR_ELF32}"            >> ${readme}
echo "Multilib options:   ${ARC_MULTILIB_OPTIONS}"           >> ${readme}

# Run the tests
status=0
# binutils
if [ "x${DO_BINUTILS}" = "xyes" ]
then
    run_check ${bd_elf}/binutils \
	binutils \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/binutils \
	${res_elf} \
	binutils/binutils \
	"${logfile_elf}" \
	|| status=1
fi
# gas
if [ "x${DO_GAS}" = "xyes" ]
then
    run_check ${bd_elf}/binutils \
	gas \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/binutils \
	${res_elf} \
	gas/testsuite/gas \
	"${logfile_elf}" \
	|| status=1
fi
# ld
if [ "x${DO_LD}" = "xyes" ]
then
    run_check ${bd_elf}/binutils \
	ld \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/binutils \
	${res_elf} ld/ld \
	"${logfile_elf}" \
	|| status=1
fi
# gcc and g++
if [ "x${DO_GCC}" = "xyes" ]
then
    run_check ${bd_elf}/gcc-stage2 \
	gcc \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res \
	${bd_elf}/gcc-stage2 \
	${res_elf} \
	gcc/testsuite/gcc/gcc \
	"${logfile_elf}" \
	|| status=1
    echo "Testing g++..."
    save_res ${bd_elf}/gcc-stage2 \
	${res_elf} \
	gcc/testsuite/g++/g++ \
	"${logfile_elf}" \
	|| status=1
fi
# libgcc
if [ "x${DO_LIBGCC}" = "xyes" ]
then
    run_check ${bd_elf}/gcc-stage2 \
	target-libgcc \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/gcc-stage2 \
	${res_elf} \
	${target_dir}/libgcc/testsuite/libgcc \
	"${logfile_elf}" \
	|| status=1
fi
# libgloss
if [ "x${DO_LIBGLOSS}" = "xyes" ]
then
    run_check ${bd_elf}/newlib \
	target-libgloss \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/newlib \
	${res_elf} \
	${target_dir}/libgloss/testsuite/libgloss \
	"${logfile_elf}" \
	|| status=1
fi
# newlib
if [ "x${DO_NEWLIB}" = "xyes" ]
then
    run_check ${bd_elf}/newlib \
	target-newlib \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/newlib \
	${res_elf} \
	${target_dir}/newlib/testsuite/newlib \
	"${logfile_elf}" \
	|| status=1
fi
# libstdc++
if [ "x${DO_LIBSTDCPP}" = "xyes" ]
then
    run_check ${bd_elf}/gcc-stage2 \
	target-libstdc++-v3 \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/gcc-stage2 \
	${res_elf} \
	${target_dir}/libstdc++-v3/testsuite/libstdc++ \
	"${logfile_elf}" \
	|| status=1
fi
# sim
if [ "x${DO_SIM}" = "xyes" ]
then
    run_check ${bd_elf}/gdb \
	sim \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/gdb \
	${res_elf} sim/testsuite/sim \
	"${logfile_elf}" \
	|| status=1
fi
# gdb
if [ "x${DO_GDB}" = "xyes" ]
then
    run_check ${bd_elf}/gdb \
	gdb \
	"${logfile_elf}" \
	${ARC_TEST_BOARD_ELF32} \
	|| status=1
    save_res ${bd_elf}/gdb \
	${res_elf} gdb/testsuite/gdb \
	"${logfile_elf}" \
	|| status=1
fi

exit ${status}

# vim: noexpandtab sts=4 ts=8:
