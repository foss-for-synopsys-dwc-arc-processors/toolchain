Working with small data section
===============================

.. highlight:: c


.. note::

   These notes are applicable to ARC GCC starting only with 2017.09 release.


Small data available access range
---------------------------------

========== ============ =========== ============
Data Type   Range        #Elements   Size
========== ============ =========== ============
char         [-256,255]        512   512 bytes
short        [-256,510]        383   766 bytes
int         [-256,1020]        319   1276 bytes
========== ============ =========== ============

The lower limit depends on the possibility to access byte-aligned datum, hence,
it is hard connected to the range of s9 short immediate (i.e., -256). Any other
access can be done using address-scaling feature of the load/store instructions.

The number of elements which we can fit in sdata section highly depends on the
data alignment properties. For example if we use only 4 byte datum, 1 byte
aligned, we can fit up to 128 elements in the section.


Sdata and address scaling mode discussion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To increase the access range for small data area, the compiler will use scaled
addresses whenever it is possible. Thus, we can extend theoretically this range
to [-1024,1020] for 32-bit data (e.g., _int_) if type aligned (i.e., 4-bytes).
However, as we cannot be 100% sure we address only 32-bit/4-byte aligned data,
we need to consider the worst case which is byte-aligned data. Thus, the
effective range is [-256,255], with possibilities to access 16-bit aligned data
(e.g., _short_) up to 510, and 32-bit aligned data (e.g., ``int`` or ``long
long``) up to 1020. While the lower limit remains set to -256. This is because
we set the linker script defined variable ``__SDATA_BEGIN__`` with an offset of
0x100.  However, this rule can be overwritten by using a custom linker script.


Controlling what goes into SDATA segment
----------------------------------------

Automatic for global data
^^^^^^^^^^^^^^^^^^^^^^^^^

Global data smaller than a given number in bytes can be placed into the sdata
section. The number of bytes can be controlled via **-G<number>** option.

For ARC, by default this number is set to 8 whenever we have double load/store
operations available (i.e., ARC HS architecture), otherwise to 4.

For example, a 8 bytes setting will allow us to place into sdata the following
variables::

   char gA[8];
   short gB[4];
   int gC[2];
   long long gD;

Notable exceptions:

* Volatile global data will not be placed into sdata section when
  **-mno-volatile-cache** option is used;
* Strings and functions never end in small data area;
* Weak variables as well not;
* No constant will end in small data area as those one, we would like to place
  into ROM.

Using named sections
^^^^^^^^^^^^^^^^^^^^

Another way to control which data goes into small data area is to use named
sections like this::

   int a __attribute__((section (".sdata"))) = 1;
   int b __attribute__((section (".sbss")));

Variables _a_ and _b_ will go into sdata/sbss sections without checking the data
type size against the **-G<number>** value. Thus, we can always control which
data is accesses via _gp_ register by setting **-G0** and using named sections
to the desired ones.  Using named section we can also place into sdata static
data.
