#!/bin/sh

# Copyright (C) 2010-2012 Synopsys Inc.

# Contributor Brendan Kehoe <brendan@zen.org>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a master script for ARC tool chains.

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

#		   SCRIPT TO BUILD ARC-LINUX-UCLIBC TOOLKIT
#		   ========================================

# Usage:

#     ${ARC_GNU}/toolchain/build_uclibc.sh [--force]

# --force

#     Blow away any old build sub-directories

# The directory in which we are invoked is the build directory, in which we
# find the unified source tree and in which all build directories are created.

# All other parameters are set by environment variables.

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

# LINUXDIR

#     The directory containing the Linux source tree (needed for headers).

# UNISRC

#     The name of the unified source directory within the build directory

# INSTALLDIR

#     The directory where the tool chain should be installed

# ARC_ENDIAN

#     "big" or "little" to indicate the endianness to use.

# DISABLE_MULTILIB

#     Either --enable-multilib or --disable-multilib to control the building
#     of multilibs

# Unlike earlier versions of this script, we do not recognize the
# ARC_GNU_ONLY_CONFIGURE and ARC_GNU_CONTINUE environment variables. If you
# are using this script, you need to run the whole thing. If you want to redo
# bits, go into the relevant directories and do it by hand!

# This version is modified to work with the source tree as organized in
# GitHub.

# We source the script arc-init.sh to set up variables needed by the script
# and define a function to get to the configuration directory (which can be
# tricky under MinGW/MSYS environments).

# The script constructs a unified source directory (if --force is specified)
# and uses a build directory (bd-elf32) local to the directory in which it is
# executed. The script generates a date and time stamped log file in that
# directory.

# This approach is based on Mike Frysinger's guidelines on building a
# cross-compiler.

#     http://dev.gentoo.org/~vapier/CROSS-COMPILE-GUTS

# However this seems to have a basic flaw, because it relies on using sysroot,
# and for older versions of GCC (4.4.x included), the build of libgcc does not
# take any notice of sysroot.

# This has been extended to uClibc and brought up to date, using the
# install-headers targets of Linux and uClibc.

# The basic approach recommended by Frysinger is:

# 1. Build binutils
# 2. Install the Linux kernel headers
# 3. Install the uClibc headers
# 4. Build gcc stage 1 (C only)
# 5. Build uClibc
# 6. Build gcc stage 2 (C, C++ etc)

# We create a sysroot, where we can put our intermediate stuff. However there
# is a catch with GCC 4.4.7 (fixed in in GCC 4.7) that libgcc is muddled up in
# gcc and doesn't seem to recognize the sysroot. So we have to also install
# headers in the install directory before building libgcc.

# So we use a revised flow.

# 1. Install the Linux kernel headers into the temporary directory
# 2. Install uClibc headers into the temporary directory using host GCC
# 3. Build and install GCC stage 1 without headers into temporary directory
# 4. Build & install uClibc using the stage 1 compiler into the final directory
# 5. Build & install the whole tool chain from scratch (including GCC stage 2)
#    using the temporary headers

# At present the GDB binutils libraries are out of step, so GDB has to be
# built separately. gdbserver also has to be built and installed
# separately. So we add two extra steps

# 6. Build & install GDB
# 7. Build & install gdbserver


# -----------------------------------------------------------------------------
# Local variables.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arche=arceb
else
    arche=arc
fi

arch=arc
unified_src_abs="$(echo "${PWD}")"/${UNISRC}
build_dir="$(echo "${PWD}")"/bd-uclibc
build_dir_gdb="$(echo "${PWD}")"/bd-uclibc-gdb

version_str="ARCompact Linux uClibc toolchain (built $(date +%Y%m%d))"
bugurl_str="http://solvnet.synopsys.com"


# tmp_install_dir = Temporary install dir for stage 1 compiler
tmp_install_dir="$(echo "${PWD}")/tmp-install-uclibc-$$"
rm -rf ${tmp_install_dir}
mkdir -p ${tmp_install_dir}

