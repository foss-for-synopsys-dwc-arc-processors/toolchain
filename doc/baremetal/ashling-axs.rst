.. highlightlang:: shell

.. index:: Ashling, SDP, AXS101, AXS102, AXS103, GDB

Using Ashling Opella-XD GDB server with AXS SDP
===============================================

.. note::
    The Ashling GDB Server software for ARC is implemented by Ashling and
    delivered as part of the Ashling Opella-XD probe for ARC processors
    product.  This guide aims to provide all necessary information to
    successfully debug ARC applications using the GNU toolchain for ARC and the
    Ashling GDB server, however for all issues related to the Ashling GDB
    Server application, user should contact `Ashling Microsystems Ltd.
    <http://www.ashling.com/>`_ for further assistance.

Ashling GDB Server can be used to debug application running on the AXS10x
family of software development platforms. It is recommended to use latest
version of Ashling drivers and software package available.


Building an application
-----------------------

To learn how to build applications for AXS SDP, please refer to corresponding
section of :ref:`OpenOCD manual <label_building-an-application-axs>`.

.. _axs-opella-board-configuration:

Board configuration
-------------------

Board should be configured mostly the same way as for the OpenOCD, but it is
required to change *JP1402* and *JP1403* jumpers - to debug with Opella-XD it is
required to set *JP1403* and unset *JP1402*, while for OpenOCD it is otherwise.
Refer to :ref:`OpenOCD manual <label_building-an-application-axs>` and to the
User Guide of the AXC00x CPU card you are using for more details.

.. _run-ashling-gdb-server:

Running Ashling GDB Server
--------------------------

.. note::
    Starting from Ashling ver. 1.2.6 **--device** option should contain specific cpu name of the board:
    "arc-600", "arc-700", "arc-em", "arc-hs". Using simple "arc" would cause an error.
    
Options of the Ashling GDB Server are described in its User Manual. It is
highly recommended that users be familiar with Ashling GDB Server operation
before proceeding. In a nutshell, to run GDB Server with multiple cores in the
JTAG chain::

    $ ./ash-arc-gdb-server --device arc --arc-reg-file <ARC_REG_FILE> \
        --scan-file arc2core.xml  --tap-number 1,2

Command for Ashling version  starting from 1.2.6::

    $ ./ash-arc-gdb-server --device arc-{CPU} --arc-reg-file <ARC_REG_FILE> \
        --scan-file arc2core.xml  --tap-number 1,2
 
where "arc-{CPU}" is equal to "arc-600", "arc-700", "arc-em", "arc-hs".

That will open GDB server connections on port 2331 (core 1) and 2332 (core 2).
Use GDB to connect to the core you want to debug. ``<ARC_REG_FILE>`` is a path
to a file with AUX register definitions for the core you are going to debug.
Actual file that should be used depends on what target core is. A set of files
can be found in this ``toolchain`` repository in ``extras/opella-xd``
directory. In this directory there are ``arc600-cpu.xml``, ``arc700-cpu.xml``,
``arc-em-cpu.xml`` and ``arc-hs-cpu.xml`` files for GDB server, `direct link
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/tree/arc-staging/extras/opella-xd>`_.


To run with AXS101 with all four cores in a chain ::

    $ ./ash-arc-gdb-server --device arc --arc-reg-file <ARC_REG_FILE> \
        --scan-file arc4core.xml  --tap-number 1,2,3,4

Command for Ashling version  starting from 1.2.6::

    $ ./ash-arc-gdb-server --device arc-{CPU} --arc-reg-file <ARC_REG_FILE> \
        --scan-file arc4core.xml  --tap-number 1,2,3,4    
 
where "arc-{CPU}" is equal to "arc-600", "arc-700", "arc-em", "arc-hs".

File ``arc4core.xml`` is not shipped with Ashling GDB Server, but can be easily
created after looking at ``arc2core.xml`` and reading Ashling Opella-XD User
Manual.

To run Ashling GDB Server with JTAG chain of a single core::

    $ ./ash-arc-gdb-server --device arc --arc-reg-file <ARC_REG_FILE>

Command for Ashling version starting from 1.2.6::

    $ ./ash-arc-gdb-server --device arc-{CPU} --arc-reg-file <ARC_REG_FILE>

where "arc-{CPU}" is equal to "arc-600", "arc-700", "arc-em", "arc-hs".
    
Option ``--jtag-frequency ...MHz`` can be passed to gdbserver to change JTAG
frequency from default 1MHz. Rule of the thumb is that maximum frequency can
be no bigger than half of the frequency, but for cores with external memory
that value can be much lower. Most of the cores in different SDP models can
work safely with JTAG frequencies around 10 ~ 12 MHz. ARC EM6 in the AXS101 is
an exception - maximum recommended frequency is 5MHz.


