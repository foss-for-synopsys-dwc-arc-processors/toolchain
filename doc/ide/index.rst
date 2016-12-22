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

* OS: Windows 7, Windows 10, Ubuntu Linux 14.04 LTS and RedHat Enterprise Linux 6
  Development Host Systems
* Eclipse Oxygen (4.7) (part of Windows installer)
* CDT version 9.3.0 (part of Windows installer)
* Java VM version >= 1.7 is required (part of Windows installer)
* On Linux both 32bit and 64-bit versions of Eclipse are supported, on Windows only
  32-bit Eclipse installations are supported. Eclipse 64-bit installation is not supported,
  so it is required to run 32-bit version of Eclipse on 64-bit Windows versions, to overcome
  this limitation.

.. note::
    Before you begin, refer to the EM Starter Kit
    guide and follow the instructions on how to connect EM Starter Kit to
    your PC. This is required for the Eclipse IDE GDB debugger to successfully
    download and debug programs on the target.

Creating and building an application
------------------------------------
.. toctree::

   arc-project-templates
   building-user-guide
   building-linux-uclibc-applications

Debugging
---------
.. toctree::

   creating-a-debug-configuration
   debugging-with-openocd
   debugging-with-opellaxd
   debugging-with-nsim
   debugging-with-custom-gdb-server
   debugging-with-running-gdb-server
   debugging-a-big-endian-application-on-em-sk

Miscellaneous
-------------
.. toctree::

   creating-eclipse-plugins-release-zip-file