# parse options
until
opt=$1
case ${opt} in
    --force)
	rm -rf ${build_dir} ${build_dir_gdb}
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
logfile="$(echo "${PWD}")/uclibc-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ${ARC_ENDIAN}-endian uClibc: $(date)" >> ${logfile}
echo "START ${ARC_ENDIAN}-endian uClibc: $(date)"

# Initalize, including getting the tool versions. Note that we don't need
# newlib for now if we rebuild our unified source tree.
. "${ARC_GNU}"/toolchain/arc-init.sh
uclibc_build_dir="$(echo "${PWD}")"/uClibc
linux_build_dir="$(echo "${PWD}")"/linux
gdb_dir="${ARC_GNU}/gdb"

# Note stuff for the log
echo "Installing in ${INSTALLDIR}" >> ${logfile} 2>&1
echo "Installing in ${INSTALLDIR}"

# -----------------------------------------------------------------------------
# Install the Linux headers

echo "Installing Linux headers" >> "${logfile}"
echo "========================" >> "${logfile}"

echo "Start installing LINUX headers ..."

# Linux builds in place, so if ${ARC_GNU} is set (to a different location) we
# have to create the directory and copy the source across.
mkdir -p "${linux_build_dir}"
cd "${linux_build_dir}"

if [ ! -f Makefile ]
then
    echo Copying over Linux sources
    tar -C "${LINUXDIR}" --exclude=.svn --exclude='*.o' \
	--exclude='*.a' -cf - . | tar -xf -
fi

# Configure Linux if not already
if [ ! -f .config ]; then
    if make ARCH=${arch} defconfig >> "${logfile}" 2>&1
    then
	echo "  finished configuring LINUX"
    else
	echo "ERROR: Linux configuration was not successful. Please"
	echo "       see \"${logfile}\" for details."
	exit 1
    fi
else
    echo "  LINUX already configured"
fi

if make ARCH=${arch} INSTALL_HDR_PATH=${tmp_install_dir}/${arche}-linux-uclibc \
    headers_install >> "${logfile}" 2>&1
then
    echo "  finished installing LINUX headers"
else
    echo "ERROR: LINUX header install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# -----------------------------------------------------------------------------
# Install uClibc headers for the Stage 1 compiler. This needs a C compiler,
# which we do not yet have. We get round this by using the native C
# compiler. uClibc will complain, but get on with the job anyway.

echo "Installing uClibc headers" >> "${logfile}"
echo "=========================" >> "${logfile}"

echo "Start installing UCLIBC headers ..."

# uClibc builds in place, so if ${ARC_GNU} is set (to a different location) we
# have to create the directory and copy the source across.
mkdir -p ${uclibc_build_dir}
cd ${uclibc_build_dir}

if [ ! -f Makefile.in ]
then
    echo Copying over uClibc sources
    tar -C "${ARC_GNU}"/uClibc --exclude=.svn --exclude='*.o' \
	--exclude='*.a' -cf - . | tar -xf -
fi

# Patch the temporary install directories used into the uClibc config. There
# are better ways to do this using defconfig, but for now we'll leave it.
sed -e "s#%KERNEL_HEADERS%#${tmp_install_dir}/include#" \
    -e "s#%RUNTIME_PREFIX%#${tmp_install_dir}/${arche}-linux-uclibc/#" \
    -e "s#%DEVEL_PREFIX%#${tmp_install_dir}/${arche}-linux-uclibc/#" \
    -e "s#%CROSS_COMPILER_PREFIX%##" \
    < "${ARC_GNU}"/uClibc/arc_config > .config

if make ARCH=${arch} V=1 install_headers >> "${logfile}" 2>&1
then
    echo "  finished installing UCLIBC headers"
else
    echo "ERROR: uClibc header install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi
  
# -----------------------------------------------------------------------------
# Stage 1 GCC built without headers into the temporary install directory.

echo "Building gcc stage 1" >> "${logfile}"
echo "====================" >> "${logfile}"

echo "Start building GCC stage 1 ..."

# Create the build dir
rm -rf "${build_dir}"
mkdir -p "${build_dir}"
cd "${build_dir}"