Running GDB
-----------

Run GDB::

    $ arc-elf32-gdb ./application.to.debug

Then it is required to specify description of target core that will be debugged
with Ashling GDB Server.

Then it is required to specify XML target description file appropriate for the
``ARC_REG_FILE`` used to start Ashling GDB server. XML target description files
for ``arc600-cpu.xml``, ``arc700-cpu.xml``, ``arc-em-cpu.xml`` and
``arc-hs-cpu.xml`` can be found in this ``toolchain`` repository in
``extras/opella-xd``, `direct link
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/tree/arc-staging/extras/opella-xd>`_.
Provided files are: ``opella-arc600-tdesc.xml``, ``opella-arc700-tdesc.xml``,
``opella-arcem-tdesc.xml`` and ``opella-archs-tdesc.xml``.
File ``aux-minimal.xml`` should be also downloaded from that folder
and put into the same folder as ``opella-*-tdesc.xml``. This file
contains description common to all architectures and is included by all
"tdesc" files.
It is important that ``ARC_REG_FILE`` for Ashling GDB server and target
description file for GDB match each other, so if Opella's file has been
modified, so should be the target description.::

    (gdb) set tdesc filename <path/to/opella-CPU-tdesc.xml>

Connect to the target GDB server::

    (gdb) target remote <gdbserver-host>:<port-number>

where ``<gdbserver-host>`` is a hostname/IP-address of the host that runs OpenOCD
(can be omitted if it is localhost), and ``<port-number>`` is a number of port of
the core you want to debug (see previous section).

In most cases you need to load application into the target::

    (gdb) load

The system is now ready to debug the application.

To debug several cores on the AXC00x card simultaneously, start
additional GDBs and connect to the required TCP ports. Cores are controlled
independently from each other.

.. _known-issues:

Known issues
------------

* XML register file is specified only once in the GDB Server argument, that
  means that if your JTAG chain includes multiple cores of different model
  (e.g. ARC 700 and EM) you cannot debug them simultaneously, but you can debug
  multiple cores of they same type (e.g. all EM).

* GDB on Windows can't read XML files with Windows line endings (CR/LF) - tdesc
  XML file must be converted to UNIX line endings (LF).

* HS36 core of the AXS102 cannot be used when both cores are in the JTAG chain
  - if "resume" operation is initiated on the core, GDB Server and GDB will
  behave like it is running and never halting, but in reality it never started
  to run. To workaround this issue remove HS34 from the JTAG chain (remove
  JP1200 jumper on the AXC002 card, remove ``--scan-file`` and ``--tap-number``
  options from Ashling GDB Server command line). If you need both HS34 and HS36
  in the JTAG chain use OpenOCD instead of Ashling GDB Server. Why this problem
  happens is a mystery, since HS36 works without problems when it is single in
  the JTAG chain, and HS34 always work fine; this is likely a problem with
  Ashling GDB Server.

* In Opella software version of 1.0.6 prior to 1.0.6-D it has been observed
  that in some cases target core may hang on application load, if target has
  external memory attached. This happens when P-packet is disabled, and since
  P-packet should be disabled when using new GDB with those versions of Opella
  software, effectively it is not possible to use GDB >= 7.9 with Ashling
  GDBserver < 1.0.6-D to debug cores that employ external memory.

* In version of 1.0.6 it has been observed that breakpoint set at ``main()``
  function of application may be not hit on first run in HS34 core in AXS102.

* In version 1.0.6-D it has been observed that gdbserver doesn't invalidate I$
  of the second ARC 600 core of AXS101 - if this core hits a software
  breakpoint it gets stuck at it forever.


Known Issues of previous versions of Ashling software
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* In version of Ashling software up to 1.0.5B, passing option ``--tap-number
  2`` will cause GDB Server to print that it opened connection on port 2331 for
  core 2, however that is not true, instead GDB Server will create this
  connection for core 1. Therefore if your JTAG chain contains multiple ARC
  TAPs you _must_ specify all of them in the argument to ``--tap-number``
  option.

* Up to version 1.0.5F there is an error in handling of 4-byte software
  breakpoints at 2-byte aligned addresses.  For example in this sample of code
  attempt to set breakpoint at 0x2b2 will fail.::

    0x000002b0 <+0>:	push_s     blink
    0x000002b2 <+2>:	st.a       fp,[sp,-4]
    0x000002b6 <+6>:	mov_s      fp,sp
    0x000002b8 <+8>:	sub_s      sp,sp,16

* Big endian ARC v2 cores are not supported on versions prior to 1.0.5-F.