#!/bin/bash -eu

# Copyright (C) 2015-2017 Synopsys Inc.
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

# Set sim to simulator name: cgen, nsim, nsim-gdb
# sim=SET ME

# Set processor to the processor name (value of -mcpu= option).
# processor=SET ME

# Toolchain source directory root.
# tools_src = SET ME

# Toolchain installation path
# Example: /opt/arcgnu/arc_gnu_2016.03_prebuilt_elf32_le_linux_install
# tools_installation=SET ME

# Triplet, like arc-elf32 or arc-linux-uclibc
# triplet=SET ME

# Root location with nSIM properties files
# TODO: Better to use TCFs...
# nsim_props_root = SET ME

# Set to run specific DejaGnu tests. Example:
# runtestflags="suite-name.exp=test-name.c"
runtestflags=""

# Enable support of compat.exp tests from GCC testsuite if necessary.
# These tests are intended to check compatibility between GNU and MetaWare
# compilers. There is an example of configuration for ARC EM (little endian).
export ARC_GCC_COMPAT_SUITE="0"

if [ "${ARC_GCC_COMPAT_SUITE:-0}" == "1" ]; then
    runtestflags="compat.exp"

    # Set path to alternate compiler.
    export GCC_COMPAT_CCAC_PATH="$METAWARE_ROOT/arc/bin/ccac"

    # Set options for GCC. If you want to run tests for big endian target
    # it's necessary to pass "-EB" to MetaWare compiler and change path to
    # MetaWare libraries from "-L$METAWARE_HOME/arc/lib/av2em/le" to
    # "-L$METAWARE_HOME/arc/lib/av2em/be".
    export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=em4_dmips -mno-sdata \
        -fshort-enums -Wl,-z,muldefs -Wl,--no-warn-mismatch -lgcc -lnsim -lc \
        -lg -lm -L$METAWARE_ROOT/arc/lib/av2em/le -lmw"

    # Set options for alternate compiler.
    # Metaware and GCC has different expectations for structure alignment.
    # See Synopsys STAR 9001042680.
    export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -av2em -Xbasecase -Hnocopyr \
	-Hnosdata -fstrict-abi"
fi

#
# Run
#
rm -rf {gdb,gcc}.{sum,log}
rm -f *.x? *.x *.i *.gcda *.ira
rm -f *.s *.o *.cl zzz-gdbscript *.baz bps tracecommandsscript

export ARC_MULTILIB_OPTIONS="cpu=$processor"
export DEJAGNU=$tools_src/toolchain/site.exp
export PATH=$tools_installation/bin:$PATH

case $sim in
    nsim)
	board=arc-sim-nsimdrv
	;;
    nsim-gdb)
	export ARC_NSIM_PROPS=$nsim_props_root/$processor.props
	board=arc-nsim
	;;
    cgen)
	board=arc-sim
	;;
    openocd)
	board=arc-openocd
	;;
esac

case $tool in
    gdb)
	rm -rf gdb.*
	testsuite=$tools_src/gdb/testsuite
	mkdir $(ls -1d $testsuite/gdb.* | grep -Po '(?<=\/)[^\/]+$')
	;;
    newlib)
	# Newlib requires that targ-include/newlib.h is present in object
	# directory to run regressions.
	mkdir -p targ-include
	cp -a $tools_installation/$triplet/include/newlib.h targ-include
esac

# Create a memory.x file for baremetal boards that use -Wl,marcv2elfx.
# Actual memory map depends on a particular board.
cat > memory.x <<EOF
/* ARC EM Starter Kit v2.2 EM7D */

MEMORY
{
    ICCM : ORIGIN = 0x00000000, LENGTH = 256K
    DRAM : ORIGIN = 0x10000000, LENGTH = 128M
    DCCM : ORIGIN = 0x80000000, LENGTH = 128K
}

REGION_ALIAS("startup", ICCM)
REGION_ALIAS("text", ICCM)
REGION_ALIAS("data", DCCM)
REGION_ALIAS("sdata", DCCM)

PROVIDE (__stack_top = (0x8001FFFF & -4) );
PROVIDE (__end_heap = (0x8001FFFF) );
EOF

runtest --tool=$tool --target_board=$board --target=arc-default-elf32 $runtestflags
