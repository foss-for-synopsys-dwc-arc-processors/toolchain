ARC GNU Tool Chain Windows Installer
====================================

This directory contains scripts to build a Windows installer for the ARC GNU
tool chain.

With a tool chain built and the required prerequsites (NSIS, Cygwin-like
environment), `buildall.sh` can be called which will build a dated set of
installers for a particular tool chain release. Note that current it is
required to edit the variables in the `PARAMS` section of `buildall.sh` for
the installer to work.

To avoid issues with long PATHs, the 8192 character "special build" is required
which can be found at http://nsis.sourceforge.net/Special_Builds#Large_strings.

`buildall.sh` uses a set of components in a `parts` subdirectory, combining
them to create a set of files to be installed. This allows for example
multiple installers to be created which share a common toolchain but have
different Eclipse versions. For each installer it then calls `makensis` on a
installer-specific top level script, which depends on the file
`arc_setup_base.nsi`. New installers can be created by duplicating a top
level script and the relevant section in `buildall.sh`.

The scripts in this folder build installers using the following components:

* $ARCBUILD/arcwin - Windows build of ARC toolchain
* arc-msys - MSYS GNU Coreutils
* arc-make - MinGW GNU Make
* arc-shell - Directory with `arcshell.bat` found in this directory.
* openocd - Windows build of ARC OpenOCD
* eclipse - Windows Eclipse C++ Environment with ARC Plugins
* openjdk - JRE for Eclipse
