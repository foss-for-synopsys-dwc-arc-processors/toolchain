#!/bin/sh

# Copyright (C) 2012 Synopsys Inc.

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

#	  SCRIPT TO BUILD ARC-ELF32 AND ARC-LINUX-UCLIBC TOOL CHAINS
#         ==========================================================

# Invocation Syntax

#     build-all.sh [--source-dir <source_dir>]  [--linux-dir <linux_dir>]
#                  [--build-dir <build_dir>] [--install-dir <install_dir>]
#                  [--symlink-dir <symlink_dir>]
#                  [--auto-pull | --no-auto-pull]
#                  [--auto-checkout | --no-auto-checkout]
#                  [--datestamp-install]
#                  [--comment-install <comment>] [--big-endian]
#                  [--enable-multilib | --disable-multilib]

# This script is a convenience wrapper to build the ARC GNU 4.4 tool
# chains. It utilizes Joern Rennecke's build-elf32.sh script and Bendan
# Kehoe/Jeremy Bennett's build-uclibc.sh script. The arguments have the
# following meanings:

# This version is modified to work with the source tree as organized in
# GitHub.

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

#     The directory in which the unified source tree will be constructed and
#     in which the build directories will be created. If not sepcified, the
#     script will use the source directory.

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
#     to ensure the correct branch is checked out. Default is to checkout.

# --auto-pull | --no-auto-pull

#     If specified, a "git pull" will be done in each component repository
#     after checkout to ensure the latest code is in use. Default is to pull.

# --datestamp-install

#     If specified, this will append a date and timestamp to the install
#     directory name. (see the comments under --symlink-dir above for reasons
#     why this might be useful).

# --comment-install <comment>

#     If specified, this will append a user specified string <comment> to the
#     install directory name. This may prove useful if building variants of
#     tool chains.

# --big-endian

#     If specified, build the big-endian version of the tool chains
#     (i.e. arceb-elf32- and arceb-linux-uclibc-). At present this is only
#     implemented for the Linux tool chain.

# --disable-multilib | --enable-multilib

#     Use these to control whether mutlilibs should be built. If this argument
#     is not used, then the value of the environment variable,
#     DISABLE_MULTILIB, will be used if set. If it is not set, then the
#     default is to enable multilibs.

# Where directories are specified as arguments, they are relative to the
# current directory, unless specified as absolute names.

# We do not recognize the ARC_GNU_ONLY_CONFIGURE and ARC_GNU_CONTINUE
# environment variables, which were used in previous versions of this
# script. If you are using this script, you need to run the whole thing. If
# you want to redo bits, use the underlying scripts, or go into the relevant
# directories and do it by hand!


# ------------------------------------------------------------------------------
# Unset variables, which if inherited as environment variables from the caller
# could cause us grief.
unset builddir
unset INSTALLDIR
unset SYMLINKDIR
unset ARC_ENDIAN
unset autocheckout
unset autopull
unset datestamp
unset commentstamp

# In bash we typically write function blah_blah () { }. However Ubuntu default
# /bin/sh -> dash doesn't recognize the "function" keyword It's exclusion
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
autocheckout="--auto-checkout"
autopull="--auto-pull"

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

    --disable-multilib|--enable-multilib)
	DISABLE_MULTILIB=$1
	;;

    ?*)
	echo "Usage: ./build-all.sh [--source-dir <source_dir>]"
        echo "                      [--linux-dir <linux_dir>]"
        echo "                      [--build-dir <build_dir>]"
        echo "                      [--install-dir <install_dir>]"
	echo "                      [--symlink-dir <symlink_dir>]"
	echo "                      [--auto-checkout | --no-auto-checkout]"
        echo "                      [--auto-pull | --no-auto-pull]"
	echo "                      [--datestamp-install]"
	echo "                      [--comment-install <comment>]"
	echo "                      [--enable-multilib | --disable-multilib]"
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

# Default Linux directory if not already set.
if [ "x${LINUXDIR}" = "x" ]
then
    if [ -d "${ARC_GNU}"/linux ]
    then
	LINUXDIR="${ARC_GNU}"/linux
    else
	echo "ERROR: Cannot find Linux sources."
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

# Default multilib usage
if [ "x${DISABLE_MULTILIB}" = "x" ]
then
    DISABLE_MULTILIB=--enable-multilib
fi

# All the things we export to the scripts
export UNISRC=unisrc
export ARC_GNU
export LINUXDIR
export INSTALLDIR
export ARC_ENDIAN
export DISABLE_MULTILIB

# Change to the build directory
cd ${builddir}

# Set up a logfile
logfile="$(echo "${PWD}")/all-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

# Checkout the correct branch for each tool
echo "Checking out GIT trees" >> "${logfile}"
echo "======================" >> "${logfile}"

echo "Checking out GIT trees ..."
if ${ARC_GNU}/toolchain/arc-versions.sh ${autocheckout} ${autopull} \
    >> ${logfile} 2>&1
then
    true
else
    echo "ERROR: Failed to checkout GIT versions of tools"
    exit 1
fi

# Make a unified source tree in the build directory
echo "Linking unified tree" >> "${logfile}"
echo "====================" >> "${logfile}"

echo "Linking unified tree ..."
component_dirs="${ARC_GNU}/gcc ${ARC_GNU}/newlib ${ARC_GNU}/binutils"
rm -rf ${UNISRC}

if ${ARC_GNU}/toolchain/symlink-trunks.sh --dest ${UNISRC} \
    "${component_dirs}" >> "${logfile}" 2>&1
then
    true
else
    echo "ERROR: Failed to create ${UNISRC}"
    exit 1
fi

# Build the arc-elf32- tool chain
if "${ARC_GNU}"/toolchain/build-elf32.sh --force
then
    true
else
    echo "ERROR: arc-elf32- tool chain build failed."
    exit 1
fi

# Build the arc-linux-uclibc- tool chain
if "${ARC_GNU}"/toolchain/build-uclibc.sh --force
then
    true
else
    echo "ERROR: arc-linux-uclibc- tool chain build failed."
    exit 1
fi

# Link to the defined place. Note the introductory comments about the need to
# specify explicitly the install directory.
if [ "x${SYMLINKDIR}" != "x" ]
then
    rm -f ${SYMLINKDIR}
    ln -s ${INSTALLDIR} ${SYMLINKDIR}
fi
