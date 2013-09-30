#!/bin/sh

# Script to set RPATHs to be relative in shared binaries

# Copyright (C) 2012, 2013 Synopsys Inc.

# Contributor Simon Cook <simon.cook@embecosm.com>

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
    grep 'ELF 32-bit LSB executable, Intel 80386\|ELF 64-bit LSB executable, x86-64' | \
    sed -e 's/:.*$//')

for f in $files; do
    echo $f
    RPATH=$(readelf -d "${f}" | grep 'Library rpath')
    # If no RPATH, continue
    if [ $? -gt 0 ]; then
	continue
    fi
    # Build a relative directory
    RELDIR=${f:2}
    RELDIR=$(echo ${RELDIR//[^\/]})
    RELDIR=$(echo ${RELDIR//\//\/..})
    RPATH=$(echo "${RPATH}" | sed "s#.*\[${REPLACEDIR}\(.*\)\]#\$ORIGIN${RELDIR}\1#")
    patchelf --set-rpath "${RPATH}" ${f}
done

# We also need to patch libc.so because it is hardcoded
if [ "${ARC_ENDIAN}" = "big" ]
then
    arch=arceb
else
    arch=arc
fi
uclibc_libc_path=${arch}-linux-uclibc/lib/libc.so
if [ -f $uclibc_libc_path ]; then
    sed -e "s#${REPLACEDIR}/${arch}-linux-uclibc/lib/##g" < \
        $uclibc_libc_path > _libc.so
    mv _libc.so $uclibc_libc_path
fi

# vi: set expandtab:

