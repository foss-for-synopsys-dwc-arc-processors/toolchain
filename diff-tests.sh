#!/bin/bash

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

exit


# Check for flags
usedir="false"
showall="false"
until
complete="false"
case $1
    in
    -d)
	usedir="true"
	shift
	;;

    -a)
	showall="true"
	shift
	;;
    
    *)
	complete="true"
	;;
esac;
[ "true" == "${complete}" ]
do
    continue
done

# Get the individual results if we have any. Note that we don't check for the
# strings at start of line, since they may have FTP prompts showing. Don't
# print out lines which have no tests at all.
echo "                           PASS  FAIL XPASS XFAIL KFAIL UNRES UNSUP UNTES TOTAL"

if ls $* > /dev/null 2>&1
then
    for logfile in $*
    do
	if [ "${usedir}" == "true" ]
	then
	    dir=`dirname ${logfile}`
	    tname=`basename ${dir}`
	else
	    logfile_base=`basename ${logfile}`
	    tname=`echo ${logfile_base} | sed -e 's/\.log//'`
	fi

	p=`grep 'PASS:' ${logfile} | grep -v 'XPASS' | wc -l`
	f=`grep 'FAIL:' ${logfile} | grep -v 'XFAIL' | grep -v 'KFAIL' | wc -l`
	xp=`grep 'XPASS:' ${logfile} | wc -l`
	xf=`grep 'XFAIL:' ${logfile} | wc -l`
	kf=`grep 'KFAIL:' ${logfile} | wc -l`
	ur=`grep 'UNRESOLVED:' ${logfile} | wc -l`
	us=`grep 'UNSUPPORTED:' ${logfile} | wc -l`
	ut=`grep 'UNTESTED:' ${logfile} | wc -l`
	tot=`echo "${p} ${f} + ${xp} + ${xf} + ${ur} + ${us} + ${ut} + p" | dc`

	if [ "${showall}" == "true" -o "x${tot}" != "x0" ]
	then
	    printf "%-25s %5d %5d %5d %5d %5d %5d %5d %5d %5d\n" \
  		${tname} ${p} ${f} ${xp} ${xf} ${kf} ${ur} ${us} ${ut} ${tot} | \
		tee -a ${tmpf}
	fi
    done
fi

# Total each column, if we have any results
if ls $* > /dev/null 2>&1
then
    pt=`cut -c 27-31 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    ft=`cut -c 33-37 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    xpt=`cut -c 39-43 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    xft=`cut -c 45-49 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    kft=`cut -c 51-55 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    urt=`cut -c 57-61 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    ust=`cut -c 63-67 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    utt=`cut -c 69-73 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    tott=`cut -c75-79 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
else
    pt=0
    ft=0
    xpt=0
    xft=0
    kft=0
    urt=0
    ust=0
    utt=0
    tott=0
fi

rm -f ${tmpf}

echo "-----                     ----- ----- ----- ----- ----- ----- ----- ----- -----"
printf "TOTAL                     %5d %5d %5d %5d %5d %5d %5d %5d %5d\n" \
    ${pt} ${ft} ${xpt} ${xft} ${kft} ${urt} ${ust} ${utt} ${tott}

