ARC GNU Tool Chain
==================

This is the main Git repository for the ARC GNU tool chain. It contains just
the scripts required to build the entire tool chain.

Branches in this repository are:
* `arc-releases` is the stable branch for the tool chain release. Head of
  this branch is a latest stable release. It is a branch recommended for most
  users
* `arc-staging` is the semi-stable branch for the tool chain release
  candidates. Head of this branch is either a latest stable release or latest
  release candidate for the upcoming release
* `arc-dev` is the development branch for the current tool chain release
* `arc-4.8-dev` is the development branch for the 4.8 tool chain release
* `arc-4.4-dev` is the development branch for the 4.4 tool chain release
* `arc-mainline-dev` is the mainline development branch (deprecated).

While the top of *development* branches should build and run reliably, there
is no guarantee of this. Users who encountered an error are welcomed to create
a new bug report at GitHub Issues for this `toolchain` project.

The build script in this repository can be used for different versions of
toolchain components, however such cross-version compatibility is not
guaranteed.

The build script from this repository by default will automatically check out
components to versions corresponding to the toolchain branch. Build script from
development branch of toolchain repository will by default check out latest
development branches of components. Build script from release and staging
branches will check out components to the corresponding git tag. For example
build script for 2015.06 release will checkout out components to arc-2015.06
tag.


Prerequisites
-------------

Linux-like environment is required to build GNU tool chain for ARC. To build a
tool chain for Windows, it is recommended to cross-compile it using MinGW on
Linux. Refer to "Building tool chain on Windows" section of this document.

