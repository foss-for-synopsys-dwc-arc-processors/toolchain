##############################################################################
# Copyright (C) 2014-2016 Synopsys Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

#
# How to use:
#
# This is a script to create prebuilt packages of GNU Toolchain
#
# 1. Checkout toolchain directory to desired branch. Create tags if needed.
#
# 2. Run "make -f release.mk RELEASE=<release> toolchain". If you do not
# want build-all.sh to checkout directories, then do "touch
# ../release_output/.stamp_checked_out before running makefile.  Note that
# "toolchain" target will build only toolchain prebuilts, nothing else, but it
# also doesn't have other prerequisites. Target "all" will also build IDE and
# OpenOCD, however this also requires additional preparations.
#

#
# Configuration
#
CONFIG_STATIC_TOOLCHAIN := n

DEPLOY_DESTINATION =

# URL base for git repositories.
GIT_URL_BASE := git@github.com:foss-for-synopsys-dwc-arc-processors

# Whether there is a directory that contains already cloned git repositories
# that can be used as a git reference. If specified than it *must* contain
# copies of all repositories that will be used.
GIT_REFERENCE_ROOT :=

IDE_PLUGIN_LOCATION :=

JAVA_VERSION := 8u66

ROOT := $(realpath ..)

THIRD_PARTY_SOFTWARE_LOCATION :=

# Must be a folder available to Windows host, e.g. Linux folder shared via
# Samba.
WINDOWS_WORKSPACE := $(ROOT)/windows_workspace

# Include overriding configuration
-include release.config


#
# Helpers
#

define create_dir
	mkdir -p $@
endef

# Create tarball for release
# :param $1 - name of directory to tar. Directory must be in the $O.
define create_tar
       cd $O && tar caf $1$(TAR_EXT) $1/
endef

# Clone git repository
# $1 - tool name
# $2 - directory name
ifeq ($(GIT_REFERENCE_ROOT),)
define git_clone
	$(GIT) clone -q $(GIT_URL_BASE)/$1.git $(ROOT)/$2
endef
else
define git_clone
	$(GIT) clone -q --reference=$(GIT_REFERENCE_ROOT)/$2 \
	    $(GIT_URL_BASE)/$1.git $(ROOT)/$2
endef
endif

#
# Build flags common to all toolchains
#

BUILDALLFLAGS := --disable-werror --strip --rel-rpaths --no-auto-pull \
--no-auto-checkout --elf32-strip-target-libs

EXTRA_CONFIG_FLAGS += --with-python=no
ifeq ($(CONFIG_STATIC_TOOLCHAIN),y)
EXTRA_CONFIG_FLAGS += LDFLAGS=-static
endif
BUILDALLFLAGS += --config-extra '$(EXTRA_CONFIG_FLAGS)'

#
# Output artifacts
#
O := ../release_output
# Use -a when invoking tar, then we can easily change to .tar.xz if we want.
TAR_EXT := .tar.gz

# Toolchain: source tarball
# This variable should use .. instead of $(ROOT) so that tar will auto-remove
# .. from file paths. Perhaps this ugliness can be fixed with --transform?
TOOLS_SOURCE_CONTENTS := $(addprefix ../,binutils cgen gcc gdb newlib toolchain uClibc)
TOOLS_SOURCE_DIR := $O/arc_gnu_$(RELEASE)_sources

# Toolchain: baremetal for Linux hosts
TOOLS_ELFLE_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_elf32_le_linux_install
TOOLS_ELFBE_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_elf32_be_linux_install

# Toolchain: baremetal for Windows hosts
TOOLS_ELFLE_DIR_WIN := arc_gnu_$(RELEASE)_prebuilt_elf32_le_win_install
TOOLS_ELFBE_DIR_WIN := arc_gnu_$(RELEASE)_prebuilt_elf32_be_win_install

# Toolchain: linux
TOOLS_LINUXLE_700_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_arc700_linux_install
TOOLS_LINUXBE_700_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_uclibc_be_arc700_linux_install
TOOLS_LINUXLE_HS_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_archs_linux_install
TOOLS_LINUXBE_HS_DIR_LINUX := arc_gnu_$(RELEASE)_prebuilt_uclibc_be_archs_linux_install

