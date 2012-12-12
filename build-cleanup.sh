#!/bin/sh

# Copyright (C) 2012 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is a master script for building ARC tool chains.

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

#		SCRIPT TO CLEAN UP ARC BUILD SCRIPT ARTIFACTS
#		=============================================

# Remove the following from the build directory:
# - the tool specific build directories (bd-*)
# - temporary uClibc header install directories (tmp-install-uclibc-*)

# Move logs to the log subdirectory, creating it if it does not exist.

# Default source directory if not already set
if [ "x${ARC_GNU}" = "x" ]
then
    d=`dirname "$0"`
    ARC_GNU=`(cd "$d/.." && pwd)`
fi

cd ${ARC_GNU}

echo Removing tool specific build directories...
rm -rf bd-*

echo Removing temporary uClibc header install directories...
rm -rf tmp-install-uclibc-*

echo Archiving log files...
mkdir -p logs
mv -f *.log logs
