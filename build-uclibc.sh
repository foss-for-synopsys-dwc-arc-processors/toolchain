#!/bin/sh

# Copyright (C) 2010-2014 Synopsys Inc.

# Contributor Brendan Kehoe <brendan@zen.org>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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

# UCLIBC_DISABLE_MULTILIB

#     Either --enable-multilib or --disable-multilib to control the building
#     of multilibs.

# UCLIBC_DEFCFG

#     The defconfig to be used when building uClibc.

# ISA_CPU

#     For use with the --with-cpu flag to specify the ISA. Can be arc700 or
#     archs.

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

# TLS_SUPPORT

#     Build with threading and thread local storage support if this is
#     set to "yes".

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
# and uses a build directory (bd-4.8-uclibc) local to the directory in which
# it is executed.

# The script generates a date and time stamped log file in the logs directory.

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

# We build GDB after GCC. gdbserver also has to be built and installed
# separately. So we add two extra steps

# 6. Build & install GDB
# 7. Build & install gdbserver


# -----------------------------------------------------------------------------
# Local variables.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arche=arceb
    build_dir="$(echo "${PWD}")"/bd-${RELEASE}-uclibceb
else
    arche=arc
    build_dir="$(echo "${PWD}")"/bd-${RELEASE}-uclibc
fi
build_dir_stage1=${build_dir}-stage1

arch=arc
unified_src_abs="$(echo "${PWD}")"/${UNISRC}
triplet=${arche}-snps-linux-uclibc

if [ $ISA_CPU = arc700 ]
then
    version_str="ARCompact ISA Linux uClibc toolchain $RELEASE_NAME"
else
    version_str="ARCv2 ISA Linux uClibc toolchain $RELEASE_NAME"
fi
bugurl_str="http://solvnet.synopsys.com"

# parse options
until
opt=$1
case ${opt} in
    --force)
	rm -rf ${build_dir}
	;;
    ?*)
	echo "Usage: ./build-uclibc.sh [--force]"
	exit 1
	;;
esac
[ -z "${opt}" ]
do
    shift
done

# Set up a logfile
logfile="${LOGDIR}/uclibc-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ${ARC_ENDIAN}-endian uClibc: $(date)" >> ${logfile}
echo "START ${ARC_ENDIAN}-endian uClibc: $(date)"

# Initalize, including getting the tool versions. Note that we don't need
# newlib for now if we rebuild our unified source tree.
. "${ARC_GNU}"/toolchain/arc-init.sh
uclibc_build_dir="$(echo "${PWD}")"/uClibc
linux_build_dir=${LINUXDIR}

# Note stuff for the log
echo "Installing in ${INSTALLDIR}" >> ${logfile} 2>&1
echo "Installing in ${INSTALLDIR}"

# Setup vars
SYSROOTDIR=${INSTALLDIR}/${triplet}/sysroot

# -----------------------------------------------------------------------------
# Install the Linux headers

echo "Installing Linux headers" >> "${logfile}"
echo "========================" >> "${logfile}"

echo "Start installing LINUX headers ..."

cd "${linux_build_dir}"

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

if make ARCH=${arch} INSTALL_HDR_PATH=${SYSROOTDIR}/usr \
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

# make will fail if there is yet no .config file, but we can ignore this error.
make distclean >> "${logfile}" 2>&1 || true 

# Patch the temporary install directories used into the uClibc config.
# uClibc 0.9.34 onwards use defconfig
if [ ! -f extra/Configs/defconfigs/arc/defconfig ]
then
    ${SED} -e "s#%KERNEL_HEADERS%#${SYSROOTDIR}/usr/include#" \
           -e "s#%RUNTIME_PREFIX%#/#" \
           -e "s#%DEVEL_PREFIX%#$/usr/#" \
           -e "s#%CROSS_COMPILER_PREFIX%#${triplet}-#" \
           < "${ARC_GNU}"/uClibc/arc_config > .config
else
    make ARCH=arc ${UCLIBC_DEFCFG} >> "${logfile}" 2>&1
    ${SED} -e "s#%KERNEL_HEADERS%#${SYSROOTDIR}/usr/include#" \
           -e "s#%RUNTIME_PREFIX%#/#" \
           -e "s#%DEVEL_PREFIX%#/usr/#" \
           -e "s#CROSS_COMPILER_PREFIX=\".*\"#CROSS_COMPILER_PREFIX=\"${triplet}-\"#" \
	   -i .config
fi

# Patch .config for big endian for use with correct flags
if [ "${ARC_ENDIAN}" = "big" ]
then
    ${SED} -e 's@ARCH_LITTLE_ENDIAN=y@# ARCH_LITTLE_ENDIAN is not set@' \
           -e 's@# ARCH_BIG_ENDIAN is not set@ARCH_BIG_ENDIAN=y@' \
           -i .config
else
    ${SED} -e 's@ARCH_BIG_ENDIAN=y@# ARCH_BIG_ENDIAN is not set@' \
           -e 's@# ARCH_LITTLE_ENDIAN is not set@ARCH_LITTLE_ENDIAN=y@' \
           -i .config
