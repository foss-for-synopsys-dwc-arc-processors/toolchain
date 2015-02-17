#!/bin/sh

# Copyright (C) 2010-2013 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a script to count the results from a set of test directories.

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

# Look for the different GNU results in different directories. We put the
# results to a temporary file, to allow us to suck out the summary as well.

# The argument is the list of log files to process. It may optionally start
# with -d, indicating that the name of the test is the last directory name,
# not the tool and/or -a to indicate that tests with zero results should be
# included.

tmpf=/tmp/check-results-$$

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
[ "true" = "${complete}" ]
do
    continue
done

# Get the individual results if we have any. Note that we don't check for the
# strings at start of line, since they may have FTP prompts showing. Don't
# print out lines which have no tests at all.
echo "                          PASS  FAIL XPASS XFAIL KFAIL UNRES UNSUP UNTES  TOTAL"

if ls $* > /dev/null 2>&1
then
    for logfile in $*
    do
	if [ "${usedir}" = "true" ]
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

	if [ "${showall}" = "true" -o "x${tot}" != "x0" ]
	then
	    printf "%-23s %6d %5d %5d %5d %5d %5d %5d %5d %6d\n" \
  		${tname} ${p} ${f} ${xp} ${xf} ${kf} ${ur} ${us} ${ut} ${tot} | \
		tee -a ${tmpf}
	fi
    done
fi

# Total each column, if we have any results
if ls $* > /dev/null 2>&1
then
    pt=`cut -c 25-30 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    ft=`cut -c 32-36 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    xpt=`cut -c 38-42 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    xft=`cut -c 44-48 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    kft=`cut -c 50-54 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    urt=`cut -c 56-60 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    ust=`cut -c 62-66 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    utt=`cut -c 68-72 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
    tott=`cut -c 74-79 ${tmpf} | sed -e '2,$s/$/ +/' -e '$s/$/ p/' | dc`
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

echo "-----                   ------ ----- ----- ----- ----- ----- ----- ----- ------"
printf "TOTAL                   %6d %5d %5d %5d %5d %5d %5d %5d %6d\n" \
    ${pt} ${ft} ${xpt} ${xft} ${kft} ${urt} ${ust} ${utt} ${tott}

# vim: noexpandtab sts=4 ts=8:
