#!/bin/sh -e

# Copyright (C) 2013-2014 Synopsys Inc.

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
# Download some external dependencies. Return non-zero status if there is an error.
#

urls='
ftp://ftp.gmplib.org/pub/gmp/gmp-5.1.3.tar.bz2
http://www.mpfr.org/mpfr-3.1.2/mpfr-3.1.2.tar.bz2
http://www.multiprecision.org/mpc/download/mpc-1.0.1.tar.gz
'

for url in ${urls} ; do
    filename="$(echo "${url}" | sed 's/^.*\///')"
    dirname="$(echo "${filename}" | sed 's/\.tar\..*$//')"
    toolname="$(echo "${dirname}" | cut -d- -f1)"

    if echo "${filename}" | grep -q .tar.bz2 ; then
        tar="tar xjf"
    else
        tar="tar xzf"
    fi

    if [ ! -d "${toolname}" ]; then
        if [ ! -d "${dirname}" ]; then
            if [ ! -f "${filename}" ]; then
                wget -nv "${url}"
            fi
            ${tar} "${filename}"
        fi
        mv "${dirname}" "${toolname}"
    fi
done

