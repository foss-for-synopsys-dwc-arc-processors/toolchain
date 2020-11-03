#!/usr/bin/env bash

# Copyright (C) 2017 Synopsys Inc.

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

# We source the script arc-init.sh to set up variables needed by the script
# and define a function to get to the configuration directory (which can be
# tricky under MinGW/MSYS environments).

# The script generates a date and time stamped log file in the logs directory.

# Approach is following:
# 1. Install Linux headers
# 2. Build and install Binutils
# 3. Build and install GCC stage 1 (without libgcc and C++)
# 4. Install glibc headers
# 5. Build and install libgcc from GCC stage 1 build tree.
# 6. Build and install glibc
# 7. Build and install GCC stage 2 (with C++)
# 8. Build and install GDB
# 9. Build and copy GDB-server for target and or native GDB.

# Order of things may change, there are various guides in the Internet that
# have some slightly different proposals. For example, this:
#
#   http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/
#
# proposes that we don't really need to build gcc and libgcc second time at
# stage 2. That does make sense to me, however it is important to understand
# that gcc and libgcc "configure" scripts can make different decisions based on
# what headers and binary files are already present in the installation
# location, therefore I'm not 100% sure that gcc and libgcc from stage 2 are
# identical to those from stage 1. Someone should check those things out and
# confirm or deny whether build gcc and libgcc at stage 2 is required. For now
# I stick with tried way of building gcc and libgcc twice.
#
# Another guide: http://dev.gentoo.org/~vapier/CROSS-COMPILE-GUTS
#
# Unlike that guide, this build script installs kernel headers before doing
# anything else, for reasons that are explained in the historical note further
# down, and apparently that may not be needed anymore.
#

# -----------------------------------------------------------------------------
# Local variables.
if [ "${ARC_ENDIAN}" = "big" ]
then
    arche=arceb
    build_dir="$(echo "${PWD}")/bd-glibceb"
else
    arche=arc
    build_dir="$(echo "${PWD}")/bd-glibc"
fi

arch=arc
triplet=${arche}-snps-linux-gnu

# Set up a logfile
logfile="${LOGDIR}/glibc-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "START ${ARC_ENDIAN}-endian glibc: $(date)" | tee -a ${logfile}

# Initalize, including getting the tool versions.
. "${ARC_GNU}"/toolchain/arc-init.sh
toolchain_build_dir="$(echo "${PWD}")"/toolchain
linux_src_dir=${LINUXDIR}
linux_build_dir=$build_dir/linux

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

# Purge old build dir if there is any and create a new one.
rm -rf "$build_dir"
mkdir -p "$build_dir"

# -----------------------------------------------------------------------------
# Black magic for macOS. The problem is that default sed on macOS is not
# compatible with GNU, while some scripts use GNU-specific extensions. GNU sed
# can be installed with Homebrew, but by default it will have a name `gsed`, so
# scripts should be modified to use it. While this can be done in ARC scripts,
# we don't have full control over other projects, Linux in particular, which
# also require GNU sed. Therefore in followind lines a new directory is
# created, a link named `sed` is created and is pointed to `gsed` and directory
# is added to the PATH, so GNU sed will be used by Linux.  Alternative solution
# would be to install GNU sed as `sed` in Homebrew, however that might have
# some negative effect on other applications, so I don't think it is wise to
# require this from the user.
if [ "$IS_MAC_OS" = yes ]; then
    mkdir $build_dir/macos_aliases
    ln -s $(which gsed) $build_dir/macos_aliases/sed
    export PATH=$build_dir/macos_aliases:$PATH
fi

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
# Note the --disable-shared option. It is used here, because binutils libraries
# shouldn't be build as dynamic libs (this causes issues on macOS), however the
# target libraries should be built as shared ones.  But as far as I see same
# option is used for both host and target, so --enable-shared should be used
# for components that build target libraries (like gcc and libgcc), but
# shouldn't be used for binutils, since it doesn't has target libraries and is
# known to have troubles when shared libraries are used.
build_dir_init binutils
configure_linux_stage2 binutils binutils --disable-gdb --disable-shared
make_target building all

