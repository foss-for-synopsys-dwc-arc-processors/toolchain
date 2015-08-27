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
toolchain_build_dir=$PWD/toolchain

# variables to control whether the simulator is build. Note that we actively
# edit in the requirement for a simulator library in case it has been left
# commented out from a previous part-completed run of this script.
if [ "x${DO_SIM}" = "x--sim" ]
then
    sim_config="--enable-sim --enable-sim-endian=no"
    sim_build=all-sim
    # NB: CGEN doesn't have install-strip target.
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
# Gas requires opcodes to be installed, LD requires BFD to be installed.
# However those dependencies are not described in the Makefiles, instead if
# required components is not yet installed, then dummy as-new and ld-new will
# be installed. Both libraries are installed by install-binutils. Therefore it
# is required that binutils is installed before ld and gas. That order
# denedency showed up only with Linux toolchain so far, but for safety same
# patch is applied to baremetal toolchain.
make_target_ordered installing ${HOST_INSTALL}-binutils ${HOST_INSTALL}-ld \
    ${HOST_INSTALL}-gas
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-binutils \
      install-pdf-ld install-pdf-gas
fi

# Sometimes there are problems with libstdc++ precompiled headers and canadian
# cross toolchain - this happens because libstdc++ configure scripts checks
# feature availability using the host compiler with host headers, but when
# doing header precompilation it uses host compiler with headers of new
# toolchain. Those headers should be the same in general, but there is a nasty
# cyclic dependency with fenv.h. If compiler which is being used for configure
# has this header - then this "host header" will be used. If it doesn't have
# fenv.h - then file from libstdc++ distribution is used. In normal case of a
# bare toolchain there is no such header, so final toolchain includes file from
# libstdc++. But with windows cross compilation, during configure stage this
# header exists in toolchain - version that was installed from libstdc++. Thus
# configure got confused, because that is not a real file in the sense
# libstdc++ expects it to be. As a results "new" libstdc++ is configured like
# fenv.h exists, but it is not.

# Ultimately that seems to happen because libstdc++ configure script uses host
# compiler as-is, with it's own headers, but instead it should use it only as
# code-compiler, with -nostdinc and headers of toolchain being built. What is
# more, that is exactly how things happen, when toolchain is built from unified
# source tree, when newlib is in the tree. But when they are build separately -
# things get awry, and improper process is used. That happens squarely because
# top level `configure` script will modify FLAGS_FOR_TARGET variable the way we
# need it _only_ when newlib is part of the whole build. For us workaround is
# simple - build of libstdc++ precompiled headers should be disabled (it
# doesn't seem they are installed anywhere), which removes problematic build
# step. Perhaps, more sustainable solution would be to make a step back with
# regards of unified tree usage and make newlib part of the unified source tree
# for baremetal builds.
if [ "$TOOLCHAIN_HOST" ]; then
    pch_opt=--disable-libstdcxx-pch
else
    pch_opt=
fi

# GCC must be built in 2 stages. First minimal GCC build is for building
# newlib and second stage is a complete GCC with newlib headers. See:
# http://www.ifp.illinois.edu/~nakazato/tips/xgcc.html
if [ "$DO_ELF32_GCC_STAGE1" = "yes" ]; then
    build_dir_init gcc-stage1
    configure_elf32 gcc gcc --without-headers --with-newlib
    make_target building all-gcc
    make_target installing ${HOST_INSTALL}-gcc
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

# GCC + configure of libstdc++ with newly installed newlib headers
build_dir_init gcc-stage2
configure_elf32 gcc gcc --with-newlib \
    --with-headers="$INSTALLDIR/${arch}-elf32/include" \
    --with-libs="$INSTALLDIR/${arch}-elf32/lib" $pch_opt
make_target building all-gcc all-target-libgcc
make_target installing ${HOST_INSTALL}-gcc install-target-libgcc
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gcc
fi

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
cd $build_dir/gcc-stage2
make_target building all-target-libstdc++-v3
make_target installing install-target-libstdc++-v3
# Don't build libstdc++ documentation because it requires additional software
# on build host.

# Expat if requested
if [ "$SYSTEM_EXPAT" = no ]
then
    mkdir -p $toolchain_build_dir/_download_tmp
    expat_version=2.1.0
    expat_tar=expat-${expat_version}.tar.gz
    if [ ! -s $toolchain_build_dir/_download_tmp/$expat_tar ]; then
	wget -nv -O $toolchain_build_dir/_download_tmp/$expat_tar \
	  http://sourceforge.net/projects/expat/files/expat/$expat_version/$expat_tar/download
    fi

    build_dir_init expat
    tar xzf $toolchain_build_dir/_download_tmp/$expat_tar --strip-components=1
    configure_elf32 expat $PWD
    make_target building all
    make_target installing install
fi

# GDB and CGEN simulator (maybe)
build_dir_init gdb
configure_elf32 gdb
make_target building all-gdb ${sim_build}
make_target installing ${sim_install} ${HOST_INSTALL}-gdb
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gdb
fi

# Restore GDB config for simulator (does nothing if the change was not made).
${SED} -i "${ARC_GNU}"/gdb/gdb/configure.tgt \
    -e 's!# gdb_sim=../sim/arc/libsim.a!gdb_sim=../sim/arc/libsim.a!'

# Copy TCF handler.
cp "$ARC_GNU/toolchain/extras/arc-tcf-gcc" "$INSTALLDIR/bin/${arch}-elf32-tcf-gcc"

echo "DONE  ELF32: $(date)" | tee -a "$logfile"

# vim: noexpandtab sts=4 ts=8:
