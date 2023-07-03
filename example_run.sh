#!/bin/bash -eu

# Enable support of compat.exp tests from GCC testsuite if necessary.
# These tests are intended to check compatibility between GNU and MetaWare
# compilers. There is an example of configuration for ARC EM (little endian).

#fnptr-by-value-1"

export DEJAGNU="/SCRATCH/brunoam/src/arc-gnu-toolchain/toolchain/site.exp"

export METAWARE_ROOT="/global/apps/mwdt_2023.03/MetaWare"

# Set path to alternate compiler.
export GCC_COMPAT_CCAC_PATH="$METAWARE_ROOT/arc/bin/ccac"

# Set options for GCC. If you want to run tests for big endian target
# it's necessary to pass "-EB" to MetaWare compiler and change path to
# MetaWare libraries from "-L$METAWARE_HOME/arc/lib/av2em/le" to
# "-L$METAWARE_HOME/arc/lib/av2em/be".
#export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=em4_dmips -fshort-enums -Wl,-z,muldefs -lgcc -lg -lmw -lm -L$METAWARE_ROOT/arc/lib/av2em/le --specs=hl.specs"
# -mno-sdata"
#export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=hs5x -fshort-enums -Wl,-z,muldefs -lgcc -lg -lm -L$METAWARE_ROOT/arc/lib/av2em/le --specs=hl.specs"

# Set options for alternate compiler.
# Metaware and GCC has different expectations for structure alignment.
# See Synopsys STAR 9001042680.
#export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -ansi -av2hs -Xbasecase -Hnocopyr -Hnosdata -fstrict-abi"


#      HS6x Default
#export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=hs6x -Wl,-z,muldefs -Wl,--no-warn-mismatch -lgcc -lnsim -lg -lm \
#-L$METAWARE_ROOT/arc/lib/av2em/le -lmw --specs=hl.specs"

#export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -arc64 -Xbasecase -Hnocopyr -Hnosdata -fstrict-abi"



#      HS5x Default

export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=hs5x -Wl,-z,muldefs -Wl,--no-warn-mismatch -lgcc -lnsim -lg -lm \
-L$METAWARE_ROOT/arc/lib/av3hs/le -lmw --specs=hl.specs"

export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -arcv3hs -Xbasecase -Hnocopyr -Hnosdata -fstrict-abi"
#export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -arcv3hs -Xbasecase -Hnocopyr -Hnosdata -fstrict-abi  -Xfp_dds -Xfp_div -Xfp_dp -Xfp_hp -Xfp_sp -Xfp_vec -Xfp_wide"


#     ARCV2 default flags (works fine!)

#export GCC_COMPAT_GCC_OPTIONS="-O0 -g -mcpu=em4_dmips -mno-sdata \
#    -fshort-enums -Wl,-z,muldefs -Wl,--no-warn-mismatch -lgcc -lnsim \
#    -lg -lm -L$METAWARE_ROOT/arc/lib/av2em/le -lmw --specs=hl.specs"

#export GCC_COMPAT_CCAC_OPTIONS="-O0 -g -av2em -Xbasecase -Hnocopyr -Hnosdata -fstrict-abi"

rm -rf *.o

runtest compat.exp=pr83487-2_main.c
#=fnptr-by-value-1_main.c
