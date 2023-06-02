.. highlight:: shell

.. index:: OpenOCD, GDB, EM Starter Kit


Using GNU Toolchain to Debug Applications on EM Starter Kit
===========================================================

To learn how to build and debug application using Eclipse IDE, please use
:doc:`../ide/index` manual.

You can find all necessary information about configuring the board and
connecting to UART in a User Guide which is published in
`ARC EM Starter Kit section <https://github.com/foss-for-synopsys-dwc-arc-processors/ARC-Development-Systems-Forum/wiki/ARC-Development-Systems-Forum-Wiki-Home#arc-em-starter-kit-1>`_
on ARC Development Systems Forum.

Prerequisites
-------------

A toolchain for Linux and Windows hosts can be downloaded from the `GNU Toolchain
Releases page <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_.
OpenOCD for debugging applications on hardware boards is shipped with IDE bundle only.
OpenOCD binary (``openocd`` for Linux and ``openocd.exe`` for Windows) resides in ``bin`` directory of IDE.

Download and install Digilent Adept `runtime and utilities <https://digilent.com/shop/software/digilent-adept/download>`_
to be able to work with EM Starter Kit on Linux. In order to use OpenOCD on Windows it is required to install
appropriate WinUSB drivers, see :doc:`../ide/how-to-use-openocd-on-windows` for details.


Building a Simple Application
-----------------------------

