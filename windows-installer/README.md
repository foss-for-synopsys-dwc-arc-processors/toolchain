ARC GNU Tool Chain Windows Installer
====================================

This directory contains scripts to build a Windows installer for the ARC GNU
tool chain.

With a tool chain built and the required prerequisites (NSIS, Cygwin-like
environment), `buildall.sh` can be called which will build a dated set of
installers for a particular tool chain release. Note that current it is
required to edit the variables in the `PARAMS` section of `buildall.sh` for
the installer to work.

To avoid issues with long PATHs, the 8192 character "special build" is required
which can be found at http://nsis.sourceforge.net/Special_Builds#Large_strings.

It is recommended to either copy contents of this directory to the location where you are going to build IDE installer or to build installer in this directory.


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

Prepare directories:

    $ mkdir in

Copy MinGW and MSYS runtime files:

    $ To be added later

Copy tool chain:

    $ rsync -avP ${PATH_TO_TOOLCHAIN_INSTALL}/ in

Copy OpenOCD:

    $ rsync -av ${PATH_TO_OPENOCD}/ in

Copy Eclipse

    $ rsync -av ${PATH_TO_ECLIPSE}/ in/eclipse

Copy Java runtime environment:

    $ mkdir in/eclipse/jre
    $ cd in/eclipse/jre
    $ tar xaf ${PATH_TO_JRE_TAR_GZ} --strip-components=1
    $ cd -

Copy arcshell.bat:

    $ rsync -av ${PATH_TO_ARCSHELL} in/

MSYS Coreutils:

    $ cd in
    $ tar xaf ${PATH_TO_COREUTILS_TAR}/

Copy Make (note the need to rename make file):

    $ tar xaf ${PATH_TO_MAKE_TAR}
    $ cp bin/{mingw32-,}make.exe
    $ cd -

Generate installer an uninstaller sections:

    $ ./gen-nsis-sections.sh

Generate installer:

    $ /cygdrive/c/Program\ Files\ \(x86\)/NSIS/makensis.exe installer-standard.nsi


Notes cross-compiling for Windows
---------------------------------

When cross-compiling for Windows from Linux, a couple of changes need to be
made to the `build-elf32.sh` script. Note that a native (Linux) build of the
toolchain needs to be in a user's PATH to build newlib/libgcc/libstdc++-v3.

The first is that `--host=i686-w64-mingw32 --build=x86_64-linux-gnu` needs to
be added to the configure command. This sets the use of a Windows toolchain
(i486-mingw32-gcc, etc.) to be used to build the toolchain.

The second is that `gcc/auto-build.h` needs to be copied into the build
directory after configuring but before building (as it is does not generate
itself). This is the same file as `gcc/auto-host.h` created when building a
native toolchain; this file can be copied and renamed. The build should
then continue as normal.

Note that cross-compiling only works for the ELF32 toolchain, so `--no-uclibc`
should be passed as an option to `build-all.sh`.