# IDE: vanilla Eclipse variables
ECLIPSE_VERSION := mars-1
ECLIPSE_VANILLA_ZIP_WIN := eclipse-cpp-$(ECLIPSE_VERSION)-win32.zip
ECLIPSE_VANILLA_TGZ_LINUX := eclipse-cpp-$(ECLIPSE_VERSION)-linux-gtk-x86_64.tar.gz
# Coma separated list
ECLIPSE_REPO := http://download.eclipse.org/releases/luna
# Coma separated list
ECLIPSE_PREREQ := org.eclipse.tm.terminal.serial,org.eclipse.tm.terminal.view
ECLIPSE_DL_LINK_BASE := http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/mars/1

# Java.
JRE_TGZ_LINUX := jre-$(JAVA_VERSION)-linux-x64.tar.gz
JRE_TGZ_WIN   := jre-$(JAVA_VERSION)-windows-i586.tar.gz

# IDE: output related variables
IDE_INSTALL_LINUX := arc_gnu_$(RELEASE)_ide_linux_install
IDE_EXE_WIN := arc_gnu_$(RELEASE)_ide_win_install.exe
IDE_TGZ_LINUX := $(IDE_INSTALL_LINUX).tar.gz
IDE_PLUGINS_ZIP := arc_gnu_$(RELEASE)_ide_plugins.zip

# OpenOCD
OOCD_DIR_WIN := arc_gnu_$(RELEASE)_openocd_win_install
OOCD_DIR_LINUX := arc_gnu_$(RELEASE)_openocd_linux_install
# Should be created and checked out manually before running this Makefile.
OOCD_SRC_DIR_LINUX := $(ROOT)/openocd

# List of files that will be uploaded to GitHub Release.
UPLOAD_ARTIFACTS = \
    $(TOOLS_SOURCE_DIR)$(TAR_EXT) \
    $(TOOLS_ELFLE_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_ELFBE_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXLE_700_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXBE_700_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXLE_HS_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXBE_HS_DIR_LINUX)$(TAR_EXT) \
    $(IDE_TGZ_LINUX) \
    $(IDE_EXE_WIN) \
    $(IDE_PLUGINS_ZIP)

# List of files that will be deployed internally. Is a superset of "upload"
# artifacts.
DEPLOY_ARTIFACTS = \
    $(UPLOAD_ARTIFACTS) \
    $(TOOLS_ELFLE_DIR_WIN)$(TAR_EXT) \
    $(TOOLS_ELFBE_DIR_WIN)$(TAR_EXT) \
    $(OOCD_DIR_WIN).zip \
    $(OOCD_DIR_LINUX)$(TAR_EXT)

# md5sum
MD5SUM_FILE := md5.sum

#
# Check prerequisite variables
#
ifeq ($(RELEASE),)
$(error RELEASE variable can not be empty)
endif

ifneq ($(filter upload create-tag push-tag, $(MAKECMDGOALS)),)
ifeq ($(RELEASE_TAG),)
$(error RELEASE_TAG variable can not be empty for this target)
endif
endif

ifneq ($(filter upload, $(MAKECMDGOALS)),)
ifeq ($(RELEASE_NAME),)
$(error RELEASE_NAME variable can not be empty for "upload" target)
endif
endif

#
# Configuration
#
CP = rsync -a
GIT = git
PYTHON = /depot/Python-3.4.3/bin/python3

#
# Human friendly aliases
#
.PHONY: checkout source-tarball elf-le-build elf-be-build elf-le elf-be all \
    windows ide openocd-win \
    openocd openocd-tar openocd-build openocd-install openocd-configure openocd-bootstrap \
    toolchain

all: $O/$(MD5SUM_FILE)
	@echo "MD5 sums:"
	@cat $<

toolchain: \
    $O/.stamp_source_tarball \
    $O/.stamp_elf_le_tarball $O/.stamp_elf_be_tarball \
    $O/.stamp_linux_le_700_tarball $O/.stamp_linux_be_700_tarball \
    $O/.stamp_linux_le_hs_tarball $O/.stamp_linux_be_hs_tarball \
    $O/.stamp_elf_le_windows_tarball $O/.stamp_elf_be_windows_tarball

