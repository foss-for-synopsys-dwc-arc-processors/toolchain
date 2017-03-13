#!/usr/bin/env bash

# Copyright (C) 2012-2017 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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

#	  SCRIPT TO BUILD ARC-ELF32 AND ARC-LINUX-UCLIBC TOOL CHAINS
#         ==========================================================

# Invocation Syntax

#     build-all.sh [--source-dir <source_dir>]  [--linux-dir <linux_dir>]
#                  [--build-dir <build_dir>] [--install-dir <install_dir>]
#                  [--symlink-dir <symlink_dir>]
#                  [--auto-pull | --no-auto-pull]
#                  [--auto-checkout | --no-auto-checkout]
#                  [--external-download | --no-external-download]
#                  [--elf32 | --no-elf32] [--uclibc | --no-uclibc]
#                  [--datestamp-install]
#                  [--comment-install <comment>]
#                  [--big-endian | --little-endian]
#                  [--jobs <count>] [--load <load>] [--single-thread]
#                  [--cpu <cpu name>]
#                  [--uclibc-defconfig <defconfig>]
#                  [--config-extra <flags>]
#                  [--target-cflags <flags>]
#                  [--multilib | --no-multilib]
#                  [--pdf | --no-pdf]
#                  [--rel-rpaths | --no-rel-rpaths]
#                  [--disable-werror | --no-disable-werror]
#                  [--strip | --no-strip]
#                  [--release-name <release>]
#                  [--nptl | --no-nptl]
#                  [--checkout-config <config>]
#                  [--host <triplet>]
#                  [--native-gdb | --no-native-gdb]
#                  [--system-expat | --no-system-expat]
#                  [--elf32-gcc-stage1 | --no-elf32-gcc-stage1]
#                  [--elf32-strip-target-libs | --no-elf32-strip-target-libs]
#                  [--optsize-newlib | --no-optsize-newlib]
#                  [--optsize-libstdc++ | --no-optsize-libstdc++]
#                  [--native | --no-native]
#                  [--uclibc-build-in-src-tree | --no-uclibc-build-in-src-tree]

# --source-dir <source_dir>

#     The location of the ARC GNU tools source tree. If not specified, the
#     script will use the value of the ARC_GNU environment variable if
#     available.

#     If this argument is not specified, and the ARC_GNU environment variable
#     is also not set, the script will use the parent of the directory where
#     this script is installed.

# --linux-dir <linux_dir>

#     The location of the ARC linux source tree. If not specified, the script
#     will use (in order)
#     - the value of the LINUXDIR environment variable
#     - a directory named "linux" in the source directory.

#     If a valid Linux directory cannot be determined, the script will
#     terminate with an error.

#     If an argument is specified with this option, then the arc-versions.sh
#     script will assume it is already checked out on the desired branch (to
#     help Linux developers).

# --build-dir <build_dir>

#     The directory in which the build directories will be created. If not
#     specified, the script will use the source directory.

# --install-dir <install_dir>

#     The directory in which both tool chains should be installed. If not
#     specified, both will be installed in the INSTALL sub-directory of the
#     source directory.

#     The previous scripts used to install in <base>/elf32 and <base>/uclibc
#     folders, which wasted file space by duplicating common material and also
#     needed 2 entries in PATH for elf32/uclibc tools despite being from the
#     same build.

# --symlink-dir <symlink_dir>

#     If specified, the install directory will be symbolically linked to this
#     directory.

#     For example it may prove useful to install in a directory named with the
#     date and time when the tools were built, and then symbolically link to a
#     directory with a fixed name. By using the symbolic link in the users
#     PATH, the latest version of the tool chain will be used, while older
#     versions of the tool chains remain available under the dated
#     directories.

# --auto-checkout | --no-auto-checkout

#     If specified, a "git checkout" will be done in each component repository
#     to ensure the correct branch is checked out. If tool chain is built from
#     a source tarball then default is to not make a checkout. If tool chain is
#     built from a Git repository then default is to make a checkout.

# --auto-pull | --no-auto-pull

#     If specified, a "git pull" will be done in each component repository
#     after checkout to ensure the latest code is in use. Default is to pull.
#     If tool chain is built from a source tarball then default is to not pull.
#     If tool chain is built from a Git repository then default is to pull.

# --external-download | --no-external-download

#     If specified, then GMP, MPFR and MPC libraries will be downloaded as
#     source tarballs, unpacked and placed inside GCC source directory. GCC
#     makefiles will recognize those directories properly and will use them
#     instead of system libraries. Some systems (RHEL, CentOS) doesn't have all
#     of the required dependencies in official repositories. This is done right
#     after checkout. Default is to download.

# --elf32 | --no-elf32

