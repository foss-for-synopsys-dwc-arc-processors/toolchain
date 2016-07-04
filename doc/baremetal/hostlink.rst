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

Because libgloss implementation is often specific to a particular chip (nee
:abbr:`BSP (board support package)`), Synopsys provides only two libgloss
implementation as of now - libnsim, that supports nSIM GNU IO Hostlink and
libnosys, which is really an architecture-agnostic implementation, that simply
provides empty stubs for a few of the most used system functions - this is
enough to link an application, however it may not function as expected.

nSIM GNU IO Hostlink works via software exceptions, just like the syscalls in
real OS - when target application needs something to be done by the hostlink,
it causes a software exception with parameters that specify what action is
required. nSIM intercepts those exceptions and handles them. The advantage of
this approach is that same application binary can be used with other execution
environments, which also handle software exceptions - unlike the case where a
system function implementation is really baked inside the application binary.

To use hostlink in application, add option ``--specs=nsim.specs`` to gcc options
when linking - library libnsim.a will be linked in and will provide
implementations to those system level functions

To use a generic libnosys library, add option ``--specs=nosys.specs`` to gcc
options when linking. Note that one of the important distinction between
libnsim and libnosys is that ``_exit()`` implementation in libnosys is an
infinite loop, while in libnsim it will halt the CPU core. As a result, at the
end of an execution, application with libnosys will spin, while application
with libnsim will halt.

If you are a chip and/or OS developer it is likely that you would want to
provide a libgloss implementation appropriate for your case, because libnsim.a
is not intended to be in the real-world production baremetal applications.