fi

# PREFIX is an arg to Makefile, it is not set in .config.
if make ARCH=${arch} V=1 PREFIX=${SYSROOTDIR} install_headers >> "${logfile}" 2>&1
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

# Create the build dir for stage 1.
rm -rf "${build_dir_stage1}"
mkdir -p "${build_dir_stage1}"
cd "${build_dir_stage1}"

# Configure the build. Disable anything that might try to build a run-time
# library and don't bother with multilib for stage 1. Note: with gcc 4.4.x, we
# also disable building libgomp
if [ "x${TLS_SUPPORT}" = "xyes" ]
then
    thread_flags="--enable-threads --enable-tls"
else
    thread_flags="--disable-threads --disable-tls"
fi
config_path=$(calcConfigPath "${unified_src_abs}")
if "${config_path}"/configure --target=${triplet} \
        --with-cpu=${ISA_CPU} \
        --disable-fast-install --with-endian=${ARC_ENDIAN} ${DISABLEWERROR} \
        --disable-multilib \
        --enable-languages=c --prefix="${INSTALLDIR}" \
        --without-headers --enable-shared ${thread_flags} \
        --disable-libssp --disable-libmudflap --without-newlib --disable-c99 \
        --disable-libgomp ${CONFIG_EXTRA} \
        --with-sysroot=${SYSROOTDIR} \
	>> "${logfile}" 2>&1
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
PATH=${INSTALLDIR}/bin:$PATH
export PATH

# -----------------------------------------------------------------------------
# Build uClibc using the stage 1 compiler.

echo "Building uClibc" >> "${logfile}"
echo "===============" >> "${logfile}"

echo "Start building UCLIBC ..."

# We don't need to create directories or copy source, since that is already
# done when we got the headers.
cd ${uclibc_build_dir}

# Patch the directories used into the uClibc config. Note that the kernel
# headers will have been moved by the previous header install. At this step we
# also disable HARDWIRED_ABSPATH to avoid absolute path references to allow
# relocatable toolchains.
if [ ! -f extra/Configs/defconfigs/arc/defconfig ]
then
    ${SED} -e "s#%KERNEL_HEADERS%#${SYSROOTDIR}/usr/include#" \
           -e "s#%RUNTIME_PREFIX%#/#" \
           -e "s#%DEVEL_PREFIX%#/usr/#" \
           -e "s#%CROSS_COMPILER_PREFIX%#${triplet}-#" \
           -e "s/HARDWIRED_ABSPATH=y/# HARDWIRED_ABSPATH is not set/" \
           < "${ARC_GNU}"/uClibc/arc_config > .config
else
    make ARCH=arc ${UCLIBC_DEFCFG} >> "${logfile}" 2>&1
    ${SED} -e "s#%KERNEL_HEADERS%#${SYSROOTDIR}/usr/include#" \
           -e "s#%RUNTIME_PREFIX%#/#" \
           -e "s#%DEVEL_PREFIX%#/usr/#" \
           -e "s#CROSS_COMPILER_PREFIX=\".*\"#CROSS_COMPILER_PREFIX=\"${triplet}-\"#" \
           -e "s/HARDWIRED_ABSPATH=y/# HARDWIRED_ABSPATH is not set/" \
           -i .config
fi

# Patch .config for big endian for use with correct flags
if [ "${ARC_ENDIAN}" = "big" ]
then
    ${SED} -e 's@ARCH_LITTLE_ENDIAN=y@# ARCH_LITTLE_ENDIAN is not set@' \
           -e 's@# ARCH_BIG_ENDIAN is not set@ARCH_BIG_ENDIAN=y@' \
           -i .config
else 
    ${SED} -e 's@ARCH_BIG_ENDIAN=y@# ARCH_BIG_ENDIAN is not set@' \
           -e 's@# ARCH_LITTLE_ENDIAN is not set@ARCH_LITTLE_ENDIAN=y@' \
           -i .config
fi

if make ARCH=${arch} clean >> "${logfile}" 2>&1
then
    echo "  finished cleaning UCLIBC"
else
    echo "ERROR: uClibc clean was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# PREFIX is an arg to Makefile, it is not set in .config.
if make ARCH=${arch} V=2 PREFIX=${SYSROOTDIR} >> "${logfile}" 2>&1
then
    echo "  finished building UCLIBC"
else
    echo "ERROR: uClibc build was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make ARCH=${arch} V=2 PREFIX=${SYSROOTDIR} install >> "${logfile}" 2>&1
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

# Recreate the build dir
rm -rf "${build_dir}"
mkdir -p "${build_dir}"
cd "${build_dir}"