# Configure the build. Disable anything that might try to build a run-time
# library and don't bother with multilib for stage 1. Note: with gcc 4.4.x, we
# also disable building libgomp
config_path=$(calcConfigPath "${unified_src_abs}")
if "${config_path}"/configure --target=${arche}-linux-uclibc --with-cpu=arc700 \
        --disable-fast-install --with-endian=${ARC_ENDIAN} \
        --disable-werror --disable-multilib \
        --enable-languages=c --prefix="${tmp_install_dir}" \
        --without-headers --enable-shared --disable-threads --disable-tls \
	--disable-libssp --disable-libmudflap --without-newlib --disable-c99 \
	--disable-libgomp >> "${logfile}" 2>&1
then
    echo "  finished configuring stage 1"
else
    echo "ERROR: Stage 1 configure failed. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi
   
if make ${PARALLEL} all-build all-binutils all-gas all-ld all-gcc \
                    all-target-libgcc >> "${logfile}" 2>&1
then
    echo "  finished building stage 1"
else
    echo "ERROR: Stage 1 build was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make install-binutils install-gas install-ld install-gcc \
        install-target-libgcc >> "${logfile}" 2>&1
then
    echo "  finished installing stage 1"
else
    echo "ERROR: Stage 1 install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# Add the newly created stage 1 tool chain to the path for now, but remember
# the old path for restoring later.
oldpath=${PATH}
export PATH=${tmp_install_dir}/bin:$PATH

# -----------------------------------------------------------------------------
# Build uClibc using the stage 1 compiler.

echo "Building uClibc" >> "${logfile}"
echo "===============" >> "${logfile}"

echo "Start building UCLIBC ..."

# We don't need to create directories or copy source, since that is already
# done when we got the headers.
cd ${uclibc_build_dir}

# Patch the directories used into the uClibc config. Note that the kernel
# headers will have been moved by the previous header install. There are
# better ways to do this using defconfig, but for now we'll leave it.
sed -e "s#%KERNEL_HEADERS%#${tmp_install_dir}/${arche}-linux-uclibc/include#" \
    -e "s#%RUNTIME_PREFIX%#${INSTALLDIR}/${arche}-linux-uclibc/#" \
    -e "s#%DEVEL_PREFIX%#${INSTALLDIR}/${arche}-linux-uclibc/#" \
    -e "s#%CROSS_COMPILER_PREFIX%#${arche}-linux-uclibc-#" \
    < "${ARC_GNU}"/uClibc/arc_config > .config

if make ARCH=${arch} clean >> "${logfile}" 2>&1
then
    echo "  finished cleaning UCLIBC"
else
    echo "ERROR: uClibc clean was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi
  
if make ARCH=${arch} V=1 >> "${logfile}" 2>&1
then
    echo "  finished building UCLIBC"
else
    echo "ERROR: uClibc build was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make ARCH=${arch} V=1 install >> "${logfile}" 2>&1
then
    echo "  finished installing UCLIBC"
else
    echo "ERROR: uClibc install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# Restore the search path
PATH=${oldpath}
unset oldpath

# -----------------------------------------------------------------------------
# Build and install the full tool chain in the proper directory. Blow away the
# old build directory and start again.
echo "Building final (stage 2) tool chain" >> "${logfile}"
echo "===================================" >> "${logfile}"

echo "Start building Stage 2 TOOL CHAIN ..."

# Re Create the build dir
rm -rf "${build_dir}"
mkdir -p "${build_dir}"
cd "${build_dir}"

# Configure the build. This time we allow things, and use the headers from the
# stage 1 build. We still have to disable libgomp
config_path=$(calcConfigPath "${unified_src_abs}")
if "${config_path}"/configure --target=${arche}-linux-uclibc --with-cpu=arc700 \
        --disable-werror ${DISABLE_MULTILIB} \
        --with-pkgversion="${version_str}"\
        --with-bugurl="${bugurl_str}" \
        --enable-fast-install=N/A  --with-endian=${ARC_ENDIAN} \
        --with-headers=${tmp_install_dir}/${arche}-linux-uclibc/include \
        --enable-languages=c,c++ --prefix="${INSTALLDIR}" \
        --enable-shared --without-newlib --disable-libgomp \
    >> "${logfile}" 2>&1