Consider this simple application (assume that it's saved in ``main.c``):

.. code-block:: c

  int main()
  {
      return 0;
  }

Different core templates in EM Starter Kit use different memory maps.
It means that you need to use a special memory map file with ``.x`` extension
to be able to compile and run your application on EM Starter Kit.

In first, clone `toolchain <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain>`_
repository and look into ``extras/dev_systems`` directory. This directory contains
memory map files for different boards and cores. For example, ``sk2.3_em7d.x``
is a memory map file for EM7D core of EM Starter Kit 2.3. You need to put that memory map
file to the current directory, rename it to ``memory.x`` and use ``-Wl,-marcv2elfx``
option while compiling your application. Please refer to :doc:`linker` for more details
about ``memory.x`` files.

That is how we compile the application for EM7D core of EM Starter Kit 2.3::

  cp -a toolchain/extras/dev_systems/sk2.3_em7d.x memory.x
  arc-elf32-gcc -g -Wl,-marcv2elfx -specs=nosys.specs -mcpu=em4_dmips main.c -o main.elf

We use ``libnosys`` (``--specs=nosys.specs``) her to force standard IO functions
to do nothing - they will set ``errno = ENOSYS`` and return -1 in most cases.

You need to use correct ``-mcpu`` and other additional options for building your
application for particular board and core. You can find all necessary options
for any EM Starter Kit configuration in this table:

.. table::

   +------+--------+------------------------------------------------------------+
   |EM SK |  CPU   |  Flags                                                     |
   +======+========+============================================================+
   |      | EM4    | -mcpu=em4_dmips -mmpy-option=wlh5                          |
   |  v1  +--------+------------------------------------------------------------+
   |      | EM6    | -mcpu=em4_dmips -mmpy-option=wlh5                          |
   +------+--------+------------------------------------------------------------+
   |      | EM5D   | -mcpu=em4 -mswap -mnorm -mmpy-option=wlh3 -mbarrel-shifter |
   |      +--------+------------------------------------------------------------+
   | v2.0 | EM7D   | -mcpu=em4 -mswap -mnorm -mmpy-option=wlh3 -mbarrel-shifter |
   |      +--------+------------------------------------------------------------+
   |      | EM7DFPU| -mcpu=em4 -mswap -mnorm -mmpy-option=wlh3 -mbarrel-shifter |
   |      |        | -mfpu=fpuda_all                                            |
   +------+--------+------------------------------------------------------------+
   |      | EM5D   | -mcpu=em4_dmips -mmpy-option=wlh3                          |
   +      +--------+------------------------------------------------------------+
   | v2.1 | EM7D   | -mcpu=em4_dmips -mmpy-option=wlh3                          |
   +      +--------+------------------------------------------------------------+
   |      | EM7DFPU| -mcpu=em4_fpuda -mmpy-option=wlh3                          |
   +------+--------+------------------------------------------------------------+
   |      | EM7D   | -mcpu=em4_dmips                                            |
   +      +--------+------------------------------------------------------------+
   | v2.2 | EM9D   | -mcpu=em4_fpus -mfpu=fpus_all                              |
   +      +--------+------------------------------------------------------------+
   |      | EM11D  | -mcpu=em4_fpuda -mfpu=fpuda_all                            |
   +------+--------+------------------------------------------------------------+
   |      | EM7D   | -mcpu=em4_dmips                                            |
   +      +--------+------------------------------------------------------------+
   | v2.3 | EM9D   | -mcpu=em4_fpus -mfpu=fpus_all                              |
   +      +--------+------------------------------------------------------------+
   |      | EM11D  | -mcpu=em4_fpuda -mfpu=fpuda_all                            |
   +------+--------+------------------------------------------------------------+

Building an Application With Support of UART
--------------------------------------------

Consider this application (assume that it's saved in ``hello.c``):

.. code-block:: c

  #include<stdio.h>

  int main()
  {
      printf("Hello, World!\n");
      return 0;
  }

You need to use ``emsk_em9d.specs`` (for EM7D or EM9D) or ``emsk_em11d.specs``
(for EM11D) specs files instead of ``nosys.specs`` to enable support of UART.
It allows using standard C function for input and output: ``printf()``, ``scanf()``,
etc.

That is how we compile the application for EM7D core of EM Starter Kit 2.3::

  cp -a toolchain/extras/dev_systems/sk2.3_em7d.x memory.x
  arc-elf32-gcc -g -Wl,-marcv2elfx -specs=emsk_em9d.specs -mcpu=em4_dmips main.c -o main.elf

Running an application with OpenOCD
-----------------------------------

OpenOCD is used for connecting to development boards, running a GDB
server and loading programs to the boards using GDB.

Starting OpenOCD
^^^^^^^^^^^^^^^^

OpenOCD uses configuration files for describing different boards. OpenOCD
is shipped with different configuration files for different EM Starter Kit
versions:

* ``snps_em_sk_v1.cfg`` - for ARC EM Starter Kit v1.x.
* ``snps_em_sk_v2.1.cfg`` - for ARC EM Starter Kit versions 2.0 and 2.1.
* ``snps_em_sk_v2.2.cfg`` - for ARC EM Starter Kit version 2.2.
* ``snps_em_sk_v2.3.cfg`` - for ARC EM Starter Kit version 2.3.
* ``snps_em_sk.cfg`` - this is a configuration for ARC EM Starter Kit 2.0 and
  2.1, preserved for compatibility.

Assume that EM Starter Kit 2.3 is used. If you've downloaded IDE bundle for
Linux then you can run OpenOCD this way (replace ``<ide>`` by a path to
the directory of IDE bundle)::

  <ide>/bin/openocd -s <ide>/share/openocd/scripts -c 'gdb_port 49101' -f board/snps_em_sk_v2.3.cfg

If you've built and installed OpenOCD manually then you can run OpenOCD this way::

  openocd  -c 'gdb_port 49101' -f board/snps_em_sk_v2.2.cfg

If you've downloaded and installed IDE bundle for Windows then you can run OpenOCD this way:

.. code-block:: winbatch

    openocd -s C:\arc_gnu\share\openocd\scripts -c "gdb_port 49101" -f board\snps_em_sk_v2.3.cfg

OpenOCD will be waiting for GDB connections on TCP port specified as an
argument to ``gdb_port`` command (49101 in our case). If ``gdb_port`` is not
passed then the default port 3333 is used. It's recommended not to use a default
port since it may be occupied by another application. OpenOCD can be closed by CTRL+C.

Connecting GDB to OpenOCD
^^^^^^^^^^^^^^^^^^^^^^^^^

Write a sample application and save it to ``simple.c``:

.. code-block:: c

  int main()
  {
      int a = 1;
      int b = 2;
      int c = a + b;
      return c;
  }

Build the application for EM7D core of EM Starter Kit 2.3::

  cp -a toolchain/extras/dev_systems/sk2.3_em7d.x memory.x
  arc-elf32-gcc -g -Wl,-marcv2elfx -specs=nosys.specs -mcpu=em4_dmips main.c -o main.elf

Start OpenOCD as it described earlier and start GDB, connect to target and run it:

.. code-block:: text

    $ arc-elf32-gdb -quiet main.elf
    # Connect. Replace 3333 with port of your choice if you changed it when starting OpenOCD
    (gdb) target remote :3333
    # Increase timeout, because OpenOCD sometimes can be slow
    (gdb) set remotetimeout 15
    # Load application into target
    (gdb) load
    # Go to start of main function
    (gdb) tbreak main
    (gdb) continue
    # Resume with usual GDB commands
    (gdb) step
    (gdb) next
    # Go to end of the application
    (gdb) tbreak exit
    (gdb) continue
    # For example, check exit code of application
    (gdb) info reg r0

Execution should stop at function ``exit``. Value of register ``r0`` should be ``3``.

Known issues and limitations
----------------------------

* Bare metal applications has nowhere to exit, and default implementation of
  exit is an infinite loop. To catch exit from application you should set
  breakpoint at function ``exit`` like in the example.

.. vim: set sts=3:
