#!/usr/bin/env bash

# Copyright (C) 2010-2016 Synopsys Inc.

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

#     ${ARC_GNU}/toolchain/build_uclibc.sh

# The directory in which we are invoked is the build directory, in which all
# build directories are created.

# All other parameters are set by environment variables.

# LOGDIR

#     Directory for all log files.

# ARC_GNU

#     The directory containing all the sources. If not set, this will default
#     to the directory containing this script.

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

#     The defconfig to be used when building uClibc. That should a name of file
#     that is inside uClibc/extra/Configs/defconfig/arc directory.

# ISA_CPU

#     Specifies target ARC core, can be arc700 or archs.

# CONFIG_EXTRA

#     Additional flags for use with configuration.

# CFLAGS_FOR_TARGET
# CXXFLAGS_FOR_TARGET

#     Additional flags used when building the target libraries (e.g. for
#     compact libraries) picked up automatically by make. This variable is used
#     by configure scripts and make, and build-uclibc.sh doesn't do anything
#     about it explicitly.

# DO_PDF

#     Either --pdf or --no-pdf to control whether we build and install PDFs of
#     the user guides.

# PARALLEL

#     string "-j <jobs> -l <load>" to control parallel make.

# HOST_INSTALL

#     Make target prefix to install host application. Should be either
#     "install" or "install-strip".

# NPTL_SUPPORT

#     Build with threading, thread local storage support and NPTL if this is
#     set to "yes".

# We source the script arc-init.sh to set up variables needed by the script
# and define a function to get to the configuration directory (which can be
# tricky under MinGW/MSYS environments).

# The script generates a date and time stamped log file in the logs directory.

# Approach is following:
# 1. Install Linux headers
# 2. Install uClibc headers
# 3. Build and install Binutils
# 4. Build and install GCC stage 1 (without C++)
# 5. Build and install uClibc
# 6. Build and install GCC stage 2 (with C++)
# 7. Build and install GDB
# 8. Build and copy GDB-server for target

# Following after this paragraph text, is a text of historical significance
# that described how things used to be done in the age of ARC GCC 4.4 and early
# days of ARC GCC 4.8. Things changed since then so this is not totally
# relevant today, but explains how things evolved, since some things today can
# be done differently then they are done right now, because it was an evolution
# of previous decisions. For example it seems that we can install Linux and
# uClibc headers after stage 1 instead of doing this as a first step.  Although
# that might be true in general, but not for ARC, since our libgcc depends on
# libc headers. To be completely honest I haven't read this header guide while
# modifying toolchain to support sysroot and avoid unified source tree, as I
# was just looking at the code itself, and was completely oblivious to the
# presence of this gentoo web-guide... (On the matter of comments in code: will
# anybody read this???).

# << How it used to be done: >>

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

# << End of history lesson >>


# -----------------------------------------------------------------------------
# Local variables.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arche=arceb
    build_dir="$(echo "${PWD}")/bd-uclibceb"
else
    arche=arc
    build_dir="$(echo "${PWD}")/bd-uclibc"
fi

arch=arc
triplet=${arche}-snps-linux-uclibc

# Set up a logfile
logfile="${LOGDIR}/uclibc-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ${ARC_ENDIAN}-endian uClibc: $(date)" | tee -a ${logfile}

# Initalize, including getting the tool versions.
. "${ARC_GNU}"/toolchain/arc-init.sh
toolchain_build_dir="$(echo "${PWD}")"/toolchain
uclibc_build_dir="$(echo "${PWD}")"/uClibc
linux_src_dir=${LINUXDIR}
linux_build_dir=$build_dir/linux

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

# Note stuff for the log
echo "Installing in ${INSTALLDIR}" | tee -a ${logfile}

# Setup vars
if [ $IS_NATIVE = yes ]; then
    SYSROOTDIR=$INSTALLDIR
    install_prefix=
else
    SYSROOTDIR=$INSTALLDIR/$triplet/sysroot
    install_prefix=/usr
fi
DEFCFG_DIR=extra/Configs/defconfigs/arc/

# Purge old build dir if there is any and create a new one.
rm -rf "$build_dir"
mkdir -p "$build_dir"

# -----------------------------------------------------------------------------
# Install the Linux headers

