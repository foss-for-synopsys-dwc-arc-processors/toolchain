.. highlightlang:: shell

.. index:: OpenOCD, SDP, AXS101, AXS102, AXS103, arcv2elfx, GDB

Using OpenOCD with AXS SDP
==========================

Synopsys DesignWare ARC Software Development Platforms (SDP) is a family of
standalone platforms that enable software development, debugging and profiling.
More information can be found at `Synopsys web-site
<https://www.synopsys.com/dw/ipdir.php?ds=arc-software-development-platform>`_.

To debug applications on the AXS10x software development platforms you can use
OpenOCD. Please consult with `OpenOCD readme
<https://github.com/foss-for-synopsys-dwc-arc-processors/openocd/blob/arc-0.9-dev-2016.03/doc/README.ARC>`_
for instructions to download, build and install it.

AXS SDP consists of a mainboard and one of the CPU cards:

* AXS101 uses AXC001 CPU card;
* AXS102 uses AXC002 CPU card;
* AXS103 uses AXC003 CPU card.


Prerequisites
-------------

Binary toolchain releases can be downloaded from the `GNU Toolchain Releases
page
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_.
For Linux hosts there is a choice between complete tarballs that include
toolchain, IDE and OpenOCD, and tarballs that include toolchain only. For
Windows hosts there is only a single installer, that contains all of the
Toolchain components and allows to select which ones to install.

.. note::
    In order to use OpenOCD it is required to install appropriate WinUSB
    drivers, see :doc:`../ide/how-to-use-openocd-on-windows` for details.

.. _label_building-an-application-axs:

Building an application
-----------------------

To learn how to build and debug application with Eclipse IDE, please use
:doc:`../ide/index` manual.

A memory map appropriate to the selected board should be used to link
applications.  This "toolchain" repository includes memory maps for all ARC SDP
systems. They can be found `in the tree
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/tree/arc-staging/extras/dev_systems>`_.
Memory map files in that directory have ``.x`` extension and file to be used
should be renamed to ``memory.x``, because ``arcv2elfx`` linker emulation
doesn't support ability to override that file name. Please refer to linker page
:doc:`linker` for more details about ``memory.x`` files.

For example to build an application for AXS103/HS36::

    $ cp -a toolchain/extras/dev_systems/axs103.x memory.x
    $ arc-elf32-gcc -Wl,-marcv2elfx --specs=nosys.specs -O2 -g \
        -mcpu=hs38_linux test.c -o test.elf

.. table:: List of compiler flags corresponding to particular CPUs

   +-----+--------+---------------------------------------------------------+
   | AXS |  CPU   |  Flags                                                  |
   +=====+========+=========================================================+
   | 101 | EM6    | -mcpu=em4_dmips -mmpy-option=3                          |
   |     +--------+---------------------------------------------------------+
   |     | ARC770 | -mcpu=arc700                                            |
   |     +--------+---------------------------------------------------------+
   |     | AS221  | -mcpu=arc600_mul32x16                                   |
   +-----+--------+---------------------------------------------------------+
   | 102 |  HS34  | -mcpu=hs -mdiv-rem -mmpy-option=9 -mll64 -mfpu=fpud_all |
   |     +--------+---------------------------------------------------------+
   |     |  HS36  | -mcpu=hs -mdiv-rem -mmpy-option=9 -mll64 -mfpu=fpud_all |
   +-----+--------+---------------------------------------------------------+
   | 103 |  HS36  | -mcpu=hs38_linux                                        |
   |     +--------+---------------------------------------------------------+
   |     |  HS38  | -mcpu=hs38_linux                                        |
   |     +--------+---------------------------------------------------------+
   |     |  HS47  | -mcpu=hs4x_rel31                                        |
   |     +--------+---------------------------------------------------------+
   |     |  HS48  | -mcpu=hs4x_rel31                                        |
   +-----+--------+---------------------------------------------------------+


.. _openocd-axs-board-configuration:

Board configuration
-------------------

First it is required to set jumpers and switches on the mainboard:

*  PROG_M0 (JP1508), PROG_M1 (JP1401) and BS_EN (JP1507) jumpers should be 
   removed (it is their default position);
*  PROG_SRC (JP1403) jumper should be removed (default); DEBUG_SRC (JP1402)
   jumper should be placed (default); SW2501, SW2502, SW2503 and SW2401 should
   be set to their default positions according to the AXC00x CPU Card User
   Guides depending on what CPU card is being used. Following changes should be
   applied then:

   - SW2401.10 switch should be set to "1" (moved to the left), this will
     configure bootloader to setup clocks, memory maps and initialize DDR
     SDRAM and then halt a CPU.
   - For the core you are going to debug choose "Boot mode" type
     "Autonomously", this is done by moving top two switches of the respective
     switch block to the position "1". Alternatively, if you leave default boot
     mode "By CPU Start Button" you need to press "Start" button for this CPU,
     before trying to connect to it with the OpenOCD.

Configuration of the JTAG chain on the CPU card must match the configuration in
the OpenOCD. By default OpenOCD is configured to expect complete JTAG chain
that includes all of the CPU cores available on the card.

*  For the AXC001 card jumpers TSEL0 and TSEL1 should be set.
*  For the AXC002 card jumpers JP1200 and JP1201 should be set.
*  For the AXC003 card it is not possible to modify JTAG chain directly.

Reset board configuration after changing jumpers or switch position, for
this press "Board RST" button SW2410 near the power switch. Two seven-segment
displays should show a number respective to the core that is selected to start
autonomously. Dot should appear on the first display as well, to notify that
bootloader was executed in bypass mode. To sum it up, for the AXS101 following
numbers should appear:

* 1.0 for the AS221 core 1
* 2.0 for the AS221 core 2
* 3.0 for the EM6
* 4.0 for the ARC 770D.

For the AXS102 following numbers should appear:

* 1.0 for the HS34
* 2.0 for the HS36.

For the AXS103 following numbers should appear:

* 1.0 for the HS36
* 2.0 for the HS34
* 3.0 for the HS38 (core 0)
* 4.0 for the HS38 (core 1)


Running OpenOCD
---------------

Run OpenOCD for the AXS101 platform::

    $ openocd -f board/snps_axs101.cfg

Or run OpenOCD for the AXS102 platform::

    $ openocd -f board/snps_axs102.cfg

AXS103 SDP supports different core configurations, so while in AXS101 and
AXS102 there is a chain of several cores, which can operate independently, in
AXS103 one of the particular configurations is chosen at startup and it is not
possible to modify chain via jumpers. As a result, different OpenOCD
configuration files should be used depending on whether AXS103 is configured
to implement HS36 or to implement HS38.

To run OpenOCD for the AXS103 platform with HS36::

    $ openocd -f board/snps_axs103_hs36.cfg

To run OpenOCD for the AXS103 platform with HS38x2::

    $ openocd -f board/snps_axs103_hs38.cfg
    
To run OpenOCD for the AXS103 platform with HS47D::

    $ openocd -f board/snps_axs103_hs47D.cfg
    
To run OpenOCD for the AXS103 platform with HS48x2::

    $ openocd -f board/snps_axs103_hs48.cfg


OpenOCD will open a GDBserver connection for each CPU core on target (4 for
AXS101, 2 for AXS102, 1 or 2 for AXS103). GDBserver for the first core listens
on the TCP port 3333, second on port 3334 and so on. Note that OpenOCD
discovers cores in the reverse order to core position in the JTAG chain.
Therefore for AXS101 port assignment is following:

*  3333 - ARC 770D
*  3334 - ARC EM
*  3335 - AS221 core 2
*  3336 - AS221 core 1.

For AXS102 ports are:

*  3333 - ARC HS36
*  3334 - ARC HS34.

For AXS103 HS38x2 or HS48x2 ports are:

*  3333 - ARC HS38 or HS48 core 1
*  3334 - ARC HS38 or HS48 core 0.

For AXS103 HS47D ports are:

*  3333 - ARC HS47D



Running GDB
-----------

Run GDB::

    $ arc-elf32-gdb ./application.to.debug

Connect to the target GDB server::

    (gdb) target remote <gdbserver-host>:<port-number>

where ``<gdbserver-host>`` is a hostname/IP-address of the host that runs
OpenOCD (can be omitted if it is a localhost), and ``<port-number>`` is a
number of port of the core you want to debug (see previous section).

In most cases it is needed to load application into the target::

    (gdb) load

After that application is ready for debugging.

To debug several cores on the AXC00x card simultaneously, it is needed to start
additional GDBs and connect to the required TCP ports. Cores are controlled
independently from each other.


Advanced topics
---------------

Using standalone Digilent HS debug cable
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

It is possible to use standalone Digilent HS1 or HS2 debug cable instead of the
FT2232 chip embedded into the AXS10x mainboard. Follow AXS10x mainboard manual
to learn how to connect Digilent cable to mainboard. In the nutshell:

*  Connect cable to the DEBUG1 6-pin connector right under the CPU card. TMS
   pin is on the left (closer to the JP1501 and JP1502 jumpers), VDD pin is on
   the right, closer to the HDMI connector.
*  Disconnect JP1402 jumper.

Then modify board configuration file used (``board/snps_axs101.cfg``,
``board/snps_axs102.cfg``, etc): replace "source" of ``snps_sdp.cfg`` with
"source" of ``digilent-hs1.cfg`` or ``digilent-hs2.cfg`` file, depending on
what is being used.

Then restart OpenOCD.


Using OpenOCD with only one core in the JTAG chain
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In AXS101 and AXS102 it is possible to reduce JTAG chain on the CPU card to
a single core.

Change positions of TSEL0/TSEL1 (on AXC001) or JP1200/JP1201 (on AXC002) to
reduce JTAG chain to a particular core. Follow AXC00x CPU Card User Guide for
details.

Then modify OpenOCD command line to notify it that some core is not in the JTAG
chain, for example::

    $ openocd -c 'set HAS_HS34 0' -f board/snps_axs102.cfg

In this case OpenOCD is notified that HS34 is not in the JTAG chain of the
AXC002 card. Important notes:

*  Option ``-c 'set HAS_XXX 0'`` must precede option ``-f``, because they are
   executed in the order they appear.
*  By default all such variables are set ``1``, so it is required to disable
   each core one-by-one. For example, for AXS101 it is required to set two
   variables.  *  Alternative solution is to modify ``target/snps_axc001.cfg``
   or ``target/snps_axc002.cfg`` files to suit exact configuration, in this
   case there will be no need to set variables each time, when starting
   OpenOCD.

Those variables are used in the ``target/snps_axc001.cfg`` file: ``HAS_EM6``,
``HAS_770`` and ``HAS_AS221`` (it is not possible to configure AXC001 to
contain only single ARC 600 core in the JTAG chain). Those variables are used
in the ``target/snps_axc002.cfg`` file: ``HAS_HS34`` and ``HAS_HS36``.

When JTAG chain is modified, TCP port number for OpenOCD is modified
accordingly. If only one core is in the chain, than it is assigned 3333 TCP
port number. In case of AS221 TCP port 3333 is assigned to core 2, while port
3334 is assigned to core 1.


Troubleshooting
---------------

*  **OpenOCD prints "JTAG scan chain interrogation failed: all ones", then there
   is a lot of messages "Warn : target is still running!".**

   An invalid JTAG adapter configuration is used: SDP USB data-port is used
   with configuration for standalone Digilent-HS cable, or vice versa. To
   resolve problem fix file ``board/snps_axs10{1,2}.cfg`` or
   ``board/snps_axs103_hs36.cfg`` depending on what board is being used.

*  **OpenOCD prints "JTAG scan chain interrogation failed: all zeros".**

   It is likely that position of JP1402 jumper does not match the debug
   interface you are trying to use. Remove jumper if you are using external
   debug cable, or place jumper if you are using embedded FT2232 chip.

*  **OpenOCD prints that is has found "UNEXPECTED" device in the JTAG chain.**

   This means that OpenOCD configuration of JTAG chain does not match settings
   of jumpers on your CPU card.

*  **I am loading application into target memory, however memory is still all
   zeros.**

   This might happen if you are using AXC001 CPU card and bootloader has not
   been executed. Either run bootloader for the selected core or configure core
   to start in autonomous mode and reset board after that - so bootloader will
   execute.

*  **OpenOCD prints "target is still running!" after a CTRL+C has been done on
   the GDB client side.**

   There is an issue with EM6 core in AXS101 - after OpenOCD writes DEBUG.FH
   bit to do a force halt of the core, JTAG TAP of this core still occasionally
   returns a status that core is running, even though it has been halted. To
   avoid problem do not try to break execution with Ctrl+C when using EM6 on
   AXS101.
