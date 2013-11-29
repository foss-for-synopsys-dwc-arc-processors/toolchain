ARC GNU Tool Chain
==================

This is the main git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

The branch name corresponds to the development for the various ARC releases.
* `arc-mainline-dev` is the mainline development branch
* `arc-4.8-dev` is the development branch for the 4.8 tool chain release
* `arc-4.4-dev` is the development branch for the 4.4 tool chain release

These branches are under active development, and while the top of each branch
should build and run reliably, they have not necessarily been through full
release testing.

Within each branch there are points where the whole development has been put
through comprehensive release testing. These are marked using git *tags*. For
example tag `arc_4_8-R1` means that this is the first release of the Synopsys
DesignWare ARC 4.8 tool chain, while tag `arc_4_8-R1.2` means this is the
second minor patch set to the first release of the ARC 4.8 tool chain.

These tagged stable releases have been through full release testing, and known
issues are documented in a Synopsys release notes.

In general the tool chain release numbering corresponds to the version of GCC
within that tool chain release. Active development is generally carried out on
the mainline branch, with changes back-ported to earlier release branches if
appropriate.

The build script will check out the corresponding branches from the tool chain
component repositories.

Prerequisites
-------------

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
you have to download and build MPC from source tarball, or you can use
[rpmfind](http://www.rpmfind.net/linux/rpm2html/search.php?query=libmpc&submit=Search+...)
to find prebuilt one. Otherwise it is the same as Fedora.


Getting sources
---------------

###  Using source tarball

If you use source tarball then it already contains all of the necessary sources
except for Linux which is a separate product. Linux sources are required only
for linux-uclibc tool chain, they are not required for baremetal elf32 tool
chain.  Latest stable release from https://kernel.org/ is recommended, only
versions >= 3.9 are supported. Untar linux tarball to the directory named
\`linux' that is the sibling of this \`toolchain' directory. For example,
assuming your current directory is \`toolchain\':

    $ cd ..
    $ wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.11.6.tar.xz
    $ tar xaf linux-3.11.6.tar.xz --transform=s/linux-3.11.6/linux/
    $ cd toolchain

### Using Git repositories

You need to check out the repositories for each of the tool chain
components (its not all one big repository), including the linux repository
for building the tool chain. These should be peers of this toolchain
directory.

	mkdir arc_gnu
	cd arc_gnu
	git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

After you have just checked this repository (toolchain) out, then the following
commands will clone all the remaining components into the right place.

    cd toolchain
    ./arc-clone-all.sh [-f | --force] [-d | --dev]

Option --force or -f will replace any existing cloned version of the
components (use with care). Option --dev or -d will attempt to clone writable
clones using the SSH version of the remote URL, suitable for developers
contributing back to this repository.

Alternatively you can manually clone the remaining repositories using the
following:

    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/binutils.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/gdb.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    git clone https://github.com/foss-for-synopsys-dwc-arc-processors/linux.git

Checkout `toolchain` repository to the desired branch, for example to get the
mainline development branch use:

    git checkout arc-mainline-dev

while to get the 4.8 version 1 stable release use:

    git checkout arc_4_8-R1.2

Building the tool chain
-----------------------

The script `build-all.sh` will build and install both _arc*-elf32-_ and
_arc*-linux-uclibc-_ tool chains. The comments at the head of this script
explain how it works and the parameters to use. It uses script
`symlink-all.sh` to build a unified source directory.

The script `arc-versions.sh` specifies the branches to use in each component
git repository. It should be edited to change the default branches if
required.

Having built a unified source directory and checked out the correct branches,
`build-all.sh` in turn uses `build-elf32.sh` and `build-uclibc.sh`. These
build respectively the _arc*-elf32_ and _arc*-linux-uclibc_ tool chains. Details
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
 * `--isa-v2` - build tool chain for ARC ISA v2 core (ARC EM) instead of ARC
   ISA v1 cores (ARC600, ARC700).

Please consult `./build-all.sh --help` to get a full list of supported options.

### Examples

Build tool chain for Linux development:

    ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT

Build tool chain for EM cores (for example for EM Starter Kit):

    ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --isa-v2

Build tool chain for baremetal applications for ARC ISA v1 cores (ARC600, ARC700):

    ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT


Usage examples
--------------

In all cases it is expected that you have added tool chain to PATH:

    $ export PATH=$INSTALL_ROOT/bin:$PATH


### ARC 700 application running on CGEN simulator

Build application:

    $ arc-elf32-gcc hello_world.c -mARC700

Run it on CGEN-based simulator:

    $ arc-elf32-run a.out
    hello world

Or debug it in GDB using simulator (GDB output omitted):

    $ arc-elf32-gdb --quiet a.out
    (gdb) target sim
    (gdb) load
    (gdb) start
    (gdb) l
    (gdb) continue
    hello world
    (gdb) q


### ARC EM application using nSIM simulator

Before starting nsim_gdb you need to update properties file for nSIM, in
$NSIM_HOME/systemc/configs find a file for your core and add to it:

    nsim_emt=1

This will enable input-output operations. Use nSIM User Guide to learn about
other nSIM properties. Then start nsim_gdb (ARC EM is used as an example):

    $ $NSIM_HOME/bin/nsim_gdb :51000 -DLL=$NSIM_HOME/lib/libsim.so \
    -props=$NSIM_HOME/systemc/configs/nsim_av2em11.props

And in another console (GDB output is omitted):

    $ arc-elf32-gcc -mEM -g hello_world.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :51000
    (gdb) load
    (gdb) break main
    (gdb) break exit
    (gdb) continue
    (gdb) continue
    (gdb) q

Please note that in case of gdbserver-based usage all execution, input and
output happens on the side of host that runs gdbserver, so "hello world" string
will be printed on the server side.


### ARC EM application running on EM Starter Kit

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building application" of our EM Starter Kit Wiki page:
> https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/EM-Starter-Kit

Download and build the OpenOCD port for ARC as described here:
https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.7.0-dev-00222/doc/README.ARC

Run OpenOCD:

    $ openocd -f /usr/local/share/openocd/scripts/target/snps_starter_kit_arc-em.cfg \
        -c init -c halt -c 'reset halt'

Compile and run:

    $ arc-elf32-gcc -mEM -g simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :3333
    (gdb) set remotetimeout 15
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) step
    (gdb) next
    (gdb) break exit
    (gdb) continue


### Debugging applications using Ashling Opella-XD debug probe

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building application" of our EM Starter Kit Wiki page:
> https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/EM-Starter-Kit
> For different hardware configurations other changes might be required.

> The Ashling Opella-XD debug probe and it's drivers are not part of the GNU
> tools distribution and should be obtained separately.

The Ashling Opella-XD drivers distribution contain gdbserver for GNU Tools. Start
it with following command:

    $ ./ash-arc-gdb-server --jtag-frequency 8mhz --device arc \
        --arc-reg-file <core.xml>

Where <core.xml> is a path to XML file describing AUX registers of target core.
The Ashling drivers distribution contain files for ARC 600 (arc600-core.xml)
and ARC 700 (arc700-core.xml). For EM an additional download is required.
Download arc-opella-em.xml from here:
https://gist.github.com/anthony-kolesov/7193146.

The Ashling gdbserver might emit error messages like "Error: Core is running".
Those messages are harmless and do not affect the debugging experience.

Then start GDB. *Before* connecting to an Opella-XD target it is essential to specify the architecture of the target. For EM type in GDB:

    (gdb) set arc opella-target arcem

(other possibilites are arc600 and arc700).

Then connect to the target as with the OpenOCD/Linux gdbserver. For example a full session with an Opella-XD controlling an ARC EM target could start as follows:

    $ arc-elf32-gcc -mEM -g simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) set arc opella-target arcem
    (gdb) set target remote :2331
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) break exit
    (gdb) continue

Available Opella targets are: *arc600*, *arc700* and *arcem*. The same target
is used for both EM4 and EM6, so registers that are not present en EM4 template
(for example IC_CTRL) still will be presented by GDB. Their values will be
shown as zeros and setting them will not affect core, nor will cause any error.


### Application running on Linux on ARC 700

Compile application:

    $ arc-linux-gcc -g -o hello_world hello_world.c

Copy it to the NFS share, or place it in RAMFS, or make it available to target
system in any way other way. Start gdbserver on target system:

    [ARCLinux] $ gdbserver :51000 hello_world

Start GDB on host:

    $ arc-linux-gdb --quiet hello_world
    (gdb) set sysroot <buildroot/output/target>
    (gdb) target remote 192.168.0.2:51000
    (gdb) break main
    (gdb) continue
    (gdb) continue
    (gdb) quit


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
[SolvNet](https://solvnet.synopsys.com). In other cases open an issue against
[toolchain](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain)
repository on GitHub.

