Impact of 64-bit integral operation on GCC toolchain
====================================================

Intro
-----

Some of the new 64 bit integral operations made available for ARCv2HS can be
used to map the C-type long long. These are:

=================== ================= ====================================
Operations          Hardware option   Possible compiler usage
=================== ================= ====================================
LDD/STD             LL64_OPTION       Load/store 64 bit data type
Chained MPYM/MPYMU  MPY_OPTION_{5,6}  Implementation of 32x32->64 bit ops
MAC/MACU            MPY_OPTION_7      Multiply and accumulate operations
MACD/MACDU          MPY_OPTION_8+     Multiply and accumulate operations
MPYD/MPYDU          MPY_OPTION_8+     Implementation of 32x32->64 bit ops
VADD2               MPY_OPTION_9      Register to register move of a 64 bit data type
=================== ================= ====================================

64-bit move operations
----------------------

First step in efficiently supporting the long long data type is implementing an
efficient way to move the 64 bit data type in and out register file as well as
within register file.  The LL64_OPTION provides us with the means for fast
transfer of 64 bit data into a processor register pair. The LDD/STD can be used
as well to implement a fast way to save/restore the registers in
prologue/epilogue of a function. 

The MPY_OPTION_9 also gives us means to move a register to another register or
a 32-bit immediate into a 64 bit register. The 32-bit immediate is signed
extended to match the 64 bit container. Hence, for a register to register move,
we can use the following instruction::

   VADD2	r0r1,r2r3,0

The above instruction takes 32 bits in the program memory  as it uses the VADD2
A,B,u6 encoding.  Although VADD2 supports predication, we cannot use it for
register to register move due to ISA limitations (e.g., the source of the
operands needs to be the input argument vadd2 .cc b,b,u6) If we want to move
and sign extend a 32-bit immediate into a 64-bit register pair, we can use the
following instruction::

   VADD2	r0r1, 0xAFEF, 0

The above instruction takes 64 bits in the program memory as we use VADD2
A,limm,u6 encoding.


Multiplication Instructions
---------------------------

The implementation of multiplication instructions depends on the multiplier
option used. A special care should be taken for chained operation when
MPY_OPTION is either 5 or 6. In these configurations, the multiplier is
blocking sequential, hence, the chained option improves the multiplication
result.  This, however, may be relevant for EM series as the HS will employ a
fully pipelined multiplier.

In general, for 32x32bit -> 64 bit type of multiplier, we use the {mpy,mpym }
instructions pair. However, when using MPY_OPTION larger than 7, we can make
use of the MPYD/MPYDU instructions. These instructions are faster and are
having a smaller impact on memory size than previous used solution. Please
remark that the MPYD/MPYDU clobbers also the 64-bit accumulator register
(ACCH,ACCL).


Multiply and Accumulate instructions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ISAv2, provides a number of MAC operations.  These are MAC/MACU for
MPY_OPTION equals to 7, and additionally MACD/MACDU when using MPY_OPTION eight
or more. The latter ones are interesting as they place the 64 bit result in a
register pair. All the MAC operations are using the 64-bit accumulator register
(ACCH,ACCL) to accumulate with, as well to place the result mac into.

Using a MAC operation needs to set up the accumulator register, as well as
collecting the result from the accumulator and place it into a general purpose
register. Hence,

.. list-table::
   :header-rows: 1

   * - Used instructions
     - Single MAC (instructions)
     - Multiple MACs, unroll case
     - Throughput
   * - MAC / MACU
     - 4 (2 loads into ACCH,ACCL; 1 MAC; 1 move from ACCH to register)
     - 4 + 1 for each unrolled MAC (2 to initialize ACCH,ACCL; 2 to move the accumulator)
     - 3+ (output/anti-dependency on ACC), 1 (otherwise)
   * - MACD / MACDU
     - 3 (2 loads to ACCH,ACCL; 1 MAC)
     - 2 + 1 for each unrolled MAC
     - 3+ (output/anti-dependency on ACC), 1 (otherwise)
   * - ADD / MPYD
     - 3 ( 2 additions; 1 MPYD)
     - 3 ops for each MAC
     - 3
   * - ADD / MPY
     - 4 (2 additions; 2 multiplications)
     - 4 ops for each MAC
     - 4

Caveats
^^^^^^^

Having the implicit 64-bit accumulator as destination for MPYD/MPYDU operations
complicate the generated code when we have an anti-dependency with a MAC
operation on the accumulator register.

The accumulator register is used as input as well as output for the MAC
operation, hence, using them in a pipelined fashion may be difficult (if, for
example, between mac operations exist an output/anti-dependency). In this case,
it is faster to use an implementation with ADD/MPYD operations.


Case study
^^^^^^^^^^

Let us consider the following C-program:

.. code-block:: c

   long long foo (long long a, int b, int c)
   {
     a += (long long )c * (long long )b;
     return a;
   }

================ ===========================
 Implementation   Resulted Code (estimated)
================ ===========================
 ADD/MPY          .. code-block:: asm

                     mpym   r5,r3,r2
                     mpy    r4,r3,r2
                     add.f  r0,r0,r4
                     adc    r1,r1,r5

 ADD/MPYD         .. code-block:: asm

                     mpyd   r2,r3,r2
                     add.f  r0,r2,r0
                     adc    r1,r3,r1

 MAC              .. code-block:: asm

                     mov    ACCL,r0
                     mov    ACCH,r1
                     mac    r0,r2,r3
                     mov    r1,ACCH

MACD (option 8)   .. code-block:: asm

                     mov    ACCL,r0
                     mov    ACCH,r1
                     macd   r0,r2,r3

MACD (option 9)   .. code-block:: asm

                     vadd2  ACC,r0,0
                     macd   r0,r2,r3

================ ===========================


Implementation matrix used by GCC
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Due to the accumulator caveats, I propose the following implementation matrix
for MAC ops:

========== === === === === === === === ===
MPY_OPTION  2   3   4   5   6   7   8   9
========== === === === === === === === ===
ADD/MPY     Y   Y   Y   Y   Y   Y   N   N
ADD/MPYD    N   N   N   N   N   N   Y   N
MAC         N   N   N   N   N   N   N   N
MACD        N   N   N   N   N   N   N   Y
========== === === === === === === === ===

