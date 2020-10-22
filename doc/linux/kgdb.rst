.. index:: Linux, GDB

Using KGDB to debug Linux
=========================

While user-space programs can be debugged with regular GDB (in combination with
gdbserver), this is not the case for debugging the kernel. gdbserver is a
user-space program itself and cannot control the kernel. KGDB, Kernel GDB,
solves this by acting as a gdbserver that is inside the kernel. 


Configuring the Kernel for KGDB
-------------------------------

Your kernel configuration needs to have the following options set::

    CONFIG_KGDB
    CONFIG_KGDB_SERIAL_CONSOLE


Kernel command line
-------------------

Use the kgdboc option on the kernel boot args to tell KGDB which serial port to
use. Kernel bootargs can be modified in the DTS file or can be passed via
bootloader if it is used.

Examples:

* One serial port, KGDB is shared with console: ``console=ttyS0,115200n8
  kgdboc=ttyS0,115200``
* Two serial ports, one for console, another for KGDB: ``console=ttyS0,115200n8
  kgdboc=ttyS1,115200``

These examples assume you want to attach gdb to the kernel at a later stage.
Alternatively, you can add the kgdbwait option to the command line. With
kgdbwait, the kernel waits for a debugger to attach at boot time. In the case
of two serial ports, the kernel command line looks like the following::

    console=ttyS0,115200n8 kgdboc=ttyS1,115200 kgdbwait


Connect from GDB
----------------

After the kernel is set up, you can start the debugging session. To connect to
your target using a serial connection, you need to have a development PC with
UART that runs GDB and a terminal program.

Stop the Kernel
^^^^^^^^^^^^^^^

First, stop the kernel on the target using a SysRq trigger. To do so, send a
``remote break`` command using your terminal program, followed by the character
``g``:
* using minicom: ``Ctrl-a, f, g``
* using Tera Term: ``Alt-b, g``

You must also stop the kernel if you have two UARTs, even though one of the two
UARTs is dedicated to KGDB.

Connect GDB
^^^^^^^^^^^

After stopping the kernel, connect GDB::

    $ arc-elf32-gdb vmlinux
    (gdb) set remotebaud 115200
    (gdb) target remote /dev/ttyUSB0

You are then connected to the target and can use GDB like any other program.
For instance, you can set a breakpoint now using ``b <identifier>`` and then
continue kernel execution again using ``c``.