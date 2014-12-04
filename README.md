ARC GNU Tool Chain
==================

This is the main git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

The branch name corresponds to the development for the various ARC releases.
* `arc-releases` is the stable branch for the 4.8 tool chain release. Head of
  this branch is either a latest stable release or latest release candidate for
  the upcoming release.
* `arc-4.8-dev` is the development branch for the 4.8 tool chain release
* `arc-4.4-dev` is the development branch for the 4.4 tool chain release
* `arc-mainline-dev` is the mainline development branch

While the top of *development* branches should build and run reliably, there
is no guarantee of this. Users who encountered an error are welcomed to create
a new bug report at GitHub Issues for this `toolchain` project.

Within each branch there are points where the whole development has been put
through comprehensive release testing. These are marked using git *tags*, for
example `arc-2014.12` for tool chain released in December 2014.

These tagged stable releases have been through full release testing, and known
issues are documented in a Synopsys release notes.

The build script will check out the corresponding branches from the tool chain
component repositories.

Prerequisites
-------------

You will need a Linux like environment. Cygwin and MinGW environments under
Windows should work as well, but are not tested. If you want to build a tool
chain for Windows, then it is recommended to cross compile it using MinGW on
Linux. Refer to `windows-installer` directory for instructions.

You will need the standard GNU tool chain pre-requisites as documented in the
ARC GNU tool chain user guide or on the
[GCC website](http://gcc.gnu.org/install/prerequisites.html)

On Ubuntu 12.04/14.04 LTS you can install those with following command (as root):

    # apt-get install texinfo byacc flex libncurses5-dev zlib1g-dev \
    libexpat1-dev libx11-dev texlive build-essential

On Fedora 17 you can install those with following command (as root):

    # yum groupinstall "Development Tools"
    # yum install texinfo-tex byacc flex ncurses-devel zlib-devel expat-devel \
    libX11-devel

GCC depends on the GMP, MPFR and MPC packages, however there are problems with
availability of those packages on the RHEL/CentOS systems (packages has too old
versions or not available at all). To avoid this problem our build script will
download sources of those packages from the official web-sites. If you wish to
use versions installed on your host system instead, pass option
`--no-download-external` to the `build-all.sh` script, but usually this is not
required.


Getting sources
---------------

###  Using source tarball

If you use source tarball then it already contains all of the necessary sources
except for Linux which is a separate product. Linux sources are required only
for linux-uclibc tool chain, they are not required for bare metal elf32 tool
chain.  Latest stable release from https://kernel.org/ is recommended, only
versions >= 3.9 are supported. Untar linux tarball to the directory named
`linux` that is the sibling of this `toolchain` directory. For example:

    $ wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.15.3.tar.xz
    $ tar xaf linux-3.15.3.tar.xz --transform=s/linux-3.15.3/linux/

### Using Git repositories

You need to check out the repositories for each of the tool chain
components (its not all one big repository), including the linux repository
for building the tool chain. These should be peers of this `toolchain`
directory.

    $ mkdir arc_gnu
    $ cd arc_gnu
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

After you have just checked this `toolchain` repository out, then the following
commands will clone all the remaining components into the right place.

    $ cd toolchain
    $ ./arc-clone-all.sh [-f | --force] [-d | --dev]

Option --force or -f will replace any existing cloned version of the
components (use with care). Option --dev or -d will attempt to clone writable
clones using the SSH version of the remote URL, suitable for developers
contributing back to this repository.

Alternatively you can manually clone the remaining repositories using the
following:

    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git binutils
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    $ git clone --reference binutils \
      https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git gdb
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/linux.git

The binutils and gdb share the same repository, but must be in separate
directories, because they use separate branches. Option `--reference` passed
when cloning gdb repository will tell git to use share objects from binutils in
the gdb repository. This will greatly reduce amount of disk space consumed and
time to clone the repository.

Checkout `toolchain` repository to the desired branch, for example to get the
current development branch (not usually required since this is the default
branch):

    $ git checkout arc-4.8-dev

while to get latest release or release candidate:

    $ git checkout arc-releases

To get a specific release of GNU tool chain for example 2014.12:

    $ git checkout arc-2014.12


Building the tool chain
-----------------------

The script `build-all.sh` will build and install both _arc*-elf32-_ and
_arc*-snps-linux-uclibc-_ tool chains. The comments at the head of this script
explain how it works and the parameters to use. It uses script
`symlink-all.sh` to build a unified source directory.

The script `arc-versions.sh` specifies the branches to use in each component
git repository. It should be edited to change the default branches if
required.

Having built a unified source directory and checked out the correct branches,
`build-all.sh` in turn uses `build-elf32.sh` and `build-uclibc.sh`. These
build respectively the _arc*-elf32_ and _arc*-snps-linux-uclibc_ tool chains. Details
of the operation are provided as comments in each script file. Both these
scripts use a common initialization script, `arc-init.sh`.

The most important options if `build-all.sh` are:

 * `--install-dir <dir>` - define where tool chain will be installed. Once
   installed tool chain cannot be moved to another location, however it can be
   moved to another system and used from the same location.
 * `--no-elf32` and `--no-uclibc` - choose type of tool chain to build. By
   default both are built. Specify `--no-uclibc` if you intend to work
   exclusively with bare metal applications, specify `--no-elf32` of you intend
   to work exclusively with Linux applications. Linux kernel is built with
   uClibc tool chain.
 * `--no-multilib` - do not build multilib standard libraries. Use it when you
   are going to work with bare metal applications for a particular core. This
   option does not affect uClibc tool chain.
 * `--cpu <cpu>` - configure GNU tool chain to use specific core as a default
   choice (default core is a core for which GCC will compile for, when `-mcpu=`
   option is not passed). Default is arc700 for both bare metal and Linux
   tool chains. Combined with `--no-multilib` you can build GNU tool chain that
   support only one specific core you need. Valid values include `arc600`,
   `arc700`, `arcem` and `archs`, however `arc600` and `arcem` are valid for
   bare metal tool chain only.

Please consult head of the `./build-all.sh` file to get a full list of
supported options and their detailed descriptions.

### Build options examples

Build default tool chain, bare metal tool chain will support all ARC cores,
while Linux tool chain will support ARC 700:

    $ ./build-all.sh --install-dir $INSTALL_ROOT

Build tool chain for ARC 700 Linux development:

    $ ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT

Build tool chain for ARC HS Linux development:

    $ ./build-all.sh --no-elf32 --cpu archs --install-dir $INSTALL_ROOT

Build bare metal tool chain for EM cores (for example for EM Starter Kit):

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --cpu arcem --no-multilib


Usage examples
--------------

In all those examples it is expected that you have added tool chain to the PATH:

    $ export PATH=$INSTALL_ROOT/bin:$PATH


### ARC 700 application running on CGEN simulator

Build application:

    $ arc-elf32-gcc hello_world.c -marc700

Run it on CGEN-based simulator:

    $ arc-elf32-run a.out
    hello world

Or debug it in the GDB using simulator (GDB output omitted):

    $ arc-elf32-gdb --quiet a.out
    (gdb) target sim
    (gdb) load
    (gdb) start
    (gdb) l
    (gdb) continue
    hello world
    (gdb) q

Note that CGEN supports only ARC 600 and ARC 700.


### ARC EM application using nSIM simulator

Before starting `nsimdrv` you need to update properties file for nSIM, in
$NSIM_HOME/systemc/configs find a file for your core and add to it:

    nsim_emt=1

This will enable input-output operations. Read nSIM User Guide to learn about
other nSIM properties. Then start `nsimdrv` (ARC EM is used as an example):

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000
      -propsfile $NSIM_HOME/systemc/configs/nsim_av2em11.props

Alternatively you can use TCF files:

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000 \
      -tcf $NSIM_HOME/etc/tcf/templates/em6_gp.tcf -on nsim_emt

And in another console (GDB output is omitted):

    $ arc-elf32-gcc -marcem -g hello_world.c
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
https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.9-dev-2014.12/doc/README.ARC

Run OpenOCD:

    $ openocd -f /usr/local/share/openocd/scripts/board/snps_em_sk.cfg

Compile test application and run:

    $ arc-elf32-gcc -marcem -g simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :3333
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

> The Ashling Opella-XD debug probe and its drivers are not part of the GNU
> tools distribution and should be obtained separately.

The Ashling Opella-XD drivers distribution contains gdbserver for GNU tool chain. Start
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

Copy it to the NFS share, or place it in rootfs, or make it available to target
system in any way other way. Start gdbserver on target system:

    [ARCLinux] $ gdbserver :51000 hello_world

Start GDB on host:

    $ arc-linux-gdb --quiet hello_world
    (gdb) set sysroot <buildroot/output/target>
    (gdb) target remote 192.168.218.2:51000
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

