#!/bin/sh

# Script to set RPATHs to be relative in shared binaries

# Copyright (C) 2012-2015 Synopsys Inc.

# Contributor Simon Cook <simon.cook@embecosm.com>
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


# This should be run in the INSTALL directory, so there should be a bin
# subdirectory.

REPLACEDIR=${INSTALLDIR}
cd ${REPLACEDIR}

# Get a suitable SED
if [ x`uname -s` = "xDarwin" ]
then
    # You can install gsed with 'brew install gnu-sed'
    SED=gsed
else
    SED=sed
fi

if ! [ -d bin ]; then
    echo "\`$INSTALLDIR' is not a toolchain installation directory."
    exit 1
fi

# We need patchelf for this to install
which patchelf > /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "patchelf needs to be installed"
    exit 1
fi

# Get list of x86/x86_64 executables
files=$(find -type f -exec file {} \; | \
    grep -e 'ELF 32-bit LSB executable, Intel 80386' \
	 -e 'ELF 64-bit LSB\s*executable, x86-64' \
	 -e 'ELF 64-bit LSB executable, AMD x86-64' | \
    ${SED} -e 's/:.*$//')

for f in $files; do
    echo $f
    RPATH=$(readelf -d "${f}" | grep 'Library rpath\|Library runpath')
    # If no RPATH, continue
    if [ $? -gt 0 ]; then
	continue
    fi
    # Build a relative directory
    RELDIR=`echo ${f#./} | ${SED} -e 's#[^/]##g' | ${SED} -e 's#/#/..#g'`
    RPATH=$(echo "${RPATH}" | ${SED} "s#.*\[${REPLACEDIR}\(.*\)\]#\$ORIGIN${RELDIR}\1#")
    patchelf --set-rpath "${RPATH}" ${f}
done

# vim: noexpandtab sts=4 ts=8:
