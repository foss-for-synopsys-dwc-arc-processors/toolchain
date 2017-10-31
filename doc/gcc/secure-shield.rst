SecureShield Programming
========================

SecureShield API
----------------

A secure-callable API is a set of functions executing in secure mode that can be
called from code executing in normal mode. The processor contains a special
function call instruction, SJLI, that the compiler uses to implement a
secure-mode API. This instruction transfers execution from normal mode to secure
mode. Any other call or jump into secure mode from normal mode results in a
processor exception.

The GNU tools support a secure-callable API with a two-executable approach:

* One linked executable contains the secure-mode code;
* The second linked executable contains the normal-mode code.

The normal-mode code is compiled normally—no special code is generated for calls
to the secure-mode API.  However, such calls are resolved by the linker in the
normal executable with special function entry points that transfer control to
the normal executable using the SJLI instruction. In the secure-mode executable,
functions that are designate as belonging to the secure API need an index into
the SJLI table. Also the runtime initialization for the secure-mode needs to be
carried on by the user.


Identifying the Secure-Callable APIs
------------------------------------

To indicate to the compiler that a secure-mode function is callable from normal
mode, you can use ``__attribute__((secure_call (IndexNumber)))`` with
secure-callable function. Where ``IndexNumber`` is the entry of that particular
function into the SJLI table.


Programming Cautions
--------------------

Using function pointer of a secure call function is not supported. However, one
can make a stub which can be called indirectly, the stub itself calls the secure
call normally.


Example
-------

Let us consider the following example:

.. code-block:: c

   #include <stdio.h>

   extern int foo (int) __attribute__((secure_call(2)));

   int bar (void)
   {
     printf ("%d\n", foo (100));
     return 0;
   }

   int bar2 (void)
   {
     return foo(100);
   }

Where function ``foo()`` is an external secure function located at index 2 in
the SJLI table.

The result is::

   .cpu EM
   .section	.rodata.str1.4,"aMS",@progbits,1
   .align 4
         .LC0:
            .string	"%d\n"
            .section	.text
            .align 4
            .global	bar
            .type	bar, @function
         bar:
            push_s blink
            mov_s r0,100	;3
            sjli  2	; @foo
            mov_s r1,r0	;4
            mov_s r0,@.LC0	;14
            bl @printf;1
            pop_s blink
            j_s.d [blink]
            mov_s r0,0	;3
            .size	bar, .-bar
            .align 4
            .global	bar2
            .type	bar2, @function
         bar2:
            push_s blink
            mov_s r0,100	;3
            sjli  2	; @foo
            pop_s blink
            j_s [blink]
             .size	bar2, .-bar2

Where, we can easily spot the call to ``foo()`` function via ``SJLI`` instruction.
