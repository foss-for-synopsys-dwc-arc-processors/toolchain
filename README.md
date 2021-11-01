ARC GNU Tool Chain
==================

This is the main Git repository for the ARC GNU toolchain. It contains
documentation & various supplimentary meterials required for development,
verification & releasing of pre-built toolchain artifacts.

Branches in this repository are:
* `arc-releases` is the stable branch for the toolchain release. Head of
  this branch is a latest stable release. It is a branch recommended for most
  users
* `arc-dev` is the development branch for the current toolchain release

While the top of *development* branches should build and run reliably, there
is no guarantee of this. Users who encountered an error are welcomed to create
a new bug report at GitHub Issues for this `toolchain` project.

# Build environment

Real toolchain building is being done by [Crosstool-NG](https://github.com/crosstool-ng/crosstool-ng)
and so we inherit all the capabilities provided by that powerful and flexible tool.
We recommend those interested in rebuilding of ARc GNU tools to become familiar with
Crosstool-NG coumentation available here: https://crosstool-ng.github.io/docs
to better understand its capabilities and limitations. But in a nutshell when all the environment
is set (that's described in details below) what needs to be done is as easy as:
```shell
./ct-ng sample_name
./ct-ng build
```

Crosstool-NG is meant to be used in Unix-like environment and so the best user experience
could be achieved in up-to-date mainstream Linux distributions, which have all needed
tools in their repositories.

Also Crosstool-NG is known to work on macOS with Intel processors
and hopefully will soon be usable on macOS with ARM processors as well. That said ARC GNU
cross-toolchain for macOS might be built natively on macOS. Or it's possible to built it
in a canadian cross manner (see https://crosstool-ng.github.io/docs/toolchain-types) on a Linux
host with use of [OSXCross](https://github.com/tpoechtrager/osxcross) as a cross-toolchain for macOS.

There're ways to build ARC GNU cross-toolchain on Windows as well, and the most convenient would be
use of [Windows Subsystem for Linux v2, WSL2](https://docs.microsoft.com/en-us/windows/wsl/compare-versions)
or any other full-scale virtual machine with Linux inside. Fortunately though it's possible to
use canadian-cross approach for Windows as well with use of MinGW cross-toolchain on Linux host.
Moreover even MinGW cross-toolchain might be built with Crosstool-NG right in place, limiting
amount of external deoendencies.

So our recommendation is to either use pre-built toolchain for Linux, Windows or macOS
(could be found on [releases](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases) page)
or build in a true Linux environment, be it real Linux host or a virtual machine.

And due to requirements of some toolchain components for building from source as well as for
execution of a prebuilt toolchain it's necessary to use up-to-date Linux distribution.

As of today the oldest supported distributions are:
* CentOS/RHEL 7
* Ubuntu 18.04 LTS

# Prerequisites

GNU toolchain for ARC has same standard prerequisites as an upstream GNU tool
chain as documented in the GNU toolchain user guide or on the [GCC
website](http://gcc.gnu.org/install/prerequisites.html)

## Ubuntu 18.04 and newer

```shell
sudo apt update
sudo apt install -y autoconf help2man libtool texinfo byacc flex libncurses5-dev zlib1g-dev \
                    libexpat1-dev texlive build-essential git wget gawk \
                    bison xz-utils make python3 rsync locales
```

## CentOS/RHEL 7.x

```
sudo yum install -y autoconf bison bzip2 file flex gcc-c++ git gperf \
                    help2man libtool make ncurses-devel patch \
                    perl-Thread-Queue python3 rsync texinfo unzip wget \
                    which xz
```

## Fedora & CentOS/RHEL 8.x

### Enabling "PowerTools" repository for CentOS/RHEL 8.x
Some packages like `gperf`, `help2man` & `texinfo` are not available in a base
package repositories, instead they are distributed via so-called "PowerTools Repository",
to enable it, do the following:
```
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --set-enabled powertools
```

Then install all the packages in the same way as it is done for Fedora in the next
section.

### Packages installation in Fedora, CentOS/RHEL 8.x
```
sudo dnf install -y autoconf bison bzip2 diffutils file flex gcc-c++ git \
                    gperf help2man libtool make ncurses-devel patch \
                    perl-Thread-Queue python3 rsync texinfo unzip wget \
                    which xz
```

## Locale installation for building uClibc

For building uClibc it is required to have `en_US.UTF-8` locale installed on the
build host (otherwise build fails, for details see https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/issues/207). In case
`en_US.UTF-8` is missing the following needs to be done:

* Install package with locales. In case of Debian or Debian-based Linux
distributions it is `locales`.

* Enable & generate `en_US.UTF-8` locale
  ```
  # sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
  ```

# Preparing Crosstool-NG

To simplify toolchain building process we use a powerful, flexible and rather
user-friendly tool called "Crosstool-NG. In its nature it's a mixture of Makefiles
and bash scripts which hide all the magic & complexity needed to properly
configure, build & install all the components of the GNU toolchain.

Still Crosstool-NG is distributed in sources and needs to be built before use.
Though it is as simple as:
```shell
# Get the sources
git clone https://github.com/foss-for-synopsys-dwc-arc-processors/crosstool-ng.git

# Step into the just obtained source tree
cd crosstool-ng

# Optionally select its version of choise, for example the one used for creation of `arc-2021.09` release
git checkout arc-2021.09-release

# Configure & build Crosstool-NG
./bootstrap && ./configure --enable-local && make
```

# Building the Toolchain

Once Crosstool-NG is built and ready fo use it's very easy to get a toolchain
of choice to be built. One just needs to decide on configuration options
to be used for toolchain building or use one of the existing pre-defined
settings (which mirror configuration of pre-built toolchains we distribute
via https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases).

## Crosstool-NG configuration: use pre-configured "samples"

The following pre-defined configurations (they are called "samples" on Crosstool's parlance) are available at the moment:
1. `snps-arc-arc700-linux-uclibc` - Linux uClibc cross-toolchain for ARC700 processors for 64-bit Linux hosts
2. `snps-arc-archs-linux-gnu` - Linux glibc cross-toolchain for ARC HS3x & HS4x processors for 64-bit Linux hosts
3. `snps-arc-archs-linux-uclibc` - Linux uClibc cross-toolchain for ARC HS3x & HS4x processors for 64-bit Linux hosts
4. `snps-arc-archs-native-gnu` - Linux glibc "native" toolchain from ARC HS3x & ARC HS4x processors
5. `snps-arc-elf32-macos` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS) for 64-bit macOS hosts
6. `snps-arc-elf32-win` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS) for 64
-bit Windows hosts
7. `snps-arc-multilib-elf32` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS) for 64-bit Linux hosts
8. `snps-arc64-snps-linux-gnu` - Linux glibc cross-toolchain for for ARC HS6x processors for 64-bit Linux hosts
9. `snps-arc64-snps-native-gnu` -  Linux glibc "native" toolchain from ARC HS6x processors
9. `snps-arc64-unknown-elf` - Bare-metal cross-toolchain for ARC HS6x processors for 64-bit Linux hosts

And to get Crosstool-NG configured with either of those samples just say: `./ct-ng sample_name`. For example, to get bare-metal toolchain for ARCompact/ARCv2 processors say: `./ct-ng snps-arc-multilib-elf32`.

> :warning: Please note though, all of these samples are meant to be used for building on a Linux host. And while some samples will work perfectly fine if they are used for Crosstool-NG configuration on say macOS host, those which employ so-called "canadian cross" build methodology (see if `CT_CANADIAN=y` is defined in the sample's `crosstool.config`) won't work on non-Linux hosts as they use existing cross-toolchain for the target host ([MinGW32](https://www.mingw-w64.org) if we build a cross-toolchain for Windows hosts or [OSXCross](https://github.com/tpoechtrager/osxcross) if we build for macOS hosts).

## Crosstool-NG configuration: manual tuning

If pre-defined "sample" doesn't meet one's requirements it's possible to either fine-tune some existing sample or start over from scratch 
and make all the settings manually. For that just say `./ct-ng menuconfig` and use [menuconfig](https://en.wikipedia.org/wiki/Menuconfig) interface in the same way as it's done in many other projects like the Linux kernel, uClibc, Buildroot and many others.

> :warning: To start configuration from scratch make sure `.config` file doesn't exist in the Crosstool's root directory or say `./ct-ng distclean`.

The most interesting options for toolchain users might be:
* Selection of the default target CPU model. To change it go to `Target options -> Emit assembly for CPU` and specify one of the possible values for GCC's `-mcpu` option, see https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/wiki/Understanding-GCC-mcpu-option for the reference.
* Selection of ARC64 processors. For that go to  `Target options -> Bitness` and select `64-bit`.
* `CFLAGS` to be used for compilation of libraries for the target. Those might be set in  `Target options -> Targte CFLAGS`.

## Building a toolchain with Crosstool-NG

All the information above was on how to get Crosstool-NG prepared for operation and how to get it configured to perform a toolchain build with needed settings.
And now when all the preparations are done it's required only to start build process with:
```shell
./ct-ng build
```

## Building toolchain for Windows

To build toolchain for Windows hosts it is recommended to do a "Canadian
cross-compilation" on Linux, that is toolchain for ARC targets that runs on
Windows hosts is built on Linux host. Build scripts expect to be run in
Unix-like environment, so it is often faster and easier to build toolchain on
Linux, than do this on Windows using environments like Cygwin and MSYS. While
those allow toolchain to be built on Windows natively this way is not
officially supported and not recommended by Synopsys, due to severe performance
penalty of those environments on build time and possible compatibility issue.

Some limitation apply:
- Only bare metal toolchain can be built this way.
- It is required to have toolchain for Linux hosts in the `PATH` for Canadian
  cross-build to succeed - it will be used to compile standard library of tool
  chain.

To do a canadian-cross toolchain on Linux, MinGW toolchain must be installed on the build host.
There're muliple ways to get MinGW installed:
* On Ubuntu 18.04 & 20.04 that can be done with: `sudo apt install mingw-w64`
* On CentOS/RHEL 8.x it's a bit more challenging:
    ```
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --set-enabled powertools
    sudo dnf install -y mingw32-gcc
    ```
* Or it could be built with help of that same Crosstool-NG:
    ```
    ./ct-ng x86_64-w64-mingw32
    ./ct-ng build
    ```

Once the MinGW is available on the build host just make sure its binaries are avaialble via a standard system path, or otherwise add path to them in local `PATH` environment variable.


Usage examples
--------------

In all of the following examples it is expected that GNU toolchain for ARC has
been added to the user's `PATH` environment variable. Please note that built toolchain by default gets installed in the current users's `~/x-tools/TOOLCHAIN_TUPLE` folder, where `TOOLCHAIN_TUPLE` is by default dynamically generated based on the toolchain type (bare-metal, glibc or uclibc), CPU's bitness (32- or 64-bit), provided vendor name etc.

For example:
* With `snps-arc-multilib-elf32` sample built toolchain will be installed in `~/x-tools/arc-snps-elf`
* With `snps-arc64-unknown-elf` sample built toolchain will be installed in `~/x-tools/arc64-snps-elf`

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

GDB also might execute commands in a batch mode so that it could be done
automatically:

    $ arc-elf32-gdb -nx --batch -ex 'target remote :51000' -ex 'load' \
                                -ex 'break main' -ex 'break exit' \
                                -ex 'continue' -ex 'continue' -ex 'quit' a.out

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
please see [documentation](https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/baremetal/index.html).


### Using EM Starter Kit to run bare metal ARC EM application

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building an application" of our EM Starter Kit page:
> https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/baremetal/em-starter-kit.html

Build instructions for OpenOCD are available at its page:
https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.9-dev-2021.09/doc/README.ARC

To run OpenOCD:

    $ openocd -f /usr/local/share/openocd/scripts/board/snps_em_sk_v2.3.cfg

Compile test application and run:

    $ arc-elf32-gcc -mcpu=em4_dmips -g --specs=emsk_em9d.specs simple.c
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


### Using Ashling Opella-XD debug probe to debug bare metal applications

> A custom linker script is required to link applications for EM Starter Kit.
> Refer to the section "Building an application" of our EM Starter Kit page:
> https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/baremetal/em-starter-kit.html
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


Getting help
------------

For all inquiries Synopsys customers are advised to use
[SolvNet](https://solvnet.synopsys.com). Everyone else is welcomed to open an
issue against
[toolchain](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain)
repository on GitHub.