#     If specified, build the arc-elf32- tool chain (default is --elf32).

# --uclibc | --no-uclibc

#     If specified, build the arc-uclibc-linux- tool chain (default is
#     --uclibc).

# --datestamp-install

#     If specified, this will append a date and timestamp to the install
#     directory name. (see the comments under --symlink-dir above for reasons
#     why this might be useful).

# --comment-install <comment>

#     If specified, this will append a user specified string <comment> to the
#     install directory name. This may prove useful if building variants of
#     tool chains.

# --big-endian | --little-endian

#     If --big-endian is specified, test the big-endian version of the tool
#     chains (i.e. arceb-elf32- and arceb-linux-uclibc-), otherwise test the
#     little endin versions.

# --jobs <count>

#     Specify that parallel make should run at most <count> jobs. The default
#     is <count> equal to one more than the number of processor cores shown by
#     /proc/cpuinfo.

# --load <load>

#     Specify that parallel make should not start a new job if the load
#     average exceed <load>. The default is <load> equal to one more than the
#     number of processor cores shown by /proc/cpuinfo.

# --single-thread

#     Equivalent to --jobs 1 --load 1000. Only run one job at a time, but run
#     whatever the load average.

# --cpu <cpu name>

#    Specify default family of CPU for tool chain. Possible values: depend on
#    what values are available in GCC. As of version 2016.03 values available
#    in ARC GCC are: em arcem em4 em4_dmips em4_fpus em4_fpuda quarkse hs archs
#    hs34 hs38 hs38_linux arc600 arc600_norm arc600_mul64 arc600_mul32x16
#    arc601 arc601_norm arc601_mul64 arc601_mul32x16 arc700.

# --uclibc-defconfig <defconfig>

#     If specified, the defconfig used to build uClibc will be <defconfig>. The
#     default is defconfig for ARC 700 and arcv2_defconfig for ARC HS - this is
#     decided based on value of --cpu option. If CPU is "arc700", then
#     defconfig for ARC 700 will be used. In all other cases defconfig for ARC
#     HS will be used.

# --config-extra <flags>

#     Add <flags> to the configuration line for the tool chain. Note this does
#     not include the configuration of gdbserver for the UCLIBC LINUX tool
#     chain

# --target-cflags <flags>

#     <flags> value will be used as CFLAGS/CXXFLAGS when building target
#     packages. Depending on a particular type of software either
#     CFLAGSS/CXXFLAGS will be set, or CFLAGS_FOR_TARGET/CXXFLAGS_FOR_TARGET
#     will be set.  This can be used for example to make more compact
#     libraries, by specifying "-Os -g". Note that this will override default
#     "-O2 -g", therefore to append a flag to default one, for example -mll64,
#     value of <flags> would be like "-O2 -g -mll64".  Libraries optimized for
#     size use a set of their own CFLAGS and --target-cflags may override those
#     flags if desired, with the sole exception of -Os, which is always
#     enforced in size optimized libraries.

# --multilib | --no-multilib

#     Use these to control whether mutlilibs should be built. If this argument
#     is not used, then the value of the environment variable,
#     DISABLE_MULTILIB, will be used if set. If it is not set, then the
#     default is to enable multilibs for the ELF32 tool chain and disable for
#     the UCLIBC LINUX tool chain.

# --pdf | --no-pdf

#     Use these to control whether PDF versions of user guides should be built
#     and installed (default --pdf).

# --rel-rpaths | --no-rel-rpaths

#     Use these to control whether once tools have been built, the tools RPATHs
#     are set so they are relative to the INSTALL directory and thus become
#     portable (default --rel-rpaths).

# --disable-werror | --no-disable-werror

#     Use these to control whether the tools are built with --disable-werror
#     (default --disable-werror).

# --strip | --no-strip

#     Install stripped host binaries. Target libraries are not affected.
#     Default is --no-strip.

# --sed-tool

#     Specify the path of the sed to use.

# --release-name

#     Name of this releases. Default value is "git describe --tag --always" of
#     the gcc repository. If build is done from the source tarball, then
#     current date is used.

# --nptl | --no-nptl

#     When building Linux toolchain with NPTL support, it will support
#     threading and thread local storage (TLS) and will use NPTL instead of old
#     threads library. (default --nptl)

# --checkout-config <config>

#     Allows to override default checkout configuration. That affects git
#     revisions/branches/tags that will be used to build toolchain, so this
#     option doesn't have any effect if --no-auto-checkout is specified.
#     Argument may take two forms - if it contains slash, then it is considered
#     as file path and is used as-is; otherwise it is considered as a
#     configuration name and will be used as toolchain/config/$config.sh. Build
#     will be aborted if specified configuration doesn't exist.  Default value
#     is "arc-dev" for development branch, and latest release tag for release
#     branch.

