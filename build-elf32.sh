#!/bin/sh

# Copyright (C) 2009, 2011, 2012, 2013 Embecosm Limited
# Copyright (C) 2012-2015 Synopsys Inc.

# Contributor Joern Rennecke <joern.rennecke@embecosm.com>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

# This script builds the ARC 32-bit ELF tool chain.

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

#     ${ARC_GNU}/toolchain/build-elf32.sh

# The directory in which we are invoked is the build directory, in which we
# find the components source trees and in which all build directories are created.

# All other parameters are set by environment variables

# LOGDIR

#     Directory for all log files.

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# INSTALLDIR

#     The directory where the tool chain should be installed

# ARC_ENDIAN

#     "little" or "big"

# ELF32_DISABLE_MULTILIB

#     Either --enable-multilib or --disable-multilib to control the building
#     of multilibs.

# ISA_CPU

#     For use with the --with-cpu flag to specify the ISA. Can be arc700 or
#     arcem.

# DO_SIM

#     Either --sim or --no-sim to control whether we build and install the
#     CGEN simulator.

# CONFIG_EXTRA

#     Additional flags for use with configuration.

# CFLAGS_FOR_TARGET

#     Additional flags used when building the target libraries (e.g. for
#     compact libraries) picked up automatically by make. This variable is used
#     by configure scripts and make, and build-elf.sh doesn't do anything about
#     it explicitly.

# DO_PDF

#     Either --pdf or --no-pdf to control whether we build and install PDFs of
#     the user guides.

# PARALLEL

#     string "-j <jobs> -l <load>" to control parallel make.

# HOST_INSTALL

#     Make target prefix to install host application. Should be either
#     "install" or "install-strip".

# We source the script arc-init.sh to set up variables needed by the script
# and define a function to get to the configuration directory (which can be
# tricky under MinGW/MSYS environments).

# The script uses a build directory (bd-elf32[eb]) local to the directory in
# which it is executed.

# The script generates a date and time stamped log file in the logs directory.

# This version is modified to work with the source tree as organized in
# GitHub.

# ------------------------------------------------------------------------------
# Local variables.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arch=arceb
    build_dir="$(echo "${PWD}")/bd-elf32eb"
else
    arch=arc
    build_dir="$(echo "${PWD}")/bd-elf32"
fi

# Set up a logfile
logfile="${LOGDIR}/elf32-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ELF32: $(date)" | tee -a "$logfile"

# Initialize common variables and functions.
. "${ARC_GNU}"/toolchain/arc-init.sh

# variables to control whether the simulator is build. Note that we actively
# edit in the requirement for a simulator library in case it has been left
# commented out from a previous part-completed run of this script.
if [ "x${DO_SIM}" = "x--sim" ]
then
    sim_config="--enable-sim --enable-sim-endian=no"
    sim_build=all-sim
    # CGEN doesn't have install-strip target.
    sim_install=install-sim
    ${SED} -i "${ARC_GNU}"/gdb/gdb/configure.tgt \
	   -e 's!# gdb_sim=../sim/arc/libsim.a!gdb_sim=../sim/arc/libsim.a!'
else
    sim_config=--disable-sim
    sim_build=
    sim_install=
    ${SED} -i "${ARC_GNU}"/gdb/gdb/configure.tgt \
	-e 's!gdb_sim=../sim/arc/libsim.a!# gdb_sim=../sim/arc/libsim.a!'
fi

# If PDF docs are enabled, then check if prerequisites are satisfied.
if [ "x${DO_PDF}" = "x--pdf" ]
then
    if ! which texi2pdf >/dev/null 2>/dev/null
    then
	echo "TeX is not installed. See README.md for a list of required"
	echo "system packages. Option --no-pdf can be used to disable build"
	echo "of PDF documentation."
	exit 1
    fi

    # There are issues with Texinfo v4 and non-C locales.
    # See http://lists.gnu.org/archive/html/bug-texinfo/2010-03/msg00031.html
    if [ 4 = `texi2dvi --version | grep -Po '(?<=Texinfo )[0-9]+'` ]
    then
	export LC_ALL=C
    fi
fi

echo "Installing in ${INSTALLDIR}" | tee -a "$logfile"

# Purge old build dir if there is any and create a new one.
rm -rf "$build_dir"
mkdir -p "$build_dir"

# Binutils
build_dir_init binutils
configure_elf32 binutils
make_target building all-binutils all-gas all-ld
make_target installing ${HOST_INSTALL}-binutils ${HOST_INSTALL}-gas ${HOST_INSTALL}-ld
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-binutils \
      install-pdf-ld install-pdf-gas
fi

# GCC
build_dir_init gcc
configure_elf32 gcc gcc --with-newlib
make_target building all-gcc all-target-libgcc
make_target installing ${HOST_INSTALL}-gcc install-target-libgcc
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gcc
fi

# Newlib (build in sub-shell with new tools added to the PATH)
build_dir_init newlib
(
PATH=$INSTALLDIR/bin:$PATH
configure_elf32 newlib
make_target building all-target-newlib
make_target installing install-target-newlib
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-target-newlib
fi
)

# libstdc++
# It is built in the build tree of GCC to avoid nasty problems which might
# happen when libstdc++ is being built in the separate directory while new
# compiler is in the PATH. Notably a known broken situation is when new
# toolchain is being installed on top of the previous installation and
# libstdc++ configure script will find some header files left from previous
# installation and will decide that some features are present, while they are
# not. That problem doesn't occur when libstdc++ is built in same build tree as
# GCC before that.

echo "Building libstdc++ ..." | tee -a "$logfile"
cd $build_dir/gcc
make_target building all-target-libstdc++-v3
make_target installing install-target-libstdc++-v3
# Don't build libstdc++ documentation because it requires additional software
# on build host.

# GDB and CGEN simulator (maybe)
build_dir_init gdb
configure_elf32 gdb
make_target building all-gdb ${sim_build}
make_target installing ${sim_install} install-gdb
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gdb
fi

# Restore GDB config for simulator (does nothing if the change was not made).
${SED} -i "${ARC_GNU}"/gdb/gdb/configure.tgt \
    -e 's!# gdb_sim=../sim/arc/libsim.a!gdb_sim=../sim/arc/libsim.a!'

echo "DONE  ELF32: $(date)" | tee -a "$logfile"

# vim: noexpandtab sts=4 ts=8:
