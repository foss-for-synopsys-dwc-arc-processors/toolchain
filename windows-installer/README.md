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

