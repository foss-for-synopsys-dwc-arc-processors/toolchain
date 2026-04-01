# ARC GNU Toolchain

This is the main Git repository for the ARC GNU toolchain. It contains
documentation & various supplementary materials required for development,
verification & releasing of pre-built toolchain artifacts.

## Documentation

There are several documentation sites for ARC GNU toolchain:

1. [GNU toolchain documentation site](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03) - the documentation site for all ARC targets.
2. [Old GNU toolchain documentation site](https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/) - the documentation site for ARC Classic targets
for release `arc-2023.03` and earlier.

## Building ARC GNU toolchains

Follow [Building ARC Toolchains](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/building-toolchains/) 
guide to build any ARC GNU toolchain manually using Crosstool-NG.

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
documentation page](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/):

Usage examples for ARC Classic:

* [Getting Started with nSIM](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-classic/getting-started-nsim/)
* [Getting Started with Picolibc](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-classic/getting-started-picolibc/)
* [Building baremetal applications for ARC Classic and running them on HS Development Kit](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/platforms/board-hsdk/)
* [Building baremetal applications for ARC Classic and running them on EM Software Development Platform](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/platforms/board-emsdp/)
* [Debugging applications on Linux](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/linux/hsdk/build/#debugging-applications-using-gdbserver)

Usage examples for ARC-V:

* [Getting Started with Picolibc](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-v/getting-started-picolibc/)
* [Getting Started with Newlib](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-v/getting-started-newlib/)
* [Running on nSIM](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-v/running-on-nsim/)
* [Running on QEMU](https://foss-for-synopsys-dwc-arc-processors.github.io/documentation/2026.03/toolchain/arc-v/running-on-qemu/)

## Getting help

For all inquiries Synopsys customers are advised to use
[SolvNet](https://solvnet.synopsys.com). Everyone is welcome to open an
issue against
[toolchain](https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain)
repository on GitHub.
