ARC GNU Tool Chain
==================

This is the main Git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

The branch name corresponds to the development for the various ARC releases.
* `arc-releases` is the stable branch for the tool chain release. Head of
  this branch is either a latest stable release or latest release candidate for
  the upcoming release.
* `arc-dev` is the development branch for the current tool chain release
* `arc-4.8-dev` is the development branch for the 4.8 tool chain release
* `arc-4.4-dev` is the development branch for the 4.4 tool chain release
* `arc-mainline-dev` is the mainline development branch

While the top of *development* branches should build and run reliably, there
is no guarantee of this. Users who encountered an error are welcomed to create
a new bug report at GitHub Issues for this `toolchain` project.

Within each branch there are points where the whole development has been put
through comprehensive release testing. These are marked using Git *tags*, for
example `arc-2014.12` for tool chain released in December 2014.

These tagged stable releases have been through full release testing, and known
issues are documented in a Synopsys release notes.

The build script will check out the corresponding branches from the tool chain
component repositories.

Prerequisites
-------------

Linux like environment is required to build GNU tool chain for ARC. To build a
tool chain for Windows, it is recommended to cross compile it using MinGW on
Linux. Refer to `windows-installer` directory for instructions.

GNU tool chain for ARC has same standard prerequisites as an upstream GNU tool
chain as documented in the GNU tool chain user guide or on the [GCC
website](http://gcc.gnu.org/install/prerequisites.html)

On Ubuntu 12.04/14.04 LTS those can be installed with following command (as root):

    # apt-get install texinfo byacc flex libncurses5-dev zlib1g-dev \
      libexpat1-dev libx11-dev texlive build-essential git

On CentOS 6/7 those can be installed those with following command (as root):

    # yum groupinstall "Development Tools"
    # yum install texinfo-tex byacc flex ncurses-devel zlib-devel expat-devel \
      libX11-devel git texlive-*

It's necessary to install a full `texlive` set in CentOS 6/7 (`texlive-*`) to
prevent TeX blaming about missing fonts while building a documentation.
Since `texlive-*` installs a huge bunch of packets (hundreds of megabytes)
it's possible to omit `texlive-*` in `yum install` and pass `--no-pdf` option
to the `build-all.sh` script if the documentation is not necessary.

GCC depends on the GMP, MPFR and MPC packages, however there are problems with
availability of those packages on the RHEL/CentOS 6 systems (packages has too
old versions or not available at all). To avoid this problem our build script
will download sources of those packages from the official web-sites.  If option
`--no-download-external` is passed to the `build-all.sh` script, when building
tool chain, then those dependencies will not be downloaded automatically,
instead versions of those libraries installed on the build host will be used.
In most cases this is not required.


Getting sources
---------------

###  Using source tarball

GNU tool chain source tarball already contains all of the necessary sources
except for Linux which is a separate product. Linux sources are required only
for Linux tool chain, they are not required for bare metal elf32 tool chain.
Latest stable release from https://kernel.org/ is recommended, only versions >=
3.9 are supported. Linux sources should be located in the directory named
`linux` that is the sibling of this `toolchain` directory. For example:

    $ wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.11.tar.xz
    $ tar xaf linux-3.13.11.tar.xz --transform=s/linux-3.13.11/linux/

### Using Git repositories

Repositories for each of the tool chain components (its not all one big
repository), including the linux repository, should be cloned before building
the tool chain. These should be peers of this `toolchain` directory.

    $ mkdir arc_gnu
    $ cd arc_gnu
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

After this `toolchain` repository has been checked out, then the following
commands will clone all the remaining components into the right place.

    $ cd toolchain
    $ ./arc-clone-all.sh [-f | --force] [-d | --dev]

Option --force or -f will replace any existing cloned version of the
components (use with care). Option --dev or -d will attempt to clone writable
clones using the SSH version of the remote URL, suitable for developers
contributing back to this repository.

Alternatively remaining repositories can be cloned manually using following
commands:

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
when cloning gdb repository will tell Git to share internal Git files between
binutils and gdb repository. This will greatly reduce amount of disk space
consumed and time to clone the repository.

By default `toolchain` repository will be checked out to the current
development branch `arc-dev`.

Following command will check out repository to the latest release or release
candidate:

    $ git checkout arc-releases

This repository can be checked out to a specific GNU tool chain for ARC release
by specifying a particular release tag, for example for 2014.12 release that
would be:

    $ git checkout arc-2014.12


Building the tool chain
-----------------------

The script `build-all.sh` will build and install both _arc*-elf32-_ and
_arc*-snps-linux-uclibc-_ tool chains. The comments at the head of this script
explain how it works and the parameters to use.

The script `arc-versions.sh` specifies the branches to use in each component
Git repository. It can be edited to change the default branches if required.

After checking out correct branches  `build-all.sh` in turn uses
`build-elf32.sh` and `build-uclibc.sh`. These build respectively the
_arc*-elf32_ and _arc*-snps-linux-uclibc_ tool chains. Details of the operation
are provided as comments in each script file. Both these scripts use a common
initialization script, `arc-init.sh`.

The most important options of `build-all.sh` are:

 * `--install-dir <dir>` - define where tool chain will be installed. Unless
   option `--rel-rpaths` is specified to the `build-all.sh` then once tool
   chain is installed, it cannot be moved to another location, however it can
   be moved to another system and used from the same location (this is a
   limitation of upstream tool chain implementation and is not specific to
   ARC).
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
   option is not passed). Default is arc700 for both bare metal and Linux tool
   chains. Combined with `--no-multilib` this options allows to build GNU tool
   chain that supports only one specific core. Valid values include `arc600`,
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

