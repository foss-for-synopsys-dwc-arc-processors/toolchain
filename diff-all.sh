#!/bin/bash

# Copyright (C) 2013 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# A wrapper to find the differences between tests for all components

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

#     ./diff-all.sh <dir1> <dir2> [<descr>]

# If provided <desc> is now the differences found in dir2 should be
# described. It defaults to "new".

# This is a wrapper for diff-tests.sh

# The arguments
dir1=$1
dir2=$2
msg=${3-new}

# Try all possible test results
for t in binutils ld as gcc g++ newlib libstdc++ sim gdb
do
    if [ -e ${dir1}/${t}.sum -a -e ${dir2}/${t}.sum ]
    then
	echo "RESULTS for ${t}"
	./diff-tests.sh ${dir1}/${t}.sum ${dir2}/${t}.sum ${msg}
    fi
done