echo "Installing Linux headers ..." | tee -a "${logfile}"
echo "============================" >> "${logfile}"

cd "${linux_src_dir}"

# It would be irresponsible for us to configure linux in source tree and leave
# it at that, because if anybody else after that would try to configure/build
# linux out-of-tree they will fail - Linux cannot configure out of tree when it
# is already configured in tree. So we need to either clean configuration after
# installing headers or just  configure out of tree ourself. Second options
# seems like more solid solution. However it will fail if Linux already has
# been configured. Bam! In that case we just use Linux as-is. All of that is
# mildly complex but this approach makes sure that this script is a friendly
# neighbor and doesn't pollute in many places.
if [ ! -f .config ]
then
    # Linux makefile expects this directory to exist.
    mkdir -p "$linux_build_dir"
    if make ARCH=arc defconfig O="$linux_build_dir" >> "${logfile}" 2>&1
    then
	echo "  finished configuring Linux"
	cd "$linux_build_dir"
    else
	echo "ERROR: Linux configuration was not successful. Please"
	echo "       see \"${logfile}\" for details."
	exit 1
    fi
else
    echo "  Linux already configured"
fi

# Wherever linux has been configured in or out of tree, at this stage we are in
# the directory with .config file.
if make ARCH=arc INSTALL_HDR_PATH=$SYSROOTDIR$install_prefix \
    headers_install >> "${logfile}" 2>&1
then
    echo "  finished installing Linux headers"
else
    echo "ERROR: Linux header install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# -----------------------------------------------------------------------------
# Install uClibc headers for the Stage 1 compiler. This needs a C compiler,
# which we do not yet have. We get round this by using the native C
# compiler. uClibc will complain, but get on with the job anyway.

echo "Installing uClibc headers ..." | tee -a "${logfile}"
echo "=============================" >> "${logfile}"

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

# Copy the defconfig file to a temporary location
TEMP_DEFCFG=`temp_file_in_dir "${DEFCFG_DIR}" XXXXXXXXXX_defconfig`
if [ ! -f "${TEMP_DEFCFG}" ]
then
    echo "ERROR: Failed to create temporary defconfig file."
    exit 1
fi
cp ${DEFCFG_DIR}${UCLIBC_DEFCFG} ${TEMP_DEFCFG}

# Patch defconfig with the temporary install directories used.
${SED} -e "s@%KERNEL_HEADERS%@$SYSROOTDIR$install_prefix/include@" \
       -e "s@%RUNTIME_PREFIX%@/@" \
       -e "s@%DEVEL_PREFIX%@$install_prefix/@" \
       -e "s@CROSS_COMPILER_PREFIX=\".*\"@CROSS_COMPILER_PREFIX=\"${triplet}-\"@" \
       -i ${TEMP_DEFCFG}

# Patch defconfig for big or little endian.
if [ "${ARC_ENDIAN}" = "big" ]
then
    ${SED} -e 's@ARCH_WANTS_LITTLE_ENDIAN=y@ARCH_WANTS_BIG_ENDIAN=y@' \
           -i ${TEMP_DEFCFG}
else
    ${SED} -e 's@ARCH_WANTS_BIG_ENDIAN=y@ARCH_WANTS_LITTLE_ENDIAN=y@' \
           -i ${TEMP_DEFCFG}
fi

# Patch the defconfig for thread support.
if [ "x${NPTL_SUPPORT}" = "xyes" ]
then
    ${SED} -e 's@LINUXTHREADS_OLD=y@UCLIBC_HAS_THREADS_NATIVE=y@' \
           -i ${TEMP_DEFCFG}
else
    ${SED} -e 's@UCLIBC_HAS_THREADS_NATIVE=y@LINUXTHREADS_OLD=y@' \
           -i ${TEMP_DEFCFG}
fi

# Create the .config from the temporary defconfig file.
make ARCH=arc `basename ${TEMP_DEFCFG}` >> "${logfile}" 2>&1

# Now remove the temporary defconfig file.
rm -f ${TEMP_DEFCFG}

# PREFIX is an arg to Makefile, it is not set in .config.
if make ARCH=${arch} V=1 PREFIX=${SYSROOTDIR} install_headers >> "${logfile}" 2>&1
then
    echo "  finished installing uClibc headers"
else
    echo "ERROR: uClibc header install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if [ "x${NPTL_SUPPORT}" = "xyes" ]
then
    thread_flags="--enable-threads --enable-tls"
else
    thread_flags="--disable-threads --disable-tls"
fi

if [ $IS_CROSS_COMPILING = yes ]; then
    # install-sh doesn't know anything about our cross-compiling things, so it
    # always uses "strip" by default. But {binutils,gdb}/Makefiles do set STRIPPROG
    # variable apropriately to arc-linux-strip, and install-sh uses this variable.
    # However it seems that in some cases STRIPPROG is not set, which causes a
    # failure, because "strip" on host system is not aware of ARC. For example in
    # binutils/binutils most targets are stripped correctly (objdump, objcopy to
    # name a few), but c++filt is not stripped - STRIPPROG is not set. To avoid
    # problems with cross-compilation STRIPPROG has to be explicitly set to
    # everyone. This is needed only for binutils and gdb.
    stripprog_opt="STRIPPROG=${triplet}-strip"

    # See build-elf32.sh for explanation of --disable-libstdcxx-pch
    pch_opt=--disable-libstdcxx-pch
else
    stripprog_opt=
    pch_opt=
fi

# -----------------------------------------------------------------------------
# Build Binutils - will be used by both state 1 and stage2
build_dir_init binutils
configure_uclibc_stage2 binutils
make_target building all-binutils all-ld all-gas

# Gas requires opcodes to be installed, LD requires BFD to be installed.
# However those dependencies are not described in the Makefiles, instead if
# required components is not yet installed, then dummy as-new and ld-new will
# be installed. Both libraries are installed by install-binutils. Therefore it
# is required that binutils is installed before ld and gas.
make_target_ordered installing ${HOST_INSTALL}-binutils ${HOST_INSTALL}-ld \
  ${HOST_INSTALL}-gas $stripprog_opt
if [ $DO_PDF = --pdf ]
then
    make_target "generating PDF documentation" install-pdf-binutils \
      install-pdf-ld install-pdf-gas
fi

# -----------------------------------------------------------------------------
# Add tool chain to the path for now, since binutils is required to build
# libgcc, while GCC stage 1 will be required to build uClibc, but remember the
# old path for restoring later. Not needed when cross compiling.
if [ $IS_CROSS_COMPILING != yes ]; then
    oldpath=${PATH}
    PATH=${INSTALLDIR}/bin:$PATH
    export PATH
fi

# -----------------------------------------------------------------------------
# Build stage 1 GCC (not needed when cross compiling).
if [ $IS_CROSS_COMPILING != yes ]; then
    build_dir_init gcc-stage1
    configure_uclibc_stage1 gcc
    make_target building all-gcc all-target-libgcc
    make_target installing ${HOST_INSTALL}-gcc install-target-libgcc
    # No need for PDF docs for stage 1.
fi

# -----------------------------------------------------------------------------
# Build uClibc using the stage 1 compiler.

echo "Building uClibc ..." | tee -a "${logfile}"
echo "===================" >> "${logfile}"

# We don't need to create directories or copy source, since that is already
# done when we got the headers.
cd ${uclibc_build_dir}

# Copy the defconfig file to a temporary location
TEMP_DEFCFG=`temp_file_in_dir "${DEFCFG_DIR}" XXXXXXXXXX_defconfig`
if [ ! -f "${TEMP_DEFCFG}" ]
then
    echo "ERROR: Failed to create temporary defconfig file."
    exit 1
fi
cp ${DEFCFG_DIR}${UCLIBC_DEFCFG} ${TEMP_DEFCFG}

# Patch defconfig with the temporary install directories used.
${SED} -e "s@%KERNEL_HEADERS%@$SYSROOTDIR$install_prefix/include@" \
       -e "s@%RUNTIME_PREFIX%@/@" \
       -e "s@%DEVEL_PREFIX%@$install_prefix/@" \
       -e "s@CROSS_COMPILER_PREFIX=\".*\"@CROSS_COMPILER_PREFIX=\"${triplet}-\"@" \
       -i ${TEMP_DEFCFG}

# At this step we also disable HARDWIRED_ABSPATH to avoid absolute
# path references to allow relocatable toolchains.
echo "HARDWIRED_ABSPATH=n" >> ${TEMP_DEFCFG}

# Patch defconfig for big or little endian.
if [ "${ARC_ENDIAN}" = "big" ]
then
    ${SED} -e 's@ARCH_WANTS_LITTLE_ENDIAN=y@ARCH_WANTS_BIG_ENDIAN=y@' \
           -i ${TEMP_DEFCFG}
else
    ${SED} -e 's@ARCH_WANTS_BIG_ENDIAN=y@ARCH_WANTS_LITTLE_ENDIAN=y@' \
           -i ${TEMP_DEFCFG}
fi

# Patch the defconfig for thread support.
if [ "x${NPTL_SUPPORT}" = "xyes" ]
then
    ${SED} -e 's@LINUXTHREADS_OLD=y@UCLIBC_HAS_THREADS_NATIVE=y@' \
           -i ${TEMP_DEFCFG}
else
    ${SED} -e 's@UCLIBC_HAS_THREADS_NATIVE=y@LINUXTHREADS_OLD=y@' \
           -i ${TEMP_DEFCFG}
fi

# Create the .config from the temporary defconfig file.
make ARCH=arc `basename ${TEMP_DEFCFG}` >> "${logfile}" 2>&1

# Now remove the temporary defconfig file.
rm -f ${TEMP_DEFCFG}

if make ARCH=${arch} clean >> "${logfile}" 2>&1
then
    echo "  finished cleaning uClibc"
else
    echo "ERROR: uClibc clean was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

# PREFIX is an arg to Makefile, it is not set in .config.
if make ARCH=${arch} V=2 PREFIX=${SYSROOTDIR} >> "${logfile}" 2>&1
then
    echo "  finished building uClibc"
else
    echo "ERROR: uClibc build was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if make ARCH=${arch} V=2 PREFIX=${SYSROOTDIR} install >> "${logfile}" 2>&1
then
    echo "  finished installing uClibc"
else
    echo "ERROR: uClibc install was not successful. Please see"
    echo "       \"${logfile}\" for details."
    exit 1
fi

if [ $IS_CROSS_COMPILING != yes ]; then
    # Restore the search path
    PATH=$oldpath
    unset oldpath
fi

# -----------------------------------------------------------------------------
# GCC stage 2
build_dir_init gcc-stage2
configure_uclibc_stage2 gcc gcc $pch_opt
make_target building all-gcc all-target-libgcc all-target-libstdc++-v3
make_target installing ${HOST_INSTALL}-gcc install-target-libgcc \
  install-target-libstdc++-v3
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gcc
fi

# Despite usage of "--with-sysroot" crt, libgcc and libstdc++ will be installed
# to different non-sysroot directories. So they has to be moved manually - GCC
# would find them in the sysroot without problems. Original files should be
# removed to enable "multiple sysroots" case, otherwise files in lib/gcc and
# $triplet/lib would have priority over the sysroot - that would negate the
# whole purpose of using sysroot. Also my experiments showed that G++ can't
# find libstdc++ headers in sysroot, they should be where they've been
# installed - that shouldn't be a problem as long as multiple sysroots differ
# only in binary parts, while headers are identical.
# This is not needed for native toolchain, which doesn't have sysroot.
if [ $IS_NATIVE != yes ]; then
    mv $INSTALLDIR/$triplet/lib/libgcc_s* $SYSROOTDIR/lib/
    mv $INSTALLDIR/$triplet/lib/libstdc++*.so* $SYSROOTDIR/usr/lib
    mv $INSTALLDIR/$triplet/lib/libstdc++*.{a,la} $SYSROOTDIR/usr/lib
    mv $INSTALLDIR/$triplet/lib/libsupc++.{a,la} $SYSROOTDIR/usr/lib

    mv $INSTALLDIR/lib/gcc/$triplet/*/*.o $SYSROOTDIR/usr/lib
    mv $INSTALLDIR/lib/gcc/$triplet/*/*.a $SYSROOTDIR/usr/lib
fi

# Add the newly created tool chain to the path
if [ $IS_CROSS_COMPILING != yes ]; then
    PATH=${INSTALLDIR}/bin:$PATH
    export PATH
