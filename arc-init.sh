#!/usr/bin/env bash

# Copyright (C) 2007-2017 Synopsys Inc.

# This file is a common initialization script for ARC tool chains.

# Contributor Brendan Kehoe <brendan@zen.org>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
# Contributor Anton Kolesov  <Anton.Kolesov@synopsys.com>

# RelPath function from http://www.ynform.org/w/Pub/Relpath 

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

#		      COMMON ARC TOOLKIT INITIALIZATION
#	              ---------------------------------

# Invocation Syntax
#	. arc-init.sh

# NOTE. Must be used by source from the calling script, not exec.

# On entry the variable ARC_GNU must be set to the source tree path, and the
# arc-versions.sh script must exist at the top of that source tree.

# This script will carry out the following actions:

# - register to trap certain signals with an error message and exit.

# - request any command failure to cause immediate exit (except where the
#   result is explicitly tested).

# - set the following environment variables to the sub-directories to be used:
#   - binutils
#   - gcc
#   - gdb
#   - newlib
#   - uclibc

# - check that ARC_GNU has been defined

# - check that ${ARC_GNU}/arc-versions.sh exists, and if so exit.

# - force the shell to be bash (if available) or sh, rather than any
#   alternatives.

# - define the string "-x" in the variable addShellArgs if we were invoked
#   from bash with -x, so we can reuse this in sub-commands.

# - define the shell function calcConfigPath, to set config paths, even under
#   MinGW/MSYS which does not support symbolic links and has problems with
#   "c:/" versus "/c/".

# TODO: Is this really the set of signals intended. The original script
#       specified them numerically, and they seem like a strange selection.

# 16-Mar-12: Jeremy Bennett. Name trapped signals. Use standard format and
#            width for error messages. Force to use bash or sh instead of all
#            shells, not just tcsh. Incorporate arc-relpath.sh in this script,
#            since it is the only place it is used.

# 10-Jan-13; Jeremy Bennett. Add useful functions.

# Common variables
ARC_COMMON_BUGURL="https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/issues"

# -----------------------------------------------------------------------------
# Useful functions

# In bash we typically write function blah_blah () { }. However Ubuntu default
# /bin/sh -> dash doesn't recognize the "function" keyword. Its exclusion
# seems to work for both

# Function to run a particular test in a particular directory
# Returns non-zero value if make fails.

# $1 - build directory
# $2 - tool to test (e.g. "binutils" will run "check-binutils"
# $3 - log file

#Depending of the OS pick the right sed tool
if [ "x${SED}" = "x" ]
then
  if [ "`uname -s`" = "Darwin" ]
  then
    #gsed is included as part gnu-sed package, you can install it with homebrew
    #brew install gnu-sed
    SED=gsed
  else
    SED=sed
  fi
fi
export SED

# Some targets have a version of mktemp that does not support the
# --tmpdir option for creating temporary files in a particular
# directory.  This wrapper takes a first argument a directory to
# create the temporary file in, and a second argument the pattern to
# pass to mktemp.  The function writes out the name of the newly
# created temporary file, including directory prefix, and the return
# value will be zero on success, otherwise non-zero on error.
temp_file_in_dir () {
    DIR=$1
    PATTERN=$2
    FILE=$(cd ${DIR} && mktemp "${PATTERN}")
    STATUS=$?
    if [ ${STATUS} = 0 ]
    then
        echo ${DIR}/${FILE}
    else
        echo "temp_file failed: ${FILE}"
    fi
    return ${STATUS}
}

# Make sure we stop if something failed. Since we are run with source, not exec
# the build=*.sh scripts will also do this.
trap "echo ERROR: Failed due to signal ; date ; exit 1" \
    HUP INT QUIT SYS PIPE TERM

# Exit immediately if a command exits with a non-zero status (but note this is
# not effective if the result of the command is being tested for, so we can
# still have custom error handling).
set -e
set -o pipefail

# None of the standard scripts should fall into this failure, but better to be
# safe.
if [ -z "${ARC_GNU}" ]
then
    echo "ERROR: Please set ARC_GNU to the source tree path before you"
    echo "       source this file."
    exit 1
fi

# Check we have the versions script.
if [ ! -f "${ARC_GNU}"/toolchain/arc-versions.sh ]
then
    echo "ERROR: Script requires arc-versions.sh to exist and define"
    echo "       binutils, gcc, gdb, newlib and uclibc versions."
    exit 1
fi

# Always use bash (if available) or else sh
bash_cmd=$(which bash)
if [ "x${bash_cmd}" != "x" ]
then
    SHELL=${bash_cmd}
else
    SHELL=$(which sh)
fi
export SHELL

# If using bash, if the user ran 'bash -x build-rel.sh' make it also use -x
# for the scripts we invoke.
case "${SHELLOPTS}" in
    *xtrace*) addShellArgs=-x ;;
esac

# Under MinGW/MSYS, we must do relative paths, since GCC 4.4.2 (at least) will
# fail when gengtype cannot use MSYS paths like /c/foo, instead preferring
# c:/foo.  Avoid the problem completely with a rel path like ../../foo. There
# is an assumption that if we are in a MSYS world, we are using bash (so shopt
# works).

# For standard Linux sysems, we can just use configure paths as given.
if [ "x" = "x${MSYSTEM}" ]
then
    # All other systems use the path as given.
    calcConfigPath () {
	echo "$*"
    }
else
    calcConfigPath () {

	# Need extra pattern matching, so this only works with bash
	shopt -s extglob

        path1=$(echo "${PWD}")
        path2=$(echo "$*")
        orig1=${path1}
        path1=${path1%/}
        path2=${path2%/}
        path1=${path1}/
        path2=${path2}/

        while true
	do
            if [ ! "${path1}" ]
	    then
                break
            fi

            part1=${path2#${path1}}
            if [ "${part1#/}" = "${part1}" ]
	    then
                path1="${path1%/*}"
                continue
            elif [ "${path2#${path1}}" = "${path2}" ]
	    then
                path1="${path1%/*}"
                continue
            else
		break
	    fi
        done

        part1=${path1}
        path1=${orig1#${part1}}
        depth=${path1//+([^\/])/..}
        path1=${path2#${path1}}
        path1=${depth}${path2#${part1}}
        path1=${path1##+(\/)}
        path1=${path1%/}

        if [ ! "${path1}" ]
	then
            path1=.
        fi

        printf "${path1}"
    }
fi

# Build functions for the repeated code (configure and make invocations).
# Arguments:
# $1 - name
build_dir_init() {
    echo "Building $1 ..." | tee -a "$logfile"
    mkdir -p "$build_dir/$1"
    cd "$build_dir/$1"
}

# Arguments:
# $1 - name
# $2 - src dir (optional, default is same as name)
# $3 - extra options (optional)
configure_elf32() {
    local tool=$1
    shift
    if [ $# -gt 0 ]
    then
	local src=$1
	shift
    else
	local src=$tool
    fi
    echo "  configuring..."
    # If there is / in srcdir - that this is already a path. Otherwise
    # construct path from a directory name.
    if echo "$src" | grep -q -e /
    then
	config_path="$(calcConfigPath $src)"
    else
	config_path="$(calcConfigPath "$ARC_GNU/$src")"
    fi

    if [ $IS_CROSS_COMPILING = yes ]; then
	host_opt="--host=$TOOLCHAIN_HOST"
    else
	host_opt=
    fi

    # Options --with-gnu-as --with-gnu-ld should be set explicitly, because gcc
    # is built separately from bintuils and hence "configure" cannot determine
    # if this is GNU as and ld or not.  As a result it would assume that they
    # are not and some features will be disabled.
    if ! "$config_path/configure" \
	--target=${arch}-elf32 \
	--with-cpu=$ISA_CPU \
	$ELF32_DISABLE_MULTILIB \
	--with-pkgversion="ARCompact/ARCv2 ISA elf32 toolchain $RELEASE_NAME" \
	--with-bugurl="$ARC_COMMON_BUGURL" \
	--enable-fast-install=N/A \
	--with-endian=$ARC_ENDIAN \
	$DISABLEWERROR \
	--enable-languages=c,c++ \
	--disable-shared \
	--disable-tls \
	--disable-threads \
	--prefix="$INSTALLDIR" \
	--with-gnu-as \
	--with-gnu-ld \
	$host_opt \
	$CONFIG_EXTRA \
	"$@" \
	>> "$logfile" 2>&1
    then
	echo "ERROR: failed while configuring."
	echo "See \`$logfile' for details."
	return 1
    fi
}

# Arguments:
# $1 - name
# $2 - src dir (optional, default is same as name)
# $3 - extra options (optional)
configure_linux_stage1() {
    local tool=$1
    shift
    if [ $# -gt 0 ]
    then
	local src=$1
	shift
    else
	local src=$tool
    fi
    echo "  configuring..."
    config_path="$(calcConfigPath "$ARC_GNU/$src")"

    if [ $IS_NATIVE = yes ]; then
	local native_sys_header_opt=--with-native-system-header-dir="$INSTALLDIR/include/"
    else
	local sysroot_opt=--with-sysroot="$SYSROOTDIR"
    fi


    # Options --with-gnu-as --with-gnu-ld should be set explicitly, because gcc
    # is built separately from bintuils and hence "configure" cannot determine
    # if this is GNU as and ld or not.  As a result it would assume that they
    # are not and some features will be disabled.
    if ! "$config_path/configure" \
	--target=$triplet \
	--with-cpu=$ISA_CPU \
	--disable-fast-install \
	--with-endian=$ARC_ENDIAN \
	$DISABLEWERROR \
	--disable-multilib \
	--enable-languages=c,c++ \
	--prefix="$INSTALLDIR" \
	--without-headers \
	--enable-shared \
	$thread_flags \
	--disable-libssp \
	--disable-libmudflap \
	--without-newlib \
	--disable-c99 \
	--disable-libgomp \
	--with-pkgversion="$LINUX_TOOLS_VERSION" \
	--with-bugurl="$ARC_COMMON_BUGURL" \
	--with-gnu-as \
	--with-gnu-ld \
	$CONFIG_EXTRA \
	$sysroot_opt \
	$native_sys_header_opt \
	$* \
	>> "$logfile" 2>&1
    then
	echo "ERROR: failed while configuring."
	echo "See \`$logfile' for details."
	return 1
    fi
}

# Arguments:
# $1 - name
# $2 - src dir (optional, default is same as name)
# $3 - extra options (optional)
configure_linux_stage2() {
    local tool=$1
    shift
    if [ $# -gt 0 ]
    then
	local src=$1
	shift
    else
	local src=$tool
    fi
    echo "  configuring..."
    # If there is / in srcdir - that this is already a path. Otherwise
    # construct path from a directory name.
    if echo "$src" | grep -q -e /
    then
	config_path="$(calcConfigPath $src)"
    else
	config_path="$(calcConfigPath "$ARC_GNU/$src")"
    fi

    if [ $IS_CROSS_COMPILING = yes ]; then
	local host_opt="--host=$TOOLCHAIN_HOST"
    fi

    if [ $IS_NATIVE = yes ]; then
	local native_sys_header_opt=--with-native-system-header-dir="$INSTALLDIR/include/"
    else
	local sysroot_opt=--with-sysroot="$SYSROOTDIR"
    fi

    # Options --with-gnu-as --with-gnu-ld should be set explicitly, because gcc
    # is built separately from bintuils and hence "configure" cannot determine
    # if this is GNU as and ld or not.  As a result it would assume that they
    # are not and some features will be disabled.
    if ! "$config_path/configure" \
	--target=$triplet \
	--with-cpu=${ISA_CPU} \
	$UCLIBC_DISABLE_MULTILIB \
	--with-pkgversion="$LINUX_TOOLS_VERSION" \
	--with-bugurl="$ARC_COMMON_BUGURL" \
	--enable-fast-install=N/A \
	--with-endian=$ARC_ENDIAN \
	$DISABLEWERROR \
	--enable-languages=c,c++,fortran \
	--prefix="$INSTALLDIR" \
	--enable-shared \
	--without-newlib \
	--disable-libgomp \
	--with-gnu-as \
	--with-gnu-ld \
	$host_opt \
	$CONFIG_EXTRA \
	$sysroot_opt \
	$native_sys_header_opt \
	$* \
	>> "$logfile" 2>&1
    then
	echo "ERROR: failed while configuring."
	echo "See \`$logfile' for details."
	return 1
    fi
}


# Configure application to run on ARC, that is --host=arc-snps-linux-uclibc (or
# whatever is correct for particular case).
# Arguments:
# $1 - source directory
# $2 - target triplet
# rest are passed to configure as is
configure_for_arc() {
    echo "  configuring..."

    local srcdir=$1
    local triplet=$2

    # Cannto do a simple "CFLAGS=$CFLAGS_FOR_TARGET, because if latter is empty
    # that would reset CFLAGS unnecessarily.
    local cflags=
    local cxxflags=
    if [ "$CFLAGS_FOR_TARGET" ]
    then
	cflags="CFLAGS=$CFLAGS_FOR_TARGET"
	cxxflags="CXXFLAGS=$CXXFLAGS_FOR_TARGET"
    fi
    shift 2

    # --prefix must correspond to prefix on *target* system, not where it will
    # be installed on build host - prefix value might be stored somewhere in
    # final product, therefore stored value should be one which is valid for
    # target system. To install files on build host DESTDIR should be set when
    # calling "make install". Note - prefix is set to /usr, DESTDIR should
    # point to sysroot.
    if ! $srcdir/configure --prefix=/usr --host=$triplet \
	    --with-pkgversion="$LINUX_TOOLS_VERSION"\
	    --with-bugurl="$ARC_COMMON_BUGURL" \
	    $DISABLEWERROR \
	    "$cflags" "$cxxflags" $* \
	    >> "$logfile" 2>&1
    then
	echo "ERROR: failed while configuring."
	echo "See \`$logfile' for details."
	return 1
    fi
}

# Arguments:
# $1 - step name. It should be a gerund for proper text representation, as
# "building", not "build".
# remaining - make targets. Although really can be make vars as well, like "A=aa".
make_target() {
    local step="$1"
    shift
    echo "  $step..."
    if ! make $PARALLEL $* 2>&1 | $PV >> "$logfile"
    then
	echo "ERROR: failed while $step."
	echo "See \`$logfile' for details."
	return 1
    fi
}

# Same as `make_target` but without parallelism, where order is required.
# Arguments:
# $1 - step name. It should be a gerund for proper text representation, as
# "building", not "build".
# remaining - make targets
make_target_ordered() {
    local step="$1"
    shift
    echo "  $step..."
    if ! make $* 2>&1 | $PV >> "$logfile"
    then
	echo "ERROR: failed while $step."
	echo "See \`$logfile' for details."
	return 1
    fi
}

get_multilibs() {
    # We can invoke compiler only when (built == host). When
    # cross-compiling has to use multilib of compiler in the PATH. So when
    # cross-compiling native compiler should be identical to the target
    # one.
    if [ $IS_CROSS_COMPILING = yes ]; then
	echo $(${arch}-elf32-gcc -print-multi-lib 2>/dev/null)
    else
	echo $($INSTALLDIR/bin/${arch}-elf32-gcc -print-multi-lib 2>/dev/null)
    fi
}

# Helper function to build expat, used by both uclibc and elf32 toolchains.
# Arguments:
#   $1 - download directory.
#   $2 - configure type. Basically an XXX part of `configure_XXX` call.
#        Examples: elf32, linux_stage2.
build_expat() {
    mkdir -p $1
    expat_version=2.1.0
    expat_tar=expat-${expat_version}.tar.gz
    if [ ! -s $1/$expat_tar ]; then
	$WGET -O $1/$expat_tar \
	  "http://sourceforge.net/projects/expat/files/expat/$expat_version/$expat_tar/download?use_mirror=kent"
    fi

    build_dir_init expat
    tar xzf $1/$expat_tar --strip-components=1
    configure_$2 expat $PWD
    make_target building all
    make_target installing install
}

# $1 - a configuration file or a directory with .config
# $2 - option to enable
kconfig_enable_option() {
    local config=$1
    if [ -d "$1" ]; then
        config=$1/.config
    fi

    # Delete occurrences of option $2 from $config and append
    # "$2=y" to enable this option.
    if ! grep -q "$2=y" $config ; then
        # Config file must not be empty because sed does not work
        # correctly with empty files.
        echo >> $config

        $SED -i \
            -e "/# $2 is not set/d" \
            -e "/$2=n/d" \
            -e "\$a$2=y" \
            $config
    fi
}

# $1 - a configuration file or a directory with .config
# $2 - option to disable
kconfig_disable_option() {
    local config=$1
    if [ -d "$1" ]; then
        config=$1/.config
    fi

    # Delete option $2 from $config and append "$2=n" to disable this
    # option by force.
    if ! grep -q "$2=n" $config ; then
        # Config file must not be empty because sed does not work
        # correctly with empty files.
        echo >> $config

        $SED -i \
            -e "/# $2 is not set/d" \
            -e "/$2=y/d" \
            -e "\$a$2=n" \
            $config
    fi
}

# Create a common log directory for all logs in this and sub-scripts
LOGDIR="$ARC_GNU/logs"
mkdir -p "$LOGDIR"

# Export the environment variables
export LOGDIR

# vim: noexpandtab sts=4 ts=8:
