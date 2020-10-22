.. highlightlang:: shell

.. index:: OpenOCD, GDB, EM Starter Kit


Using GNU Toolchain to Debug Applications on EM Starter Kit
===========================================================

Prerequisites
-------------

Toolchain for Linux and Windows hosts can be downloaded from the `GNU Toolchain
Releases page
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_.
For Linux hosts there is a choice between complete tarballs that include
toolchain, IDE and OpenOCD (like installer for Windows), and tarballs that
include toolchain only.

In order to use OpenOCD on Windows it is required to install appropriate WinUSB drivers,
see :doc:`../ide/how-to-use-openocd-on-windows` for details.


Building an application
-----------------------

To learn how to build and debug application with Eclipse IDE, please use
:doc:`../ide/index` manual.

Different core templates in EM Starter Kit use different memory maps, so
different memory map files are required to compile applications that work
properly on those configurations. This "toolchain" repository includes memory
maps for all supported EM Starter Kit versions and configurations. They can be
found at
https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/tree/arc-staging/extras/dev_systems
Memory map files in that directory have ``.x`` extension and file to be used
should be renamed to ``memory.x``, because ``arcv2elfx`` linker emulation
doesn't support ability to override that file name. Please refer to
:doc:`linker` for more details about ``memory.x`` files.

For example for EM Starter Kit v2.3 EM7D to build an application::

    $ cp -a toolchain/extras/dev_systems/sk2.3_em7d.x memory.x
    $ arc-elf32-gcc -Wl,-marcv2elfx --specs=nosys.specs -mcpu=em4_dmips -O2 -g \
         test.c -o test.elf

.. table:: List of compiler flags corresponding to particular CPUs

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


C library for GNU Toolchain for ARC provides basic support for UART module of EM
Starter Kit, which allows to use standard C function for input and output:
``printf()``, ``scanf()``, etc. Memory map files are also provided for processor
configurations of EM Starter Kit. Both of those features are available via
special "specs" files: ``emsk_em9d.specs`` and ``emsk_em11d.specs`` (there is no
separate file for EM7D of EM Starter Kit, it is identical to EM9D). Usage
example is following::

    $ cat hello_world.c
    #include <stdio.h>
    int main() {
        printf("hello world\n");
        return 0;
    }

    $ arc-elf32-gcc --specs=emsk_em9d.specs -mcpu=em4_dmips hello_world.c

Note that it is still required to specify valid ``-mcpu`` option value - it is
not set by the specs file.



Running an application with OpenOCD
-----------------------------------

Starting OpenOCD
^^^^^^^^^^^^^^^^

Parameters of a particular target board are described in the OpenOCD
configuration files. OpenOCD repository from Synopsys already includes several
configuration files made specifically for Synopsys own development platforms:
ARC EM Starter Kit and ARC SDP. Due to differences between different versions
of ARC EM Starter Kit hardware, there are separate configuration files for
different ARC EM Starter Kit versions:

* ``snps_em_sk_v1.cfg`` - for ARC EM Starter Kit v1.x.
* ``snps_em_sk_v2.1.cfg`` - for ARC EM Starter Kit versions 2.0 and 2.1.
* ``snps_em_sk_v2.2.cfg`` - for ARC EM Starter Kit version 2.2.
* ``snps_em_sk_v2.3.cfg`` - for ARC EM Starter Kit version 2.3.
* ``snps_em_sk.cfg`` - this is a configuration for ARC EM Starter Kit 2.0 and
  2.1, preserved for compatibility.

Following documentation would assume the usage of the latest ARC EM Starter Kit
version 2.3 which is similar to 2.2.

Start OpenOCD::

    # On Linux (for manually built OpenOCD):
    $ openocd  -c 'gdb_port 49101' -f board/snps_em_sk_v2.3.cfg

    # On Linux (for prebuilt OpenOCD from IDE package):
    $ $ide_dir/bin/openocd -s $ide_dir/share/openocd/scripts \
        -c 'gdb_port 49101' -f board/snps_em_sk_v2.3.cfg

    @rem on Windows:
    > openocd -s C:\arc_gnu\share\openocd\scripts -c "gdb_port 49101" ^
      -f board\snps_em_sk_v2.3.cfg

OpenOCD will be waiting for GDB connections on TCP port specified as an
argument to ``gdb_port`` command, in this example it is 49101. When
``gdb_port`` command hasn't been specified, OpenOCD will use its default port,
which is 3333, however this port might be already occupied by some other
software. In our experience we had a case, where port 3333 has been occupied,
however no error messages has been printed but OpenOCD and GDB wasn't printing
anything useful as well, instead it was just printing some ambiguous error
messages after timeout. In that case another application was occupying TCP port
only on localhost address, thus OpenOCD was able to start listening on other IP
addresses of system, and it was possible to connect GDB to it using that
another IP address. Thus it is recommended to use TCP ports which are unlikely
to be used by anything, like 49001-49150, which are not assigned to any
application.

OpenOCD can be closed by CTRL+C. It is also possible to start OpenOCD from Eclipse
as an external application.


Connecting GDB to OpenOCD
^^^^^^^^^^^^^^^^^^^^^^^^^

Write a sample application:

.. code-block:: c

    /* simple.c */
    int main(void) {
        int a, b, c;
        a = 1;
        b = 2;
        c = a + b;
        return c;
    }


Compile it - refer to "Building application" section for details, creation of
``memory.x`` is not shown in this example::

    $ arc-elf32-gcc -Wl,-marcv2elfx --specs=nosys.specs -mcpu=em4_dmips -O2 -g \
        simple.c -o simple_sk2.3_em7d.elf

Start GDB, connect to target and run it::

    $ arc-elf32-gdb --quiet simple_sk2.1_em5d.elf
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

Execution should stop at function ``exit``. Value of register ``r0`` should be
``3``.


Known issues and limitations
----------------------------

* Out of the box it is impossible to perform any input/output operations, like
  printf, scanf, file IO, etc.

    * When using an nSIM hostlink (GCC option ``--specs=nsim.specs``), calling
      any of those function in application will result in a hang (unhandled
      system call to be exact).
    * When using libnosys (``--specs=nosys.specs``), standard IO functions will
      simply do nothing - they will set ``errno = ENOSYS`` and return -1 at most.
    * It is possible to use UART for text console I/O operations, but that is
      not implemented by default in GNU toolchain. Consult EM Starter Kit
      documentation and examples for details.

* Bare metal applications has nowhere to exit, and default implementation of
  exit is an infinite loop. To catch exit from application you should set
  breakpoint at function ``exit`` like in the example.

.. vim: set sts=3: