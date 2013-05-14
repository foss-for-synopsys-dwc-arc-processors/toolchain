#!/bin/sh

# Copyright (C) 2013 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a script to find the differences between two sets of summary
# test results.

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

# ------------------------------------------------------------------------------

# Usage:

#     ./diff-tests.sh <test1>.sum <test2>.sum [<descr>]

# If provided <desc> is now the differences found in test2 should be
# described. It defaults to "new".


# Grep out the results we want

# Certain specific tests are not constant between runs/endianesses, so we have
# some specific sed matches to deal with these.

# @param[in] $1 result type we are grepping for (PASS, FAIL etc)
# @param[in] $2 input test summary file
# @param[in] $3 output file of grepped results
grepres () {
    restype=$1
    summaryf=$2
    resf=$3

    # Sort out the results we want. Do some custom sed's of results to remove
    # known variable elements of particular test prints.
    grep ^${restype}: ${summaryf} | \
	sed -e 's/\(dump.exp: reload.*capture.*0x\)[[:xdigit:]]\+/\1/' | \
	sort > ${resf}
}


# Compares the results in two summary files, reporting on the changes between
# the two.

# Function to extract one result type

# @param[in] $1 The type of result (PASS, FAIL etc)
oneres () {
    restype=$1

    # Sort out the results we want.
    grepres ${restype} ${summary1} ${tmpf1}
    grepres ${restype} ${summary2} ${tmpf2}
    
    # Find the results only in the new (second file)
    diff -u --suppress-common-lines ${tmpf1} ${tmpf2} | \
	sed -n -e "s/^+${restype}:/  ${restype}:/p" > ${tmpdiff} 

    # Count this way, so we don't get the filename echoed
    count=`cat ${tmpdiff} | wc -l`

    # Print the results
    if [ "x${count}" != "x0" ]
    then
	echo "Total ${msg} only ${restype}: ${count}"
	cat ${tmpdiff}
	echo
    fi
}

# The arguments
summary1=$1
summary2=$2
msg=${3-new}

# Some temporary files
tmpf1=/tmp/diff-tests-1-$$
tmpf2=/tmp/diff-tests-2-$$
tmpdiff=/tmp/diff-tests-diff-$$

oneres PASS
oneres FAIL
oneres XPASS
oneres XFAIL
oneres KFAIL
oneres UNRESOLVED
oneres UNTESTED
oneres UNSUPPORTED
rm ${tmpf1} ${tmpf2} ${tmpdiff}