fi

# -----------------------------------------------------------------------------
# Build and install GDB

# Expat if requested
if [ "$SYSTEM_EXPAT" = no ]
then
    build_expat $toolchain_build_dir/_download_tmp uclibc_stage2
fi

build_dir_init gdb
configure_uclibc_stage2 gdb
make_target building all-gdb
make_target installing ${HOST_INSTALL}-gdb $stripprog_opt
if [ "$DO_PDF" = "--pdf" ]
then
    make_target "generating PDF documentation" install-pdf-gdb
fi

# -----------------------------------------------------------------------------
# Create symlinks
echo "Creating symlinks ..." | tee -a "${logfile}"
echo "=====================" >> "${logfile}"

cd ${INSTALLDIR}/bin
for i in ${triplet}-*
do
    ln -fs $i $(echo $i | sed "s/${triplet}/${arche}-linux/")
    ln -fs $i $(echo $i | sed "s/${triplet}/${arche}-linux-uclibc/")
done

echo "  finished creating symlinks"

# -----------------------------------------------------------------------------
# Native GDB

if [ $DO_NATIVE_GDB = yes ]; then

    # GDB needs ncurses (termcap to be exact).
    # Since ncurses is a separate product it is an outlier with regards of build process.
    ncurses_version=5.9
    ncurses_url_base=http://ftp.gnu.org/pub/gnu/ncurses
    ncurses_tar=ncurses-${ncurses_version}.tar.gz
    ncurses_url=$ncurses_url_base/$ncurses_tar
    mkdir -p $toolchain_build_dir/_download_tmp
    cd $toolchain_build_dir/_download_tmp
    if [ ! -s $ncurses_tar ]; then
	wget -nv -O $ncurses_tar $ncurses_url
    fi

    build_dir_init ncurses
    tar xaf $toolchain_build_dir/_download_tmp/$ncurses_tar --strip-components=1

    # Update ncurses/config.sub which is not aware of arceb-* targets
    patch config.sub $ARC_GNU/toolchain/extras/ncurses.big-endian.patch

    # Ada is not supported on ARC, so it has to be disabled, otherwise dumb
    # configure script might find Ada compiler for host system and will try to
    # use it as a compiler for ARC.
    # C++ has to be disabled because of STAR9000908736 - there is an error when
    # linking its demo application. Otherwise there is no reason to disable C++
    # support.
    configure_for_arc . $triplet --without-cxx-binding --without-ada
    make_target building
    make_target_ordered installing install DESTDIR=$SYSROOTDIR

    build_dir_init native_gdb

    config_path=$(calcConfigPath "${ARC_GNU}")/gdb
    configure_for_arc "$config_path" $triplet \
	--disable-gas --disable-ld --disable-binutils
    make_target building

    # See comment for stripprog_opt for an explanation why this is needed.
    # Strip will strip complete symbol table, not just debug symbols.
    make_target_ordered installing install-strip-gdb DESTDIR=$SYSROOTDIR \
	STRIPPROG=${triplet}-strip
else
    # If native GDB has been disabled, then simple gdbserver still will be
    # built. It doesn't need ncurses.
    build_dir_init gdbserver
    # Static options are same as when gdbserver is configured by the top-level
    # configure script.
    config_path=$(calcConfigPath "${ARC_GNU}")/gdb/gdb/gdbserver
    LDFLAGS="-static-libstdc++ -static-libgcc" \
	configure_for_arc "$config_path" $triplet
    make_target building

    # gdbserver makefile lacks install-strip target. It is possible to trick
    # gdbserver Makefile to install stripped binary by setting INSTAL_PROGRAM
    # Makefile variable to 'install -c -s', however this way gdbserver would be
    # stripped from all symbols, not just debug symbols.
    # Note that $SYSROOTDIR/bin might not exist yet.
    mkdir -p $SYSROOTDIR$install_prefix/bin
    ${triplet}-objcopy -g gdbserver $SYSROOTDIR$install_prefix/bin/gdbserver
fi

echo "DONE  UCLIBC: $(date)" | tee -a "${logfile}"

# vim: noexpandtab sts=4 ts=8:
