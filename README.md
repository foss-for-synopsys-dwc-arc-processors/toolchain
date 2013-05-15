ARC GNU Tool Chain
==================

This is the main git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

This is the version for the 4.8 tool chain release development branches. It
contains various patches applied since the official tool chain release. The
tool chain should still be reliable, but has not been through full release
testing.

The build script will check out the development branches from the 4.8 tool
chain component repositories.

Prequisites
-----------

You will need a Linux like environment (Cygwin and MinGW environments under
Windows should work as well).

You will need the standard GNU tool chain pre-requisites as documented in the
ARC GNU tool chain user guide or on the
[GCC website](http://gcc.gnu.org/install/prerequisites.html)

Finally you will need to check out the repositories for each of the tool chain
components (its not all one big repository), including the linux repository
for building the tool chain. These should be peers of this toolchain
directory. If you have yet to check any repository out, then the following
should be appropriate for creating a new directory, `arc` with all the
components.

    mkdir arc
    cd arc
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/binutils.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/gdb.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/linux.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git
    cd toolchain

For convenience, the script `arc-clone-all.sh` in this repository will clone
all the repositories for you.

Building the tool chain
-----------------------

The script `build-all.sh` will build and install both *arc*-elf32-* and
*arc*-linux-uclibc-* tool chains. The comments at the head of this script
explain how it works and the parameters to use. It uses script
`symlink-all.sh` to build a unified source directory.

The script `arc-versions.sh` specifies the branches to use in each component
git repository. It should be edited to change the default branches if
required.

Having built a unified source directory and checked out the correct branches,
`build-all.sh` in turn uses `build-elf32.sh` and `build-uclibc.sh`. These
build respectively the *arc*-elf32* and *arc*-linux-uclibc* tool chains. Details
of the operation are provided as comments in each script file. Both these
scripts use a common initialization script, `arc-init.sh`.

Testing the tool chain
----------------------

The script `run-tests.sh` will run the regression test suites against all the
main tool chain components. The comments at the htead of this script explain
how it works and the parameters to use. It in turn uses the run-elf32-tests.sh
and run-uclibc-tests.sh scripts.

You should be familiar with DejaGnu testing before using these scripts. Some
configuration of the target board specifications (in the `dejagnu/baseboards`
directory) may be required for your particular test target.
