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

rm -rf tmp packages/arc_gnu_ide_plugins *.nsi *.nsh
mkdir tmp

# Copy core utils
echo "Copying core utils and MSYS runtime files..."
tar -C tmp -xaf packages/coreutils/coreutils-*-msys-*-bin.tar.lzma
tar -C tmp -xaf packages/coreutils/libiconv-*-msys-*-dll*.tar.lzma
tar -C tmp -xaf packages/coreutils/libintl-*-msys-*-dll*.tar.lzma
tar -C tmp -xaf packages/coreutils/msysCORE-*-msys-*-bin.tar.lzma

# Copy Make and MinGW runtime files
echo "Copying Make and MinGW runtime files..."
tar -C tmp -xaf packages/make/gcc-core-*-mingw32-dll.tar.lzma
tar -C tmp -xaf packages/make/gettext-*-mingw32-dll.tar.lzma
tar -C tmp -xaf packages/make/libiconv-*-mingw32-dll.tar.lzma
tar -C tmp -xaf packages/make/make-*-mingw32-cvs-*-bin.tar.lzma
mv tmp/bin/{mingw32-,}make.exe

# Copy arcshell.bat
echo "Copying arcshell.bat..."
cp toolchain/windows-installer/arcshell.bat tmp/

# Copy OpenOCD
echo "Copying OpenOCD..."
tar -C tmp -xaf packages/openocd-*.tar.gz --strip-components=1

# Copy tool chain
echo "Copything toolchain..."
tar -C tmp -xaf packages/arc_gnu_*_prebuilt_elf32_win_install.tar.gz --strip-components=1

# Unzip Eclipse
unzip packages/eclipse-cpp-*-win32.zip -d tmp

# Copy Java runtime environment:
echo "Copying JRE..."
mkdir tmp/eclipse/jre
tar -C tmp/eclipse/jre -xaf packages/jre-*-windows-i586.tar.gz --strip-components=1

# Install ARC plugins
mkdir packages/arc_gnu_ide_plugins
unzip packages/arc_gnu_ide_2015.06_plugins.zip -d packages
# For some reason some of important exec files don't have exec bit set by the 
# cygwin unzip, but eclipse.exe has it.
chmod +x tmp/eclipse/eclipsec.exe
chmod +x tmp/eclipse/plugins/org.eclipse.equinox.launcher.*/*.dll

# Same as in Makefile.release
tmp/eclipse/eclipsec.exe \
    -application org.eclipse.equinox.p2.director \
    -noSplash \
    -repository ${ECLIPSE_REPO},file://$(cygpath -w -a packages/arc_gnu_ide_plugins) \
    -installIU ${ECLIPSE_PREREQ},com.arc.cdt.feature.feature.group

# Generate installer and uninstaller sections
echo "Generating NSIS files..."
./toolchain/windows-installer/gen-nsis-sections.sh tmp

# All file paths should relative to the location of .nsi file (or to current
# directory if /NOCD is used). To simplify scripts they are copied here, so
# all of them are in current directory.
cp toolchain/windows-installer/*.nsi .
cp toolchain/windows-installer/*.nsh .

# Generate installer
echo "Creating installer..."
cp toolchain/windows-installer/*.nsi .
cp toolchain/windows-installer/*.nsh .
/cygdrive/c/Program\ Files\ \(x86\)/NSIS/makensis.exe /Darcver=$RELEASE installer-standard.nsi

echo "Done"

# vim: noexpandtab sts=4 ts=8:
