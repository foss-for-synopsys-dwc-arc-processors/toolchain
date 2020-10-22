Frequently asked questions
==========================

Compiling
---------

* **Q: How to change heap and stack size in baremetal applications?**

  A: To change size of heap in baremetal applications the following option
  should be specified to the linker: ``--defsym=__DEFAULT_HEAP_SIZE=${SIZE}``,
  where ``${SIZE}`` is desired heap size, in bytes. It also possible to use
  size suffixes, like ``k`` and ``m`` to specify size in kilobytes and
  megabytes respectively. For stack size respective option is
  ``--defsym=__DEFAULT_STACK_SIZE=${STACK_SIZE}``. Note that those are linker
  commands - they are valid only when passed to "ld" application, if gcc driver
  is used for linking, then those options should be prefixed with ``-Wl``. For
  example::

    $ arc-elf32-gcc -Wl,--defsym=__DEFAULT_HEAP_SIZE=256m \
      -Wl,--defsym=__DEFAULT_STACK_SIZE=1024m --specs=nosys.specs \
      hello.o -o hello.bin

  Those options are valid only when default linker script is used. If custom
  linker script is used, then effective way to change stack/heap size depends
  on properties of that linker script - it might be the same, or it might be
  different.

* **Q: Linker fails with error: ``undefined reference to `_exit'``. Among other
  possible functions are also _sbrk, _write, _close, _lseek, _read, _fstat,
  _isatty.**

  A: Function ``_exit`` is not provided by the libc itself, but must be
  provided by the libgloss, which is basically a BSP (board support package).
  Currently two libgloss implementations are provided for ARC: generic libnosys
  and libnsim which implements nSIM IO hostlink. In general libnosys is more
  suitable for hardware targets that doesn't have hostlink support, however
  libnsim has a distinct advantage that on exit from application and in case of
  many errors it will halt the core, while libnosys will cause it to infinitely
  loop on one place. To use libnsim, pass option ``--specs=nsim.specs`` to gcc
  at link stage. If you are a chip or board developer, then it is likely that
  you would want to implement libgloss specific to your hardware.

* **Q: I've opened hs38.tcf and gcc options include ``-mcpu=hs34``. Why hs34
  instead of hs38?**

  A: Possible values of ``-mcpu=`` options are orthogonal to names of IPlib
  templates and respective TCF. GCC option ``-mcpu=`` supports both ``hs34``
  and ``hs38`` values, but they are different - ``hs38`` enables more features,
  like ``-mll64`` which are not present in ``hs34``. ARC HS IPlib template hs38
  doesn't contain double-word load/store, therefore ``-mcpu=hs38`` is not
  compatible with this template. ``-mcpu=hs34``, however, is compatible and
  that is why TCF generator uses this value. See :doc:`baremetal/gcc-mcpu` for
  a full list of possible ``-mcpu`` values and what IPlibrary templates they
  correspond to.

Debugging
---------

* **Q: There are ``can't resolve symbol`` error messages when using gdbserver
  on Linux for ARC target**

  A: This error message might appear when gdbserver is a statically linked
  application. Even though it is linked statically, gdbserver still opens
  ``libthread_db.so`` library using ``dlopen()`` function. There is a circular
  dependency here, as ``libthread_db.so`` expects several dynamic symbols to be
  already defined in the loading application (gdbserver in this case). However
  statically linked gdbserver doesn't export those dynamic symbols, therefore
  ``dlopen()`` invocation causes those error messages. In practice there
  haven't been noticed any downside of this, even when debugging applications
  with threads, however that was tried only with simple test cases. To fix this
  issue, either rebuild gdbserver as a dynamically linked application, or pass
  option ``--with-libthread-db=-lthread_db`` to ``configure`` script of script.
  In this case gdbserver will link with ``libthread_db`` statically, instead of
  opening it with ``dlopen()`` and dependency on symbols will be resolved at
  link time.

* **Q: GDB prints an error message that ``XML support has been disabled at
  compile time``.**

  A: GDB uses Expat library to parse XML files. Support of XML files is
  optional for GDB, therefore it can be built without Expat available, however
  for ARC it usually required to have support of XML to read target description
  files. Mentioned error message might happen if GDB has been built without
  available development files for the Expat. On Linux systems those should be
  available as package in package manager. If Expat development files are not
  available for some reason, then pass option ``--no-system-expat`` to
  ``build-all.sh`` - with this option script will download and build Expat on
  it's own. That is especially useful when cross compiling for Windows hosts
  using Mingw, if development files of Expat are not available in the used
  Mingw installation.


ARC Development Systems
-----------------------

* **Q: How to reset ARC SDP board programmatically (without pressing "Reset"
  button)?**

  A: It is possible to reset ARC SDP board without touching the physical button
  on the board. This can be done using the special OpenOCD openocd::

      $ openocd -f test/arc/reset_sdp.tcl

  Note that OpenOCD will crash with a segmentation fault after executing this
  script - this is expected and happens only after board has been reset, but
  that means that other OpenOCD scripts cannot be used in chain with
  ``reset_sdp.tcl``, first OpenOCD should be invoked to reset the board, second
  it should be invoked to run as an actual debugger.

* **Q: Can I program FPGA's in ARC EM Starter Kit or in ARC SDP?**

  OpenOCD has some support for programming of FPGA's over JTAG, however it is
  not officially supported for ARC development systems.

* **Q: When debugging ARC EM core in AXS101 with Ashling Opella-XD and
  GDBserver I get an error messages and GDB shows that all memory and registers
  are zeroes**

  A: Decrease a JTAG frequency to no more than 5MHz using an Ashling GDBserver
  option ``--jtag-frequency``. This particular problem can be noted if
  GDBserver prints::

      Error: Core is running (unexpected), attempting to halt...
      Error: Core is running (unexpected), attempting to halt...
      Error: Unable to halt core

  While GDB shows that whole memory is just zeroes and all register values are
  also zeroes.