then
    echo "  finished configuring stage 2 build"
else
    echo "ERROR: stage 2 configure failed. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make ${PARALLEL} all-build all-binutils all-gas all-ld all-gcc \
                    all-target-libgcc all-target-libstdc++-v3 \
                    >> "${logfile}" 2>&1
then
    echo "  finished building stage 2 tool chain"
else
    echo "ERROR: Stage 2 build was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

if make install-binutils install-gas install-ld install-gcc \
        install-target-libgcc install-target-libstdc++-v3 >> "${logfile}" 2>&1
then
    echo "  finished installing stage 2 tool chain"
else
    echo "ERROR: Stage 2 install was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

# Add the newly created tool chain to the path
export PATH=${INSTALLDIR}/bin:$PATH

# -----------------------------------------------------------------------------
# Build and install GDB separately. We need to do this, because its binutils
# libraries are not compatible.
echo "Building GDB" >> "${logfile}"
echo "============" >> "${logfile}"

echo "Start building GDB ..."

# Create the build dir
rm -rf "${build_dir_gdb}"
mkdir -p "${build_dir_gdb}"
cd "${build_dir_gdb}"

# Configure the build. This time we allow things, and use the headers from the
# stage 1 build. We still have to disable libgomp
config_path=$(calcConfigPath "${gdb_dir}")
if "${config_path}"/configure --target=${arche}-linux-uclibc --with-cpu=arc700 \
        --disable-werror ${DISABLE_MULTILIB} \
        --with-pkgversion="${version_str}"\
        --with-bugurl="${bugurl_str}" \
        --enable-fast-install=N/A  --with-endian=${ARC_ENDIAN} \
        --prefix="${INSTALLDIR}" \
    >> "${logfile}" 2>&1
then
    echo "  finished configuring GDB"
else
    echo "ERROR: GDB configure failed. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make ${PARALLEL} all-sim all-gdb >> "${logfile}" 2>&1
then
    echo "  finished building GDB"
else
    echo "ERROR: GDB build was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

if make install-sim install-gdb >> "${logfile}" 2>&1
then
    echo "  finished installing GDB"
else
    echo "ERROR: GDB install was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

# -----------------------------------------------------------------------------
# gdbserver has to be built on its own.

echo "Building gdbserver to run on an ARC" >> "${logfile}"
echo "===================================" >> "${logfile}"

echo "Start building GDBSERVER to run on an ARC ..."

rm -rf ${build_dir_gdb}/gdb/gdbserver
mkdir -p ${build_dir_gdb}/gdb/gdbserver
cd ${build_dir_gdb}/gdb/gdbserver

config_path=$(calcConfigPath "${gdb_dir}"/gdb/gdbserver)
if "${config_path}"/configure \
        --with-pkgversion="${version_str}"\
        --with-bugurl="${bugurl_str}"  --with-endian=${ARC_ENDIAN} \
        --with-bugurl="http://solvnet.synopsys.com" \
        --host=${arche}-linux-uclibc >> "${logfile}" 2>> "${logfile}"
then
    echo "  finished configuring gdbserver"
else
    echo "ERROR: gdbserver configure failed. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

export CC=${arche}-linux-uclibc-gcc
if make ${PARALLEL} CFLAGS="${CFLAGS} -static" >> "${logfile}" 2>&1
then
    echo "  finished building GDBSERVER to run on an arc"
else
    echo "ERROR: gdbserver build was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

mkdir -p ${INSTALLDIR}/target-bin
if cp gdbserver ${INSTALLDIR}/target-bin
then
    echo "  finished installing GDBSERVER to run on an ARC"
else
    echo "ERROR: gdbserver install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

rm -rf "${tmp_install_dir}"

echo "DONE  UCLIBC: $(date)" >> ${logfile}
echo "DONE  UCLIBC: $(date)"
