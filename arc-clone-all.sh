#!/bin/sh
 
# Copyright (C) 2013 Embecosm Limited.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# A script to clone all the components of the ARC tool chain

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

#		     CLONE ALL ARC TOOL CHAIN COMPONENTS
#		     ===================================

# Run this in the directory where you want to create all the repositories

# Function to clone a tool. First argument is the name to use for the remote,
# second is the name of the tool, third the repository to clone from.
clone_tool () {
    remote=$1
    tool=$2
    repo=$3

    # Clear out anything pre-existing and clone the repo
    rm -rf ${tool}
    git clone -o ${remote} ${repo} ${tool}
}

# Clone all the ARC tools and the toolchain scripts
clone_tool arc cgen git://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
clone_tool arc binutils  git://github.com/foss-for-synopsys-dwc-arc-processors/binutils.git
clone_tool arc gcc       git://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
clone_tool arc gdb       git://github.com/foss-for-synopsys-dwc-arc-processors/gdb.git
clone_tool arc newlib    git://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
clone_tool arc uClibc    git://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
clone_tool arc linux     git://github.com/foss-for-synopsys-dwc-arc-processors/linux.git
clone_tool arc toolchain git://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

# We perhaps ought to allow an option to check out specific versions. For now
# just messages.
echo "All repositories cloned"
