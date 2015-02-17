#!/bin/sh

# Copyright (C) 2012-2015 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a script to build BusyBox and the Linux kernel for ARC700.

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

#		 SCRIPT TO BUILD BUSYBOX and LINUX for ARC700
#		 ============================================

# This convenience script does a completely clean build of busybox, installs
# from that into the initramfs , fixes libraries in the initramfs and then
# builds the kernel.

# This is not part of the official process (which uses buildroot), but is
# convenient for developers who wish to build/rebuild a kernel quickly.  The
# options to the script are documented in the comments.

# There is an assumption that the layout of repositories is standard.
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#
#			       Shell functions
#
# ------------------------------------------------------------------------------

# Convenience function to copy a message to the log and terminal

# @param[in] $1  The message to log
logterm () {
    echo $1 | tee -a ${logfile}
}


# Convenience function to copy a message to the log only

# @param[in] $1  The message to log
logonly () {
    echo $1 >> ${logfile}
}


# Convenience function to exit with a suitable message.
failedbuild () {
  echo "Build failed. See ${logfile} for details."
  exit 1
}


# ------------------------------------------------------------------------------
#
#				  Parse args
#
# ------------------------------------------------------------------------------

# Default source directory is where we have this script.
d=`dirname "$0"`
ARC_GNU=`(cd "$d/.." && pwd)`

# Generic release set up, which we'll share with sub-scripts. This defines
# (and exports RELEASE, LOGDIR and RESDIR, creating directories named $LOGDIR
# and $RESDIR if they don't exist.
. "${ARC_GNU}"/toolchain/define-release.sh

# Set defaults for some options
do_busybox="--busybox"
busybox_version="1_22_1"
linux_dir=linux
linux_defconfig=nsimosci_defconfig
linux_version="arc-3.13"
arc_initramfs="ARC700/arc_initramfs_12_2013_gnu_4_8_ABI_v3.tgz"
tooldir=/opt/arc-${RELEASE}

# Parse options
getopt_string=`getopt -n build-kernel.sh -o d:i:l:t:h -l linux-defconfig: \
                   -l initramfs: -l linux-dir: -l tooldir -l help \
                   -l busybox -l no-busybox \
                   -l busybox-version: -l linux-version: \
                   -s sh -- "$@"`
eval set -- "$getopt_string"

while true
do
    case $1 in

	-d|--linux-defconfig)
	    # If set, argument specifies the Linux defconfig to use, otherwise
	    # no defconfig is run.
	    shift
	    linux_defconfig=$1
	    ;;

	-i|--initramfs)
	    # Argument specifies the initramfs to use relative to the
	    # arc_initramfs_archives directory.
	    shift
	    initramfs=$1
	    ;;

	-l|--linux-dir)
	    # Argument specifies the name of the Linux directory.
	    shift
	    linux_dir=$1
	    ;;

	-t|--tooldir)
	    # Argument specifies the name of the tool chain installation
	    # directory.
	    shift
	    tooldir="$1"
	    ;;

	--busybox | --no-busybox)
	    # Disable building BusyBox if desired.
	    do_busybox="$1"
	    ;;

	--busybox-version)
	    # Argument specifies the branch/tag of BusyBox to checkout. If set
	    # to the emptry string, no checkout is done.
	    shift
	    busybox_version=$1
	    ;;

	--linux-version)
	    # Argument specifies the branch/tag of Linux to checkout. If set
	    # to the emptry string, no checkout is done.
	    shift
	    linux_version=$1
	    ;;

	-h|--help)
	    echo "Usage: ./build-kernel.sh [-i|--initramfs <initramfs>]"
            echo "                         [-d|--linux-defconfig <config>]"
            echo "                         [-l|--linux-dir <dir>]"
            echo "                         [-t|--tooldir <dir>]"
	    echo "                         [--busybox | --no-busybox]"
	    echo "                         [--busybox-version]"
	    echo "                         [--linux-version]"
            echo "                         [-h|--help]"

	    exit 0
	    ;;

	--)
	    shift
	    break
	    ;;

	*)
	    echo "Internal error!"
	    echo $1
	    exit 1
	    ;;
    esac
    shift
done

# Silently ignore any other arguments

# Set up logging
logfile="${LOGDIR}/kernel-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"
echo "Logging to ${logfile}"

# Ensure we have the right tool chain on the path!
PATH=${tooldir}/bin:${PATH}
export PATH


# ------------------------------------------------------------------------------
#
#			       Set up initramfs
#
# ------------------------------------------------------------------------------

# Create arc_initramfs if specified. Need to patch the ownership.
logterm "Creating initramfs..."

# Work from top level directory so arc_initramfs is created in the correct
# directory.
if ! cd ${ARC_GNU} >> ${logfile} 2>&1
then
    logterm "ERROR: Could not change to root directory ${ARC_GNU}"
    failedbuild
fi

if [ "x${arc_initramfs}" != "x" ]
then
    echo "(sudo password may be needed to set up initramfs)"
    sudo rm -rf arc_initramfs >> ${logfile} 2>&1
    sudo tar zxpf arc_initramfs_archives/${arc_initramfs} >> ${logfile} 2>&1
    sudo chown -hR `id -u`:`id -g` arc_initramfs >> ${logfile} 2>&1
fi

# Blow away all existing libraries and copy in all the shared libraries and
# one static library that is referred to. Edit libc.so to use the new
# filename.
logterm "Setting up libraries..."

# Do we need to blow away existing libraries?

