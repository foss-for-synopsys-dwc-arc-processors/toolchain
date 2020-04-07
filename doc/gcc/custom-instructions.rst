Custom instructions: what and how
=================================

ARC architecture allows users to specify extension instructions. These extension
instructions are not macros; the assembler creates encodings for use of these
instructions according to the specification by the user.

To create a custom instruction, ones need to make use of the .extInstruction
pseudo-op, which also allows the user to choose for a particular instruction
syntax, one of:

* Three operand instruction;
* Two operand instruction;
* One operand instruction;
* No operand instruction.

But what is the difference between those ones. To answer this question, we need
to check how an extension instruction is encoded:

* Major Opcode = 0x07

  * Sub Opcode1 = 0x00-0x2E, 0x30-0x3f : Used by three operand instructions;
  * Sub Opcode1 = 0x2F:

    * Sub Opcode2 = 0x00-0x3E : Used by two operand instructions;
    * Sub Opcode2 = 0x3F:

      * Sub Opcode3 = 0x00-0x3F: Used by one operand instructions;


The three operand instructions are having op<.cc><.f> a,b,c syntax format, and
it is the most general form of an ARC instruction:

- op<.f>      a,b,c
- op<.f>      a,b,u6
- op<.f>      b,b,s12
- op<.cc><.f> b,b,c
- op<.cc><.f> b,b,u6
- op<.f>      a,limm,c
- op<.f>      a,limm,u6
- op<.f>      0,limm,s12
- op<.cc><.f> 0,limm,c
- op<.cc><.f> 0,limm,u6
- op<.f>      a,b,limm
- op<.cc><.f> b,b,limm
- op<.f>      a,limm,limm
- op<.cc><.f> 0,limm,limm
- op<.f>      0,b,c
- op<.f>      0,b,u6
- op<.f>      0,limm,c
- op<.f>      0,limm,u6
- op<.f>      0,b,limm
- op<.f>      0,limm,limm

The two operand instructions are having the following syntax format:

- op<.f> b,c
- op<.f> b,u6
- op<.f> b,limm
- op<.f> 0,c
- op<.f> 0,u6
- op<.f> 0,limm

The one operand instructions are having the following syntax format:

- op<.f> c
- op<.f> u6
- op<.f> limm

The no-operand instructions are actually using op<.f> u6 one-operand instruction
syntax, with u6 set to zero.

On top of the formal syntax choices, we have also syntax class modifiers:

* OP1_MUST_BE_IMM which applies for SYNTAX_3OP type of extension instructions,
  specifying that the first operand of a three-operand instruction must be an
  immediate (i.e., the result is discarded). This is usually used to set the
  flags using specific instructions and not retain results.

* OP1_IMM_IMPLIED modifies syntax class SYNTAX_2OP, specifying that there is an
  implied immediate destination operand which does not appear in the syntax. In
  fact this is actually an 3-operand encoded instruction!


Examples
--------

Example 1
^^^^^^^^^

.. Using nasm here instead of asm, because asm doesn't recognize OR symbol.

.. code-block:: nasm

   .extInstruction insn1, 0x07, 0x2d, SUFFIX_NONE, SYNTAX_3OP|OP1_MUST_BE_IMM


will allow us the following syntax:

.. code-block:: asm

   insn1  0,b,c
   insn1  0,b,u6
   insn1  0,limm,c
   insn1  0,b,limm


Example 2
^^^^^^^^^

.. code-block:: nasm

   .extInstruction insn2, 0x07, 0x2d, SUFFIX_NONE, SYNTAX_2OP|OP1_IMM_IMPLIED


will allow us the following syntax:

.. code-block:: asm

   insn2  b,c
   insn2  b,u6
   insn2  limm,c
   insn2  b,limm

.. note::

   The encoding of insn2 uses the SYNTAX_3OP format (i.e., Major 0x07 and
   SubOpcode1: 0x00-0x2E, 0x30-0x3F)

Example 3
^^^^^^^^^

.. code-block:: asm

   .extInstruction insn1, 7, 0x21, SUFFIX_NONE, SYNTAX_3OP
   .extInstruction insn2, 7, 0x21, SUFFIX_NONE, SYNTAX_2OP
   .extInstruction insn3, 7, 0x21, SUFFIX_NONE, SYNTAX_1OP
   .extInstruction insn4, 7, 0x21, SUFFIX_NONE, SYNTAX_NOP

   start:
       insn1   r0,r1,r2
       insn2   r0,r1
       insn3   r1
       insn4

will result in the following encodings:

.. code-block:: objdump

   Disassembly of section .text:

   0x0000 <start>:
      0:   3921 0080               insn1   r0,r1,r2
      4:   382f 0061               insn2   r0,r1
      8:   392f 407f               insn3   r1
      c:   396f 403f               insn4