In all of those examples it is expected that GNU tool chain for ARC has been
added to the PATH:

    $ export PATH=$INSTALL_ROOT/bin:$PATH


### Using CGEN simulator to run bare metal ARCompact applications

Build application:

    $ arc-elf32-gcc hello_world.c -marc700

To run it on CGEN-based simulator without debugger:

    $ arc-elf32-run a.out
    hello world

To debug it in the GDB using simulator (GDB output omitted):

    $ arc-elf32-gdb --quiet a.out
    (gdb) target sim
    (gdb) load
    (gdb) start
    (gdb) l
    (gdb) continue
    hello world
    (gdb) q

CGEN simulator supports only ARC 600 and ARC 700.


### Using nSIM simulator to run bare metal ARC applications

nSIM simulator supports GNU IO hostlink used by the libc library of bare metal
GNU tool chain for ARC. nSIM option `nsim_emt=1` enables GNU IO hostlink.

To start nSIM in gdbserver mode for ARC EM6:

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000 \
      -tcf $NSIM_HOME/etc/tcf/templates/em6_gp.tcf -on nsim_emt

And in second console (GDB output is omitted):

    $ arc-elf32-gcc -marcem -g hello_world.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :51000
    (gdb) load
    (gdb) break main
    (gdb) break exit
    (gdb) continue
    (gdb) continue
    (gdb) q

If one of the HS TCFs is used, then it is required to add `-on
nsim_isa_ll64_option` to nSIM options, because GCC for ARC automatically
generates double-world memory operations, which are not enabled in TCFs
supplied with nSIM:

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000 \
      -tcf $NSIM_HOME/etc/tcf/templates/hs36.tcf -on nsim_emt \
      -on nsim_isa_ll64_option

nSIM distribution doesn't contain big-endian TCFs, so `-on
nsim_isa_big_endian` should be added to nSIM options to simulate big-endian
cores:

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000 \
      -tcf $NSIM_HOME/etc/tcf/templates/em6_gp.tcf -on nsim_emt \
      -on nsim_isa_big_endian

Default linker script of GNU Tool chain for ARC is not compatible with memory
maps of cores that only has CCM memory (EM4, EM5D, HS34), thus to run
application on nSIM with those TCFs it is required to link application with
linker script appropriate for selected core.

When application is simulated on nSIM gdbserver all input and output happens on
the side of host that runs gdbserver, so in "hello world" example string will
be printed in the console that runs nSIM gdbserver.


### Using EM Starter Kit to run bare metal ARC EM application

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building application" of our EM Starter Kit Wiki page:
> https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/EM-Starter-Kit

Build instructions for OpenOCD are available at its page:
https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.9-dev-2014.12/doc/README.ARC

To run OpenOCD:

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


### Using Ashling Opella-XD debug probe to debug bare metal applications

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building application" of our EM Starter Kit Wiki page:
> https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/EM-Starter-Kit
> For different hardware configurations other changes might be required.

> The Ashling Opella-XD debug probe and its drivers are not part of the GNU
> tools distribution and should be obtained separately.

The Ashling Opella-XD drivers distribution contains gdbserver for GNU tool
chain.  Command to start it:

    $ ./ash-arc-gdb-server --jtag-frequency 8mhz --device arc \
        --arc-reg-file <core.xml>

Where <core.xml> is a path to XML file describing AUX registers of target core.
The Ashling drivers distribution contain files for ARC 600 (arc600-core.xml)
and ARC 700 (arc700-core.xml). However due to recent changes in GDB with
regards of support of XML target descriptions those files will not work out of
the box, as order of some registers changed. To use Ashling GDB server with GDB
starting from 2015.06 release it is required to use modified files that can be
found in this `toolchain` repository in `extras/opella-xd` directory.

The Ashling gdbserver might emit error messages like "Error: Core is running".
Those messages are harmless and do not affect the debugging experience.

*Before* connecting GDB to an Opella-XD gdbserver it is essential to specify
path to XML target description file that is aligned to `<core.xml>` file passed
to GDB server. All registers described in `<core.xml>` also must be described
in XML target description file in the same order. Otherwise GDB will not
function properly.

    (gdb) set tdesc filename <path/to/opella-CPU-tdesc.xml>

XML target description files are provided in the same `extras/opella-xd`
directory as Ashling GDB server core files.

Then connect to the target as with the OpenOCD/Linux gdbserver. For example a
full session with an Opella-XD controlling an ARC EM target could start as
follows:

    $ arc-elf32-gcc -mEM -g simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) set tdesc filename toolchain/extras/opella-xd/opella-arcem-tdesc.xml
    (gdb) set target remote :2331
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) break exit
    (gdb) continue


### Debugging applications on Linux for ARC

Compile application:

    $ arc-linux-gcc -g -o hello_world hello_world.c

Copy it to the NFS share, or place it in rootfs, or make it available to target
system in any way other way. Start gdbserver on target system:

    [ARCLinux] # gdbserver :51000 hello_world

Start GDB on the host:

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

For all inquiries Synopsys customers are advised to use
[SolvNet](https://solvnet.synopsys.com). Everyone else is welcomed to open an
issue against
[toolchain](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain)
repository on GitHub.

