.. index:: memory.x, linker script, linker, -mvarcv2elfx

Linker scripts and memory.x files
=================================

Introduction to linker and linker scripts
-----------------------------------------

The way how code and data sections will be organized in the memory by linker
strongly depends on the linker script or linker emulation chosen. Linker script
(also known as linker command file) is a special file which specifies where to
put different sections of ELF file and defines particular symbols which may be
used referenced by an application. Linker emulation is basically way to select
one of the predetermined linker scripts of the GNU linker.


Linux user-space applications
-----------------------------

Linux user-space applications are loaded by the dynamically linker in their own
virtual memory address space, where they do not collide with other applications
and it is a duty of dynamic linker to make sure that application doesn't collide
with libraries it uses (if any). In most cases there is no need to use custom
linker scripts.


Baremetal applications
----------------------

Baremetal applications are loaded into target memory by debugger or by
application bootloader or are already in the ROM mapped to specific location. If
memory map used by linker is invalid that would mean that application will be
loaded into the non-existing memory or will overwrite some another memory -
depending on particular circumstances that would cause immediate failure on
invalid write to non-existing memory, delayed failure when application will try
to execute code from non-existing memory, or an unpredictable behaviour if
application has overwritten something else.


Default linker emulation
^^^^^^^^^^^^^^^^^^^^^^^^

Default linker emulation for ARC baremetal toolchain would put all loadable ELF
sections as a consecutive region, starting with address 0x0. This is usually
enough for an application prototyping, however real systems often has a more
complex memory maps. Application linked with default linker emulation may not
run on systems with CCMs and it is unlikely to run on systems with external
memory if it is mapped to address other than 0x0. If system has some of it's
memories mapped to 0x0 this memory may be overwritten by the debugger or
application loader when it will be loading application into target - this may
cause undesired effects. Default linker emulation also puts interrupt vector
table (``.ivt`` section) between code and data sections which is rarely
reflects a reality and also default linker emulation doesn't align ``.ivt``
properly (address of interrupt vector table in ARC processors must be
1KiB-aligned). Therefore default linker emulation is not appropriate if
application should handle interrupts. So default linker emulation can be used
safely only with applications that don't handle interrupts and only on
simulations that simulate whole address space, like following templates:
em6_dmips, em6_gp, em6_mini, em7d_nrg, em7d_voice_audio, em11d_nrg,
em11d_voice_audio, hs36_base, hs36, hs38_base, hs38, hs38_full, hs38_slc_full.


arcv2elfx linker emulation
^^^^^^^^^^^^^^^^^^^^^^^^^^

For cases where default linker emulation is not enough there is an ``arcv2elfx``
linker emulation, which provides an ability to specify custom memory map to
linker without the need to write a complete linker scripts. To use it pass
option ``-marcv2elfx`` to the linker, but note that when invoking gcc driver it is
required to specify this option as ``-Wl,-marcv2elfx``, so that compiler driver
would know that this is an option to pass to the linker, and not a
machine-specific compiler option. When this option is present, linker will try
to open a file named ``memory.x``. Linker searches for this file in current
working directory and in directories listed via ``-L`` option, but unfortunately
there is no way to pass custom file name to the linker. ``memory.x`` must specify
base addresses and sizes of memory regions where to put code and data sections.
It also specifies parameters of heap and stack sections.

For example, here is a sample ``memory.x`` map for ``hs34.tcf`` template:

.. code-block:: text
   :linenos:

   MEMORY {
       ICCM0    : ORIGIN = 0x00000000, LENGTH = 0x00004000
       DCCM     : ORIGIN = 0x80000000, LENGTH = 0x00004000
   }

   REGION_ALIAS("startup", ICCM0)
   REGION_ALIAS("text", ICCM0)
   REGION_ALIAS("data", DCCM)
   REGION_ALIAS("sdata", DCCM)

   PROVIDE (__stack_top = (0x80003fff & -4 ));
   PROVIDE (__end_heap =  (0x80003fff ));

This ``memory.x`` consists of three logical sections. First sections ``MEMORY``
specifies a list of memory regions - their base address and size. Names of
those regions can be arbitrary, and also it may describe regions that are not
directly used by the linker. Second sections describes ``REGION_ALIAS`` es -
this section translates arbitrary region names to standard region names
expected by linker emulation. There are four such regions:

* ``startup`` for interrupt vector table and initialization code. Note that
  currently there is a limitation that this section must always start always at
  address 0x0. That is - ``arcv2elfx`` emulation currently supports interrupt
  vector table only at address 0x0.
* ``text`` is a region where code will be located.
* ``data`` is a regions where data will be located (unsurprisingly).
* ``sdata`` is a region where small data section will be located.

Finally two symbols are provided to specify end of data region in memory -
``__stack_top`` and ``__end_heap``. They effectively point to same address, although
``__stack_top`` should be 4-byte aligned. ``__stack_top`` is a location where stack
starts and it will grow downward. Heap starts at the address immediately
following end of data sections (``.noinit`` section to be exact) and grows upward
to ``__end_heap``. Therefore heap and stack grow towards each other and eventually
may collide and overwrite each over. This linker emulation doesn't provide any
protection against this scenario.


Custom linker scripts
^^^^^^^^^^^^^^^^^^^^^

In many cases neither default linker emulation, nor ``arcv2elfx`` are enough to
describe memory map of a system, therefore it would be needed to write a custom
linker script. Please consult GNU linker User manual for details. Default linker
scripts can be found in ``arc-elf32/lib/ldscripts`` folder in toolchain
installation directory.
