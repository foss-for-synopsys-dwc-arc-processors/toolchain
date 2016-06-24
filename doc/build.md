How to Build GNU Toolchain for ARC Manually
===========================================

This document is a quick set of commands to build GNU toolchain for ARC
manually, without build-*.sh scripts from this repository. Those instructions
do everything mostly the same, sans scripting sugar. In general it is
recommended to build GNU Toolchain for ARC using build-all.sh script. This
document describes what is done by this scripts and can be useful for
situations where those scripts do not work for one or another reason.

It is assumed that current directory is top level directory, which contains all
of the requires git repositories checked out.


Baremetal (elf32) toolchain
---------------------------

Build Binutils:

    mkdir -p build/binutils
    cd build/binutils
    ../../binutils/configure \
        --target=arc-elf32|arceb-elf32 \
	--with-cpu=arcem|archs|arc700|arc600 \
        --disable-multilib|--enable-multilib \
        --enable-fast-install=N/A \
        --with-endian=little|big \
	--disable-werror \
        --enable-languages=c,c++ \
        --with-headers=../../newlib/newlib/libc/include \
	--prefix=${INSTALLDIR}
    make {all,pdf}-{binutils,gas,ld}
    make install-{,pdf-}{binutils,gas,ld}
    cd -

Build GCC, but without libstdc++. Libstdc++ requires libc which is not
available at that stage:

    mkdir -p build/gcc
    cd build/gcc
    ../../gcc/configure \
        --target=arc-elf32|arceb-elf32 \
	--with-cpu=arcem|archs|arc700|arc600 \
        --disable-multilib|--enable-multilib \
        --enable-fast-install=N/A \
        --with-endian=little|big \
	--disable-werror \
        --enable-languages=c,c++ \
        --with-headers=../../newlib/newlib/libc/include \
	--prefix=${INSTALLDIR}
    make all-{gcc,target-libgcc} pdf-gcc
    make install-{gcc,-target-libgcc,pdf-gcc}
    cd -

Build newlib, build tools should be added to the PATH:

    export PATH=$INSTALLDIR:$PATH
    mkdir -p build/newlib
    cd build/newlib
    ../../newlib/configure \
        --target=arc-elf32|arceb-elf32 \
	--with-cpu=arcem|archs|arc700|arc600 \
        --disable-multilib|--enable-multilib \
        --enable-fast-install=N/A \
        --with-endian=little|big \
	--disable-werror \
        --enable-languages=c,c++ \
        --with-headers=../../newlib/newlib/libc/include \
	--prefix=${INSTALLDIR}
    make all-target-newlib
    make install-target-newlib
    cd -

Now it is possible to build listdc++. Note extra options passed to configure.
Without --disable-gcc and --disable-libgcc make would try to build those two
once again, and without --with-newlib configuration will fail with "unsupported
target/host combination". Another option is to build libstdc++ using build tree
of GCC and calling `make all-target-libstdc++-v3`, in that case there is no
need to call "configure" separately, but --with-newlib should be passed when
configuring GCC. Note that in case of a separate build directory things might
get awry if there is already a previous version of toolchain at the
installation target location and in that case it is required to use build tree
of GCC.

    mkdir -p build/libstdc++-v3
    cd build/libstdc++-v3
    ../../gcc/configure \
        --target=arc-elf32|arceb-elf32 \
	--with-cpu=arcem|archs|arc700|arc600 \
        --disable-multilib|--enable-multilib \
        --enable-fast-install=N/A \
        --with-endian=little|big \
	--disable-werror \
        --enable-languages=c,c++ \
        --with-headers=../../newlib/newlib/libc/include \
	--prefix=${INSTALLDIR} \
	--disable-gcc --disable-libgcc --with-newlib
    make all-target-libstdc++-v3
    make install-target-libstdc++-v3
    cd -