# --host <triplet>

#     `<triplet>` will be passed to toolchain `configure` scripts as a value of
#     --host option. Needed for Canadian cross compilation, for example allows
#     to build on Linux host toolchain that will run on Windows host and will
#     compile software for ARC processors. Note that this makes sense only for
#     baremetal (elf32) toolchain.

# --native-gdb | --no-native-gdb

#     Whether to build or not to build native GDB - GDB that will run directly
#     on ARC Linux. Default is yes. Makes sense only for Linux toolchain
#     (--uclibc). Note that GDB requires ncurses, which will be built
#     automatically. That has several possible points of failure:
#     - ncurses is not part of GNU Toolchain. Its source is autodownloaded.
#       Build process will fail if it cannot be downloaded. If you have
#       problems, either use --no-native-gdb or put ncurses-5.9.tar.gz into
#       toolchain/_download_tmp directory.
#     - static ncurses libs will be installed to sysroot. You might experience
#       issues if you will build ncurses on your own (or via Buildroot). If that
#       is the case - build toolchain without native GDB, and then build GDB
#       manually with your ncurses. Buildroot handles this nicely.
#     - Due to a bug ncurses has to be built without C++ bindings.

# --system-expat | --no-system-expat

#    Whether to use expat library installed into system or build it in this
#    script. expat is used by GDB to parse XML, therefore is needed to work
#    with XML Target descriptions. Usually using system expat is sufficient,
#    however it may cause issues if system doesn't have expat or it is of wrong
#    version. Notable use case for --no-system-expat is mingw32 build, if mingw
#    installation lacks expat. Default value is to use system expat.

# --elf32-gcc-stage1 | --no-elf32-gcc-stage1

#     Whether to build or not to build gcc-stage1 for elf32 targets. It may
#     may be useful to turn off building gcc-stage1 if toolchain is already
#     presented in PATH thus newlib may be built by precompiled GCC. Default
#     is --elf32-gcc-stage1.

# --optsize-newlib | --no-optsize-newlib

#    Whether to build an optimized for code size second set of newlib libc and
#    libm archives. Generated files will have _nano prefix, for example
#    libc_nano.a. This affects only elf32/baremetal toolchain. Default is
#    --optsize-libs.

# --optsize-libstdc++ | --no-optsize-libstdc++

#    Whether to build an optimized for code size libcstdc++ archive. Generated
#    files will have _nano prefix, for example libctdc++_nano.a. This change
#    affects only elf32/baremetal toolchain. Note that due to quirks of
#    libstdc++ configure script, enabling this option will cause GCC to be
#    built one more time (specifically for code size libcstdc++), therefore
#    enabling this option might cause big increase in build time of the
#    toolchain. Default is --optsize-libstdc++.

# --elf32-strip-target-libs | --no-elf32-strip-target-libs

#    Whether to strip target libraries from debug symbols (except for
#    .debug_frame section). Debug information contains absolute paths to source
#    files, so when toolchain is moved to another system it is required to
#    configure GDB to translate paths on a build host to paths on a runtime
#    hosts, otherwise GDB would complain about missing source files. Default is
#    to not strip libraries.

# --native | --no-native

#    Whether this is a native/self-hosting toolchain, IOW toolchain that would run on
#    ARC Linux or it is a cross-toolchain, that would run on other host but
#    would compile for ARC. Makes sense only for uClibc/Linux toolchain.

# --uclibc-build-in-src-tree | --no-uclibc-build-in-src-tree

#    Whether to build uClibc inside of its the source tree. Default is to build
#    inside the source tree because out of tree build often triggers a build
#    failure, because total list of arguments to linker/archiver exceeds
#    maximum in Linux systems. Building inside of the source tree means that it
#    is not possible to run multiple concurrent builds from the same tree.

# Where directories are specified as arguments, they are relative to the
# current directory, unless specified as absolute names.

# ------------------------------------------------------------------------------
# Unset variables, which if inherited as environment variables from the caller
# could cause us grief.
unset builddir
unset INSTALLDIR
unset SYMLINKDIR
unset ARC_ENDIAN
unset PARALLEL
unset autocheckout
unset autopull
unset external_download
unset datestamp
unset commentstamp
unset jobs
unset load
unset DISABLEWERROR
unset HOST_INSTALL
unset SED

# In bash we typically write function blah_blah () { }. However Ubuntu default
# /bin/sh -> dash doesn't recognize the "function" keyword. Its exclusion
# seems to work for both
build_pathnm ()
{
    if [ "x" = "x${MSYSTEM}" ]
    then
	# Linux
	if echo $1 | grep -q -e "^/"
	then
	    RESULT=$1		# Absolute directory
	else
	    RESULT=`pwd`/$1	# Relative directory
	fi
    else
	# MinGW/MSYS
	if echo $1 | grep -q -e "^[A-Za-z]:"
	then
	    RESULT=$1		# Absolute directory
	else
	    RESULT=`pwd`\$1	# Relative directory
	fi
    fi
    echo $RESULT
}

# Set defaults for some options
autocheckout=""
autopull=""
external_download="--external-download"
elf32="--elf32"
uclibc="--uclibc"
ISA_CPU="arc700"
UCLIBC_DEFCFG=""
CONFIG_EXTRA=""
DO_PDF="--pdf"
DO_NATIVE_GDB=maybe
rel_rpaths="--no-rel-rpaths"
DISABLEWERROR="--disable-werror"
CFLAGS_FOR_TARGET=""
CXXFLAGS_FOR_TARGET=""
HOST_INSTALL=install
SED=sed
RELEASE_NAME=
is_tarball=
NPTL_SUPPORT="yes"
CHECKOUT_CONFIG=
TOOLCHAIN_HOST=
SYSTEM_EXPAT=yes
DO_ELF32_GCC_STAGE1=yes
DO_STRIP_TARGET_LIBRARIES=no
BUILD_OPTSIZE_NEWLIB=yes
BUILD_OPTSIZE_LIBSTDCXX=yes
IS_NATIVE=no
UCLIBC_IN_SRC_TREE=yes

# Default multilib usage and conversion for toolchain building
case "x${DISABLE_MULTILIB}" in
    x--multilib | x-enable-multilib)
	ELF32_DISABLE_MULTILIB=
	UCLIBC_DISABLE_MULTILIB=
	;;

    x--no-multilib | x--disable-multilib)
	ELF32_DISABLE_MULTILIB=--disable-multilib
	UCLIBC_DISABLE_MULTILIB=--disable-multilib
	;;

    x*)
	ELF32_DISABLE_MULTILIB=
	UCLIBC_DISABLE_MULTILIB=--disable-multilib
	;;
esac


if [ x`uname -s` = "xDarwin" ]
then
    IS_MAC_OS=yes
    #You can install gsed with 'brew install gnu-sed'
    SED=gsed
else
    IS_MAC_OS=no
fi

