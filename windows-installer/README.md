ARC GNU Tool Chain Windows Installer
====================================

This directory contains scripts to build a Windows installer for the ARC GNU
tool chain.

With a tool chain built and the required prerequisites (NSIS, Cygwin-like
environment), `build-installer.sh` can be called which will build an installer
for a particular tool chain release.

To avoid issues with long PATHs, the NSIS 8192 character "special build" is required
which can be found at http://nsis.sourceforge.net/Special_Builds#Large_strings.

It is recommended to either copy contents of this directory to the location
where you are going to build IDE installer or to build installer in this
directory.


Prerequisites
-------------

Create directory for tarballs with prerequisites and download it there.
Following guide assumes that this directory is named `tars`. Required packages
are:
* Windows build of ARC toolchain
* MSYS GNU Coreutils
* MinGW GNU Make
* `arc-shell.bat` found in this directory.
* OpenOCD - Windows build of ARC OpenOCD
* Eclipse - Windows Eclipse C++ Environment with ARC Plugins and Terminal View
  plugin
* Java Runtime for Eclipse:
  http://www.oracle.com/technetwork/java/javase/downloads/index-jsp-138363.html
* MinGW runtime files
  - http://sourceforge.net/projects/mingw/files/MinGW/Base/gettext/
  - gcc-core-4.8.1-4-mingw32-dll.tar from
    http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/
  - http://sourceforge.net/projects/mingw/files/MinGW/Base/libiconv/
* MSYS runtime files
  - http://sourceforge.net/projects/mingw/files/MSYS/Base/msys-core/
  - http://sourceforge.net/projects/mingw/files/MSYS/Base/libiconv/


How to build windows installer
------------------------------

It is assumed that all prerequisites are in "tars" directory".

Prepare directories:

    $ mkdir in
    $ cd in

Copy MinGW and MSYS runtime files:

    $ tar xaf ../tars/coreutils-5.97-3-msys-1.0.13-bin.tar.lzma
    $ tar xaf ../tars/gcc-core-4.8.1-4-mingw32-dll.tar.lzma
    $ tar xaf ../tars/gettext-0.18.3.1-1-mingw32-dll.tar.lzma
    $ tar xaf ../tars/libiconv-1.14-1-msys-1.0.17-dll-2.tar.lzma
    $ tar xaf ../tars/libiconv-1.14-3-mingw32-dll.tar.lzma
    $ tar xaf ../tars/libintl-0.18.1.1-1-msys-1.0.17-dll-8.tar.lzma
    $ tar xaf ../tars/msysCORE-1.0.18-1-msys-1.0.18-bin.tar.lzma
    $ tar xaf ../tars/make-3.82.90-2-mingw32-cvs-20120902-bin.tar.lzma
    $ mv bin/{mingw32-,}make.exe

Copy arcshell.bat:

    $ cp ../tars/arcshell.bat .

Copy OpenOCD:

    $ tar xaf ../tars/openocd-ide-1.1.0-RC2-g9e9d366.tgz --strip-components=1

Copy tool chain:

    $ tar xaf ../tars/toolchain-ide-1.1.0-RC3.tgz --strip-components=1
    $ tar xaf ../tars/toolchain-ide-1.1.0-RC3_eb.tgz --strip-components=1

Copy Eclipse

    $ mv ../tars/eclipse .

Copy Java runtime environment:

    $ mkdir eclipse/jre
    $ cd eclipse/jre
    $ tar xaf ${PATH_TO_JRE_TAR_GZ} --strip-components=1
    $ cd ../../..

Generate installer an uninstaller sections:

    $ ./gen-nsis-sections.sh

Generate installer. "arcver" NSIS variable must be defined, for example:

    $ /cygdrive/c/Program\ Files\ \(x86\)/NSIS/makensis.exe /Darcver=2014.12 \
      installer-standard.nsi


Notes cross-compiling for Windows
---------------------------------

In general you can rely on `Makefile.release` file in the upper directory for
toolchain building. Further instructions basically explain what this Makefile
does.

When cross-compiling for Windows from Linux, a couple of changes need to be
made to the `build-elf32.sh` script. Note that a native (Linux) build of the
toolchain needs to be in a user's PATH to build newlib/libgcc/libstdc++-v3.

The first is that `--host=i686-w64-mingw32 --build=x86_64-linux-gnu` needs to
be added to the configure command. This sets the use of a Windows toolchain
(i686-w64-mingw32-gcc, etc.) to be used to build the toolchain.

The second is that `gcc/auto-build.h` needs to be copied into the build
directory after configuring but before building (as it is does not generate
itself). This is the same file as `gcc/auto-host.h` created when building a
native toolchain; this file can be copied and renamed. The build should
then continue as normal.

Third is that generated `gcc/auto-host.h` will contain a code that will cause a
problem on Ubuntu MinGW, so `define caddr_t char *` should be removed.

Note that cross-compiling only works for the ELF32 toolchain, so `--no-uclibc`
should be passed as an option to `build-all.sh`. CGEN simulator cannot be built
for Windows, so --no-sim option should be passed as well (./build-all.sh will
disable simulator automatically only when build is done on Windows with MSyS).

To ease up the process this directory contains `build-elf32_windows.patch` that
will patch build-elf32.sh to do everything mentioned. It will copy auto-build.h
from this directory. If you have auto-host.h from the native built you might
want to copy it here instead of the one checked into the repository. This patch
will not set --no-sim and --no-uclibc for you though.

