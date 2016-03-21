#!/bin/bash -eu

# Copyright (C) 2015-2016 Synopsys Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# Configure
#

# Set tool to dejagnu tool name: gcc, gdb, g++, etc
# tool=SET ME

# Set sim to simulator name: cgen or nsim
# sim=SET ME

# Set processor to the processor name: arc600, arc700, arcem, archs
# processor=SET ME

# Toolchain source directory root.
# tools_src = SET ME

# Toolchain installation path
# tools_bin = SET ME

# Root location with nSIM properties files
# TODO: Better to use TCFs...
# nsim_props_root = SET ME

#
# Run
#
rm -rf {gdb,gcc}.{sum,log}
rm -f *.x? *.x *.i *.gcda *.ira
rm -f *.s *.o *.cl zzz-gdbscript *.baz bps tracecommandsscript

export ARC_MULTILIB_OPTIONS="$processor"
export DEJAGNU=$tools_src/toolchain/site.exp
export PATH=$tools_bin:$PATH

case $sim in
    nsim)
	export ARC_NSIM_PROPS=$nsim_props_root/$processor.props
	board=arc-nsim
	;;
    cgen)
	board=arc-sim
	;;
esac

case $tool in
    gdb)
	testsuite=$tool_src/gdb/gdb/testsuite
	mkdir $(ls -1d $testsuite/gdb.* | grep -Po '(?<=\/)[^\/]+$')
	;;
esac

runtest --tool=$tool --target_board=$board --target=arc-default-elf32