# Parse options
until
opt=$1
case ${opt} in
    --source-dir)
	shift
	ARC_GNU=`(cd "$1" && pwd)`
	;;

    --linux-dir)
	shift
	LINUXDIR=`(cd "$1" && pwd)`
	;;

    --build-dir)
	shift
	builddir=`(cd "$1" && pwd)`
	;;

    --install-dir)
	# This is tricky, since the install directory may not yet exist, so we
	# can't simply change to that directory to resolve its absolute
	# name. We resolve this by assuming that directories beginning with
	# "/" or (on MinGW/MSYS) "<char>:" are absolute, and just prepending
	# the current working directory to all other examples.
	shift

	INSTALLDIR=$(build_pathnm $@)
	;;

    --symlink-dir)
	# This has the same problem as --install-dir
	shift
	SYMLINKDIR=$(build_pathnm $@)
	;;

    --auto-checkout | --no-auto-checkout)
	autocheckout=$1
	;;

    --auto-pull | --no-auto-pull)
	autopull=$1
	;;

    --external-download | --no-external-download)
	external_download=$1
	;;

    --elf32 | --no-elf32)
	elf32=$1
	;;

    --uclibc | --no-uclibc)
	uclibc=$1
	;;

    --uclibc-defconfig)
	shift
	UCLIBC_DEFCFG=$1
	;;

    --datestamp-install)
	datestamp=-`date -u +%F-%H%M`
	;;

    --comment-install)
	shift
	commentstamp=$1
	;;

    --big-endian)
	ARC_ENDIAN="big"
	;;

    --little-endian)
	ARC_ENDIAN="little"
	;;

    --jobs)
	shift
	jobs=$1
	;;

    --load)
	shift
	load=$1
	;;

    --single-thread)
	jobs=1
	load=1000
	;;


    --cpu)
	shift
	ISA_CPU=$1
	;;

    --config-extra)
	shift
	CONFIG_EXTRA="$1"
	;;

    --target-cflags)
	shift
	# libstdc++ uses CXXFLAGS instead of CFLAGS, therefore both should be
	# set.
	CFLAGS_FOR_TARGET="$1"
	CXXFLAGS_FOR_TARGET="$1"
	;;

    --multilib | --enable-multilib)
	ELF32_DISABLE_MULTILIB=
	UCLIBC_DISABLE_MULTILIB=
	;;

    --no-multilib | --disable-multilib)
	ELF32_DISABLE_MULTILIB=--disable-multilib
	UCLIBC_DISABLE_MULTILIB=--disable-multilib
	;;

    --pdf|--no-pdf)
	DO_PDF=$1
	;;

    --rel-rpaths|--no-rel-rpaths)
	rel_rpaths=$1
	;;

    --disable-werror)
	DISABLEWERROR=$1
	;;

    --no-disable-werror)
	DISABLEWERROR=
	;;

    --strip)
        HOST_INSTALL=install-strip
        ;;

    --no-strip)
        HOST_INSTALL=install
        ;;

    --sed-tool)
	shift
	SED=$1
        ;;

    --release-name)
	shift
	RELEASE_NAME="$1"
	;;

    --nptl)
        NPTL_SUPPORT="yes"
        ;;
    --no-nptl)
        NPTL_SUPPORT="no"
        ;;

    --checkout-config)
	shift
	CHECKOUT_CONFIG="$1"
	;;

    --host)
	shift
	TOOLCHAIN_HOST="$1"
	;;

    --native-gdb)
	DO_NATIVE_GDB=yes
	;;

    --no-native-gdb)
	DO_NATIVE_GDB=no
	;;

    --system-expat)
	SYSTEM_EXPAT=yes
	;;

    --no-system-expat)
	SYSTEM_EXPAT=no
	;;

    --elf32-gcc-stage1)
	DO_ELF32_GCC_STAGE1=yes
	;;

    --no-elf32-gcc-stage1)
	DO_ELF32_GCC_STAGE1=no
	;;

    --elf32-strip-target-libs)
	DO_STRIP_TARGET_LIBRARIES=yes
	;;

    --no-elf32-strip-target-libs)
	DO_STRIP_TARGET_LIBRARIES=no
	;;

    --optsize-newlib)
	BUILD_OPTSIZE_NEWLIB=yes
	;;

    --no-optsize-newlib)
	BUILD_OPTSIZE_NEWLIB=no
	;;

    --optsize-libstdc++)
	BUILD_OPTSIZE_LIBSTDCXX=yes
	;;

    --no-optsize-libstdc++)
	BUILD_OPTSIZE_LIBSTDCXX=no
	;;

    --native)
	IS_NATIVE=yes
	;;

    --no-native)
	IS_NATIVE=no
	;;

    --uclibc-build-in-src-tree)
	UCLIBC_IN_SRC_TREE=yes
	;;

    --no-uclibc-build-in-src-tree)
	UCLIBC_IN_SRC_TREE=no
	;;

    ?*)
	echo "Unknown argument $1"
	echo
	echo "Usage: ./build-all.sh [--source-dir <source_dir>]"
        echo "                      [--linux-dir <linux_dir>]"
        echo "                      [--build-dir <build_dir>]"
        echo "                      [--install-dir <install_dir>]"
	echo "                      [--symlink-dir <symlink_dir>]"
	echo "                      [--auto-checkout | --no-auto-checkout]"
        echo "                      [--auto-pull | --no-auto-pull]"
	echo "                      [--external-download | --no-external-download]"
        echo "                      [--elf32 | --no-elf32]"
        echo "                      [--uclibc | --no-uclibc]"
	echo "                      [--datestamp-install]"
	echo "                      [--comment-install <comment>]"
	echo "                      [--big-endian | --little-endian]"
        echo "                      [--jobs <count>] [--load <load>]"
        echo "                      [--single-thread]"
        echo "                      [--cpu <cpu name>]"
	echo "                      [--uclibc-defconfig <defconfig>]"
        echo "                      [--config-extra <flags>]"
        echo "                      [--target-cflags <flags>]"
	echo "                      [--multilib | --no-multilib]"
	echo "                      [--pdf | --no-pdf]"
	echo "                      [--rel-rpaths | --no-rel-rpaths]"
	echo "                      [--disable-werror | --no-disable-werror]"
	echo "                      [--strip | --no-strip]"
	echo "                      [--sed-tool <tool>]"
	echo "                      [--release-name <release>]"
	echo "                      [--nptl | --no-nptl]"
	echo "                      [--checkout-config <config>]"
	echo "                      [--host <triplet>]"
	echo "                      [--native-gdb | --no-native-gdb]"
	echo "                      [--system-expat | --no-system-expat]"
	echo "                      [--elf32-gcc-stage1 | --no-elf32-gcc-stage1]"
	echo "                      [--elf32-strip-target-libs | --no-elf32-strip-target-libs]"
	echo "                      [--optsize-newlib | --no-optsize-newlib]"
	echo "                      [--optsize-libstdc++ | --no-optsize-libstdc++]"
	echo "                      [--native | --no-native]"
	echo "                      [--uclibc-build-in-src-tree | --no-uclibc-build-in-src-tree]"
	exit 1
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done