rm -f arc_initramfs/lib/* >> ${logfile} 2>&1

cp -df ${tooldir}/arc-linux-uclibc/lib/*.so* \
      arc_initramfs/lib >> $logfile 2>&1
cp -df ${tooldir}/arc-linux-uclibc/lib/uclibc_nonshared.a \
      arc_initramfs/lib >> $logfile 2>&1
sed -i arc_initramfs/lib/libc.so -e 's#/opt/[^/]*/arc-linux-uclibc##g'

# Copy across custom binaries
logterm "Copy custom binaries..."
cp -d ${tooldir}/target-bin/* arc_initramfs/bin >> $logfile 2>&1

# Fix rcS
sed -i arc_initramfs/etc/init.d/rcS \
    -e '/\/sbin\/udhcpc eth0/ d' \
    -e '/Bringing up eth0/ a \
      ifconfig eth0 192.168.218.2 netmask 255.255.255.0'


# ------------------------------------------------------------------------------
#
#				Build BusyBox
#
# ------------------------------------------------------------------------------

# Building BusyBox is optional
if [ "${do_busybox}" = "--busybox" ]
then
    # As a sanity check remove the busybox images from initramfs. This means a
    # failed install of busybox will show up!
    rm -f arc_initramfs/bin/busybox*
    rm -f arc_initramfs/lib/busybox*

    # Build busybox.
    logterm "Building BusyBox..."

    if ! cd ${ARC_GNU}/busybox
    then
	logterm "ERROR: Could not change to BusyBox directory"
	failedbuild
    fi

    if [ "x${busybox_version}" != "x" ]
    then
	logterm "Checking out version ${busybox_version}"
	if ! git checkout ${busybox_version}
	then
	    logterm "ERROR: Could not check out BusyBox"
	    failedbuild
	fi
    fi

    logterm "Cleaning BusyBox..."
    if ! make clean >> $logfile 2>&1
    then
	logterm "ERROR: Could not clean BusyBox"
	failedbuild
    fi

    logterm "Making BusyBox defconfig..."
    if ! make defconfig >> $logfile 2>&1
    then
	logterm "ERROR: Could not build Busybox defconfig"
	failedbuild
    fi

    # We need to turn off IPv6 and set the correct location for the
    # installation.
    logterm "Patching BusyBox config..."
    sed -i .config \
	-e 's/CONFIG_PING6=y/# CONFIG_PING6 is not set/' \
	-e 's/CONFIG_FEATURE_IPV6=y/# CONFIG_FEATURE_IPV6 is not set/' \
	-e 's/CONFIG_FEATURE_PREFER_IPV4_ADDRESS=y/# CONFIG_FEATURE_PREFER_IPV4_ADDRESS is not set/' \
	-e 's/CONFIG_FEATURE_IFUPDOWN_IPV6=y/# CONFIG_FEATURE_IFUPDOWN_IPV6 is not set/' \
	-e 's/CONFIG_TRACEROUTE6=y/# CONFIG_TRACEROUTE6 is not set/' \
	-e 's/CONFIG_CROSS_COMPILER_PREFIX=""/CONFIG_CROSS_COMPILER_PREFIX="arc-linux-uclibc-"/' \
	-e 's|CONFIG_PREFIX="./_install"|CONFIG_PREFIX="../arc_initramfs"|'

    logterm "Making BusyBox..."
    if ! make >> $logfile 2>&1
    then
	logterm "ERROR: Could not build Busybox"
	failedbuild
    fi

    logterm "Installing BusyBox..."

    if ! make install >> $logfile 2>&1
    then
	logterm "ERROR: Could not install Busybox"
	failedbuild
    fi

    logterm "Changing ownership and setuid of BusyBox..."
    echo "(sudo password may be needed)"

    if ! sudo chown root.root ../arc_initramfs/bin/busybox
    then
	logterm "ERROR: Could not change BusyBox ownership to root"
	failedbuild
    fi

    if ! sudo chmod ug+s ../arc_initramfs/bin/busybox
    then
	logterm "ERROR: Could not make BusyBox setuid root"
	failedbuild
    fi
fi

# ------------------------------------------------------------------------------
#
#				 Build Linux
#
# ------------------------------------------------------------------------------

logterm "Building linux..."

if ! cd ${ARC_GNU}/${linux_dir}
then
    logterm "ERROR: Could not change to Linux directory ${linux_dir}"
    failedbuild
fi

if [ "x${linux_version}" != "x" ]
then
    logterm "Checking out version ${linux_version}"
    if ! git checkout ${linux_version}
    then
	logterm "ERROR: Could not check out linux"
	failedbuild
    fi
fi

if [ "x${linux_defconfig}" != "x" ]
then
    # Only clean if we are setting a defconfig
    logterm "Cleaning Linux..."
    if ! make ARCH=arc distclean >> $logfile 2>&1
    then
	logterm "ERROR: Could not clean Linux"
	failedbuild
    fi

    logterm "Setting default config ${linux_defconfig}"
    if ! make ARCH=arc KBUILD_DEFCONFIG=${linux_defconfig} defconfig \
	      >> $logfile 2>&1
    then
	logterm "ERROR: Could not make default config for Linux"
	failedbuild
    fi
#else
#    make ARCH=arc defconfig >> $logfile 2>&1
fi

# Patch in the correct compiler and initramfs location for the kernel config
logterm "Patching LINUX .config..."
sed -i -e 's|CONFIG_INITRAMFS_SOURCE=".*"|CONFIG_INITRAMFS_SOURCE="../arc_initramfs/"|' \
    -e 's/COMPILE="arc-elf32-"/COMPILE="arc-linux-uclibc-"/' .config

logterm "Making Linux..."
if ! make ARCH=arc >> $logfile 2>&1
then
    logterm "ERROR: Could not build Linux"
    failedbuild
fi

logterm "Linux build successful.  See ${logfile} for details."
exit 0

# vim: noexpandtab sts=4 ts=8:
