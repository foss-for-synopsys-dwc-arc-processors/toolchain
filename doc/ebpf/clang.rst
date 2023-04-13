.. _ebpf-clang:

Building Clang with eBPF Target for ARC HS Hosts
================================================

Preface
-------

If you want to build eBPF programs right on the target, then
you need to properly build Clang for ARC. There is no need for
all possible targets, so we are going to build Clang with
support of eBPF target only.

Notes for CentOS 7
------------------

It's necessary to install the latest available development tools for CentOS 7
to make it possible to build ``clang``. Use ``centos-release-scl`` repository
to install the latest tools and enable them:

.. code-block:: bash

    sudo yum install centos-release-scl
    sudo yum install devtoolset-9
    scl enable devtoolset-9 bash

Also ``llvm`` build system requires new CMake. Install ``cmake3`` packages
and use it instead of ``cmake``:

.. code-block:: bash

    sudo yum install cmake3

Notes for Ubuntu 18.04
----------------------

``llvm`` build system requires new CMake. To install it on Ubuntu 18.04
you can use ``cmake`` package provided by CMake's team:

* https://apt.kitware.com

Building Clang Toolchain for Host
---------------------------------

Prepare sources:

.. code-block:: bash

    git clone https://github.com/llvm/llvm-project.git
    mkdir llvm-project/build
    cd llvm-project/build

Prepare build system using CMake:

.. code-block:: bash

    cmake -DCMAKE_INSTALL_PREFIX=/tools/clang-bpf \
          -DLLVM_ENABLE_PROJECTS=clang            \
          -DLLVM_TARGETS_TO_BUILD=BPF             \
          -DLLVM_INCLUDE_BENCHMARKS=OFF           \
          -DLLVM_ENABLE_PIC=ON                    \
          -DLLVM_ENABLE_WARNINGS=OFF              \
          -DLLVM_ENABLE_ZLIB=OFF                  \
          -DLLVM_INCLUDE_EXAMPLES=OFF             \
          -DLLVM_INCLUDE_TESTS=OFF                \
          -DCMAKE_BUILD_TYPE=Release              \
          -G "Unix Makefiles"                     \
          ../llvm

Build and install to ``/tools/clang-bpf``:

.. code-block:: bash

    make -j $(nproc)
    make install

Building Native Clang Toolchain for ARC
---------------------------------------

Prepare sources:

.. code-block:: bash

    git clone https://github.com/llvm/llvm-project.git
    mkdir llvm-project/build
    cd llvm-project/build

Clang's build system (CMake) uses a toolchain file for configuring cross-compiler.
Suppose that the toolchain for ARC HS 4x is placed in ``/tools/arc-linux-gnu``
(the directory which contains ``bin``). Save this configuration to ``~/arc.cmake``:

.. code-block:: cmake

    SET(CMAKE_SYSTEM_NAME Linux)
    SET(CMAKE_HOST_SYSTEM_PROCESSOR arc)
    SET(CMAKE_HOST_SYSTEM_PROCESSOR Linux)
    SET(CMAKE_HOST_SYSTEM_PROCESSOR gnu)
    SET(CMAKE_SYSTEM_VERSION 1)

    SET(CMAKE_C_COMPILER /tools/arc-linux-gnu/bin/arc-linux-gnu-gcc)
    SET(CMAKE_CXX_COMPILER /tools/arc-linux-gnu/bin/arc-linux-gnu-g++)
    SET(CMAKE_FIND_ROOT_PATH /tools/arc-linux-gnu/sysroot)

    # Search for programs in the build host directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

    # ... for libraries and headers in the target directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    SET(HAVE_POSIX_REGEX 0)
    SET(HAVE_STEADY_CLOCK 0)

Prepare build system using CMake:

.. code-block:: bash

    cmake -DCMAKE_TOOLCHAIN_FILE=~/arc.cmake          \
          -DCMAKE_INSTALL_PREFIX=/tools/clang-bpf-arc \
          -DLLVM_ENABLE_PROJECTS=clang                \
          -DLLVM_TARGETS_TO_BUILD=BPF                 \
          -DCMAKE_BUILD_TYPE=MinSizeRel               \
          -DLLVM_INCLUDE_BENCHMARKS=OFF               \
          -DLLVM_ENABLE_PIC=ON                        \
          -DBUILD_SHARED_LIBS=ON                      \
          -DLLVM_ENABLE_WARNINGS=OFF                  \
          -DLLVM_ENABLE_ZLIB=OFF                      \
          -DLLVM_INCLUDE_EXAMPLES=OFF                 \
          -DLLVM_INCLUDE_TESTS=OFF                    \
          -DCMAKE_EXE_LINKER_FLAGS="-latomic"         \
          -DCMAKE_MODULE_LINKER_FLAGS="-latomic"      \
          -DCMAKE_SHARED_LINKER_FLAGS="-latomic"      \
          -G "Unix Makefiles"                         \
          ../llvm

Explanation for some options:

* ``-DCMAKE_BUILD_TYPE=MinSizeRel`` - Turn on optimizations for size.
* ``-DLLVM_INCLUDE_BENCHMARKS=OFF`` - Turn off benchmarks to avoid fails while building.
* ``-DBUILD_SHARED_LIBS=ON`` - Don't build Clang as one large blob (more than 100 MB) because
  linker cannot resolve relocations for such large binaries.
* ``-DCMAKE_***_LINKER_FLAGS="-latomic"`` - Somehow ``-latomic`` is not passed to the linker while
  building. Thus we need to pass it manually.

Build and install to ``/tools/clang-bpf-arc``:

.. code-block:: bash

    make -j $(nproc)
    make install

Then you can copy this directory to your target (e.g., to the overlay for Buildroot).

Resources
---------

* https://clang.llvm.org/get_started.html
* https://llvm.org/docs/CMake.html#frequently-used-cmake-variables
* https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/CrossCompiling
* https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html