# Default source directory if not already set
if [ "x${ARC_GNU}" = "x" ]
then
    d=`dirname "$0"`
    ARC_GNU=`(cd "$d/.." && pwd)`
fi

# Now we can decide if do auto pull and auto checkout
if [ -d "$ARC_GNU/toolchain/.git" ]
then
    is_tarball=no
else
    is_tarball=yes
fi

if [ "x$is_tarball" = "xno" ]
then
    git_auto="--auto"
else
    git_auto="--no-auto"
fi

if [ "x${autopull}" = "x" ]
then
    autopull="${git_auto}-pull"
fi

if [ "x${autocheckout}" = "x" ]
then
    autocheckout="${git_auto}-checkout"
fi

if [ "x$RELEASE_NAME" = "x" ]
then
    if [ "x$is_tarball" = "xno" ]
    then
	RELEASE_NAME="$(git --git-dir=${ARC_GNU}/gcc/.git describe --tag --always)"
    else
	RELEASE_NAME="built on $(date +%Y%m%d)"
    fi
fi

# Default Linux directory if not already set. Only matters if we are building
# the uClibc tool chain.
if [ "x${uclibc}" = "x--uclibc" -a "x${LINUXDIR}" = "x" ]
then
    if [ -d "${ARC_GNU}"/linux ]
    then
	LINUXDIR="${ARC_GNU}"/linux
    else
        echo "ERROR: Cannot find Linux sources. You can download latest"\
             "stable release from http://kernel.org and untar it as a"\
             "sibling of this \`toolchain' directory. Directory name must"\
             "be \`linux'. For more details read README.md file, section"\
             "\"Getting sources/Using source tarball\"."
	     exit 1
    fi
fi

if [ "x${builddir}" = "x" ]
then
    builddir="${ARC_GNU}"
fi

if [ "x${INSTALLDIR}" = "x" ]
then
    INSTALLDIR="${ARC_GNU}/INSTALL"
fi

if [ "x$datestamp" != "x" ]
then
    INSTALLDIR="${INSTALLDIR}$datestamp"
fi

if [ "x$commentstamp" != "x" ]
then
    INSTALLDIR="$INSTALLDIR-$commentstamp"
fi

# Default endian
if [ "x${ARC_ENDIAN}" = "x" ]
then
    ARC_ENDIAN="little"
fi

# Default defconfig for uClibc, only if it has not already been set
if [ "x${UCLIBC_DEFCFG}" = "x" ]
then
    if [ "$ISA_CPU" = arc700 ]; then
        UCLIBC_DEFCFG=defconfig
    else
        UCLIBC_DEFCFG=arcv2_defconfig
    fi
fi

# Default parallellism (number of cores + 1).
if [ "$IS_MAC_OS" != yes ]; then
    make_load="$( (echo processor; cat /proc/cpuinfo 2>/dev/null) \
               | grep -c processor )"
else
    make_load="$(( $(sysctl -n hw.ncpu) + 1))"
fi

if [ "x${jobs}" = "x" ]
then
    jobs=${make_load}
fi

if [ "x${load}" = "x" ]
then
    load=${make_load}
fi

PARALLEL="-j ${jobs} -l ${load}"

# Set version string for Linux uClibc toolchain, it will be used by arc-init. I
# do not like this cross-file dependency, but otherwise it happens that
# arc-init depends on either UCLIBC_TOOLS_VERSION, or on ISA_CPU+RELEASE_NAME.
# Probably that stuff should be centralized is some better way or uClibc
# configure procedures should take version string as an argument.
if [ $ISA_CPU = arc700 ]
then
    UCLIBC_TOOLS_VERSION="ARCompact ISA Linux uClibc toolchain $RELEASE_NAME"
else
    UCLIBC_TOOLS_VERSION="ARCv2 ISA Linux uClibc toolchain $RELEASE_NAME"
fi

# Convenience variable: IS_CROSS_COMPILING=(build != host)
if [ "$TOOLCHAIN_HOST" ]; then
    IS_CROSS_COMPILING=yes
else
    IS_CROSS_COMPILING=no
fi

# Not possible to build native GDB with cross-build toolchain
if [ $IS_CROSS_COMPILING = yes ]; then
    if [ $DO_NATIVE_GDB = yes ]; then
	echo "WARNING: It is not possible to build native GDB with"\
	    "cross-compiled tools. Ignoring --native-gdb option."
    fi
    DO_NATIVE_GDB=no
else
    if [ $DO_NATIVE_GDB = maybe ]; then
	DO_NATIVE_GDB=yes
    fi
fi

# Let user override default wget via WGET environment variable.
if [ -z "$WGET" ]; then
    WGET="wget -nv"
    export WGET
fi

if hash pv 2>/dev/null; then
    PV='pv -p --timer'
