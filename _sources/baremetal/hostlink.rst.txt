.. index:: --specs, compiler, linker, hostlink, newlib, libgloss, _exit

Hostlink and libgloss
=====================

Newlib project is split into two parts: newlib and libgloss. Newlib implements
system-agnostic function, like string formatting used in ``vprintf()`` or in math
library, while libgloss implements system-specific functions, like ``_read()`` or
``_open()`` which strongly depend on specific of the execution platform. For
example in the baremetal system function ``_write()`` would work only for stdout
and stderr and would write all of the output directly to UART, while in case of
a user-space application on top of complete OS, ``_write()`` would make a system
call, and would let OS handle output operation. For this reason, newlib
provides an architecture-level library - once compiled it can be used for all
compatible ARC-processors, but libgloss would also contain parts specific to
the particular "board" be it an ASIC, or FPGA, or a simulator. Usually it is
not enough to use just newlib to build a complete application, because newlib
doesn't provide even a dummy implementation of ``_exit()`` function, hence even
in the case of simplest applications that do not use system IO, there is still
a need to provide implementation of ``_exit()`` either through linking with some
libgloss implementation or by implementing it right in the application.

libgloss implementation is often specific to a particular chip and runtime
configuration and it is not possible to cover them all in the toolchain
distribution. However, Synopsys provides several libgloss implementations
to cover as much usecases as possible. The libgloss implementation can be
selected with the ``--specs`` gcc option. Consider three most useful libgloss
implementations.

1. ``nsim.specs`` implements nSIM GNU IO Hostlink. It works via software
exceptions, just like the syscalls in real OS - when target application needs
something to be done by the hostlink, it causes a software exception with
parameters that specify what action is required. nSIM intercepts those
exceptions and handles them. The advantage of this approach is that same
application binary can be used with other execution environments, which also
handle software exceptions - unlike the case where a system function
implementation is really baked inside the application binary. To use nSIM GNU
IO hostlink in an application, add option ``--specs=nsim.specs`` to gcc options
when linking - library ``libnsim.a`` will be linked in and will provide
implementations to those system level functions. For example, consider simple
program ``hello.c``:

.. code-block:: c

   #include <stdio.h>
   int main()
   {
       printf("Hello World!\n");
       return 0;
   }

Let's build it for ARC HS with nSIM GNU IO Hostlink support and run in nSIM:

.. code-block:: text

   $ arc-elf32-gcc -mcpu=hs --specs=nsim.specs ./hello.c -o hello
   $ nsimdrv -prop=nsim_isa_family=av2hs -prop=nsim_emt=1 ./hello
   Hello World!

Please note ``-prop=nsim_emt=1`` (emulate traps) option which enables nSIM GNU IO
Hostlink in nSIM. More details can be found in nSIM documentation.

2. ``hl.specs`` implements Metaware Hostlink. It works via memory mailbox named
``__HOSTLINK__``. The running application fills this mailbox and then debugger
or simulator executes requested system call. The advantage of this approach is
that the binary can be executed in the real hardware under Metaware Debugger.
If ``__HOSTLINK__`` symbol is not available (binary is stripped, debugger
connects to the running target) correct address can be passed to Metaware
Debugger ``mdb`` through ``-prop=__HOSTLINK__=address`` option. To use Metaware
Hostlink, add option ``--specs=hl.specs`` to the linker. Let’s build and run
our ``hello.c`` with Metaware Hostlink:

.. code-block:: text

   $ arc-elf32-gcc -mcpu=hs --specs=hl.specs ./hello.c -o hello
   $ nsimdrv -prop=nsim_isa_family=av2hs -prop=nsim_hlink_gnu_io_ext=1 ./hello
   Hello World!

Please note ``-prop=nsim_hlink_gnu_io_ext=1`` option which enables some
additional system calls support in nSIM. Also make sure that ``-prop=nsim_emt``
option is disabled in nSIM, because only one Hostlink type can be used at the
same time.

3. ``nosys.specs``, which is really an architecture-agnostic implementation, that
simply provides empty stubs for a few of the most used system functions - this is
enough to link an application, however it may not function as expected.

To use a generic libnosys library, add option ``--specs=nosys.specs`` to gcc
options when linking. Note that one of the important distinction between
hostlink libraries and ``libnosys`` is that ``_exit()`` implementation in
``libnosys`` is an infinite loop, while in hostlink implementations it will halt
the CPU core. As a result, at the end of an execution, application with
``libnosys`` will spin, while application with hostlink will halt. This spec file
is the default option.

If you are a chip and/or OS developer it is likely that you would want to
provide a libgloss implementation appropriate for your case, because libnsim.a
is not intended to be in the real-world production baremetal applications.
