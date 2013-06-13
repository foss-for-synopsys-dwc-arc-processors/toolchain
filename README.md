ARC GNU Tool Chain
==================

This is the main git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

This is the version for the 4.4 tool chain release development branches. It
contains various patches applied since the official tool chain release. The
tool chain should still be reliable, but has not been through full release
testing.

The build script will check out the development branches from the 4.4 tool
chain component repositories.

Prequisites
-----------

You will need a Linux like environment (Cygwin and MinGW environments under
Windows should work as well).

You will need the standard GNU tool chain pre-requisites as documented in the
ARC GNU tool chain user guide or on the
[GCC website](http://gcc.gnu.org/install/prerequisites.html)

On Ubuntu 12.04 LTS you can install those with following command (as root):

    apt-get install libgmp-dev libmpfr-dev texinfo byacc flex \
    libncurses5-dev zlib1g-dev libexpat1-dev libx11-dev libmpc-dev texlive \
    build-essential

On Fedora 17 you can install those with following command (as root):

    yum install gmp-devel mpfr-devel texinfo-tex byacc flex ncurses-devel \
    zlib-devel expat-devel libX11-devel libmpc-devel

On RedHat/CentOS 6.3 systems there is no official MPC package. On those systems
you have to download and build MPC from source tarball, or install you
[rpmfind](http://www.rpmfind.net/linux/rpm2html/search.php?query=libmpc&submit=Search+...)
to find prebuilt one. Otherwise it is the same as Fedora.


Getting sources
---------------

You need to check out the repositories for each of the tool chain
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
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/arc_initramfs_archives.git
    git clone git://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

For convenience, the script `arc-clone-all.sh` in this repository will clone
all the repositories for you.

Checkout `toolchain` repository to the desired branch, for example:

    cd toolchain
    git checkout arc_4_8-toolchain-dev

Building the tool chain
-----------------------

The script `build-all.sh` will build and install both *arc-elf32-* and
*arc-linux-uclibc-* tool chains. The comments at the head of this script
explain how it works and the parameters to use. It uses script
`symlink-trunks.sh` to build a unified source directory.

The script `arc-versions.sh` specifies the branches to use in each component
git repository. It should be edited to change the default branches if
required.

Having built a unified source directory and checked out the correct branches,
`build-all.sh` in turn uses `build-elf32.sh` and `build-uclibc.sh`. These
build respectively the *arc-elf32* and *arc-linux-uclibc* tool chains. Details
of the operation are provided as comments in each script file. Both these
scripts use a common initialization script, `arc-init.sh`.

The most important options if `build-all.sh` are:

 * `--install-dir <dir>` - define where tool chain will be installed. Once
   installed tool chain cannot be moved to another location, however it can be
   moved to another system and used from the same location.
 * `--no-elf32` and `--no-uclibc` - choose type of tool chain to build. By
   default both are built. Specify `--no-uclibc` if you intend to work
   exclusively with baremetal applications, specify `--no-elf32` of you intend
   to work exclusively with Linux applications. Linux kernel is built with
   uClibc tool chain.
 * `--no-multilib` - do not build multilib standard libraries. Use it when you
   are going to work exclusively with baremetal applications for ARC700. This
   option doesn't affect uClibc tool chain.
 * `--isa-v2` - build tool chain for ARC ISA v2 cores (EM and HS) instead ARC
   ISA v1 cores (ARC600, ARC700).

Please consult `./build-all.sh --help` to get a full list of supported options.

### Examples

Build tool chain for Linux development:

    ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT

Build tool chain for EM cores (for example for EM Starter Kit):

    ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --isa-v2

Build tool chain for baremetal applications for ARC ISA v1 cores (ARC600, ARC700:

    ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT

Usage examples
--------------

Add tool chain to PATH:

    export PATH=$INSTALL_ROOT/bin:$PATH

Build single source application:

    arc-elf32-gcc hello_world.c -mARC700

Run it on CGEN-based simulator:

    arc-elf32-gdb -q a.out
    (gdb) target sim
    (gdb) load
    (gdb) run

Example of running target application on gdbserver-based setup like nsim_gdb,
OpenOCD, Ashling gdbserver, etc, using nsim_gdb as an example:

    $NSIM_HOME/bin/nsim_gdb :51000 -DLL=$NSIM_HOME/lib/libsim.so \
    -props=$NSIM_HOME/systemc/configs/arc700.props

And in another console:

    arc-elf32-gdb -q a.out
    (gdb) target remote :51000
    (gdb) load
    (gdb) continue

Please note that in case of gdbserver-based usage all execution, input and
output happens on the side of host that runs gdbserver.

Testing the tool chain
----------------------

The script `run-tests.sh` will run the regression test suites against all the
main tool chain components. The comments at the head of this script explain
how it works and the parameters to use. It in turn uses the run-elf32-tests.sh
and run-uclibc-tests.sh scripts.

You should be familiar with DejaGnu testing before using these scripts. Some
configuration of the target board specifications (in the `dejagnu/baseboards`
directory) may be required for your particular test target.

Getting help
------------

If you are a Synopsys customer for all inquiries please use
[SolvNet](https://solvnet.synopsys.com). In other cases open an issue for a
respective project on GitHub.