# Gas requires opcodes to be installed, LD requires BFD to be installed.
# However those dependencies are not described in the Makefiles, instead if
# required components is not yet installed, then dummy as-new and ld-new will
# be installed. Both libraries are installed by install-binutils. Therefore it
# is required that binutils is installed before ld and gas.
# While it is possible to build with `all`, it is not possible to install with
# `install`, because in case of `strip-install` there is an error in the
# "readline" packet that doesn't support this target.
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
# Can't build libgcc yet, because libgcc depends on libc, which hasn't been
# built yet.
if [ $IS_CROSS_COMPILING != yes ]; then
    build_dir_init gcc-stage1
    configure_linux_stage1 gcc
    make_target building all-gcc
    # It looks like that libssp install target is not parallel-friendly - I had
    # occassional issues, when installing it's header.
    make_target_ordered installing ${HOST_INSTALL}-gcc
    # No need for PDF docs for stage 1.
fi

# -----------------------------------------------------------------------------
# Install glibc headers.
echo "Installing glibc headers ..." | tee -a "${logfile}"

# Configure glibc build directory.
# Path to make is set explicitly, becuase glibc's configure script searches
# first for 'gnumake', then 'gmake' and them 'make'. This might cause troubles
# on some systems which has old unsupported 'gmake' in the PATH and a new
# 'make' - even though their directories are in proper order in the PATH, a
# wrong tool is picked because of the glibc's insistence on prefering 'gmake'
# over 'make'. Thus this script enforces usage if 'make'.
build_dir_init glibc
configure_for_arc $ARC_GNU/glibc $triplet \
    --build=$($ARC_GNU/gcc/config.guess) \
    --target=$triplet \
    --with-headers=$SYSROOTDIR/usr/include \
    MAKE=`which make` \
    --enable-obsolete-rpc

# Install headers.
make_target_ordered "installing headers" \
    install-bootstrap-headers=yes \
    install-headers \
    DESTDIR=$SYSROOTDIR
touch $SYSROOTDIR/usr/include/gnu/stubs.h

# -----------------------------------------------------------------------------
# Build stage 1 libgcc (not needed when cross compiling).
if [ $IS_CROSS_COMPILING != yes ]; then
    echo "Building libgcc stage1..."
    cd $build_dir/gcc-stage1
    make_target building all-target-libgcc
    make_target installing install-target-libgcc
    # No need for PDF docs for stage 1.
fi

# -----------------------------------------------------------------------------
# Build glibc using the stage 1 compiler.
echo "Building glibc ..." | tee -a "${logfile}"
cd $build_dir/glibc
make_target building all
make_target_ordered installing install DESTDIR=$SYSROOTDIR
if [ $DO_PDF = --pdf ]; then
    make_target "generating PDF documentation" pdf
    # No target to install PDF, do it manually.
    cp -a manual/libc.pdf $INSTALLDIR/share/doc/
fi

if [ $IS_CROSS_COMPILING != yes ]; then
    # Restore the search path
    PATH=$oldpath
    unset oldpath
fi

# -----------------------------------------------------------------------------
# GCC stage 2
build_dir_init gcc-stage2
configure_linux_stage2 gcc gcc $pch_opt
make_target building all
# It looks like that libssp install target is not parallel-friendly - I had
# occassional issues, when installing it's header.
make_target_ordered installing ${HOST_INSTALL}-host install-target
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
    mv $INSTALLDIR/$triplet/lib/libatomic* $SYSROOTDIR/usr/lib
    mv $INSTALLDIR/$triplet/lib/libgcc_s* $SYSROOTDIR/lib/
    mv $INSTALLDIR/$triplet/lib/libssp* $SYSROOTDIR/usr/lib
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
    build_expat $toolchain_build_dir/_download_tmp linux_stage2
fi

# See comment for "native GDB" being built later. If whole toolchain is native,
# then this step is itself building a native GDB, hence same machinations with
# disable-build-with-cxx are required.
if [ $IS_NATIVE = yes ]; then
    cxx_build=--disable-build-with-cxx
else
    cxx_build=
fi

build_dir_init gdb
configure_linux_stage2 gdb gdb --disable-ld --disable-gas --disable-binutils \
    $cxx_build
make_target building all
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
    ln -fs $i $(echo $i | sed "s/${triplet}/${arche}-linux-gnu/")
done

echo "  finished creating symlinks"

# -----------------------------------------------------------------------------
# Native GDB

