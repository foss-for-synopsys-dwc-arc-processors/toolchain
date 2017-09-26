Using JLI Instructions with GNU
===============================

The ARCv2 ISA provides the JLI instruction, which is two-byte instructions that
can be used to reduce code size for an application. To make use of it, we
provide two new function attributes ``jli_always`` and ``jli_fixed`` which will
force the compiler to call the indicated function using a jli_s instruction. The
compiler also generates the entries in the JLI table for the case when we use
``jli_always`` attribute. In the case of ``jli_fixed`` the compiler assumes a
fixed position of the function into JLI table. Thus, the user needs to provide
an assembly file with the JLI table for the final link. This is useful when we
want to have a table in ROM and a second table in the RAM memory.

The jli instruction usage can be also forced without the need to annotate the
source code via ``-mjli-always`` command.


Optimizing Code using JLI Calls on Functions
--------------------------------------------

The usual way of using jli calls is to use the attribute _jli\_always_ with a
function. For example:

.. code-block:: c

   int func (int i) __attribute__((jli_always));

   int func (int i)
   {
     return i*i;
   }

   int main ()
   {
     printf ("func returned = %d \n", func (100));
     return 0;
   }

which leads to::

   main:
           push_s blink
           st.a fp,[sp,-4] ;28
           mov_s fp,sp     ;4
           mov_s r0,100    ;3
           jli_s @__jli.func
           mov_s r2,r0     ;4
           mov_s r1,r2     ;4
           mov_s r0,@.LC0  ;14
           bl @printf;1
           mov_s r2,0      ;3
           mov_s r0,r2     ;4
           ld.ab fp,[sp,4] ;25
           pop_s blink
           j_s [blink]

As we can see the call to func is done via the ``jli_s`` instruction, while the
other calls are done using regular ``bl`` instruction. If we want all calls to
non-local functions to be done using jli instructions we can use
``-mjli-always`` compiler option. However, we need to be careful in using this
option as the JLI table can hold only 1024 entries. The compiler cannot
efficiently check the number of entries as it only has a limited view over the
whole application. In this case the GNU tool takes care of generating the JLI
table, patching the ``jli_s`` instruction with the correct entry number
corresponding to the called function, and the initialization of the jli_base
auxiliary register.

A special way to use the jli instruction is for ROM patching. Because with the
jli instruction function calls are made indirectly through the JLI table, the
JLI table entries can be changed to invoke alternative functions without
affecting the executable code. Thus, in this case the location of each function
called via jli instruction must be fixed and known at compile time. To achieve
this, we have introduced a new ``jli_fixed`` function attribute which accept a
numerical parameter to specify the function call entry in the JLI table. This
attribute is GNU specific.

Let us consider the following example:

.. code-block:: c

   int func (int i) __attribute__((jli_fixed(2)));

   int func (int i)
   {
     return i*i;
   }

   int main ()
   {
     printf ("func returned = %d \n", func (100));
     return 0;
   }

which leads to::

   main:
           push_s blink
           st.a fp,[sp,-4] ;28
           mov_s fp,sp     ;4
           mov_s r0,100    ;3
           jli_s 2 ; @func
           mov_s r2,r0     ;4
           mov_s r1,r2     ;4
           mov_s r0,@.LC0  ;14
           bl @printf;1
           mov_s r2,0      ;3
           mov_s r0,r2     ;4
           ld.ab fp,[sp,4] ;25
           pop_s blink
           j_s [blink]

As we can see now, the operand of jli instruction is already resolved and points
to entry 2 in the JLI table. In this case, the compiler doesn't generate the JLI
table, as it needs to be provided by the user. A JLI table can be something like
this:

.. code-block:: objdump

           .section .jlitab
           .align  4
   JLI_table:
   __jli.entry0:   b       entry0  ; 0
   __jli.entry1:   b       entry1  ; 1
   __jli.func:     b       func    ; 2

The initialization of the jli_base is again done by the crt0. However, in the
case of RAM/ROM patching, one may want to overwrite the initial value with a new
value based on the location of a patched JLI table. N.B. the RAM/ROM patching
approach may require special startup and/or linker scripts which are not
provided.


Discussion about MWDT/GNU Compatibility
---------------------------------------

In general the GNU jli implementation is compatible with MWDT implementation,
except for the code that invokes the MetaWare runtime initialization code that
sets the JLI_BASE register to address the JLI table. GNU additionally introduces
the ``jli_fixed`` attribute to closely mimic the MWDT ``jli_call_fixed`` pragma.