GNU tool chain for ARC has same standard prerequisites as an upstream GNU tool
chain as documented in the GNU tool chain user guide or on the [GCC
website](http://gcc.gnu.org/install/prerequisites.html)

On Ubuntu 12.04/14.04 LTS those can be installed with following command (as root):

    # apt-get install texinfo byacc flex libncurses5-dev zlib1g-dev \
      libexpat1-dev libx11-dev texlive build-essential git

On RHEL 6/7 those can be installed with following command (as root):

    # yum groupinstall "Development Tools"
    # yum install texinfo-tex byacc flex ncurses-devel zlib-devel expat-devel \
      libX11-devel git texlive-\*

It's necessary to install a full `texlive` set in RHEL 6/7 (`texlive-*`) to
prevent errors due to missing TeX fonts while building a documentation. Since
`texlive-*` installs a big set of large packets (hundreds of megabytes) it's
possible to omit `texlive-*` in `yum install` and instead pass `--no-pdf`
option to the `build-all.sh` script if the documentation is not required.

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

    $ wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.18.24.tar.xz
    $ tar xaf linux-3.18.24.tar.xz --transform=s/linux-3.18.24/linux/

### Using Git repositories

Repositories for each of the tool chain components (its not all one big
repository), including the linux repository, should be cloned before building
the tool chain. These should be peers of this `toolchain` directory.

    $ mkdir arc_gnu
    $ cd arc_gnu
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/cgen.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git \
        binutils
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    $ git clone --reference binutils \
        https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git gdb
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/linux.git

The binutils and gdb share the same repository, but must be in separate
directories, because they use different branches. Option `--reference` passed
when cloning gdb repository will tell Git to share internal Git files between
binutils and gdb repository. This will greatly reduce amount of disk space
consumed and time to clone the repository.

By default `toolchain` repository will be checked out to the current
release branch `arc-release`.

If current working directory is not a "toolchain" directory, then change to it:

    $ cd toolchain

Following command will check out repository to the latest release:

    $ git checkout arc-releases

This repository can be checked out to a specific GNU Tool chain for ARC release
by specifying a particular release tag, for example for 2015.12 release that
would be:

    $ git checkout arc-2015.12


Building the Tool chain
-----------------------

The script `build-all.sh` will build and install both _arc*-elf32-_ and
_arc*-snps-linux-uclibc-_ tool chains. The comments at the head of this script
explain how it works and the parameters to use.

The script `arc-versions.sh` checks out each component Git repository to a
specified branch. Branches to checkout are specified in files in `config`
directory. Which file is default depends on current `toolchain` branch:
`arc-dev` branch default to `config/arc-dev.sh` file, while `arc-releases` and
`arc-staging` will default to a file corresponding to a particular release or
release candidate. Default choice of `config` file can be overridden with
`--checkout-config` option of `build-all.sh` script.

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
   choice (default core is a core for which GCC will compile for when `-mcpu=`
   option is not passed). Default is arc700 for both bare metal and Linux tool
   chains. Combined with `--no-multilib` this options allows to build GNU tool
   chain that supports only one specific core. Valid values include `arc600`,
   `arc700`, `arcem` and `archs`, however `arc600` and `arcem` are valid for
   bare metal tool chain only.
 * `--host <triplet>` - option to set host triplet of tool chain. That allows to
   do Canadian cross-compilation, where tool chain for ARC processors
   (`--target`) will run on Windows hosts (`--host`) but will be built on Linux
   host (`--build`).

Please consult head of the `./build-all.sh` file to get a full list of
supported options and their detailed descriptions.

Note about `--cpu` and `--target-cflags` options. They allow to build toolchain
tailored for a particular core. Option `--cpu` will change default CPU of GCC.
Option `--target-cflags` on the other hand will change only CFLAGS used to
compile toolchain standard library, but will not affect default compiler
options. Consequently, when using a toolchain configured this way it still will
be required to provide corresponding compiler options except for the `-mcpu`.
Option `--target-cflags` sets C[XX]FLAGS_FOR_TARGET. Those two variables
override default C[XX]FLAGS of standard libraries which are "-O2 -g". Hence to
specify custom architecture flags, but preserve optimizations it is required to
pass optimization flags to --target-cflags as well. Libraries optimized for
size will override any -Ox flag passed via --target-cflags, while other flags
will not be overridden.


### Build options examples

Build default tool chain, bare metal tool chain will support all ARC cores,
while Linux tool chain will support ARC 700:

    $ ./build-all.sh --install-dir $INSTALL_ROOT

Build tool chain for ARC 700 Linux development:

    $ ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT

Build tool chain for ARC HS Linux development:

    $ ./build-all.sh --no-elf32 --cpu archs --install-dir $INSTALL_ROOT

Build bare metal tool chain for ARC EM cores:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --cpu arcem --no-multilib

Build bare metal tool chain for ARC EM5D in the ARC EM Starter Kit 2.0:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu arcem --target-cflags "-O2 -g -mcode-density -mno-div-rem -mswap -mnorm \
      -mmpy-option=6 -mbarrel-shifter"

Build bare metal tool chain for ARC EM7D in the ARC EM Starter Kit 2.0
(EM7D_FPU is similiar, but with -mfpu=fpuda):

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu arcem --target-cflags "-O2 -g -mcode-density -mno-div-rem -mswap \
      -mnorm -mmpy-option=6 -mbarrel-shifter \
      --param l1-cache-size=16384 --param l1-cache-line-size=32"

Build bare metal tool chain for ARC EM4 in the ARC EM Starter Kit 1.1:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu arcem --target-cflags "-O2 -g -mcode-density -mdiv-rem -mswap \
      -mnorm -mmpy-option=6 -mbarrel-shifter"

Build bare metal tool chain for ARC EM6 in the ARC EM Starter Kit 1.1:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu arcem --target-cflags "-O2 -g -mcode-density -mdiv-rem -mswap \
      -mnorm -mmpy-option=6 -mbarrel-shifter \
      --param l1-cache-size=32768 --param l1-cache-line-size=128"

### Building tool chain on Windows

To build tool chain for Windows hosts it is recommended to do a "Canadian
cross-compilation" on Linux, that is tool chain for ARC targets that runs on
Windows hosts is built on Linux host. Build scripts expect to be run in
Unix-like environment, so it is often faster and easier to build tool chain on
Linux, than do this on Windows using environments like Cygwin and MSYS. While
those allow tool chain to be built on Windows natively this way is not
officially supported and not recommended by Synopsys, due to severe performance
penalty of those environments on build time and possible compatibility issue.

Some limitation apply:
- CGEN simulator is not supported on Windows hosts, thus should be disabled
  with `--no-sim` option.
- Only bare metal (elf32) tool chain can be built this way.
- It is required to have tool chain for Linux hosts in the `PATH` for Canadian
  cross-build to succeed - it will be used to compile standard library of tool
  chain.
- Expat library is required for GDB to parse XML target description files. This
  library might be not available in some Mingw setup. Easiest solution is to
  let `build-all.sh` script to build Expat by passing option
  `--no-system-expat`.

To cross-compile tool chain on Linux, Mingw tool chain should be installed. On
Ubuntu that can be done with `mingw-w64` package:

    # apt-get install mingw-w64

RHEL 6 has a very antique Mingw (4.4-something), so it is recommended to first
add EPEL repository, then install Mingw from it. In CentOS:

    # yum install epel-release
    # yum install mingw-binutils-generic mingw-filesystem-base \
      mingw32-binutils mingw32-cpp mingw32-crt mingw32-filesystem mingw32-gcc \
      mingw32-gcc-c++ mingw32-headers mingw32-winpthreads \
      mingw32-winpthreads-static

For instruction how to install EPEL on RHEL, see
<https://fedoraproject.org/wiki/EPEL/FAQ>.

After prerequisites are installed and Linux tools are in the `PATH`, do:

    $ ./build-all.sh --no-uclibc --no-sim --host i686-w64-mingw32 \
      --no-system-expat

Note that value of host triplet depends on what mingw tool chain is being used.
Triplet `i686-w64-mingw32` is valid for mingw tool chain currently used in
Ubuntu and EPEL, but, for example, mingw tool chain in standard RHEL 6 has
triplet `i686-pc-mingw32`.


Usage examples
--------------

In all of the following examples it is expected that GNU tool chain for ARC has
been added to the PATH:

    $ export PATH=$INSTALL_ROOT/bin:$PATH


### Using nSIM simulator to run bare metal ARC applications

nSIM simulator supports GNU IO hostlink used by the libc library of bare metal
GNU tool chain for ARC. nSIM option `nsim_emt=1` enables GNU IO hostlink.

To start nSIM in gdbserver mode for ARC EM6:

    $ $NSIM_HOME/bin/nsimdrv -gdb -port 51000 \
      -tcf $NSIM_HOME/etc/tcf/templates/em6_gp.tcf -on nsim_emt

And in second console (GDB output is omitted):

    $ arc-elf32-gcc -mcpu=arcem -g --specs=nsim.specs hello_world.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :51000
    (gdb) load
    (gdb) break main
    (gdb) break exit
    (gdb) continue
    (gdb) continue
    (gdb) quit

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

Note the usage of `nsim.specs` specification file. This file specifies that
applications should be linked with nSIM IO hostlink library libnsim.a, which is
implemented in libgloss - part of newlib project. libnsim provides several
functions that are required to link C applications - those functions a
considered board/OS specific, hence are not part of the normal libc.a. To link
application without nSIM IO hostlink support use `nosys.specs` file - note that
in this case system calls are either not available or have stub
implementations. One reason to prefer `nsim.specs` over `nosys.specs` even when
developing for hardware platform which doesn't have hostlink support is that
`nsim` will halt target core on call to function "exit" and on many errors,
while `exit` functions `nosys.specs` is an infinite loop.


### Using CGEN simulator to run bare metal ARCompact applications

Build application:

    $ arc-elf32-gcc -marc700 -g --specs=nsim.specs hello_world.c

To run it on CGEN-based simulator without debugger:

    $ arc-elf32-run a.out
    hello world

To debug it in the GDB using simulator (GDB output omitted):

    $ arc-elf32-gdb --quiet a.out
    (gdb) target sim
    (gdb) load
    (gdb) start
    (gdb) list
    (gdb) continue
    hello world
    (gdb) quit

CGEN simulator supports only ARC 600 and ARC 700. CGEN hostlink is mostly
compatible with nSIM hostlink - basic functions, like console IO are
implemented in  the same manner, but some other system calls like, `times` are
not available in CGEN.


### Using EM Starter Kit to run bare metal ARC EM application

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building application" of our EM Starter Kit Wiki page:
> https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/EM-Starter-Kit

Build instructions for OpenOCD are available at its page:
https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.9-dev-2014.12/doc/README.ARC

To run OpenOCD:

    $ openocd -f /usr/local/share/openocd/scripts/board/snps_em_sk.cfg

Compile test application and run:

    $ arc-elf32-gcc -mcpu=arcem -g --specs=nsim.specs simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) target remote :3333
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) step
    (gdb) next
    (gdb) break exit
    (gdb) continue
    (gdb) quit

Note that since there is no hostlink support in OpenOCD applications, so IO
functions will not work properly.


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

    $ arc-elf32-gcc -mcpu=arcem -g --specs=nsim.specs simple.c
    $ arc-elf32-gdb --quiet a.out
    (gdb) set tdesc filename toolchain/extras/opella-xd/opella-arcem-tdesc.xml
    (gdb) set target remote :2331
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) break exit
    (gdb) continue
    (gdb) quit

Similar to OpenOCD hostlink is not available in GDB with Ashling Opella-XD.


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

