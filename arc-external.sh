#!/bin/sh -e

# Copyright (C) 2013-2016 Synopsys Inc.

# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

# This script is sourced to specify the versions of tools to be built.

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

#
# Download some external dependencies. Return non-zero status if there is an
# error. This script will not work on RHEL 5, because its tar doesn't support
# .tar..xz and -a.
#

urls='
https://ftp.gnu.org/gnu/gmp/gmp-6.1.1.tar.xz
https://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.xz
https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
'

for url in ${urls} ; do
    filename="$(echo "${url}" | sed 's/^.*\///')"
    dirname="$(echo "${filename}" | sed 's/\.tar\..*$//')"
    toolname="$(echo "${dirname}" | cut -d- -f1)"

    if [ ! -d "${toolname}" ]; then
        if [ ! -d "${dirname}" ]; then
            if [ ! -f "${filename}" ]; then
                $WGET "${url}"
            fi
            tar xf "${filename}"
        fi
        mv "${dirname}" "${toolname}"
    fi
done

# vim: expandtab sts=4:
