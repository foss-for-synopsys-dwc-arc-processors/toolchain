#!/bin/bash
# Copyright (C) 2013 Synopsys Inc.
# Contributor Simon Cook <simon.cook@embecosm.com>

# Script to build Windows installers
# (We use () instead of {} to enable parallel builds)

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

#Params
ARCDIST="/cygdrive/c/bld/arc-dist"
TOOLCHAINS="/cygdrive/c/bld/arc-installers"
MAKENSIS="/cygdrive/c/Program Files (x86)/NSIS/makensis"
# Prefix for ARC Build INSTALL directory
ARCBUILD=latest

#Init
cd "$ARCDIST"
cp "$TOOLCHAINS"/arc-wrappers/* .
mysdate=$(date +%Y%m%d)
mydate=$(date +%Y-%m-%d)
sed -i arc_setup_base.nsi -e "s/SMALLDATEGOESHERE/$mysdate/"
sed -i arc_setup_base.nsi -e "s/DATEGOESHERE/$mydate/"

# Prepare an install directory from parts
function prepareparts() (
	echo "Preparing $1"
	dirname=$1
	rm -Rf $1/
	mkdir -p $1
	shift
	while [ "x$1" != "x" ]; do
		rsync -a "$ARCDIST/parts/$1/" "$ARCDIST/$dirname/"
		shift
	done
)

# Build installer
function build() (
  # e.g. $1 = ARCv1, $2 = arc_v1
  (cd $1; ../winbuild $1)
  echo "Building $2"
  "$MAKENSIS" $2.nsi > $2-$mysdate.log 2>&1
  echo "Done $2"
)

# For each install we build its directory and then its installer
# Note that we copy first the MSYS version of tools over then the MINGW make.
# We do this to give us a version of coreutils (rm) and make that work internally
( # ARCv1+v2
  prepareparts arc 		${ARCBUILD}/arc-win   arc-msys arc-make arc-shell openocd eclipseedit
  build arc arc_all ) &
( # ARCv1+v2 + My OpenJDK
  prepareparts arc-openjdk    ${ARCBUILD}/arc-win   arc-msys arc-make arc-shell openocd eclipseedit openjdk
  build arc-openjdk arc_all-openjdk ) &
wait

# Tidyup, moving executables + logs to output directory
mkdir $TOOLCHAINS/arc-$mysdate-output
mv *.exe *.log *.nsh *.nsi winbuild $TOOLCHAINS/arc-$mysdate-output

echo "Done"
