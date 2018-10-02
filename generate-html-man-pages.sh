#!/bin/bash -ex

# Generate HTML man pages for GNU projects:
# gcc, binutils, as, ld.

# This script takes an output directory as an argument.

root_dir=$(readlink -e $(dirname $0))
build_dir=$root_dir/_html_man_build
install_dir=$root_dir/_html_man_install
output_dir=${1:-$root_dir/_html_man_install}

mkdir -p $install_dir

# GCC
mkdir -p $build_dir/gcc
pushd $build_dir/gcc

$root_dir/../gcc/gcc/configure --prefix=$install_dir

# For some reason generating gccint HTML requires building actual libiberty,
# which fails. Since we don't really need this HTML - remove the dependency.
sed -i -e 's#$(build_htmldir)/gccint/index.html[^:]##' Makefile

make -j10 html
make install-html

popd

# Binutils
mkdir -p $build_dir/binutils-gdb
pushd $build_dir/binutils-gdb

_source="$(readlink -e $root_dir/../gcc)"
$root_dir/../binutils-gdb/configure --prefix=$install_dir
# Multi-job build fails. Also it seems that this target will build many
# binutils components in the process
make html
make install-html

popd

# Create output
mkdir -p $output_dir

rsync -a --delete $install_dir/share/doc/gcc/ $output_dir/gcc
rsync -a --delete $install_dir/share/doc/as.html/ $output_dir/as
rsync -a --delete $install_dir/share/doc/binutils.html/ $output_dir/binutils
rsync -a --delete $install_dir/share/doc/ld.html/ $output_dir/ld

