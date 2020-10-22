Sanitizers support for ARC
==========================

Sanitizers functionality has been enabled for ARC.

Please notice that support for the sanitizers is limited for Linux, when running
with upcoming glibc (GNU C Library) port.

ARC supports the following sanitizers:

* Address,
* Memory,
* Undefined behavior and
* Leak sanitizers.

AddressSanitizer is a fast memory error detector. It consists of a compiler
instrumentation module and a run-time library. The tool can detect the following
types of bugs:

* Out-of-bounds accesses to heap, stack and globals
* Use-after-free
* Use-after-return (runtime flag ASAN_OPTIONS=detect_stack_use_after_return=1)
* Use-after-scope (clang flag -fsanitize-address-use-after-scope)
* Double-free, invalid free
* Memory leaks (experimental)

Typical slowdown introduced by AddressSanitizer is 2x.

MemorySanitizer is a detector of uninitialized reads. It consists of a compiler
instrumentation module and a run-time library.  Typical slowdown introduced by
MemorySanitizer is 3x.

UndefinedBehaviorSanitizer (UBSan) is a fast undefined behavior detector. UBSan
modifies the program at compile-time to catch various kinds of undefined
behavior during program execution, for example:

* Using misaligned or null pointer
* Signed integer overflow
* Conversion to, from, or between floating-point types which would overflow the
  destination
* See the full list of available checks below.

UBSan has an optional run-time library which provides better error reporting.
The checks have small runtime cost and no impact on address space layout or ABI.

LeakSanitizer is a run-time memory leak detector. It can be combined with
AddressSanitizer to get both memory error and leak detection, or used in a
stand-alone mode. LSan adds almost no performance overhead until the very end of
the process, at which point there is an extra leak detection phase.

We included in this document a few example as reference to the use of the
sanitizers.  For a clearer view of how to use the sanitizers, or further
examples, please refer to `Clang documentation`_


Address Sanitizer Examples
--------------------------

Heap-use-after-free
^^^^^^^^^^^^^^^^^^^

.. code-block:: c

    // To compile: clang++ -O -g -fsanitize=address heap-use-after-free.cc
    int main(int argc, char **argv) {
      int *array = new int[100];
      delete [] array;
      return array[argc];  // BOOM
    }

.. code-block:: text

    $ ./a.out
    ==5587==ERROR: AddressSanitizer: heap-use-after-free on address 0x61400000fe44 at pc 0x47b55f bp 0x7ffc36b28200
     sp 0x7ffc36b281f8
    READ of size 4 at 0x61400000fe44 thread T0
        #0 0x47b55e in main /home/test/example_UseAfterFree.cc:7
        #1 0x7f15cfe71b14 in __libc_start_main (/lib64/libc.so.6+0x21b14)
        #2 0x47b44c in _start (/root/a.out+0x47b44c)

    0x61400000fe44 is located 4 bytes inside of 400-byte region [0x61400000fe40,0x61400000ffd0)
    freed by thread T0 here:
        #0 0x465da9 in operator delete[](void*) (/root/a.out+0x465da9)
        #1 0x47b529 in main /home/test/example_UseAfterFree.cc:6

    previously allocated by thread T0 here:
        #0 0x465aa9 in operator new[](unsigned long) (/root/a.out+0x465aa9)
        #1 0x47b51e in main /home/test/example_UseAfterFree.cc:5

    SUMMARY: AddressSanitizer: heap-use-after-free /home/test/example_UseAfterFree.cc:7 main
    Shadow bytes around the buggy address:
      0x0c287fff9f70: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      0x0c287fff9f80: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      0x0c287fff9f90: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      0x0c287fff9fa0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      0x0c287fff9fb0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
    =>0x0c287fff9fc0: fa fa fa fa fa fa fa fa[fd]fd fd fd fd fd fd fd
      0x0c287fff9fd0: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
      0x0c287fff9fe0: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd fd
      0x0c287fff9ff0: fd fd fd fd fd fd fd fd fd fd fa fa fa fa fa fa
      0x0c287fffa000: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
      0x0c287fffa010: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
    Shadow byte legend (one shadow byte represents 8 application bytes):
      Addressable:           00
      Partially addressable: 01 02 03 04 05 06 07 
      Heap left redzone:     fa
      Heap right redzone:    fb
      Freed heap region:     fd
      Stack left redzone:    f1
      Stack mid redzone:     f2
      Stack right redzone:   f3
      Stack partial redzone: f4
      Stack after return:    f5
      Stack use after scope: f8
      Global redzone:        f9
      Global init order:     f6
      Poisoned by user:      f7
      ASan internal:         fe
    ==5587==ABORTING


Heap-buffer-overflow
^^^^^^^^^^^^^^^^^^^^

.. code-block:: c

    // RUN: clang++ -O -g -fsanitize=address %t && ./a.out
    int main(int argc, char **argv) {
          int *array = new int[100];
          array[0] = 0;
          int res = array[argc + 100];  // BOOM
          delete [] array;
          return res;
    }

.. code-block:: text

    ==25372==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x61400000ffd4 at pc 0x0000004ddb59 bp 0x7fffea6005a0 sp 0x7fffea600598
    READ of size 4 at 0x61400000ffd4 thread T0
        #0 0x46bfee in main /tmp/main.cpp:4:13

    0x61400000ffd4 is located 4 bytes to the right of 400-byte region
    [0x61400000fe40,0x61400000ffd0)
    allocated by thread T0 here:
        #0 0x4536e1 in operator delete[](void*)
        #1 0x46bfb9 in main /tmp/main.cpp:2:16


Stack-buffer-overflow
^^^^^^^^^^^^^^^^^^^^^

.. code-block:: c

    // RUN: clang -O -g -fsanitize=address %t && ./a.out
    int main(int argc, char **argv) {
          int stack_array[100];
          stack_array[1] = 0;
          return stack_array[argc + 100];  // BOOM
    }

.. code-block:: text

    ==7405==ERROR: AddressSanitizer: stack-buffer-overflow on address 0x7fff64740634 at pc 0x46c103 bp 0x7fff64740470 sp 0x7fff64740468
    READ of size 4 at 0x7fff64740634 thread T0
        #0 0x46c102 in main /tmp/example_StackOutOfBounds.cc:5

    Address 0x7fff64740634 is located in stack of thread T0 at offset 436 in frame
        #0 0x46bfaf in main /tmp/example_StackOutOfBounds.cc:2

      This frame has 1 object(s):
            [32, 432) 'stack_array' <== Memory access at offset 436 overflows this variable


Global-buffer-overflow
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: c

    // RUN: clang -O -g -fsanitize=address %t && ./a.out
    int global_array[100] = {-1};
    int main(int argc, char **argv) {
          return global_array[argc + 100];  // BOOM
    }

.. code-block:: text

    ==7455==ERROR: AddressSanitizer: global-buffer-overflow on address 0x000000689b54 at pc 0x46bfd8 bp 0x7fff515e5ba0 sp 0x7fff515e5b98
    READ of size 4 at 0x000000689b54 thread T0
        #0 0x46bfd7 in main /tmp/example_GlobalOutOfBounds.cc:4

    0x000000689b54 is located 4 bytes to the right of 
      global variable 'global_array' from 'example_GlobalOutOfBounds.cc' (0x6899c0) of size 400

References
----------

* `Wikipedia <https://en.wikipedia.org/wiki/AddressSanitizer>`_
* `Clang documentation`_

.. _Clang documentation: https://clang.llvm.org/docs