# Configure the build. This time we allow things, and use the headers from the
# stage 1 build. We still have to disable libgomp
config_path=$(calcConfigPath "${unified_src_abs}")
if "${config_path}"/configure --target=${triplet} \
        --with-cpu=${ISA_CPU} \
        ${UCLIBC_DISABLE_MULTILIB} \
        --with-pkgversion="${version_str}"\
        --with-bugurl="${bugurl_str}" \
        --enable-fast-install=N/A  --with-endian=${ARC_ENDIAN} ${DISABLEWERROR} \
        --enable-languages=c,c++ --prefix="${INSTALLDIR}" \
        --enable-shared --without-newlib --disable-libgomp ${CONFIG_EXTRA} \
        --with-sysroot=${SYSROOTDIR} \
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

if make ${HOST_INSTALL}-binutils ${HOST_INSTALL}-gas ${HOST_INSTALL}-ld \
    ${HOST_INSTALL}-gcc install-target-libgcc install-target-libstdc++-v3 \
	>> "${logfile}" 2>&1
then
    echo "  finished installing stage 2 tool chain"
else
    echo "ERROR: Stage 2 install was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

# Despite "--with-sysroot" libgcc and libstdc++ will be installed to default
# directory. Copy them manually. It also looks like that buildroot will work
# properly even without this change and will copy libraries to the target
# system appropriately in any way. However Buildroot does this step with its
# internal toolchain and I'm mimicking this. Also this might help if one want
# to have multiple sysroots. In that latter case I suppose that libraries
# outside of sysroots should be removed to avoid unintentional mixing. Also my
# experiments showed that G++ can't find libstdc++ headers in sysroot, they
# should be where they've been installed.
cp -dpf ${INSTALLDIR}/${triplet}/lib/libgcc_s* ${SYSROOTDIR}/lib/
cp -dpf ${INSTALLDIR}/${triplet}/lib/libstdc++*.so* ${SYSROOTDIR}/usr/lib
cp -dpf ${INSTALLDIR}/${triplet}/lib/libstdc++*.a ${SYSROOTDIR}/usr/lib

# Add the newly created tool chain to the path
PATH=${INSTALLDIR}/bin:$PATH
export PATH

# -----------------------------------------------------------------------------
# Build and install GDB
echo "Building GDB" >> "${logfile}"
echo "============" >> "${logfile}"

echo "Start building GDB ..."

# Create the build dir, then build and install
cd "${build_dir}"

if make ${PARALLEL} all-gdb >> "${logfile}" 2>&1
then
    echo "  finished building GDB"
else
    echo "ERROR: GDB build was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

if make install-gdb >> "${logfile}" 2>&1
then
    echo "  finished installing GDB"
else
    echo "ERROR: GDB install was not successful. Please see "
    echo "       \""${logfile}"\" for details."
    exit 1
fi

# -----------------------------------------------------------------------------
# Create symlinks
echo "Creating symlinks" >> "${logfile}"
echo "=================" >> "${logfile}"

cd ${INSTALLDIR}/bin
for i in ${triplet}-*
do
    ln -fs $i $(echo $i | sed "s/${triplet}/${arche}-linux/")
    ln -fs $i $(echo $i | sed "s/${triplet}/${arche}-linux-uclibc/")
done

echo "  finished creating symlinks"

# -----------------------------------------------------------------------------
# gdbserver has to be built on its own.

echo "Building gdbserver to run on an ARC" >> "${logfile}"
echo "===================================" >> "${logfile}"

echo "Start building GDBSERVER to run on an ARC ..."

rm -rf ${build_dir}/gdb/gdbserver
mkdir -p ${build_dir}/gdb/gdbserver
cd ${build_dir}/gdb/gdbserver

config_path=$(calcConfigPath "${unified_src_abs}")/gdb/gdbserver
if "${config_path}"/configure \
        --with-pkgversion="${version_str}"\
        --with-bugurl="${bugurl_str}" \
        --host=${triplet} >> "${logfile}" 2>> "${logfile}"
then
    echo "  finished configuring gdbserver"
else
    echo "ERROR: gdbserver configure failed. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

CC=${triplet}-gcc
export CC
if make ${PARALLEL} \
    CFLAGS="-static -fcommon -mno-sdata -O3 ${CFLAGS_FOR_TARGET}" \
    >> "${logfile}" 2>&1
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

# Optionally build and install PDF documentation
if [ "x${DO_PDF}" = "x--pdf" ]
then
    echo "Building PDF documentation" >> "${logfile}"
    echo "==========================" >> "${logfile}"

    echo "Building PDFs ..."
    cd "${build_dir}"
    if make ${PARALLEL} pdf-binutils pdf-gas pdf-ld pdf-gcc \
	pdf-gdb >> "${logfile}" 2>&1
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

    echo "Installing PDF documentation" >> "${logfile}"
    echo "============================" >> "${logfile}"

    echo "Installing PDFs ..."
    if make install-pdf-binutils install-pdf-gas install-pdf-ld \
	install-pdf-gcc install-pdf-gdb >> "${logfile}" 2>&1
    then
	echo "  finished installing PDFs"
    else
	echo "ERROR: PDF install failed."
	exit 1
    fi
fi

echo "DONE  UCLIBC: $(date)" >> ${logfile}
echo "DONE  UCLIBC: $(date)"