$O/$(MD5SUM_FILE): \
    $O/.stamp_source_tarball \
    $O/.stamp_elf_le_tarball $O/.stamp_elf_be_tarball \
    $O/.stamp_linux_le_700_tarball $O/.stamp_linux_be_700_tarball \
    $O/.stamp_linux_le_hs_tarball $O/.stamp_linux_be_hs_tarball \
    $O/.stamp_elf_le_windows_tarball $O/.stamp_elf_be_windows_tarball \
    $O/$(OOCD_DIR_WIN).zip $O/$(OOCD_DIR_WIN).tar.gz \
    $O/.stamp_ide_linux_tar $O/$(IDE_PLUGINS_ZIP) \
    $O/$(OOCD_DIR_LINUX).tar.gz
	cd $O && md5sum $(UPLOAD_ARTIFACTS) > $@


checkout: $O/.stamp_checked_out

source-tarball: $O/.stamp_source_tarball

elf-le-build: $O/.stamp_elf_le_built

elf-be-build: $O/.stamp_elf_be_built

elf-le: $O/.stamp_elf_le_tarball

elf-be: $O/.stamp_elf_be_tarball

windows: $O/.stamp_elf_le_windows_tarball $O/.stamp_elf_be_windows_tarball

ide: $O/.stamp_ide_linux_tar $O/$(IDE_PLUGINS_ZIP)

#
# Initial preparations
#

.PHONY: clone
clone:
	$(call git_clone,binutils-gdb,binutils)
	$(call git_clone,cgen,cgen)
	$(call git_clone,gcc,gcc)
	$(call git_clone,binutils-gdb,gdb)
	$(call git_clone,newlib,newlib)
	$(call git_clone,linux,linux)
	$(call git_clone,uClibc,uClibc)
	$(call git_clone,openocd,openocd)


.PHONY: copy-external
copy-external: | $O
ifeq ($(IDE_PLUGIN_LOCATION),)
	$(error IDE_PLUGIN_LOCATION must be set to do copy-external)
endif
ifeq ($(THIRD_PARTY_SOFTWARE_LOCATION),)
	$(error THIRD_PARTY_SOFTWARE_LOCATION must be set to do copy-external)
endif
ifeq ($(OPENOCD_WINDOWS_LOCATION),)
	$(error OPENOCD_WINDOWS_LOCATION must be set to do copy-external)
endif
	# Copy IDE plugin
	$(CP) $(IDE_PLUGIN_LOCATION)/$(IDE_PLUGINS_ZIP) $O
	# Copy JRE. Original tarballs from Oracle do not have .tar in filenames.
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_TGZ_LINUX:.tar.gz=.gz) \
	    $O/$(JRE_TGZ_LINUX)
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_TGZ_WIN:.tar.gz=.gz) \
	    $O/$(JRE_TGZ_WIN)
	# Copy Eclipse
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_TGZ_LINUX) $O
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_ZIP_WIN) $O
	# Copy OpenOCD for Windows
	$(CP) $(OPENOCD_WINDOWS_LOCATION)/$(OOCD_DIR_WIN)$(TAR_EXT) $O

.PHONY: prerequisites
prerequisites: clone copy-external


.PHONY: distclean
distclean: clean
	rm -rf $(ROOT)/{binutils,cgen,gcc,gdb,newlib,linux,uClibc}
	rm -rf $(ROOT)/openocd

#
# Build targets
#
$O:
	mkdir -p $@

# Checkout sources
$O/.stamp_checked_out: | $O
	./build-all.sh --auto-pull --auto-checkout --no-elf32 --no-uclibc
	touch $@

# Create source tarball
$O/.stamp_source_tarball: $O/.stamp_checked_out
	tar --exclude-vcs -c -z -f $(TOOLS_SOURCE_DIR)$(TAR_EXT) --exclude=$O \
	    --transform="s|^|arc_gnu_$(RELEASE)_sources/|" $(TOOLS_SOURCE_CONTENTS)
	touch $@

$O/.stamp_elf_le_built: $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_ELFLE_DIR_LINUX) \
	    --no-uclibc --release-name $(RELEASE)
	touch $@

$O/.stamp_elf_be_built: $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_ELFBE_DIR_LINUX) \
	    --no-uclibc --release-name $(RELEASE) --big-endian
	touch $@

$O/.stamp_elf_le_tarball: $O/.stamp_elf_le_built
	$(call create_tar,$(TOOLS_ELFLE_DIR_LINUX))
	touch $@

$O/.stamp_elf_be_tarball: $O/.stamp_elf_be_built
	$(call create_tar,$(TOOLS_ELFBE_DIR_LINUX))
	touch $@

