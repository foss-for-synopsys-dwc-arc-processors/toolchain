GCC's support for ARC custom extensions
=======================================

.. highlight:: c
   :linenothreshold: 5

The ARC extension instructions are supported by GNU toolchain by the GNU
assembler. These extension instructions are not macros; the assembler creates
encodings for use of these instructions according to the specification by the
user. To use them at the C-level, we need to make use of inline assembly
facility provided by GNU compiler.


Using inline functions
----------------------

In a header file, define a macro to build a two operand custom instruction::

   #define intrinsic_2OP(NAME, MOP, SOP)                 \
       ".extInstruction " NAME "," #MOP ","              \
       #SOP ",SUFFIX_NONE, SYNTAX_2OP\n\t"

Now instantiate the extension instruction only once::

   asm (intrinsic_2OP ("chk_pkt", 0x07, 0x01));

Create an inline function::

    __extension__ static __inline int32_t __attribute__ ((__always_inline__))
    __chk_pkt (int32_t __a)
    {
      int32_t __dst;
      __asm__ ("chk_pkt %0, %1\n\t"
                 : "=r" (__dst)
                 : "rCal" (__a));
      return __dst;
    }

Example::

   #include <stdint.h>

   #define intrinsic_2OP(NAME, MOP, SOP)				\
     ".extInstruction " NAME "," #MOP ","				\
     #SOP ",SUFFIX_NONE, SYNTAX_2OP\n\t"

   asm (intrinsic_2OP ("chk_pkt", 0x07, 0x01));

   __extension__ static __inline int32_t __attribute__ ((__always_inline__))
   __chk_pkt (int32_t __a)
   {
     int32_t __dst;
     __asm__ ("chk_pkt %0, %1\n\t"
                : "=r" (__dst)
                : "rCal" (__a));
     return __dst;
   }

   int foo (void)
   {

     return __chk_pkt (10);
   }

Assembler results:

.. code-block:: asm

        .file   "t03.c"
        .cpu HS
        .extInstruction chk_pkt,0x07,0x01,SUFFIX_NONE, SYNTAX_2OP

        .section        .text
        .align 4
        .global foo
        .type   foo, @function
   foo:
   # 13 "t03.c" 1
        chk_pkt r0, 10

   # 0 "" 2
        j_s [blink]
        .size   foo, .-foo
        .ident  "GCC: (ARCompact/ARCv2 ISA elf32 toolchain arc-2016.09-rc1-2-gb04a7b5) 6.2.1 20160824"


Using a global asm helper file containing the definition of the custom instructions
-----------------------------------------------------------------------------------

Define the new assembly instruction in the global assembly helper file (e.g.,
mycustom.s):

.. code-block:: asm

   .extInstruction chk_pkt, 0x07, 0x01, SUFFIX_NONE, SYNTAX_2OP

Define the inline assembly wrapper in a C-source file::

   #define chk_pkt(src) ({long __dst_;                       \
          __asm__ ("chk_pkt %0, %1\n\t"                      \
                 : "=r" (__dst_)                             \
                 : "rCal" (src));                            \
              __dst_;})

Use the custom instruction::

   result =chk_pkt(deltachk);
 
Compile,assemble and link it like this (order is important):

.. code-block: shell

   arc-elf32-gcc –O1 –Wa,mycustom.s foo.c


Using only defines at the C source level
----------------------------------------

In a header file, define a macro to build a two operand custom instruction::

   #define intrinsic_2OP(NAME, MOP, SOP)                     \
       ".extInstruction " NAME "," #MOP ","                  \
          #SOP ",SUFFIX_NONE, SYNTAX_2OP\n\t"

Now instantiate the extension instruction only once::

   __asm__ (intrinsic_2OP ("chk_pkt", 0x07, 0x01));

Define a macro for the custom instruction to be used in C sources::

   #define chk_pkt(src) ({long __dst;                        \
          __asm__ ("chk_pkt %0, %1\n\t"                      \
                 : "=r" (__dst)                              \
                 : "rCal" (src));                            \
              __dst;})

Use the custom instruction in C-sources::

   result = chk_pkt(deltachk);

Compile,assemble and link it like this:

.. code-block:: shell

   arc-elf32-gcc –O1 foo.c


For reference the header file for the above example looks like this::

   #ifndef _EXT_INSTRUCTIONS_H_
   #define _EXT_INSTRUCTIONS_H_

   #define intrinsic_2OP(NAME, MOP, SOP)                                        \
       ".extInstruction " NAME "," #MOP "," #SOP ",SUFFIX_NONE, SYNTAX_2OP\n\t" 

   __asm__ (intrinsic_2OP ("chk_pkt", 0x07, 0x01));

   #define chk_pkt(src) ({long __dst;                   \
           __asm__ ("chk_pkt %0, %1\n\t"                \
             : "=r" (__dst)                             \
             : "rCal" (src));                           \
            __dst;})

   #endif /* _EXT_INSTRUCTIONS_H_ */

Using the inline assembly can prove difficult if one is using complex
instructions.  It is recommended to check always if the output/input constrains
are matching the instruction definition. In the above example, my assumption is
that the custom instruction can access all the “r” registers. If this is not
the case, then we should take special care when making the #define(using
mov/lr/sr/aex instructions for example).  We can also define extension core
registers using “.extCoreRegister” assembly directive.   


References
----------

* `GNU assembler manual from our release: Arc Machine Directives <https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_
* `GCC -Inline assembly -Howto <http://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html>`_