else
    PV='tee'
fi
export PV

# If PDF docs are enabled, then check if prerequisites are satisfied.
if [ $DO_PDF = --pdf ]; then
    if ! which texi2pdf >/dev/null 2>/dev/null ; then
	echo "TeX is not installed. See README.md for a list of required"
	echo "system packages. Option --no-pdf can be used to disable build"
	echo "of PDF documentation."
	exit 1
    fi

    # Texi is a major source of toolchain build errors -- PDF regularly do not
    # work with particular versions of texinfo, but work with others. To
    # workaround those issues build scripts should be aware of texi version.
    export TEXINFO_VERSION_MAJOR=$(texi2pdf --version | \
	perl -ne 'print $1 if /Texinfo ([0-9]+)/')
    export TEXINFO_VERSION_MINOR=$(texi2pdf --version | \
	perl -ne 'print $2 if /Texinfo ([0-9]+)\.([0-9]+)/')

    # There are issues with Texinfo v4 and non-C locales.
    # See http://lists.gnu.org/archive/html/bug-texinfo/2010-03/msg00031.html
    if [ 4 = "$TEXINFO_VERSION_MAJOR" ]; then
	export LC_ALL=C
    fi

    # On macOS TeX binary might not be in the PATH even when texi2pdf is.
    if [ $IS_MAC_OS = yes ]; then
	if ! which tex &>/dev/null ; then
	    export PATH=/Library/TeX/texbin:$PATH
	fi
    fi
fi

# Standard setup
. "${ARC_GNU}/toolchain/arc-init.sh"

# All the things we export to the scripts
export ARC_GNU
export LINUXDIR
export INSTALLDIR
export ARC_ENDIAN
export ELF32_DISABLE_MULTILIB
export UCLIBC_DISABLE_MULTILIB
export ISA_CPU
export CONFIG_EXTRA
export DO_PDF
export DO_NATIVE_GDB
export PARALLEL
export UCLIBC_DEFCFG
export DISABLEWERROR
export HOST_INSTALL
if [ "x${CFLAGS_FOR_TARGET}" != "x" ]
then
    export CFLAGS_FOR_TARGET
    export CXXFLAGS_FOR_TARGET
fi
export SED
export RELEASE_NAME
export NPTL_SUPPORT
export CHECKOUT_CONFIG
# Used by configure funcs in arc-init.sh
export TOOLCHAIN_HOST
export UCLIBC_TOOLS_VERSION
export SYSTEM_EXPAT
export DO_ELF32_GCC_STAGE1
export BUILD_OPTSIZE_NEWLIB
export BUILD_OPTSIZE_LIBSTDCXX
export DO_STRIP_TARGET_LIBRARIES
export IS_CROSS_COMPILING
export IS_MAC_OS
export IS_NATIVE
export UCLIBC_IN_SRC_TREE

# Set up a logfile
logfile="${LOGDIR}/all-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

# Some commonly used variables might cause invalid results when inherited from
# environment so we need to unset them.
arc_unset_vars=
for var_name in CROSS_COMPILE ARCH BUILD_CFLAGS BUILD_LDFLAGS PREFIX \
    RUNTIME_PREFIX DEVEL_PREFIX MULTILIB_DIR UCLIBC_EXTRA_CFLAGS \
    UCLIBC_EXTRA_CPPFLAGS CC CFLAGS LDFLAGS LIBS CPPFLAGS CXX CXXFLAGS \
    build_configargs host_configargs target_configargs AR AS DLLTOOL LD LIPO \
    NM RANLIB STRIP WINDRES WINDMC OBJCOPY OBJDUMP READELF CC_FOR_TARGTE \
    CXX_FOR_TARGET GCC_FOR_TARGET AR_FOR_TARGET AS_FOR_TARGET \
    DLLTOOL_FOR_TARGET LD_FOR_TARGET LIPO_FOR_TARGET NM_FOR_TARGET \
    OBJDUMP_FOR_TARGET RUNLIB_FOR_TARGET READELF_FOR_TARGET STRIP_FOR_TARGET \
    WINDRES_FOR_TARGET WINDMC_FOR_TARGET ; do
    if env | grep ^${var_name}= > /dev/null 2>&1
    then
        arc_unset_vars="${arc_unset_vars} ${var_name}"
        unset ${var_name}
    fi
done
if [ "${arc_unset_vars}" ]
then
    echo "WARNING: Your environment has some variables that might affect " \
         "build in a undesirable way. These variables will be unset: " \
         "\`${arc_unset_vars}'." | tee -a "${logfile}"
fi

# Log the environment
echo "Build environment" >> "${logfile}"
echo "=================" >> "${logfile}"
env >> "${logfile}" 2>&1

