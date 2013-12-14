#!/bin/sh

# Copyright (C) 2012, 2013 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a script for to build BusyBox and the Linux kernel for ARC700.

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

# Prerequisites:

# Ensure arc_initramfs_archives is cloned from git and the desired version
# unpacked into arc_initramfs as a peer of the linux tree.

# Ensure Busybox is cloned as a peer of the linux tree.

# Within Busybox run "make defconfig", then "make menuconfig" and change the
# following (only needs to be done once):
# - under "Busybox settings/Build options" set  "Busybox compiler prefix" to
#   arc-linux-uclibc-
# - under "Busybox settings/Installation options" set "Busybox installation
#   prefix" to ../arc_initramfs

# (One day we'll automate that as well).

# ------------------------------------------------------------------------------

# Useful constants. Some day these will be set from args
# LINUX_DEFCONFIG=4.10_defconfig
# LINUX_DEFCONFIG=fpga_defconfig_patched_no_sasid
LINUX_DEFCONFIG=
LINUX_TREE=linux
# ARC_INITRAMFS=arc_initramfs_10_2012_dyn_dev.tgz
# ARC_INITRAMFS=arc_initramfs_08_2012_gnu_4_4_ABI_v2.tgz
ARC_INITRAMFS=ramfs-abi-v3-gcc-4.4.tar.gz
ARC_UNPACKED_NAME=arc_initramfs_22_abi-v3-0.9.34

# Generic release set up, which we'll share with sub-scripts. This defines
# (and exports RELEASE, LOGDIR and RESDIR, creating directories named $LOGDIR
# and $RESDIR if they don't exist.
d=`dirname "$0"`
ARC_GNU=`(cd "$d/.." && pwd)`
. "${ARC_GNU}"/toolchain/define-release.sh
. "${ARC_GNU}"/toolchain/settings.sh

TOOLDIR=/opt/arc-${RELEASE}
# Ensure we have the right tool chain on the path!
PATH=${TOOLDIR}/bin:${PATH}

logfile="${LOGDIR}/kernel-build-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

# Create arc_initramfs. Need to patch the ownership.
echo "Create initramfs"
echo "Create initramfs" >> $logfile 2>&1
echo "================" >> $logfile 2>&1
cd ..
if [ "x${ARC_INITRAMFS}" != "x" ]
then
    sudo rm -rf arc_initramfs
    sudo tar zxpf arc_initramfs_archives/${ARC_INITRAMFS}
    if [ "x${ARC_UNPACKED_NAME}" != "x" ]
    then
	mv ${ARC_UNPACKED_NAME} arc_initramfs
    fi
    sudo chown -hR `id -u`:`id -g` arc_initramfs
fi

# Blow away all existing libraries and copy in all the shared libraries and
# one static library that is referred to. Edit libc.so to use the new
# filename.

echo "Setting up libraries..."
echo "Setting up libraries" >> $logfile 2>&1
echo "====================" >> $logfile 2>&1

# rm -f arc_initramfs/lib/* >> $logfile 2>&1
cp -df ${TOOLDIR}/arc-linux-uclibc/lib/*.so* \
      arc_initramfs/lib >> $logfile 2>&1
cp -df ${TOOLDIR}/arc-linux-uclibc/lib/uclibc_nonshared.a \
      arc_initramfs/lib >> $logfile 2>&1
${SED} -i arc_initramfs/lib/libc.so -e 's#/opt/[^/]*/arc-linux-uclibc##g'

# As a sanity check remove the busybox images from initramfs. This means a
# failed install of busybox will show up!
rm -f arc_initramfs/bin/busybox*
rm -f arc_initramfs/lib/busybox*

# Build busybox.
echo "Building busybox..."
echo "Building busybox" >> $logfile 2>&1
echo "================" >> $logfile 2>&1

cd busybox
OLDPATH=${PATH}
PATH=${TOOLDIR}/bin:${PATH}
make clean >> $logfile 2>&1
if make >> $logfile 2>&1
then
    echo "Busybox build succeeded"
else
    echo "Busybox build failed"
    exit 1
fi

echo "Installing busybox..."
echo "Installing busybox" >> $logfile 2>&1
echo "==================" >> $logfile 2>&1

make install >> $logfile 2>&1
PATH=${OLDPATH}

echo "Changing ownership and setuid of busybox..."
echo "Changing ownership and setuid of busybox" >> $logfile 2>&1
echo "========================================" >> $logfile 2>&1

sudo chown root.root ../arc_initramfs/bin/busybox
sudo chmod ug+s ../arc_initramfs/bin/busybox

# Copy across other custom binaries
echo "Copy custom binaries..."
echo "Copy custom binaries" >> $logfile 2>&1
echo "====================" >> $logfile 2>&1
cp -d ${TOOLDIR}/target-bin/* ../arc_initramfs/bin >> $logfile 2>&1

# Build Linux
echo "Building linux..."
echo "Building linux" >> $logfile 2>&1
echo "==============" >> $logfile 2>&1

cd ../${LINUX_TREE}
make ARCH=arc distclean                                     >> $logfile 2>&1

if [ "x${LINUX_DEFCONFIG}" != "x" ]
then
    make ARCH=arc KBUILD_DEFCONFIG=${LINUX_DEFCONFIG} defconfig >> $logfile 2>&1
else
    make ARCH=arc defconfig >> $logfile 2>&1
fi
# Temporary patch to deal with compiler issue!
echo "Patching LINUX .config"
${SED} -i .config -e 's/COMPILE="arc-elf32-"/COMPILE="arc-linux-uclibc-"/'

if make ARCH=arc >> $logfile 2>&1
then
    echo "Linux built successfully"
    exit 0
else
    echo "Linux build failed"
    exit 1
fi
