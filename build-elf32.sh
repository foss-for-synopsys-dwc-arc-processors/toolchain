#!/bin/sh

# Copyright (C) 2009, 2011, 2012 Embecosm Limited
# Copyright (C) 2012 Synopsys Inc.

# Contributor Joern Rennecke <joern.rennecke@embecosm.com>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This script builds the ARC 32-bit ELF tool chain from a unified source tree.

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

#     ${ARC_GNU}/toolchain/build-elf32.sh [--force]

# --force

#     Blow away any old build sub-directories

# The directory in which we are invoked is the build directory, in which we
# find the unified source tree and in which all build directories are created.

# All other parameters are set by environment variables

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# UNISRC

#     The name of the unified source directory within the build directory

# INSTALLDIR

#     The directory where the tool chain should be installed

# DISABLE_MULTILIB

#     Either --enable-multilib or --disable-multilib to control the building
#     of multilibs

# We source the script arc-init.sh to set up variables needed by the script
# and define a function to get to the configuration directory (which can be
# tricky under MinGW/MSYS environments).

# The script constructs a unified source directory (if --force is specified)
# and uses a build directory (bd-4.8-elf32) local to the directory in which it
# is executed. The script generates a date and time stamped log file in that
# directory.

# This version is modified to work with the source tree as organized in
# GitHub.

# ------------------------------------------------------------------------------
# Local variables. We need to use unified_src as a relative directory when
# constructing.
arch=arc
unified_src_abs="$(echo "${PWD}")"/${UNISRC}
build_dir="$(echo "${PWD}")"/bd-4.8-elf32

# parse options
until
opt=$1
case ${opt} in
    --force)
	rm -rf ${build_dir}
	;;
    ?*)
	echo "Usage: ./build-elf32.sh [--force]"
	exit 1
	;;
esac
[ -z "${opt}" ]
do
    shift
done

# Set up a logfile
mkdir -p ${PWD}/logs
logfile="$(echo "${PWD}")/logs/elf32-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ELF32: $(date)" >> ${logfile}
echo "START ELF32: $(date)"

# ARC initialization (Note. source, not exec)
. "${ARC_GNU}"/toolchain/arc-init.sh

# Note stuff for the log
log_path=$(calcConfigPath "${logfile}")

echo "Installing in ${INSTALLDIR}" >> "${log_path}" 2>&1
echo "Installing in ${INSTALLDIR}"


# Configure binutils, GCC and newlib
# TODO: should fix warnings instead of using --disable-werror.
echo "Configuring tools" >> "${log_path}"
echo "=================" >> "${log_path}"

echo "Configuring tools ..."

# Create the build dir
build_path=$(calcConfigPath "${build_dir}")
mkdir -p "${build_path}"
cd "${build_path}"

# Configure the build.
config_path=$(calcConfigPath "${unified_src_abs}")
log_path=$(calcConfigPath "${logfile}")
if "${config_path}"/configure --target=${arch}-elf32 --with-cpu=arc700 \
        --disable-werror ${DISABLE_MULTILIB} \
        --with-pkgversion="ARCompact elf32 toolchain (built $(date +%Y%m%d))" \
        --with-bugurl="http://solvnet.synopsys.com" \
        --enable-fast-install=N/A \
        --enable-languages=c,c++ --prefix=${INSTALLDIR} \
        --with-headers="${config_path}"/newlib/libc/include \
        --enable-sim-endian=no \
    >> "${log_path}" 2>&1
then
    echo "  finished configuring tools"
else
    echo "ERROR: configure failed."
    exit 1
fi

# Build binutils, GCC, newlib and GDB
echo "Building tools" >> "${log_path}"
echo "==============" >> "${log_path}"

echo "Building tools ..."
build_path=$(calcConfigPath "${build_dir}")
cd "${build_path}"
log_path=$(calcConfigPath "${logfile}")
if make ${PARALLEL} all-build all-binutils all-gas all-ld all-gcc \
        all-target-libgcc all-target-libgloss all-target-newlib \
        all-target-libstdc++-v3 all-sim >> "${log_path}" 2>&1
then
    echo "  finished building tools (excl GDB)"
else
    echo "ERROR: tools build (excl GDB) failed."
    exit 1
fi

# if make ${PARALLEL} all-gdb >> "${log_path}" 2>&1
# then
#     echo "  finished building GDB"
# else
#     echo "ERROR: GDB build failed."
#     exit 1
# fi

# Install binutils, GCC, newlib and GDB
echo "Installing tools" >> "${log_path}"
echo "================" >> "${log_path}"

echo "Installing tools ..."
build_path=$(calcConfigPath "${build_dir}")
cd "${build_path}"
log_path=$(calcConfigPath "${logfile}")
if make install-binutils install-gas install-ld install-gcc \
        install-target-libgcc install-target-libgloss install-target-newlib \
        install-target-libstdc++-v3 install-sim \
    >> "${log_path}" 2>&1
then
    echo "  finished installing tools (excl GDB)"
else
    echo "ERROR: tools install (excl GDB) failed."
    exit 1
fi

echo "DONE  ELF32: $(date)" >> "${log_path}"
echo "DONE  ELF32: $(date)"
