# ARC GNU Toolchain

This is the main Git repository for the ARC GNU toolchain. It contains
documentation & various supplementary materials required for development,
verification & releasing of pre-built toolchain artifacts.

## Documentation

There are several documentation sites for ARC GNU toolchain:

1. [GNU toolchain documentation site](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation) - the documentation site for ARC Classic targets.
2. [ARC-V Processors Getting Started](https://foss-for-synopsys-dwc-arc-processors.github.io/arc-v-getting-started) - the documentation for ARC-V targets.
3. [Old GNU toolchain documentation site](https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/) - the documentation site for ARC Classic targets
for release `arc-2023.03` and earlier.

## Build environment

The toolchain building is being done by [Crosstool-NG](https://github.com/crosstool-ng/crosstool-ng)
and so we inherit all the capabilities provided by that powerful and flexible tool.
We recommend those interested in rebuilding of ARc GNU tools to become familiar with
Crosstool-NG documentation available here: <https://crosstool-ng.github.io/docs>
to better understand its capabilities and limitations. But in a nutshell, when all the environment
is set (that's described in details below) what needs to be done is as easy as:

```shell
./ct-ng sample_name
./ct-ng build
```

Crosstool-NG is meant to be used in a Unix-like environment and so the best user experience
could be achieved in up-to-date mainstream Linux distributions, which have all needed
tools in their repositories.

Also Crosstool-NG is known to work on macOS with Intel processors
and hopefully will soon be usable on macOS with ARM processors as well. That said ARC GNU
cross-toolchain for macOS might be built natively on macOS. Or it's possible to build it
in a canadian cross manner (see <https://crosstool-ng.github.io/docs/toolchain-types>) on a Linux
host with the use of [OSXCross](https://github.com/tpoechtrager/osxcross) as a cross-toolchain for macOS.

There're ways to build ARC GNU cross-toolchain on Windows as well, and the most convenient would be
use of [Windows Subsystem for Linux v2, WSL2](https://docs.microsoft.com/en-us/windows/wsl/compare-versions)
or any other full-scale virtual machine with Linux inside. Fortunately, though, it's possible to
use the canadian-cross approach for Windows as well with use of MinGW cross-toolchain on Linux host.
Moreover, even MinGW cross-toolchain might be built with Crosstool-NG right in place, limiting
amount of external dependencies.

So our recommendation is to either use a pre-built toolchain for Linux, Windows or macOS
(could be found on [releases](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases) page)
or build in a true Linux environment, be it a real Linux host or a virtual machine.

And due to requirements of some toolchain components for building from source as well as for
execution of a prebuilt toolchain it's necessary to use up-to-date Linux distribution.

As of today, the oldest supported distributions are:

* Ubuntu 22.04 LTS
* RHEL/AlmaLinux 8

## Prerequisites

GNU toolchain for ARC has the same standard prerequisites as an upstream GNU
toolchain as documented in the GNU toolchain user guide or on the [GCC
website](http://gcc.gnu.org/install/prerequisites.html)

### Ubuntu 22.04

```shell
sudo apt update
sudo apt install -y autoconf help2man libtool libtool-bin texinfo byacc flex libncurses5-dev zlib1g-dev \
                    libexpat1-dev texlive build-essential git wget gawk libncursesw5 \
                    bison xz-utils make python3 rsync locales meson ninja-build
```

### RHEL/AlmaLinux 8

Some packages like `gperf`, `help2man` & `texinfo` are not available in a base
package repositories, instead they are distributed via so-called "PowerTools Repository",
to enable it, do the following:

```shell
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --set-enabled powertools
```

Then install all necessary packages:

```shell
sudo dnf install -y autoconf bison bzip2 diffutils file flex gcc-c++ git \
                    gperf help2man libtool make ncurses-devel patch \
                    perl-Thread-Queue python3 rsync texinfo unzip wget \
                    which xz meson ninja-build
```

Autoconf 2.71 is required for configuring Crosstool-NG instead of 2.67. By default,
RHEL/AlmaLinux 8 is shipped with Autoconf 2.67. In this case you should build Autoconf 2.71
manually (use your own prefix):

```shell
wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
tar -xf autoconf-2.71.tar.gz
cd autoconf-2.71
./configure --prefix=/tools/autoconf2.71
make
make install
```

Then configure your environment:

```shell
export PATH="/tools/autoconf2.71/bin:$PATH"
```

### Locale installation for building uClibc

For building uClibc it is required to have `en_US.UTF-8` locale installed on the
build host (otherwise build fails, for details see <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/issues/207>). In case
`en_US.UTF-8` is missing the following needs to be done:

* Install package with locales. In case of Debian or Debian-based Linux
distributions it is `locales`.

* Enable & generate `en_US.UTF-8` locale

  ```shell
  # sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
  ```

## Preparing Crosstool-NG

To simplify toolchain building process we use a powerful, flexible and rather
user-friendly tool called "Crosstool-NG. In its nature it's a mixture of Makefiles
and bash scripts which hide all the magic & complexity needed to properly
configure, build & install all the components of the GNU toolchain.

Still, Crosstool-NG is distributed in sources and needs to be built before use.
Though it is as simple as:

```shell
# Get the sources
git clone https://github.com/foss-for-synopsys-dwc-arc-processors/crosstool-ng.git

# Step into the just obtained source tree
cd crosstool-ng

# Optionally select its version of choice, for example the one used for creation of `arc-2024.12` release
git checkout arc-2024.12-release

# Configure & build Crosstool-NG
./bootstrap
./configure --enable-local
make
```

## Building the Toolchain

Once Crosstool-NG is built and ready for use it's very easy to get a toolchain
of choice to be built. One just needs to decide on configuration options
to be used for toolchain building or use one of the existing pre-defined
settings (which mirror configuration of pre-built toolchains we distribute
via <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>).

### Crosstool-NG configuration: use pre-configured "samples"

The following pre-defined configurations (they are called "samples" on Crosstool's parlance) are available at the moment:

1. `snps-arc-arc700-linux-uclibc` - Linux uClibc cross-toolchain for ARC700 processors for 64-bit Linux hosts
1. `snps-arceb-arc700-linux-uclibc` - Linux uClibc cross-toolchain for ARC700 processors (big endian) for 64-bit Linux hosts
1. `snps-arc-archs-linux-gnu` - Linux glibc cross-toolchain for ARC HS3x & HS4x processors for 64-bit Linux hosts
1. `snps-arceb-archs-linux-gnu` - Linux glibc cross-toolchain for ARC HS3x & HS4x processors (big endian) for 64-bit Linux hosts
1. `snps-arc-archs-linux-uclibc` - Linux uClibc cross-toolchain for ARC HS3x & HS4x processors for 64-bit Linux hosts
1. `snps-arceb-archs-linux-uclibc` - Linux uClibc cross-toolchain for ARC HS3x & HS4x processors (big endian) for 64-bit Linux hosts
1. `snps-arc-archs-native-gnu` - Linux glibc "native" toolchain from ARC HS3x & ARC HS4x processors
1. `snps-arc-elf32-win` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS) for 64
-bit Windows hosts
1. `snps-arceb-elf32-win` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS - big endian) for 64
-bit Windows hosts
1. `snps-arc-multilib-elf32` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS) for 64-bit Linux hosts
1. `snps-arceb-multilib-elf32` - Bare-metal cross-toolchain for wide range of ARCompact & ARCv2 processors (ARC600, ARC700, AEC EM & HS - big endian) for 64-bit Linux hosts
1. `snps-arc32-linux-uclibc` - Linux uClibc cross-toolchain for ARC HS5x processors for 64-bit Linux hosts
1. `snps-arc32-native-uclibc` - Linux uClibc "native" toolchain from ARC HS5x processors
1. `snps-arc64-snps-linux-gnu` - Linux glibc cross-toolchain for for ARC HS6x processors for 64-bit Linux hosts
1. `snps-arc64-snps-native-gnu` -  Linux glibc "native" toolchain from ARC HS6x processors
1. `snps-arc64-unknown-elf` - Bare-metal cross-toolchain for ARC HS6x processors for 64-bit Linux hosts
1. `snps-riscv64-unknown-elf` - Bare-metal cross-toolchain for ARC-V processors with Newlib standard library for 64-bit Linux hosts
1. `snps-riscv64-elf-win` - Bare-metal cross-toolchain for ARC-V processors with Newlib standard library for 64-bit Windows hosts
1. `snps-riscv64-snps-elf-picolibc` - Bare-metal cross-toolchain for ARC-V processors with Picolibc standard library for 64-bit Linux hosts
1. `snps-riscv64-elf-win-picolibc` - Bare-metal cross-toolchain for ARC-V processors with Picolibc standard library for 64-bit Windows hosts

And to get Crosstool-NG configured with either of those samples just say: `./ct-ng sample_name`. For example, to get bare-metal toolchain for ARCompact/ARCv2 processors say: `./ct-ng snps-arc-multilib-elf32`.

> :warning: Please note though, all of these samples are meant to be used for building on a Linux host. And while some samples will work perfectly fine if they are used for Crosstool-NG configuration on say macOS host, those which employ so-called "canadian cross" build methodology (see if `CT_CANADIAN=y` is defined in the sample's `crosstool.config`) won't work on non-Linux hosts as they use existing cross-toolchain for the target host ([MinGW32](https://www.mingw-w64.org) if we build a cross-toolchain for Windows hosts or [OSXCross](https://github.com/tpoechtrager/osxcross) if we build for macOS hosts).

## Crosstool-NG configuration: manual tuning

If pre-defined "sample" doesn't meet one's requirements, it's possible to either fine-tune some existing sample or start over from scratch
and make all the settings manually. For that just say `./ct-ng menuconfig` and use [menuconfig](https://en.wikipedia.org/wiki/Menuconfig) interface in the same way as it's done in many other projects like the Linux kernel, uClibc, Buildroot and many others.

> :warning: To start configuration from scratch, make sure `.config` file doesn't exist in the Crosstool's root directory or say `./ct-ng distclean`.

The most interesting options for toolchain users might be:

* Selection of the default target CPU model. To change it go to `Target options -> Emit assembly for CPU` and specify one of the possible values for GCC's `-mcpu` option (refer to [documentation](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2024.06/toolchain/target-options/) for details).
* Selection of ARC64 processors. For that go to `Target options -> Bitness` and select `64-bit`.
* `CFLAGS` to be used for compilation of libraries for the target. Those might be set in `Target options -> Target CFLAGS`.

## Building a toolchain with Crosstool-NG

All the information above was on how to get Crosstool-NG prepared for operation and how to get it configured to perform a toolchain build with needed settings.
And now, when all the preparations are done, it's required only to start build process with:

```shell
./ct-ng build
```

> :warning: There is set of samples which correspond to
> native toolchains. Such toolchains are used inside of ARC targets.
> If you want to build a native toolchain then a corresponding
> cross-toolchain must be presented in `PATH`. E.g., if you want to
> build `snps-arc64-snps-native-gnu` sample for a native toolchain
> then you need to build `snps-arc64-snps-linux-gnu` sample for
> a cross-compiler first and add `bin` directory of this cross-compiler
> to `PATH`.

## Building toolchain for Windows

### Preparation for building ARC cross-toolchain for Windows host

To build a toolchain for Windows hosts it is recommended to do a "Canadian
cross-compilation" on Linux, that is a toolchain for ARC targets that runs on
Windows hosts is built on Linux host. Build scripts expected to be run in
Unix-like environment, so it is often faster and easier to build toolchain on
Linux, than do this on Windows using environments like Cygwin and MSYS. While
those allow toolchain to be built on Windows natively this way is not
officially supported and not recommended by Synopsys, due to severe performance
penalty of those environments on build time and possible compatibility issue.

Some limitations apply:

* Only bare metal toolchain can be built this way.
* It is required to have toolchain for Linux hosts in the `PATH` for Canadian
  cross-build to succeed - it will be used to compile standard library of toolchain.

To do a canadian-cross toolchain on Linux, MinGW toolchain must be installed on the build host.
There're muliple ways to get MinGW installed:

* On Ubuntu 22.04 that can be done with: `sudo apt install mingw-w64`
* On RHEL/AlmaLinux 8.x it's a bit more challenging:

    ```shell
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --set-enabled powertools
    sudo dnf install -y mingw32-gcc
    ```

* Or it could be built with help of that same Crosstool-NG:

    ```shell
    ./ct-ng x86_64-w64-mingw32
    ./ct-ng build
    ```

Please note, due to recent changes in Crosstool-NG it's required to
do a tiny change in its configuration to escape a problem of
missing `libwinpthread-1.dll`, see Crosstool-NG [issue #1869](https://github.com/crosstool-ng/crosstool-ng/issues/1869)
for more details. And required change consists of removal of `CT_THREADS_POSIX` option,
i.e. in Crosstools-NG's `menuconfig` deselect it.

### Building ARC cross-toolchain for Windows host

Once the MinGW is available on the build host just make sure its binaries
are avaialble via a standard system path, or otherwise add path to them in
local `PATH` environment variable and use `snps-arc-elf32-win` sample for
Crosstool-NG configuration.

Alternatively it's possible to start from one of the other existing samples
(for example `snps-arc64-unknown-elf`) and build it in a canadian cross manner with
the following simple changes.

Run `./ct-ng menuconfig` and select `CT_CANADIAN=y` as well as set
`CT_HOST="i686-w64-mingw32"`.

Then build the toolchain as usual with `./ct-ng build`.

## Usage examples

In all of the following examples, it is expected that GNU toolchain for ARC has
been added to the user's `PATH` environment variable. Please note that built toolchain by default gets installed in the current users's `~/x-tools/TOOLCHAIN_TUPLE` folder, where `TOOLCHAIN_TUPLE` is by default dynamically generated based on the toolchain type (bare-metal, glibc or uclibc), CPU's bitness (32- or 64-bit), provided vendor name etc.

For example:

* With `snps-arc-multilib-elf32` sample built toolchain will be installed in `~/x-tools/arc-snps-elf`
* With `snps-arc64-unknown-elf` sample built toolchain will be installed in `~/x-tools/arc64-snps-elf`

You can find general information about GNU ARC toolchains on the official
documentation page:

1. [GNU toolchain for ARC Classic](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/toolchain/)
2. [GNU toolchain for ARC-V](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/arcv/)

Also, detailed usage examples for various targets and platform may found on [the official
documentation page](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/):

Usage examples for ARC Classic:

* [Building baremetal applications for ARC Classic and running them on nSIM](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/baremetal/simulators/nsim/)
* [Building baremetal applications for ARC Classic and running them on HS Development Kit](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/baremetal/hardware/hsdk/)
* [Building baremetal applications for ARC Classic and running them on EM Software Development Platform](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/baremetal/hardware/emsdp/)
* [Debugging applications on Linux](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/linux/hsdk/build/#debugging-applications-using-gdbserver)

Usage examples for ARC-V:

* [Building applications with Picolibc](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/arcv/building-picolibc/)
* [Building applications with Newlib](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/arcv/building-newlib/)
* [Running on nSIM](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/arcv/nsim/)
* [Running on QEMU](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2025.06/arcv/qemu/)

## Getting help

For all inquiries Synopsys customers are advised to use
[SolvNet](https://solvnet.synopsys.com). Everyone is welcome to open an
issue against
[toolchain](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain)
repository on GitHub.