Finally build GDB. GDB is the only component here that can be built in any
order, as it doesn't depend on other components.

    mkdir -p build/gdb
    cd build/gdb
    ../../gdb/configure \
        --target=arc-elf32|arceb-elf32 \
	--with-cpu=arcem|archs|arc700|arc600 \
        --disable-multilib|--enable-multilib \
        --enable-fast-install=N/A \
        --with-endian=little|big \
	--disable-werror \
        --enable-languages=c,c++ \
        --with-headers=../../newlib/newlib/libc/include \
	--prefix=${INSTALLDIR}
    make {all,pdf}-gdb
    make install-{,pdf-}gdb
    cd -


Linux toolchain
---------------

Define location of sysroot directory:

    export SYSROOTDIR=$INSTALLDIR/arc-snps-linux-uclibc/sysroot

Install Linux headers

    cd linux
    make ARCH=arc defconfig
    make ARCH=arc INSTALL_HDR_PATH=$SYSROOTDIR/usr headers_install
    cd -

Install uClibc headers

    cd uClibc
    make ARCH=arc arcv2_defconfig
    sed \
        -e "s#%KERNEL_HEADERS%#$SYSROOTDIR/usr/include#" \
	-e "s#%RUNTIME_PREFIX%#/#" \
	-e "s#%DEVEL_PREFIX%#/usr/#" \
	-e "s#CROSS_COMPILER_PREFIX=\".*\"#CROSS_COMPILER_PREFIX=\"arc-snps-linux-uclibc-\"#" \
	-i .config
    make ARCH=arc PREFIX=$SYSROOTDIR install_headers
    cd -

Build binutils:

    mkdir -p build/binutils
    cd build/binutils
    ../../binutils/configure \
        --target=arc-snps-linux-uclibc \
        --with-cpu=archs \
        --enable-fast-install=N/A \
        --with-endian=little \
        --disable-werror \
        --enable-languages=c,c++ \
        --prefix=${INSTALLDIR} \
        --enable-shared \
        --without-newlib \
        --disable-libgomp \
        --with-sysroot=$SYSROOTDIR
    make all-{binutils,gas,ld}
    make install-{binutils,ld,gas}
    cd -

Build Stage 1 GCC:

    mkdir -p build/gcc-stage1
    cd build/gcc-stage1
    ../../gcc/configure \
	--target=arc-snps-linux-uclibc \
        --with-cpu=archs \
        --disable-fast-install \
        --with-endian=little \
        --disable-werror \
        --disable-multilib \
        --enable-languages=c \
        --prefix=${INSTALLDIR} \
        --without-headers \
        --enable-shared \
        --disable-libssp \
        --disable-libmudflap \
        --without-newlib \
        --disable-c99 \
        --disable-libgomp \
        --with-sysroot=$SYSROOTDIR
    make all-{gcc,target-libgcc}
    make install-{gcc,target-libgcc}
    cd -

Build uClibc:

    cd uClibc
    make ARCH=arc PREFIX=$SYSROOTDIR
    make ARCH=arc PREFIX=$SYSROOTDIR install
    cd -

Build Stage 2 GCC:

    mkdir -p build/gcc-stage2
    cd build/gcc-stage2
    ../../gcc/configure \
        --target=arc-snps-linux-uclibc \
        --with-cpu=archs \
        --enable-fast-install=N/A \
        --with-endian=little \
        --disable-werror \
        --enable-languages=c,c++ \
        --prefix=${INSTALLDIR} \
        --enable-shared \
        --without-newlib \
        --disable-libgomp \
        --with-sysroot=$SYSROOTDIR
    make all-{gcc,target-libgcc,target-libstdc++-v3}
    make install-{gcc,target-libgcc,target-libstdc++-v3}
    cd -

Build GDB:

    mkdir -p build/gdb
    cd build/gdb
    ../../gcc/configure \
        --target=arc-snps-linux-uclibc \
        --with-cpu=archs \
        --enable-fast-install=N/A \
        --with-endian=little \
        --disable-werror \
        --enable-languages=c,c++ \
        --prefix=${INSTALLDIR} \
        --enable-shared \
        --without-newlib \
        --disable-libgomp \
        --with-sysroot=$SYSROOTDIR
    make all-gdb
    make install-gdb
    cd -



