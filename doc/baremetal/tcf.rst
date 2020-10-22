.. index:: TCF, compiler, arc-elf32-tcf-gcc


Using TCF
=========

General sescription
-------------------

Currently GNU toolchain has a partial support for :abbr:`TCF (target
configuration files)`, however it is not complete and in particular scenarios
TCFs cannot be used as-is.

If you are using Eclipse IDE for ARC, please refer to a
:doc:`../ide/building-user-guide`.  Eclipse IDE for ARC supports only GCC
compiler and GNU linker script sections of TCF, it doesn't support preprocessor
defines sections as of version 2016.03.

If you are using GNU toolchain without IDE on Linux hosts you can use a special
script :program:`arc-elf32-tcf-gcc` (for big-endian toolchain this file has
:program:`arceb-` prefix) that is located in the same ``bin`` directory as rest
of the toolchain executable files. This executable accepts all of the same
options as GCC driver and also an option ``--tcf <PATH/TO/TCF>``.
:program:`arc-elf32-tcf-gcc` will extract compiler options, linker script and
preprocessor defines from TCF and will pass them to GCC along with other
options.

* GCC options from ``gcc_compiler`` section will be passed as-is, but can be
  overridden by ``-m<something>`` options passed directly to
  :program:`arc-elf32-tcf-gcc`.
* GNU linker script will be extracted from ``gnu_linker_command_file`` will be
  used as a :file:`memory.x` file for ``-Wl,marcv2elfx`` linker emulation.
  Option ``-Wl,-marcv2elfx`` is added by this wrapper - there is no need to
  pass it explicitly.
* Preprocessor defines from section ``C_defines`` will be passed with
  ``-include`` option of GCC.

:program:`arc-elf32-tcf-gcc` is a Perl script that requires ``XML:LibXML``
package. It is likely to work on most Linux hosts, however it will not work on
Windows hosts, unless Perl with required library has been installed and added
to the ``PATH`` environment variable. TCF is a text file in XML format, so in
case of need it is trivial to extract compiler flags and linker script from TCF
and use them directly with GCC and ld without IDE or wrapper script.

Value of ``-mcpu=`` option is selected by TCF generator to have best match with
the target processor. This option :doc:`gcc-mcpu` not only sets various
hardware options but also selects a particular build of standard library.
Values of hardware extensions can be overridden with individual ``-m*``
options, but that will not change standard library to a matching build - it
still will use standard library build selected by ``-mcpu=`` value.


Compiler options
----------------

GCC options are stored in the ``gcc_compiler`` section of TCF. These options
are passed to GCC as-is. These are "machine-specific" options applicable only
to ARC, and which define configuration of target architecture - which of the
optional hardware extensions (like bitscan instructions, barrel shifter
instructions, etc) are present. Application that uses hardware extensions will
not work on ARC processor without those extensions - there will be an Illegal
instruction exception (although application may emulate instruction via
handling of this exception, but that is out of scope of this document).
Application that doesn't use hardware extensions present in the target ARC
processor might be ineffective, if those extensions allow more optimal
implementation of same algorithm. Usually hardware extensions allow improvement
of both code size and performance at the expense of increased gate count, with
all respective consequences.

When TCF is selected in the IDE respective compiler options are disabled in GUI
and cannot be changed by user. However if TCF is deselected those options remain
at selected values, so it is possible to "import" options from TCF and then
modify it for particular need.

When using :program:`arc-elf32-tcf-gcc` compiler options passed to this wrapper script
has a higher precedence then options in TCF, so it is possible to use TCF as a
"baseline" and then modify if needed.


Memory map
----------

Please refer to main page about GNU linker for ARC :doc:`linker` for more
details.

TCF doesn't contain a linker script for GNU linker in the strict meaning of
this term. Instead TCF contains a special memory map, which can be used
together with a linker emulation called **arcv2elfx**. This linker emulation
reads a special file called ``memory.x`` to get several defines which denote
location of particular memory areas, and then emulation allocates ELF sections
to those areas. So, for example, ``memory.x`` may specify address and size of
ICCM and DCCM memories and linker would put code sections into ICCM and data
sections to DCCM.  TCF contains this ``memory.x`` file as content of
``gnu_linker_command_file`` section. IDE and :program:`arc-elf32-tcf-gcc` simply create
this file and specify to linker to use **arcv2elfx** emulation. This is done by
passing option ``-marcv2elfx`` to linker, but note that when invoking gcc
driver it is required to specify this option as ``-Wl,-marcv2elfx``, so driver
would know that this is an option to pass to linker.

It is very important that memory map in TCF matches the one in the hardware,
otherwise application will not work. By default linker places all application
code and data as a continuous sections starting from address 0x0. Designs with
CCMs usually has ICCM mapped at address 0x0, and DCCM at addresses >=
0x8000_0000 (or simply an upper half of address space, which can be less then
32 bits wide). If application has both code and data put into ICCM, it may
technically work (load/store unit in ARC has a port to ICCM), however this
underutilizes DCCM and creates a risk of memory overflow where code and data
will not fit into the ICCM, so overflown content will be lost, likely causing
an error message in simulator or in debugger. For this reason it is recommended
to use memory.x file from TCF when linking applications that use CCM memory.
Typically TCF-generator would automatically assign instruction memory area to
ICCM and data memory area to DCCM, because parameters of those memories can be
read from BCRs, although it doesn't support such features as ICCM1 or NV ICCM.

When memory is connected via external memory bus TCF-generator cannot know
where memory will be actually located, so it will put all sections
continuously, starting from address 0. This is basically same as what happens
when no memory map has been passed to linker.  Therefore memory map in such TCF
is effectively useless, instead it is needed to manually enter a proper memory
map into "gnu_linker_command_file" section.  However when using an nSIM
simulator such TCF will work nice, as it will make nSIM simulate whole address
space, so there is no risk that application will be loaded into unexisting
address.

When using IDE there is an option to ignore memory map specified in TCF and use
default memory mapping or custom linker script. This is the default setting -
to ignore linker script embedded into TCF. However if target design uses
closely-coupled memories then it is highly advised to use memory map (embedded
into TCF or manually written).


C preprocessor defines
----------------------

TCF section ``C_defines`` contains preprocessor defines that specify presence of
various hardware optional extensions and values of Build Configuration
Registers. :program:`arc-elf32-tcf-gcc` wrapper extracts content of this section into
temporary file and includes into compiled files via ``-include`` option of GCC.


arc-elf32-tcf-gcc options
-------------------------

.. program:: arc-elf32-tcf-gcc

.. option:: --compiler

   Overwrites the default compiler name.  The compiler tool chain needs to be
   in the PATH. Default value depends on the name of this file - it will call
   compiler that has the same name, only without -tcf part. Therefore:

   * arc-elf32-tcf-gcc     -> arc-elf32-gcc
   * arceb-elf32-tcf-gcc   -> arceb-elf32-gcc
   * arc-linux-tcf-gcc     -> arc-linux-gcc
   * arceb-linux-tcf-gcc   -> arceb-linux-gcc
   * arc-a-b-tcf-gcc       -> arc-a-b-gcc
   * arc-tcf-elf32-tcf-gcc -> arc-tcf-elf32-gcc

.. option:: --tcf

   The name and the location of the TCF file.

.. option:: --verbose

   Verbose output. Prints the compiler invokation command.