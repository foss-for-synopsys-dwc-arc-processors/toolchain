#!/bin/bash -e

# Copyright (C) 2014-2015 Synopsys Inc.

# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

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


# It is assumed that current directory is directory where with script is
# located. It is also assumed that all prerequisites are downloaded to the
# "tars" directory. Eclipse in the "tars" should be already unpacked and has
# all plug-ins installed. This is a "quick and dirty" script, thus it have
# such strict requirements.

# Params
# Eclipse parameters copied from Makefile.release
ECLIPSE_REPO=http://download.eclipse.org/releases/luna
ECLIPSE_PREREQ=org.eclipse.tm.terminal.serial,org.eclipse.tm.terminal.view

if [ -z "$RELEASE" ]; then
    echo "RELEASE env variable must be set"
    exit 1
fi

rm -rf tmp packages/arc_gnu_ide_plugins *.nsi *.nsh *.bmp
mkdir tmp

echo "Preparing common files..."
mkdir tmp/common
cp toolchain/windows-installer/arcshell.bat tmp/common
./toolchain/windows-installer/gen-nsis-sections.sh tmp/common common

echo "Preparing core utils and MSYS runtime files..."
mkdir tmp/coreutils
tar -C tmp/coreutils -xaf packages/coreutils/coreutils-*-msys-*-bin.tar.lzma
tar -C tmp/coreutils -xaf packages/coreutils/libiconv-*-msys-*-dll*.tar.lzma
tar -C tmp/coreutils -xaf packages/coreutils/libintl-*-msys-*-dll*.tar.lzma
tar -C tmp/coreutils -xaf packages/coreutils/msysCORE-*-msys-*-bin.tar.lzma
./toolchain/windows-installer/gen-nsis-sections.sh tmp/coreutils coreutils

echo "Preparing Make and MinGW runtime files..."
mkdir tmp/make
tar -C tmp/make -xaf packages/make/gcc-core-*-mingw32-dll.tar.lzma
tar -C tmp/make -xaf packages/make/gettext-*-mingw32-dll.tar.lzma
tar -C tmp/make -xaf packages/make/libiconv-*-mingw32-dll.tar.lzma
tar -C tmp/make -xaf packages/make/make-*-mingw32-cvs-*-bin.tar.lzma
mv tmp/make/bin/{mingw32-,}make.exe
./toolchain/windows-installer/gen-nsis-sections.sh tmp/make make

echo "Preparing OpenOCD..."
mkdir tmp/openocd
tar -C tmp/openocd -xaf packages/arc_gnu_*_openocd_win_install.tar.gz --strip-components=1
./toolchain/windows-installer/gen-nsis-sections.sh tmp/openocd/ openocd

echo "Preparing little-endian toolchain..."
mkdir tmp/toolchain_le
tar -C tmp/toolchain_le -xaf packages/arc_gnu_*_prebuilt_elf32_le_win_install.tar.gz \
    --strip-components=1
./toolchain/windows-installer/gen-nsis-sections.sh tmp/toolchain_le toolchain_le

echo "Preparing big-endian toolchain..."
mkdir tmp/toolchain_be
tar -C tmp/toolchain_be -xaf packages/arc_gnu_*_prebuilt_elf32_be_win_install.tar.gz \
    --strip-components=1
./toolchain/windows-installer/gen-nsis-sections.sh tmp/toolchain_be toolchain_be

echo "Preparing Eclipse..."
mkdir tmp/eclipse
unzip packages/eclipse-cpp-*-win32.zip -d tmp/eclipse
# For some reason some of important exec files don't have exec bit set by the 
# cygwin unzip, but eclipse.exe has it.
chmod +x tmp/eclipse/eclipse/eclipsec.exe
chmod +x tmp/eclipse/eclipse/plugins/org.eclipse.equinox.launcher.*/*.dll
# Install ARC plugins
mkdir tmp/arc_gnu_ide_plugins
unzip packages/arc_gnu_2015.06_ide_plugins.zip -d tmp/arc_gnu_ide_plugins
# Same as in Makefile.release
echo "Installing ARC plugins into Eclipse..."
tmp/eclipse/eclipse/eclipsec.exe \
    -application org.eclipse.equinox.p2.director \
    -noSplash \
    -repository ${ECLIPSE_REPO},file://$(cygpath -w -a tmp/arc_gnu_ide_plugins) \
    -installIU ${ECLIPSE_PREREQ},com.arc.cdt.feature.feature.group
./toolchain/windows-installer/gen-nsis-sections.sh tmp/eclipse eclipse

# Copy Java runtime environment:
echo "Preparing JRE..."
mkdir -p tmp/jre/eclipse/jre
tar -C tmp/jre/eclipse/jre -xaf packages/jre-*-windows-i586.tar.gz --strip-components=1
./toolchain/windows-installer/gen-nsis-sections.sh tmp/jre jre

#
# Generate installer
#
echo "Creating installer..."
# All file paths should relative to the location of .nsi file (or to current
# directory if /NOCD is used). To simplify scripts they are copied here, so
# all of them are in current directory.
cp toolchain/windows-installer/*.nsi .
cp toolchain/windows-installer/*.nsh .
cp toolchain/windows-installer/snps_logo.bmp .
cp toolchain/windows-installer/Synopsys_FOSS_Notices.txt .
/cygdrive/c/Program\ Files\ \(x86\)/NSIS/makensis.exe /Darcver=$RELEASE installer.nsi

echo "Done"

# vim: noexpandtab sts=4 ts=8:
