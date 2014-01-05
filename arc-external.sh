#!/bin/sh -e

# Download some external dependencies. Return non-zero status if there is an error.

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

