#!/bin/bash
# Copyright (C) 2013-2015 Synopsys Inc.

# Contributor Simon Cook <simon.cook@embecosm.com>
# Contributor Anton Kolesov <Anton.Kolesov@synopsys.com>

# Script to generate the install and uninstall sections for a NSIS based
# installer.

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

# NB: `cd' is called with --, because some directories start with -, so by
# default cd thiks those are options.

copyDir() {
    dirname=$1
    space=$2

    # We print files first and then do folders next
    for f in *; do
	if [ -f "$f" ]; then
	    if [ "${dirname}" == "" ]; then
		echo "${space}File \"${PREFIX}\\${f}\""
	    else
		echo "${space}File \"${PREFIX}\\${dirname}\\${f}\""
	    fi
	fi
    done

    for f in *; do
	if [ -d "$f" ]; then
	    if [ "${dirname}" == "" ]; then
		(echo "setOutPath \"\$INSTDIR\\$f\""
		    cd -- "$f" && copyDir "$f" "  ")
	    else
		(echo "${space}setOutPath \"\$INSTDIR\\${dirname}\\$f"\"
		    cd -- "$f" && copyDir "${dirname}\\$f" "  ${space}")
	    fi
	fi
    done
}

delDir() {
    dirname=$1

    # We remove files before their containing directories
    for f in *; do
	if [ -f "$f" ]; then
	    # Delete is parsed so we need to $ -> $$
	    f=$(echo $f | /usr/bin/sed 's/\$/\$\$/g')
	    if [ "${dirname}" == "" ]; then
		echo "Delete \"\$INSTDIR\\$f\""
	    else
		echo "Delete \"\$INSTDIR\\${dirname}\\$f\""
	    fi
	fi
    done
    for f in *; do
	if [ -d "$f" ]; then
	    if [ "${dirname}" == "" ]; then
		(cd -- "$f" && delDir "$f")
	    else
		(cd -- "$f" && delDir "${dirname}\\$f")
	    fi
	fi
    done
    # Finally we remove the current directory (if it is not root)
    if [ "${dirname}" != "" ]; then
	echo "RMDir \"\$INSTDIR\\${dirname}\""
    fi
}

if [ "$1" == "" ]; then
    PREFIX=in
else
    PREFIX="$1"
fi

cd -- $PREFIX
echo "Generating install_files.nsi..."
echo "setOutPath \"\$INSTDIR\"" > ../install_files.nsi
copyDir "" "" >> ../install_files.nsi
echo "Generating uninstall_files.nsi..."
delDir "" ""  > ../uninstall_files.nsi

# vim: noexpandtab sts=4 ts=8:
