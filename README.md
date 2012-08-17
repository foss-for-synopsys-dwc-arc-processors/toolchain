ARC GNU Tool Chain
==================

This is the main git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

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
directory. if you are in this toolchain directory, then the following commands
should be suitable

    cd ..
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/binutils.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/gdb.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/linux.git
    cd toolchain

Building the tool chain
-----------------------

Details will appear here very shortly.

