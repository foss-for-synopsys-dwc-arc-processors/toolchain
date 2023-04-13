Building Linux Image for Working with eBPF in QEMU
==================================================

.. contents:: :local:

Overview
--------

This is a comprehensive guide about creating an environment for 
building, running and debugging eBPF programs for ARC processors using
`GNU toolchain <https://github.com/foss-for-synopsys-dwc-arc-processors/arc-gnu-toolchain>`_
and `QEMU <https://github.com/foss-for-synopsys-dwc-arc-processors/qemu>`_. Though we consider
ARC HS 3x/4x on QEMU as a reference platform, the same guide is applicable for boards
like HS Development Kit.

This guide consists of these steps:

1. Preparing your Linux host for building ``rootfs`` (Buildroot), Linux kernel, third-party tools and libraries.

2. Building and installing third-party tools and libraries: ``elfutils``, ``pahole`` and ``bpftool``. We are going to build them manually to ensure that the latest versions are used.

3. Preparing the building environment: cloning all necessary repositories, configuring SSH keys, etc.

4. Building ``rootfs`` (Buildroot) image and the Linux kernel.

5. Building and running eBPF programs.

Preparing Linux Host
--------------------

We assume that toolchain directory for ARC HS 3x/4x is placed in ``/tools/arc-linux-gnu``
(the directory which contains ``bin``). Ensure that ``/tools/arc-linux-gnu/bin`` is in
``PATH`` environment variable. We are going to use ``/tools`` directory for installing
tools and libraries. You can use any other path, just don't forget to consider it while
reading this guide.

The latest release may be downloaded here ("Linux/glibc ARC HS" variant):

* https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases

Standard development tools must be installed on your host: ``make``, ``cmake``, ``git``, ``rsync``,
``gcc``, ``binutils``, ``clang`` (for building eBPF programs).

Notes for CentOS 7
^^^^^^^^^^^^^^^^^^

It's necessary to install the latest available development tools for CentOS 7
to make it possible to build everything without problems. Use ``centos-release-scl``
repository to install the latest tools and Git. Then, have them enabled.

.. code-block:: bash

    sudo yum install centos-release-scl
    sudo yum install devtoolset-9 rh-git227
    scl enable devtoolset-9 rh-git227 bash

Preparing Tools and Libraries
-----------------------------

We are going to build and install some tools an libraries manually:

1. ``pahole`` host tool is used during the generation of BTF information for the Linux image.
We have to use version ≤1.23 because later versions generate BTF information for 64-bit
enumerations. However, the Linux kernel of version ≤6.0 contains tools which don't
support such BTF records and building fails on the last stage. We need to ensure that a proper
``pahole`` is used.

2. ``elfutils`` host libraries of version ≥0.189 must be presented in ``LD_LIBRARY_PATH`` because
``pahole`` relies on them for working with binaries. Support of ARCv2 was added in ``elfutils`` 0.189,
thus we need to ensure that ``pahole`` is linked with recent-enough ``elfutils`` libraries.

3. ``bpftool`` of version ≥7 must be used for building eBPF program which use features like ``bpf_loop``,
calls to another functions, etc. Older versions don't support new type of relocations for such
features. If you are experiencing problems with host's ``bpftool`` (e.g., Ubuntu 22.04 is shipped
with an outdated ``bpftool`` which may fail while building the kernel) then it would be better to
build and install it manually.

Building and Installing ``elfutils``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Install dependencies for CentOS 7
    sudo yum install libmicrohttpd libmicrohttpd-devel libsq3 libsq3-devel \
                     libarchive libarchive-devel gettext-devel zstd libcurl-devel

    # Install dependencies for the latest Fedora
    sudo dnf install libmicrohttpd libmicrohttpd-devel libsq3 libsq3-devel \
                     libarchive libarchive-devel gettext-devel

    # Install dependencies for Ubuntu 18.04
    sudo apt install libmicrohttpd-dev libsqlite3-dev libarchive-dev

    # Clone, configure and build elfutils (use your own prefix instead of /tools/elfutils)
    git clone -b elfutils-0.189 https://sourceware.org/git/elfutils.git
    cd elfutils
    autoreconf -fi
    mkdir build
    cd build
    ../configure --prefix=/tools/elfutils --enable-maintainer-mode
    make
    make install

    # Configure your environment
    export PATH=/tools/elfutils/bin:$PATH
    export LD_LIBRARY_PATH=/tools/elfutils/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