# Checkout the correct branch for each tool
echo "Checking out GIT trees" >> "${logfile}"
echo "======================" >> "${logfile}"

echo "Checking out GIT trees ..."
if ! ${ARC_GNU}/toolchain/arc-versions.sh ${autocheckout} ${autopull} \
    ${uclibc} >> ${logfile} 2>&1
then
    echo "ERROR: Failed to checkout GIT versions of tools"
    echo "- see ${logfile}"
    exit 1
fi

# There used to be a check for validity of --cpu value, and that check was done
# before any actions were taken - that makes sense to do it that way, to fail
# as quickly as possible.  However now that GCC accepts much more of those it
# became relatively ridicolous to list them here - and it is possible that
# users might want to add new custom ones. Instead to check cpu value it is
# required to get possible value from gcc/gcc/config/arc/arc-cpus.def file. For
# compatibility with older GCC (before 2016.03, if arc-cpus.def doesn't exist,
# then an old check for four fixed values is used.

cpus_def=$ARC_GNU/gcc/gcc/config/arc/arc-cpus.def
if [ -f $cpus_def ]; then
    # New GCC (2016.03 and later).
    # allowed_cpus should be a string wil values delimited by spaces.
    allowed_cpus=$(awk -v FS="[(, \t]+" '/^ARC/{printf " "$2}' $cpus_def)
    allowed_linux_cpus=$(awk -v FS="[(, \t]+" \
	'/^ARC/{if($3=="hs"||$3=="700")printf " "$2}' $cpus_def)
else
    # Old GCC (2015.12 and earlier)
    allowed_cpus="arc600 arc700 arcem archs"
    allowed_linux_cpus="arc700 archs"
fi

if [[ " ${allowed_cpus[*]} " != *" $ISA_CPU "* ]]; then
    echo "ERROR: Invalid CPU family specified."\
         "Supported values are: $allowed_cpus."
    exit 1
fi

if [ "x${uclibc}" = "x--uclibc" ]; then
    if [[ " ${allowed_linux_cpus[*]} " != *" $ISA_CPU "* ]]; then
	echo "ERROR: uClibc tool chain cannot be built for this CPU family."\
	     "Choose one of the supported CPU familes or disable building of"\
	     "uClibc tool chain with option --no-uclibc."\
	     "Supported values are: $allowed_linux_cpus."
	exit 1
    fi
fi

# Downloading external dependencies
if [ "x${external_download}" = "x--external-download" ]; then
    echo "Downloading external dependencies" >> "${logfile}"
    echo "====================================" >> "${logfile}"

    echo "Downloading external dependencies..."
	cd ${ARC_GNU}/gcc
    if ! ${ARC_GNU}/toolchain/arc-external.sh >> ${logfile} 2>&1
    then
        echo "WARNING: Failed to download external dependencies. Build will be continued but it can fail."
    fi
else
    echo "Will not download external dependencies" | tee -a "${logfile}"
fi

# Change to the build directory
cd ${builddir}

# Optionally build the arc-elf32- tool chain
if [ "x${elf32}" = "x--elf32" ]
then
    if ! "${ARC_GNU}"/toolchain/build-elf32.sh
    then
	echo "ERROR: arc-elf32- tool chain build failed."
	exit 1
    fi
    # If we have built the PDF here, we don't want to do it again if we then
    # build the uClibc tool chain, so override the DO_PDF setting.
    DO_PDF="--no-pdf"
fi

# Optionally build the arc-linux-uclibc- tool chain
if [ "x${uclibc}" = "x--uclibc" ]
then
    if ! "${ARC_GNU}"/toolchain/build-uclibc.sh
    then
	echo "ERROR: arc-linux-uclibc- tool chain build failed."
	exit 1
    fi
fi

# Link to the defined place. Note the introductory comments about the need to
# specify explicitly the install directory.
if [ "x${SYMLINKDIR}" != "x" ]
then
    rm -f ${SYMLINKDIR}
    ln -s ${INSTALLDIR} ${SYMLINKDIR}
fi

# Patch RPATHs so they are relative
if [ "x${rel_rpaths}" = "x--rel-rpaths" ]
then
    if ! "${ARC_GNU}"/toolchain/rel-rpaths.sh ${INSTALLDIR} >> "${logfile}" 2>&1
    then
	echo "ERROR: Unable to make RPATHs relative. Is patchelf installed?"
	exit 1
    fi
fi

# Copy legal notice
# Do not copy if toolchain hasn't been built
if [ -d "${INSTALLDIR}/" ]; then
    cp "${ARC_GNU}/toolchain/Synopsys_FOSS_Notices.pdf" "${INSTALLDIR}/"
fi

# vim: noexpandtab sts=4 ts=8:
