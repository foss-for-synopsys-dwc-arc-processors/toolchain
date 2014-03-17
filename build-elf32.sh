#!/bin/sh

# Copyright (C) 2009, 2011, 2012, 2013 Embecosm Limited
# Copyright (C) 2012, 2013 Synopsys Inc.

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

# RELEASE

#     The number of the current ARC tool chain release.

# LOGDIR

#     Directory for all log files.

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# UNISRC

#     The name of the unified source directory within the build directory

# LINUXDIR

#     The name of the Linux directory (absolute path)

# INSTALLDIR

#     The directory where the tool chain should be installed

# ARC_ENDIAN

#     "little" or "big"

# ELF32_DISABLE_MULTILIB

#     Either --enable-multilib or --disable-multilib to control the building
#     of multilibs.

# ISA_CPU

#     For use with the --with-cpu flag to specify the ISA. Can be arc700 or
#     EM.

# DO_SIM

#     Either --sim or --no-sim to control whether we build and install the
#     CGEN simulator.

# CONFIG_FLAGS

#     Additional flags for use with configuration.

# CFLAGS_FOR_TARGET

#     Additional flags used when building the target libraries (e.g. for
#     compact libraries) picked up automatically by make.

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

# The script constructs a unified source directory (if --force is specified)
# and uses a build directory (bd-${RELEASE}-elf32) local to the directory in
# which it is executed.

# The script generates a date and time stamped log file in the logs directory.

# This version is modified to work with the source tree as organized in
# GitHub.

# ------------------------------------------------------------------------------
# Local variables. We need to use unified_src as a relative directory when
# constructing.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arch=arceb
    build_dir="$(echo "${PWD}")"/bd-${RELEASE}-elf32eb
else
    arch=arc
    build_dir="$(echo "${PWD}")"/bd-${RELEASE}-elf32
fi

unified_src_abs="$(echo "${PWD}")"/${UNISRC}

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
logfile="${LOGDIR}/elf32-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ELF32: $(date)" >> ${logfile}
echo "START ELF32: $(date)"

# ARC initialization (Note. source, not exec)
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
if "${config_path}"/configure --target=${arch}-elf32 --with-cpu=${ISA_CPU} \
        ${ELF32_DISABLE_MULTILIB} \
        --with-pkgversion="ARCompact/ARCv2 ISA elf32 toolchain ($RELEASE_NAME)" \
        --with-bugurl="http://solvnet.synopsys.com" \
        --enable-fast-install=N/A \
        --with-endian=${ARC_ENDIAN} ${DISABLEWERROR} \
        --enable-languages=c,c++ --prefix=${INSTALLDIR} \
        --with-headers="${config_path}"/newlib/libc/include \
        ${sim_config} ${CONFIG_EXTRA} \
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
        all-target-libstdc++-v3 ${sim_build} all-gdb >> "${log_path}" 2>&1
then
    echo "  finished building tools"
else
    echo "ERROR: tools build failed."
    exit 1
fi

# Install binutils, GCC, newlib and GDB
echo "Installing tools" >> "${log_path}"
echo "================" >> "${log_path}"

echo "Installing tools ..."
build_path=$(calcConfigPath "${build_dir}")
cd "${build_path}"
log_path=$(calcConfigPath "${logfile}")
if make ${HOST_INSTALL}-binutils ${HOST_INSTALL}-gas ${HOST_INSTALL}-ld \
    ${HOST_INSTALL}-gcc ${sim_install} install-gdb \
    install-target-libgloss install-target-newlib install-target-libgcc \
    install-target-libstdc++-v3 \
    >> "${log_path}" 2>&1
then
    echo "  finished installing tools"
else
    echo "ERROR: tools install failed."
    exit 1
fi

# Restore GDB config for simulator (does nothing if the change was not made).
${SED} -i "${ARC_GNU}"/gdb/gdb/configure.tgt \
    -e 's!# gdb_sim=../sim/arc/libsim.a!gdb_sim=../sim/arc/libsim.a!'

# Optionally build and install PDF documentation
if [ "x${DO_PDF}" = "x--pdf" ]
then
    echo "Building PDF documentation" >> "${log_path}"
    echo "==========================" >> "${log_path}"

    echo "Building PDFs ..."
    build_path=$(calcConfigPath "${build_dir}")
    cd "${build_path}"
    log_path=$(calcConfigPath "${logfile}")
    if make ${PARALLEL} pdf-binutils pdf-gas pdf-ld pdf-gcc \
	pdf-target-newlib pdf-gdb >> "${log_path}" 2>&1
    then
	echo "  finished building PDFs"
    else
	echo "ERROR: PDF build failed."
	echo "Advice: Use option --no-pdf if you don't need PDF documentation."
	if ! which texi2pdf >/dev/null 2>/dev/null ; then
	    echo "Is TeX installed? See section Prerequisites of " \
	         "GCC Getting Started for a list of required system packages."
	fi
	exit 1
    fi

    echo "Installing PDF documentation" >> "${log_path}"
    echo "============================" >> "${log_path}"

    echo "Installing PDFs ..."
    build_path=$(calcConfigPath "${build_dir}")
    cd "${build_path}"
    log_path=$(calcConfigPath "${logfile}")
    if make install-pdf-binutils install-pdf-gas install-pdf-ld \
	install-pdf-gcc install-pdf-target-newlib install-pdf-gdb \
	>> "${log_path}" 2>&1
    then
	echo "  finished installing PDFs"
    else
	echo "ERROR: PDF install failed."
	exit 1
    fi
fi

echo "DONE  ELF32: $(date)" >> "${log_path}"
echo "DONE  ELF32: $(date)"