$O/.stamp_linux_le_700_built: $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXLE_700_DIR_LINUX) \
	    --no-elf32 --release-name $(RELEASE) --cpu arc700
	touch $@

$O/.stamp_linux_le_hs_built: $O/.stamp_linux_le_700_built $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXLE_HS_DIR_LINUX) \
	    --no-elf32 --release-name $(RELEASE) --cpu archs
	cp -al $O/$(TOOLS_LINUXLE_700_DIR_LINUX)/arc-snps-linux-uclibc/sysroot \
	    $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)/arc-snps-linux-uclibc/sysroot-arc700
	touch $@

$O/.stamp_linux_be_700_built: $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXBE_700_DIR_LINUX) \
	    --no-elf32 --release-name $(RELEASE) --big-endian --cpu arc700
	touch $@

$O/.stamp_linux_be_hs_built: $O/.stamp_linux_be_700_built $O/.stamp_checked_out
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXBE_HS_DIR_LINUX) \
	    --no-elf32 --release-name $(RELEASE) --big-endian --cpu archs
	cp -al $O/$(TOOLS_LINUXBE_700_DIR_LINUX)/arceb-snps-linux-uclibc/sysroot \
	    $O/$(TOOLS_LINUXBE_HS_DIR_LINUX)/arceb-snps-linux-uclibc/sysroot-arc700
	touch $@

$O/.stamp_linux_le_700_tarball: $O/.stamp_linux_le_700_built
	$(call create_tar,$(TOOLS_LINUXLE_700_DIR_LINUX))
	touch $@

$O/.stamp_linux_le_hs_tarball: $O/.stamp_linux_le_hs_built
	$(call create_tar,$(TOOLS_LINUXLE_HS_DIR_LINUX))
	touch $@

$O/.stamp_linux_be_700_tarball: $O/.stamp_linux_be_700_built
	$(call create_tar,$(TOOLS_LINUXBE_700_DIR_LINUX))
	touch $@

$O/.stamp_linux_be_hs_tarball: $O/.stamp_linux_be_hs_built
	$(call create_tar,$(TOOLS_LINUXBE_HS_DIR_LINUX))
	touch $@

#
# Windows build
#

WINDOWS_TRIPLET := i686-w64-mingw32
WINDOWS_SYSROOT := /usr/$(WINDOWS_TRIPLET)/sys-root/mingw