Building and Installing ``pahole``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Clone, configure and build pahole (use your own prefix instead of /tools/pahole)
    git clone -b v1.23 https://git.kernel.org/pub/scm/devel/pahole/pahole.git
    mkdir pahole/build
    cd pahole/build
    cmake -G "Unix Makefiles"                              \
          -D__LIB=lib                                      \
          -DDWARF_INCLUDE_DIR=/tools/elfutils/include      \
          -DLIBDW_INCLUDE_DIR=/tools/elfutils/include      \
          -DDWARF_LIBRARY=/tools/elfutils/lib/libdw.so.1   \
          -DELF_LIBRARY=/tools/elfutils/lib/libelf.so.1    \
          -DCMAKE_INSTALL_PREFIX=/tools/pahole             \
          ..
    make install

    # Configure your environment
    export PATH=/tools/pahole/bin:$PATH
    export LD_LIBRARY_PATH=/tools/pahole/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

Building and Installing ``bpftool``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Clone and build bpftool (use your own prefix instead of /tools/bpftool)
    git clone --recurse-submodules https://github.com/libbpf/bpftool.git
    cd bpftool/src
    make prefix=/tools/bpftool EXTRA_CFLAGS="-I/tools/elfutils/include" \
                               EXTRA_LDFLAGS="-L/tools/elfutils/lib"    \
                               install-bin

    # Configure your environment
    export PATH=/tools/bpftool/sbin/:$PATH

Preparing Building Environment
------------------------------

Cloning ARC eBPF Testbench
^^^^^^^^^^^^^^^^^^^^^^^^^^

Clone ARC eBPF testbench. This repository contains configuration files for Buildroot and Linux kernel
which simplify setup of the environment for working with eBPF. We are going to use it as a working
directory.

.. code-block:: bash

    git clone --recurse-submodules https://github.com/foss-for-synopsys-dwc-arc-processors/arc-bpf-testbench
    cd arc-bpf-testbench

Preparing Buildroot
^^^^^^^^^^^^^^^^^^^

Clone Buildroot, create a build directory and copy all necessary configuration files and an overlay to the
build directory from ``arc-bpf-testbench/extras``:

.. code-block:: bash

    git clone https://git.buildroot.net/buildroot
    mkdir buildroot/build
    cp -r extras/buildroot/* buildroot/build

List of copied files and directories:

1. ``busybox.fragment`` - A configuration file for BusyBox.
2. ``device_table.txt`` - A configuration file fo setting proper permissions for files in the overlay.
3. ``qemu_hs4x_ebpf_defconfig`` - A configuration file for Buildroot.
4. ``overlay`` - All necessary additional files for target's file system (configuration files, testing SSH keys, etc.).

It's assumed here that the root directory for the toolchain is ``/tools/arc-linux-gnu``.
Thus you need to change ``BR2_TOOLCHAIN_EXTERNAL_PATH`` in ``qemu_hs4x_ebpf_defconfig``
configuration file for Buildroot to the corresponding path.

Preparing Linux Sources
^^^^^^^^^^^^^^^^^^^^^^^

Clone repository of the Linux kernel with the latest patches for support of eBPF with JIT and
copy a corresponding configuration file:

.. code-block:: bash

    git clone -b bpf-early-access https://github.com/foss-for-synopsys-dwc-arc-processors/linux
    mkdir linux/build
    cp extras/linux/qemu_hs4x_ebpf_defconfig linux/arch/arc/configs

Installing SSH Keys for User's Authentication
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We are going to use SSH for interacting with the ARC Linux system. It would be
helpful to have keys for public key authorization without using a password.

You can copy the pregenerated keys from ``extras/host/.ssh/keys`` to
the corresponding host's directory ``~/.ssh/keys``. Public key for this pair
of keys is already installed in the ``buildroot/build/overlay/root/.ssh`` directory.
Don't forget to apply proper rights for those keys in ``.ssh`` for your host (600).

Configure your SSH hosts in ``~/.ssh/config`` (you also can find this file
in ``extras/host/.ssh/config``)::

    Host arc
        HostName            127.0.0.1
        Port                2022
        User                root
        IdentityFile        ~/.ssh/keys/arc

    Host arc-tap
        HostName            10.42.0.100
        Port                22
        User                root
        IdentityFile        ~/.ssh/keys/arc

Also, you can generate your own keys (use your own home path):

.. code-block:: text
    :emphasize-lines: 4

    $ mkdir -p ~/.ssh/keys
    $ ssh-keygen -t rsa -C "arc@ebpf"
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/user/.ssh/id_rsa): /home/user/.ssh/keys/arc
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/user/.ssh/keys/arc
    Your public key has been saved in /home/user/.ssh/keys/arc.pub

Add your public key to the overlay directory:

.. code-block:: bash

    mkdir -p buildroot/build/overlay/root/.ssh
    cp -f ~/.ssh/keys/arc.pub buildroot/build/overlay/root/.ssh/authorized_keys

Install SSH Keys for Host's Authentication (Host Keys)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default, Linux with SSH daemon installed generates random host keys
if they don't exist. For testing and debugging purposes using QEMU
it may lead to these difficulties:

1. Generating a set of host keys in QEMU may take a lot of time.
2. Each time you run QEMU with ``vmlinux`` image new keys a generated. Thus,
   you have to clear cached host key for the QEMU instance to avoid complaining about
   the changed target's host key.

Overlay already contains pregenerated host keys. However, you can generate
your own keys:

.. code-block:: bash

    ssh-keygen -A -f buildroot/build/overlay

Building Images
---------------

Building ``rootfs.cpio``
^^^^^^^^^^^^^^^^^^^^^^^^

.. warning::

    Buildroot requires Git of version 2+. Some old systems (e.g., CentOS 7) have
    an outdated Git which is not supported by Buildroot's build system. If you face
    this problem then you have to find a way to install newer version of Git
    (e.g., using third-party repositories).

.. note:: 
    
    SSHFS package requires ``docutils`` module for Python. Install it using
    your package manager or using ``pip`` (``pip install docutils``) or
    delete the ``BR2_PACKAGE_SSHFS=y`` line if you aren't going to use SSHFS.

.. note::

    Buildroot may complain about invalid headers' version for the toolchain:

    .. code-block :: text

        Incorrect selection of kernel headers: expected 5.16.x, got 5.18.x
    
    E.g., ``2022.09`` release is shipped with headers for Linux kernel 5.16.x.
    If it's not your case then manually change headers' versions for the toolchain
    using ``make menuconfig``.

.. code-block:: bash

    cd buildroot/build
    make -C .. O=$(pwd) defconfig BR2_DEFCONFIG=build/qemu_hs4x_ebpf_defconfig
    make -j $(nproc)

Building ``vmlinux``
^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Set necessary environment variables and build the kernel.
    cd ../../linux/build
    export ARCH=arc
    export CROSS_COMPILE=arc-linux-gnu-
    export C_INCLUDE_PATH="/tools/elfutils/include"
    export LIBRARY_PATH="/tools/elfutils/lib"
    make -C .. O=$(pwd) qemu_hs4x_ebpf_defconfig
    make -j $(nproc)

Workarounds for Well Known Pitfalls
-----------------------------------

Errors While Building Kernel's eBPF Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Change ``kernel/bpf/Makefile`` to prevent some build errors:

.. code-block:: diff

    diff --git a/kernel/bpf/Makefile b/kernel/bpf/Makefile
    index ae90af5b0425..4699a022079a 100644
    --- a/kernel/bpf/Makefile
    +++ b/kernel/bpf/Makefile
    @@ -4,7 +4,7 @@ ifneq ($(CONFIG_BPF_JIT_ALWAYS_ON),y)
    # ___bpf_prog_run() needs GCSE disabled on x86; see 3193c0836f203 for details
    cflags-nogcse-$(CONFIG_X86)$(CONFIG_CC_IS_GCC) := -fno-gcse
    endif
    -CFLAGS_core.o += $(call cc-disable-warning, override-init) $(cflags-nogcse-yy) -Og -g3
    +CFLAGS_core.o += $(call cc-disable-warning, override-init) $(cflags-nogcse-yy) -Og -g3 -finline-functions-called-once

Workaround for ``complex float`` error
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Toolchains for ARC generate ``complex float`` DIE entries in ``libgcc``.
At the moment such entries are not supported by ``pahole``.
So, it's necessary to disable generating BTF for floats. It's already done in
``bpf-early-access`` branch but if you want to build the Linux kernel from another
branch or repository with BTF information you can apply this patch
(https://github.com/foss-for-synopsys-dwc-arc-processors/linux/commit/b17d1955b67493afe37430694c8982411336fc4c):

.. code-block:: diff

    diff --git a/scripts/pahole-flags.sh b/scripts/pahole-flags.sh
    index 0d99ef17e4a5..23af14c6ef94 100755
    --- a/scripts/pahole-flags.sh
    +++ b/scripts/pahole-flags.sh
    @@ -14,7 +14,7 @@ if [ "${pahole_ver}" -ge "118" ] && [ "${pahole_ver}" -le "121" ]; then
            extra_paholeopt="${extra_paholeopt} --skip_encoding_btf_vars"
    fi
    if [ "${pahole_ver}" -ge "121" ]; then
    -       extra_paholeopt="${extra_paholeopt} --btf_gen_floats"
    +       extra_paholeopt="${extra_paholeopt}"
    fi
    if [ "${pahole_ver}" -ge "122" ]; then
            extra_paholeopt="${extra_paholeopt} -j"

Running Linux Image Using QEMU
------------------------------

All actions mentioned below are performed from the working directory
(root of ``arc-bpf-testbench``).

Running Linux Using User Level Network Interface
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    make qemu-start

Running Linux Using TUN/TAP Network Interface
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TUN/TAP network interface allows interacting of the target with your host
in both directions. For example, you can mount host's NFS directories inside
of the target. Configure TUN/TAP interface on host's side:

.. code-block:: bash

    # Manually
    sudo ip tuntap add tap1 mode tap
    sudo ip addr add 10.42.0.1/24 dev tap1
    sudo ip link set tap1 up

    # ... or using testbench
    sudo make tap

Then run ``vmlinux``:

.. code-block:: bash

    make USE_TAP=1 qemu-start

Configure a network interface on target's side:

.. code-block:: bash

    ifconfig eth0 10.42.0.100

Configuring Linux
^^^^^^^^^^^^^^^^^

Mount ``debugfs`` and turn JIT on:

.. code-block:: bash

    # On host's side
    ssh arc "mount -t debugfs debugfs /sys/kernel/debug"
    ssh arc "sysctl net.core.bpf_jit_enable=1"

    # ... or on target's side
    mount -t debugfs debugfs /sys/kernel/debug
    sysctl net.core.bpf_jit_enable=1

    # ... or using testbench for user level network interface
    make qemu-setup

    # ... or using testbench for tun/tap network interface
    make USE_TAP=1 qemu-setup

Running Kernel's Basic eBPF Tests
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Send a module for testing to the target:

.. code-block:: bash

    # For user level network interface
    rsync linux/build/lib/test_bpf.ko arc:/root

    # For TUN/TAP network interface
    rsync linux/build/lib/test_bpf.ko arc-tap:/root

Run the module on the target:

.. code-block:: bash

    # Run all tests
    insmod test_bpf.ko

    # Run a specific
    insmod test_bpf.ko test_id=42

    # Run a range of tests
    insmod test_bpf.ko test_range=42,142

Building and Running eBPF Programs
----------------------------------

.. warning::

    Old operating systems like CentOS 7 and Ubuntu 18.04 contain
    old versions of ``clang`` which may not be sufficient for building
    modern eBPF programs. If building eBPF programs fails then try to
    build the latest ``clang`` with eBPF target following
    :ref:`a corresponding guide <ebpf-clang>` and put it into ``PATH``.

Testbench contains a bunch of examples of eBPF programs. You
can build and load them using these commands from the root directory
of the testbench:

.. code-block:: bash

    # Build dependencies
    make

    # Load programs for user level network interface
    make qemu-load

    # or for TUN/TAP network interface
    make USE_TAP=1 qemu-load

Run a program:

.. code-block:: bash

    # Manually on target's side
    ./minimal

    # ... or using testbench on host's side
    make run-minimal

Explore ``README.md`` for `ARC eBPF Testbench <https://github.com/foss-for-synopsys-dwc-arc-processors/arc-bpf-testbench>`_
or run ``make help`` for information about available commands.

Using NFS for Building eBPF Programs Right on the Target
--------------------------------------------------------

Configuring NFS in CentOS 7 or Fedora
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Install NFS to the host:

.. code-block:: bash

    # For CentOS 7
    sudo yum install nfs-utils

    # For Fedora
    sudo dnf install nfs-utils

Enable services and add rules for firewall:

.. code-block:: bash

    sudo systemctl enable --now rpcbind nfs-server
    sudo firewall-cmd --add-service=nfs --permanent
    sudo firewall-cmd --reload

    # Optional (only if you are going to use SSHFS instead of NFS)
    sudo systemctl enable sshd
    sudo systemctl start sshd

Configuring NFS in Ubuntu 18.04
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Install NFS to the host and enable it:

.. code-block:: bash

    sudo apt install nfs-kernel-server
    sudo systemctl enable --now nfs-server

Configuring ``/etc/exports``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Add this line to ``/etc/exports`` (you can find ``anonuid`` and ``anongid``
for your user using ``id -u`` and ``id -g`` respectively)::

    /nfs *(rw,all_squash,anonuid=1000,anongid=1000,no_subtree_check,insecure)

Update the table of exported NFS file systems:

.. code-block:: bash

    sudo exportfs -rv

Mounting NFS Directory Inside the Guest
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a directory for mounting NFS directory on target's side:

.. code-block:: bash

    mkdir /nfs

If you use user level network interface for running QEMU then just run these
commands inside the guest:

.. code-block:: bash

    # Using NFS
    mount -t nfs 10.0.2.2:/nfs /nfs -o nolock

    # Using SSHFS
    sshfs -o idmap=user,allow_other user@10.0.2.2:/nfs /nfs

If you prefer using TUN/TAP network interface, then run QEMU like ``make USE_TAP=1 qemu-start``
and configure guest's network interface as mentioned earlier. Then run this
line on target's side:

.. code-block:: bash

    # Using NFS
    mount -t nfs 10.42.0.1:/nfs /nfs -o nolock

    # Using SSHFS
    sshfs -o idmap=user,allow_other user@10.42.0.1:/nfs /nfs

Preparing Tools
^^^^^^^^^^^^^^^

:ref:`Build Clang for ARC <ebpf-clang>` and place a directory with ``clang``
to ``/nfs`` (the full path to Clang root directory must be ``/nfs/clang``).

Download, unpack and place a native glibc ARC HS
`toolchain <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_
into ``/nfs/arc-linux-gnu``.

Copy ``/tools/arc-linux-gnu/sysroot`` to ``/nfs/sysroot``. Also build applications using testbench
(run ``make`` from the root directory of the testbench) and copy headers to the sysroot:

.. code-block:: bash

    cp -r output/arc/deps/include/* /nfs/sysroot/usr/include/

Copy applications from the testbench:

.. code-block:: bash

    cp -r apps /nfs

Building eBPF Application
^^^^^^^^^^^^^^^^^^^^^^^^^

Use these commands inside the ARC guest (QEMU):

.. code-block:: bash

    # Configure your PATH
    export PATH="/nfs/clang/bin:$PATH"
    export PATH="/nfs/arc-linux-gnu/bin:$PATH"

    # Build "minimal"
    cd /nfs/apps
    clang -g                         \
          -O2                        \
          -target bpf                \
          -D__TARGET_ARCH_arc        \
          -I/nfs/sysroot/usr/include \
          -c minimal.bpf.c           \
          -o minimal.bpf.o

    bpftool gen skeleton minimal.bpf.o > minimal.skel.h

    gcc -I/nfs/sysroot/usr/include \
        -L/usr/lib minimal.c       \
        -lbpf                      \
        -lelf                      \
        -lz                        \
        -o minimal

    # Prepare the Linux kernel
    mount -t debugfs debugfs /sys/kernel/debug
    sysctl net.core.bpf_jit_enable=1

    # Run the application
    ./minimal
