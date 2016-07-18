.. index:: DejaGNU, testing, verification

How to run DejaGNU tests for ARC toolchain
==========================================

This article describes how to run testsuites of GNU projects for ARC. This
article covers only baremetal toolchain. Tests can be run on different
platforms - simulators or hardware platforms.


Prerequisites
-------------

1. Get sources of the project you want to test.
2. Get source of the "toolchain" repository::

        $ git clone git@github.com:foss-for-synopsys-dwc-arc-processors/toolchain.git

3. Download free nSIM from webpage:
   <https://www.synopsys.com/cgi-bin/dwarcnsim/req1.cgi>. Note that requests
   are manually approved, hence it make take up to 2 workdays for download to
   be ready.
4. Build toolchain.


Preparing
---------

Create a directory where artifacts and temporary files will be created::

    $ mkdir tests
    $ cd tests

Create a ``site.exp`` file in this directory.
``toolchain/dejagnu/example_site.exp`` can be used as an example. Note that this
file is not intended to be used as-is, it must be edited for a particular case:
``srcdir`` and ``arc_exec_prefix`` variables must be set to location of toolchain
sources and location of installed toolchain respectively. Variable
``toolchain_sysroot_dir`` in that file shouldn't be set for baremetal toolchain
testing.

Required environment variables are:

* ``ARC_MULTILIB_OPTIONS`` - should be set to compiler that to be tested. Note
  that first ``-m<something>`` should be omitted, but only first. So for
  example this variables might take value: ``cpu=arcem -mnorm``.
* ``DEJAGNU`` - should be set to path to the ``site.exp`` file in "toolchain"
  repository.
* ``PATH`` - add toolchain installation location ``bin`` directory to PATH -
  some of the internal checks in the GNU testsuite often ignore tool variables
  set in site.exp and instead expect that tools are in the PATH.
* ``NSIM_HOME`` - should point to location where nSIM has been untarred.
* ``ARC_GCC_COMPAT_SUITE`` - set to 0 if you are not going to run compatibility
  tests.

Some actions are specific to particular GNU projects:

* Newlib requires::

    $ mkdir targ-include
    $ ln -s /home/user/arc_gnu/INSTALL/arc-elf32/include/newlib.h targ-include/

* GCC might require (for some tests)::

    $ pushd home/user/arc_gnu/gcc/
    $ ./contrib/gcc_update --touch
    $ popd

* libstdc++ requires::

    $ export CXXFLAGS="-O2 -g"

* GDB requires::

    $ testsuite=$/home/user/arc_gnu/gdb/gdb/testsuite
    $ mkdir $(ls -1d $testsuite/gdb.* | grep -Po '(?<=\/)[^\/]+$')

Also arc-nsim.exp board will require an environment variable ``ARC_NSIM_PROPS``
to be set and to contain path to nSIM properties file that specifies ISA
options.

Toolchain repository an example ``run.sh`` file that does some of those
actions: ``toolchain/dejagnu/example_run.sh``. Note that example file is not
intended to run as-is - it should be modifed for particular purpose.

Baremetal boards that run tests in the development systems, like
arc-openocd.exp require a valid ``memory.x`` file in the current working
directory.


Running
-------

Now, that all is set, test suite can be run with::

    $ runtest --tool=<project-to-test> --target_board=<board> \
      --target=arc-default-elf32

Where ``<project-to-test>`` can be: gcc, g++, binutils, ld, gas, newlib,
libstdc++ or gdb. ``board`` for free nSIM can be arc-nsim.exp or
arc-sim-nsimdrv.exp. The former runs nSIM as a GDBserver, while the latter will
run nSIM as a standalone simulator, which is faster and more stable, but not
suitable to run GDB testsuite.

If ``example_run.sh`` is being used, then assuming that it has been configured
properly, then running is as simple as invoking it.


Compatibility tests
-------------------

GCC contains a set of compatibility tests named ``compat.exp``. It allows to test compatibility of ARC GNU gcc compiler and proprietary Synopsys MetaWare ccac compiler for ARC EM and ARC HS targets. If you want to run these tests it is necessary to configure additional variables in ``site.exp`` file:

* ``set is_gcc_compat_suite "0"`` - enable support of compatibility tests from
  gcc.
* ``set ALT_CC_UNDER_TEST "path/to/ccac"``
* ``set ALT_CXX_UNDER_TEST "path/to/ccac"``
* ``set COMPAT_OPTIONS [list [list "options for gcc" "options for ccac"]]``
* ``set COMPAT_SKIPS [list {ATTRIBUTE}]`` - disable tests with packed
  structures to avoid unaligned access errors.

Then ``runtest`` program must be invoked with an additional option ``compat.exp``::

    $ runtest --tool=<project-to-test> --target_board=<board> \
      --target=arc-default-elf32 compat.exp

Also you can use ``example_run.sh`` and ``example_site.exp`` to simplify
configuration and set these environment variables in ``example_run.sh``:

* ``runtestflags`` - set to ``compat.exp`` to run compatibility tests only.
* ``ARC_GCC_COMPAT_SUITE`` - set to 1.
* ``GCC_COMPAT_CCAC_PATH`` - path to Synopsys MetaWare ccac executable.
* ``GCC_COMPAT_GCC_OPTIONS`` - options for gcc.
* ``GCC_COMPAT_CCAC_OPTIONS`` - options for ccac.