# Helper function to copy mingw .dll files to installation directories with
# executable files. There are several directories and for simplicity all .dlls
# are copied to all target location.
#
# :param $1 - toolchain installation directory, e.g. $O/$(TOOLS_ELFLE_DIR_WIN).
# :param $2 - toolchain triplet, e.g. arc-elf32, arceb-elf32, etc.
ifneq ($(CONFIG_STATIC_TOOLCHAIN),y)
define copy_mingw_dlls
	for t in $(addprefix $1/,bin $2/bin libexec/gcc/$2/*/); do\
		cp -a $(WINDOWS_SYSROOT)/bin/* $$t ; \
	done
endef
endif

$O/.stamp_elf_le_windows_built: $O/.stamp_checked_out $O/.stamp_elf_le_built
	PATH=$(shell readlink -e $O/$(TOOLS_ELFLE_DIR_LINUX)/bin):$$PATH \
	     ./build-all.sh $(BUILDALLFLAGS) \
	     --install-dir $O/$(TOOLS_ELFLE_DIR_WIN) --no-uclibc --no-sim \
	     --release-name $(RELEASE) --host $(WINDOWS_TRIPLET) --no-system-expat \
	     --no-elf32-gcc-stage1
	$(call copy_mingw_dlls,$O/$(TOOLS_ELFLE_DIR_WIN),arc-elf32)
	touch $@

$O/.stamp_elf_be_windows_built: $O/.stamp_checked_out $O/.stamp_elf_be_built
	# Install toolchain in the same dir as little endian
	PATH=$(shell readlink -e $O/$(TOOLS_ELFBE_DIR_LINUX))/bin:$$PATH \
	     ./build-all.sh $(BUILDALLFLAGS) \
	     --install-dir $O/$(TOOLS_ELFBE_DIR_WIN) --no-uclibc --big-endian --no-sim \
	     --release-name $(RELEASE) --host $(WINDOWS_TRIPLET) --no-system-expat \
	     --no-elf32-gcc-stage1
	$(call copy_mingw_dlls,$O/$(TOOLS_ELFBE_DIR_WIN),arceb-elf32)
	touch $@

$O/.stamp_elf_le_windows_tarball: $O/.stamp_elf_le_windows_built
	$(call create_tar,$(TOOLS_ELFLE_DIR_WIN))
	touch $@

$O/.stamp_elf_be_windows_tarball: $O/.stamp_elf_be_windows_built
	$(call create_tar,$(TOOLS_ELFBE_DIR_WIN))
	touch $@

#
# IDE related targets
#
$O/$(ECLIPSE_VANILLA_TGZ_LINUX):
	wget -nv -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_TGZ_LINUX)&r=1'

$O/$(ECLIPSE_VANILLA_ZIP_WIN):
	wget -nv -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_ZIP_WIN)&r=1'

# Install ARC plugins from .zip file and install prerequisites in Eclipse.
# Similar invocation is in windows/build-release.sh. Those invocations must be
# in sync.
$O/.stamp_ide_linux_eclipse: $O/$(ECLIPSE_VANILLA_TGZ_LINUX) $O/$(IDE_PLUGINS_ZIP)
	mkdir -p $O/$(IDE_INSTALL_LINUX)
	tar xaf $< -C $O/$(IDE_INSTALL_LINUX)
	$O/$(IDE_INSTALL_LINUX)/eclipse/eclipse \
	    -application org.eclipse.equinox.p2.director \
	    -noSplash \
	    -repository $(ECLIPSE_REPO),jar:file:$(realpath $O/$(IDE_PLUGINS_ZIP))\!/ \
	    -installIU $(ECLIPSE_PREREQ),com.arc.cdt.feature.feature.group
	# Eclipse will create a bunch of repos with local paths, that will not
	# work for end-users, hence those repos must be manually removed.
	sed -i -e "/$(subst /,_,$O)/ d" \
	    $O/$(IDE_INSTALL_LINUX)/eclipse/p2/org.eclipse.equinox.p2.engine/profileRegistry/epp.package.cpp.profile/.data/.settings/org.eclipse.equinox.p2.*
	touch $@

$O/.stamp_ide_linux_tar: \
	$O/$(OOCD_DIR_LINUX)/bin/openocd \
	$O/.stamp_ide_linux_eclipse \
	$O/.stamp_elf_be_built $O/.stamp_elf_le_built \
	$O/.stamp_linux_be_hs_built $O/.stamp_linux_le_hs_built
	cp -al $O/$(TOOLS_ELFLE_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_ELFBE_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_LINUXBE_HS_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	mkdir $O/$(IDE_INSTALL_LINUX)/eclipse/jre
	tar xaf $O/$(JRE_TGZ_LINUX) -C $O/$(IDE_INSTALL_LINUX)/eclipse/jre \
	    --strip-components=1
	cp -al $O/$(OOCD_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	tar caf $O/$(IDE_TGZ_LINUX) -C $O $(IDE_INSTALL_LINUX)
	touch $@

#
# OpenOCD
#
openocd: $(OOCD_SRC_DIR_LINUX)/src/openocd
openocd-bootstrap: $(OOCD_SRC_DIR_LINUX)/configure
openocd-configure: $(OOCD_SRC_DIR_LINUX)/Makefile
openocd-build: $(OOCD_SRC_DIR_LINUX)/src/openocd
openocd-install: $(OOCD_DIR_LINUX)/bin/openocd
openocd-tar: $O/$(OOCD_DIR_LINUX).tar.gz
openocd: openocd-tar

$(OOCD_SRC_DIR_LINUX)/configure:
	cd $(OOCD_SRC_DIR_LINUX) && ./bootstrap

$(OOCD_SRC_DIR_LINUX)/Makefile: $(OOCD_SRC_DIR_LINUX)/configure
	cd $(OOCD_SRC_DIR_LINUX) && ./configure --enable-ftdi --disable-werror \
	    --prefix=$(abspath $O/$(OOCD_DIR_LINUX))

$(OOCD_SRC_DIR_LINUX)/src/openocd: $(OOCD_SRC_DIR_LINUX)/Makefile
	$(MAKE) -C $(OOCD_SRC_DIR_LINUX) all pdf

$O/$(OOCD_DIR_LINUX)/bin/openocd: $(OOCD_SRC_DIR_LINUX)/src/openocd
	$(MAKE) -C $(OOCD_SRC_DIR_LINUX) install install-pdf

$O/$(OOCD_DIR_LINUX).tar.gz: $O/$(OOCD_DIR_LINUX)/bin/openocd
	tar -C $O -caf $O/$(OOCD_DIR_LINUX).tar.gz $(OOCD_DIR_LINUX)/

# Make OpenOCD for Windows zip file.
openocd-win: $O/$(OOCD_DIR_WIN).zip $O/$(OOCD_DIR_WIN).tar.gz

#  Tarball is an order-only dependency, because untarred directory will
#  preserve original timestamps, therefore it would be _older_ then the
#  tarball, thus each time make would try to untar it again.
$O/$(OOCD_DIR_WIN): | $O/$(OOCD_DIR_WIN)$(TAR_EXT)
	tar -C $(dir $@) -xaf $|

$O/$(OOCD_DIR_WIN).zip: $O/$(OOCD_DIR_WIN)
	cd $O && zip -q -r $(notdir $@) $(OOCD_DIR_WIN)/


#
# Create workspace for Windows script
#
.PHONY: windows-workspace
windows-workspace: $O/.stamp_windows_workspace

$(WINDOWS_WORKSPACE):
	mkdir -p $@/packages

$O/.stamp_windows_workspace: $O/.stamp_elf_le_windows_tarball \
    $O/.stamp_elf_be_windows_tarball | $(WINDOWS_WORKSPACE)
ifeq ($(THIRD_PARTY_SOFTWARE_LOCATION),)
	$(error THIRD_PARTY_SOFTWARE_LOCATION must be set to create windows workspace)
endif
	$(CP) $O/$(TOOLS_ELFLE_DIR_WIN)$(TAR_EXT) \
	      $O/$(TOOLS_ELFBE_DIR_WIN)$(TAR_EXT) \
	      $O/$(IDE_PLUGINS_ZIP) \
	      $O/$(OOCD_DIR_WIN)$(TAR_EXT) \
	      $O/$(ECLIPSE_VANILLA_ZIP_WIN) \
	      $O/$(JRE_TGZ_WIN) \
	      $(addprefix $(THIRD_PARTY_SOFTWARE_LOCATION)/,make coreutils) \
	      $(WINDOWS_WORKSPACE)/packages/
	$(CP) $(ROOT)/toolchain $(WINDOWS_WORKSPACE)/


#
# Create tag
#
create-tag:
	./tag-release.sh $(RELEASE_TAG)
	# Semihardcoded OpeOCD branch is ugly, but is OK for now.
	$(GIT) --git-dir=$(OOCD_SRC_DIR_LINUX)/.git checkout arc-0.9-dev-$(RELEASE)
	$(GIT) --git-dir=$(OOCD_SRC_DIR_LINUX)/.git tag $(RELEASE_TAG)

#
# Push tag
#
push-tag:
	./push-release.sh $(RELEASE_TAG)
	$(GIT) --git-dir=$(OOCD_SRC_DIR_LINUX)/.git push origin $(RELEASE_TAG)

#
# Deploy to shared file system
#
.PHONY: deploy
deploy: $O/$(MD5SUM_FILE) $(addprefix $O/,$(DEPLOY_ARTIFACTS))
ifeq ($(DEPLOY_DESTINATION),)
	$(error DEPLOY_DESTINATION must be set to run 'deploy' target)
endif
	$(CP) $^ $(DEPLOY_DESTINATION)/


#
# Upload
#
# This is not a part of a default target. Upload should be triggered manually.
# RELEASE_TAG and RELEASE_NAME mustbe set to something
upload: $O/$(MD5SUM_FILE)
	$(PYTHON) github/create-release.py --owner=foss-for-synopsys-dwc-arc-processors \
	    --project=toolchain --tag=$(RELEASE_TAG) --draft \
	    --name="$(RELEASE_NAME)" \
	    --prerelease --oauth-token=$(shell cat ~/.github_oauth_token) \
	    --md5sum-file=$O/$(MD5SUM_FILE) \
	    $(addprefix $O/,$(UPLOAD_ARTIFACTS))

#
# Generic directory creator
#
ifneq ($(DIRS),)
$(DIRS):
	$(create_dir)
endif

#
# Clean
#
.PHONY: clean
clean:
	-rm -rf $O
