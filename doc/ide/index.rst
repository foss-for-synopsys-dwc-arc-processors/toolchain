ARC GNU IDE
===========

The ARC GNU Eclipse IDE consists of the Eclipse IDE combined with an Eclipse
CDT Managed Build Extension plug-in for the ARC GNU Toolchain and GDB embedded
debugger plug-in for ARC, based on the Zylin Embedded CDT plug-in.  The ARC GNU
IDE supports the development of managed C/C++ applications for ARC processors
using the ARC GNU toolchain for bare metal applications (elf32).

The ARC GNU IDE provides support for the following functionality:

* Support for the ARC EM, ARC HS, ARC 600 and ARC 700 Processors
* Support for little and big endian configurations
* Ability to create C/C++ projects using the ARC elf32 cross-compilation
  toolchain
* Configuration of toolchain parameters per project
* Configuration of individual options (such as preprocessor, optimization,
  warnings, libraries, and debugging levels) for each toolchain component:

  * GCC Compiler
  * GDB Debugger
  * GAS assembler
  * Size binutils utility, etc.

* Support for Synopsys EM Starter Kit and AXS10x.
* Configuration of debug and run configurations for supported FPGA Development
  Systems and debug probes (Digilent HS1/HS2 or Ashling Opella-XD).
* GDB-based debugging using **Debug** perspective providing detailed debug
  information (including breakpoints, variables, registers, and disassembly)

ARC GNU plugins for Eclipse have following requirements to the system:

* OS: Windows 10, Ubuntu Linux 16.04 LTS and CentOS 7 development host systems
* Eclipse 2018-12 (part of Windows installer)
* CDT version 9.6.0 (part of Windows installer)
* Java VM version >= 1.8 is required (part of Windows installer)

.. note::
    Before you begin, refer to the EM Starter Kit
    guide and follow the instructions on how to connect EM Starter Kit to
    your PC. This is required for the Eclipse IDE GDB debugger to successfully
    download and debug programs on the target.

Getting Started
---------------
.. toctree::
   installation
   getting-started-with-em-starter-kit
   getting-started-with-nsim

Creating and building an application
------------------------------------
.. toctree::

   arc-project-templates
   building-user-guide
   building-linux-uclibc-applications
   how-to-use-custom-toolchain

Debugging
---------
.. toctree::

   using-debug-perspective
   creating-a-debug-configuration
   debugging-with-openocd
   how-to-use-openocd-on-windows
   debugging-with-opellaxd
   debugging-with-nsim
   debugging-with-custom-gdb-server
   debugging-with-running-gdb-server
   debugging-a-big-endian-application-on-em-sk

Miscellaneous
-------------
.. toctree::

   preferences
   creating-eclipse-plugins-release-zip-file