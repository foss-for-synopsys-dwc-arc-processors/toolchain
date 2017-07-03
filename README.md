ARC GNU Tool Chain
==================

This is the main Git repository for the ARC GNU toolchain. It contains just
the scripts required to build the entire toolchain.

Branches in this repository are:
* `arc-releases` is the stable branch for the toolchain release. Head of
  this branch is a latest stable release. It is a branch recommended for most
  users
* `arc-staging` is the semi-stable branch for the toolchain release
  candidates. Head of this branch is either a latest stable release or latest
  release candidate for the upcoming release
* `arc-dev` is the development branch for the current toolchain release
* `arc-4.8-dev` is the development branch for the 4.8 toolchain release
* `arc-4.4-dev` is the development branch for the 4.4 toolchain release

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

Linux-like environment is required to build GNU toolchain for ARC. To build a
toolchain for Windows, it is recommended to cross-compile it using MinGW on
Linux. Refer to "Building toolchain on Windows" section of this document.

GNU toolchain for ARC has same standard prerequisites as an upstream GNU tool
chain as documented in the GNU toolchain user guide or on the [GCC
website](http://gcc.gnu.org/install/prerequisites.html)

On Ubuntu 12.04/14.04 LTS those can be installed with following command (as root):

    # apt-get install texinfo byacc flex libncurses5-dev zlib1g-dev \
      libexpat1-dev texlive build-essential git wget

On RHEL 6/7 those can be installed with following command (as root):

    # yum groupinstall "Development Tools"
    # yum install texinfo-tex byacc flex ncurses-devel zlib-devel expat-devel \
      git texlive-\* wget

It's necessary to install a full `texlive` set in RHEL 6/7 (`texlive-*`) to
prevent errors due to missing TeX fonts while building a documentation. Since
`texlive-*` installs a big set of large packets (hundreds of megabytes) it's
possible to omit `texlive-*` in `yum install` and instead pass `--no-pdf`
option to the `build-all.sh` script if the documentation is not required.

`git` package is required only if toolchain is being built from git
repositories. If it is built from the source tarball, then `git` is not
required.

GCC depends on the GMP, MPFR and MPC packages, however there are problems with
availability of those packages on the RHEL/CentOS 6 systems (packages has too
old versions or not available at all). To avoid this problem our build script
will download sources of those packages from the official web-sites.  If option
`--no-download-external` is passed to the `build-all.sh` script, when building
toolchain, then those dependencies will not be downloaded automatically,
instead versions of those libraries installed on the build host will be used.
In most cases this is not required.


### macOS Prerequisites

By default HFS on macOS is configured to be case-insensitive, which is known to
cause issues with Linux sources (there are files which differ only in character
case). As a result to build uClibc toolchain for ARC it is required to use
partition that is configured to be case sensitive (use Disk Utility to create a
new partition, at least 16 GiB are needed to build uClibc toolchain, 32 GiB are
needed to build a complete baremetal toolchain. With baremetal (elf) toolchain
there are no such problems.

To build toolchain on macOS it is required to install several prerequisites
which are either not installed by default or non-GNU-compatible versions are
installed by default. This easily can be done with Homebrew:

	# Install homebrew itself (https://brew.sh/)
	$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	# Install wget
	$ brew install wget

	# Install GNU sed
	$ brew install gnu-sed

To build PDF documentation for toolchain TeX must be installed:

	$ brew cask install mactex

If PDF documentation is not needed, pass option `--no-pdf` to build-all.sh to
disable its build, then mactex is not required.

> NB! Linux/uClibc toolchain built on macOS has different uClibc configuration
> then the one built on Linux hosts - **local support is disabled**. The reason
> is that when locale support is enabled, uClibc makefiles will build an
> application called `genlocale` that will run on host system, but on macOS
> this application fails to build, therefore support for locales is disabled
> when Linux/uClibc toolchain is built on macOS.


Getting sources
---------------

GNU toolchain build process doesn't support source directories that contain
whitespaces in it. Please make sure that ARC GNU source directory path doesn't
contain any whitespaces.

###  Using source tarball

GNU Toolchain for ARC source tarball can be downloaded from project GitHub
page https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases.

GNU toolchain source tarball already contains all of the necessary sources
except for Linux which is a separate product. Linux sources are required only
for Linux toolchain, they are not required for bare-metal elf32 toolchain.
Latest stable release from https://kernel.org/ is recommended, and only
versions >= 3.9 are supported. Linux sources should be located in the directory
named `linux` that is the sibling of this `toolchain` directory. For example:

    $ wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.9.13.tar.xz
    $ tar xf linux-4.9.13.tar.xz --transform=s/linux-4.9.13/linux/

### Using Git repositories

Source tarballs are available only for releases of GNU Toolchain. To build
toolchain from different components versions (for example from current trunk)
it is recommended to use Git.
Repositories for each of the toolchain components (its not all one big
repository), including the Linux repository, should be cloned before building
the toolchain. These should be peers of this `toolchain` directory.

    $ mkdir arc_gnu
    $ cd arc_gnu
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git \
        binutils
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/gcc.git
    $ git clone --reference binutils \
        https://github.com/foss-for-synopsys-dwc-arc-processors/binutils-gdb.git gdb
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/newlib.git
    $ # For Linux uClibc toolchain:
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/uClibc.git
    $ # or for Linux glibc toolchain:
    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/glibc.git
    $ git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git \
		linux

The binutils and gdb share the same repository, but must be in separate
directories, because they use different branches. Option `--reference` passed
when cloning gdb repository will tell Git to share internal Git files between
binutils and gdb repository. This will greatly reduce amount of disk space
consumed and time to clone the repository.

Note that it is possible to save disk space and time to fetch sources by using
Git option `--depth=1` - Git will not fetch the whole history of repository and
will instead only fetch the current state. This option should be accompanied by
the valid `-b <branch>` option so that Git will fetch a state of required
branch or a tag. If branch is used, then current branches can be found in the
config/arc-dev.sh file, which at the moment of this writing are:

* binutils - arc-2017.03
* gcc - arc-2017.03
* gdb - arc-2016.09-gdb
* newlib - arc-2017.03
* uClibc - arc-2017.03
* Linux - linux-4.9.y
* glibc - vineet-glibc-master

Note, however that if `build-all.sh` will try to checkout repositories to their
latest state, which is a default behaviour, then it will anyway fetch
additional branches and tags, due to usage of `git fetch --all --tags`. To
avoid this problem, pass `--no-auto-pull --no-auto-checkout` to `build-all.sh`
- in this case it will leave Git repositories alone, leaving control in the
hands of the user.

By default `toolchain` repository will be checked out to the current
release branch `arc-releases`.

If current working directory is not a "toolchain" directory, then change to it:

    $ cd toolchain

This repository can be checked out to a specific GNU Toolchain for ARC release
by specifying a particular release tag, for example for 2016.03 release that
would be:

    $ git checkout arc-2016.03


Building the Toolchain
-----------------------

The script `build-all.sh` will build and install both _arc*-elf32-_ and
_arc*-snps-linux-uclibc-_ toolchains. The comments at the head of this script
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
_arc*-elf32_ and _arc*-snps-linux-uclibc_ toolchains. Details of the operation
are provided as comments in each script file. Both these scripts use a common
initialization script, `arc-init.sh`.

The most important options of `build-all.sh` are:

 * `--install-dir <dir>` - define where toolchain will be installed. Unless
   option `--rel-rpaths` is specified to the `build-all.sh` then once tool
   chain is installed, it cannot be moved to another location, however it can
   be moved to another system and used from the same location (this is a
   limitation of upstream toolchain implementation and is not specific to
   ARC).
 * `--no-elf32`, `--no-uclibc`, `--glibc` - choose type of toolchain to build. By
   default elf32 and uclibc are built. Specify `--no-uclibc` if you intend to work
   exclusively with bare metal applications, specify `--no-elf32` of you intend
   to work exclusively with Linux applications. Specify `--glibc` if you want to
   build glibc toolchain instead of uClibc. Linux kernel is built with uClibc or
   glibc toolchain.
 * `--no-multilib` - do not build multilib standard libraries. Use it when you
   are going to work with bare metal applications for a particular core. This
   option does not affect uClibc toolchain.
 * `--cpu <cpu>` - configure GNU toolchain to use specific core as a default
   choice (default core is a core for which GCC will compile for when `-mcpu=`
   option is not passed). Default is arc700 for both bare metal and Linux tool
   chains. Combined with `--no-multilib` this option allows to build GNU
   toolhain that supports only one specific core. Valid values depend on what
   is available in GCC As of version 2016.03 values available in ARC GCC are:
   em, arcem, em4, em4_dmips, em4_fpus, em4_fpuda, quarkse, hs, archs, hs34,
   hs38, hs38_linux, arc600, arc600_norm, arc600_mul64, arc600_mul32x16,
   arc601, arc601_norm, arc601_mul64, arc601_mul32x16, arc700. Note that only
   ARC 700 and ARC HS can be selected as a default core for Linux toolchain.
 * `--host <triplet>` - option to set host triplet of toolchain. That allows to
   do Canadian cross-compilation, where toolchain for ARC processors
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

This command will build default toolchain - bare metal toolchain will support
all ARC cores, while Linux toolchain will support ARC 700:

    $ ./build-all.sh --install-dir $INSTALL_ROOT

This command will build toolchain for ARC 700 Linux development:

    $ ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT

This command will build toolchain for ARC HS Linux development:

    $ ./build-all.sh --no-elf32 --cpu hs38 --install-dir $INSTALL_ROOT

This command will build toolchain for ARC HS Linux development with glibc:

    $ ./build-all.sh --no-elf32 --glibc --cpu hs38 --install-dir $INSTALL_ROOT

This command will build bare metal toolchain for ARC EM7D in the ARC EM Starter
Kit 2.2:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu em4_dmips

This command will build bare metal toolchain for ARC EM9D in the ARC EM Starter
Kit 2.2:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu em4_fpus --target-cflags "-O2 -g -mfpu=fpus_all"

This command will build bare metal toolchain for ARC EM11D in the ARC EM Starter
Kit 2.2:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu em4_fpuda --target-cflags "-O2 -g -mfpu=fpuda_all"

Build bare metal toolchain for ARC EM4 and EM6 in the ARC EM Starter Kit 1.1:

    $ ./build-all.sh --no-uclibc --install-dir $INSTALL_ROOT --no-multilib \
      --cpu em4_dmips

To build native ARC Linux uClibc toolchain (toolchain that runs on same system as for
which it compiles, so host == target) it is required first to build a normal
cross toolchain for this system. Then it should be added it to the PATH, after
that `build-all.sh` can be run:

    $ ./build-all.sh --no-elf32 --install-dir $INSTALL_ROOT_NATIVE \
      --cpu hs38 --native --host arc-snps-linux-uclibc

In this command line, argument to `--cpu` option must correspond to the target
CPU and argument to `--host` options depends on whether this is a big or little
endian target. Install directory must be different than the one where
cross-toolchain is installed.


### Building toolchain on Windows

To build toolchain for Windows hosts it is recommended to do a "Canadian
cross-compilation" on Linux, that is toolchain for ARC targets that runs on
Windows hosts is built on Linux host. Build scripts expect to be run in
Unix-like environment, so it is often faster and easier to build toolchain on
Linux, than do this on Windows using environments like Cygwin and MSYS. While
those allow toolchain to be built on Windows natively this way is not
officially supported and not recommended by Synopsys, due to severe performance
penalty of those environments on build time and possible compatibility issue.

Some limitation apply:
- Only bare metal (elf32) toolchain can be built this way.
- It is required to have toolchain for Linux hosts in the `PATH` for Canadian
  cross-build to succeed - it will be used to compile standard library of tool
  chain.
- Expat library is required for GDB to parse XML target description files. This
  library might be not available in some Mingw setup. Easiest solution is to
  let `build-all.sh` script to build Expat by passing option
  `--no-system-expat`.

To cross-compile toolchain on Linux, Mingw toolchain should be installed. On
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

First stage of GCC build should be disabled, because libraries will be built
with the Linux host toolchain.

After prerequisites are installed do:

    $ export PATH=$LINUX_HOST_TOOLS_PATH/bin:$PATH
    $ ./build-all.sh --no-uclibc --host i686-w64-mingw32 \
      --no-system-expat --no-elf32-gcc-stage1

Note that value of host triplet depends on what mingw toolchain is being used.
Triplet `i686-w64-mingw32` is valid for mingw toolchain currently used in
Ubuntu and EPEL, but, for example, mingw toolchain in standard RHEL 6 has
triplet `i686-pc-mingw32`.


Usage examples
--------------

In all of the following examples it is expected that GNU toolchain for ARC has
been added to the PATH:

    $ export PATH=$INSTALL_ROOT/bin:$PATH


### Using nSIM simulator to run bare metal ARC applications

nSIM simulator supports GNU IO hostlink used by the libc library of bare metal
GNU toolchain for ARC. nSIM option `nsim_emt=1` enables GNU IO hostlink.

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

Default linker script of GNU Toolchain for ARC is not compatible with memory
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
while `exit` functions `nosys.specs` is an infinite loop. For more details
please see [our wiki
page](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/Building-a-baremetal-application).


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
    (gdb) target remote :2331
    (gdb) load
    (gdb) break main
    (gdb) continue
    (gdb) break exit
    (gdb) continue
    # Register R0 contains exit code of function main()
    (gtb) info reg r0
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


Testing the toolchain
----------------------

The script `run-tests.sh` will run the regression test suites against all the
main toolchain components. The comments at the head of this script explain
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