if [ $DO_NATIVE_GDB = yes ]; then

    # GDB needs ncurses (termcap to be exact).
    # Since ncurses is a separate product it is an outlier with regards of build process.
    ncurses_version=6.0
    ncurses_url_base=http://ftp.gnu.org/pub/gnu/ncurses
    ncurses_tar=ncurses-${ncurses_version}.tar.gz
    ncurses_url=$ncurses_url_base/$ncurses_tar
    mkdir -p $toolchain_build_dir/_download_tmp
    cd $toolchain_build_dir/_download_tmp
    if [ ! -s $ncurses_tar ]; then
	$WGET -O $ncurses_tar $ncurses_url
    fi

    build_dir_init ncurses
    tar xf $toolchain_build_dir/_download_tmp/$ncurses_tar --strip-components=1

    # GCC 5 introduced some changes to the preprocessor output, that causes a
    # compilation error in files generated by ncurses. See GCC commit:
    #
    #	https://gcc.gnu.org/ml/gcc-patches/2014-06/msg02185.html
    #
    # To counter that, ncurses 6.0 added a check for GCC version, and now adds
    # an option -P if this compiler is used. However initial implementation of
    # this change was done incorrect - as a part of an algorithm that evaluates
    # a version number, there was usage of AWK with regular expression POSIX
    # classes, like [:space:]. Unfortunately, not all AWK implementations
    # support character classes; case in point is mawk, which is the default
    # AWK on Ubuntu, while gawk works just fine with those classes. Therefore,
    # on Ubuntu MKlib_gen.sh failed to properly recognize version of compiler
    # and kept generating files for an older GCC version. Ncurses already has
    # this fixed, but they didn't had a numbered release since then. There are
    # weekly official snapshoots at
    #
    #	http://invisible-mirror.net/archives/ncurses/current/
    #
    # but I don't feel sure about referencing it instead of the GNU servers. So
    # instead, we keep using official 6.0 release and patch it to have just
    # this one required change. Unfortunately, ncurses doesn't provide public
    # access to it's source control (if they use any), so I've just generated
    # diff patch for MKlib_gen.sh using original release and latest snapshot
    # (6.0-20160806).
    #
    # This patch will not be needed after updating to ncurses 6.1, after it
    # will be released.
    patch -p1 < $ARC_GNU/toolchain/extras/ncurses-MKlib_gen.patch

    # Ada is not supported on ARC, so it has to be disabled, otherwise dumb
    # configure script might find Ada compiler for host system and will try to
    # use it as a compiler for ARC.
    configure_for_arc . $triplet --without-ada
    make_target building
    make_target_ordered installing install DESTDIR=$SYSROOTDIR

    build_dir_init native_gdb

    # Due to STAR 9001066513 GDB crashes when throwing an exception.  Due to a
    # poor design GDB uses exceptions as a part of a normal execution flow to
    # verify user input (for example it throws exception when file path is
    # invalid or when typed symbol doesn't exist).  Therefore for 2016.09
    # release it is required to disable build of GDB as a C++ application.
    # This will not work for future releases, because GDB will stop supporting
    # C builds.
    config_path=$(calcConfigPath "${ARC_GNU}")/gdb
    configure_for_arc "$config_path" $triplet \
	--disable-build-with-cxx \
	--disable-gas --disable-ld --disable-binutils
    make_target building

    # See comment for stripprog_opt for an explanation why this is needed.
    # Strip will strip complete symbol table, not just debug symbols.
    make_target_ordered installing install-strip-gdb \
    install-strip-gdbserver DESTDIR=$SYSROOTDIR \
	STRIPPROG=${triplet}-strip
else
    # If native GDB has been disabled, then simple gdbserver still will be
    # built. It doesn't need ncurses.
    build_dir_init gdbserver
    # Static options are same as when gdbserver is configured by the top-level
    # configure script.
    # See commment for native GDB about build-with-cxx.
    config_path=$(calcConfigPath "${ARC_GNU}")/gdb
    LDFLAGS="-static-libstdc++ -static-libgcc" \
	configure_for_arc "$config_path" $triplet \
        --disable-build-with-cxx \
        --disable-gdb
    make_target building

    # gdbserver makefile lacks install-strip target. It is possible to trick
    # gdbserver Makefile to install stripped binary by setting INSTAL_PROGRAM
    # Makefile variable to 'install -c -s', however this way gdbserver would be
    # stripped from all symbols, not just debug symbols.
    # Note that $SYSROOTDIR/bin might not exist yet.
    mkdir -p $SYSROOTDIR$install_prefix/bin
    ${triplet}-objcopy -g gdbserver/gdbserver $SYSROOTDIR$install_prefix/bin/gdbserver
fi

echo "DONE  GLIBC: $(date)" | tee -a "${logfile}"

# vim: noexpandtab sts=4 ts=8:
