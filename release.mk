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
# Toolchain "release" makefile that does all of the steps required to make a
# GitHub release of toolchain.
#
# Please refer to doc/release.rst for documentation on how to use this
# makefile.
#

#
# Configuration
#

CONFIG_STATIC_TOOLCHAIN := n

DEPLOY_DESTINATION =

# Whether to build big endian toolchain
ENABLE_BIG_ENDIAN := y

# Whether to create a separate documentation package
ENABLE_DOCS_PACKAGE := n

# Whether to build and upload IDE
ENABLE_IDE := y

# Whether to build Linux images
ENABLE_LINUX_IMAGES := y

# Whether to build native toolchain for ARC HS Linux.
ENABLE_NATIVE_TOOLS := y

# Whether to build and upload OpenOCD for Linux.
ENABLE_OPENOCD := y

# Whether to build and upload OpenOCD for Windows.
# Requires ENABLE_OPENOCD to be set to 'y'.
ENABLE_OPENOCD_WIN := y

# Whether to build Toolchain PDF documentation. This affects only the
# "toolchain" repository - PDF documents from gcc, binutils, etc are always
# created, regardless of this option.
ENABLE_PDF_DOCS := y

# Whether to build and upload windows installer.
# Requires ENABLE_OPENOCD_WIN to be set to 'y'.
ENABLE_WINDOWS_INSTALLER := y

# URL base for git repositories.
GIT_URL_BASE := git@github.com:foss-for-synopsys-dwc-arc-processors

# Whether there is a directory that contains already cloned git repositories
# that can be used as a git reference. If specified than it *must* contain
# copies of all repositories that will be used.
GIT_REFERENCE_ROOT :=

IDE_PLUGIN_LOCATION :=

JAVA_VERSION := 8u66

# libusb is used by the OpenOCD for Windows
LIBUSB_VERSION := 1.0.20

ROOT := $(realpath ..)

THIRD_PARTY_SOFTWARE_LOCATION :=

# Triplet of Mingw toolchain.
WINDOWS_TRIPLET := i686-w64-mingw32

# Must be a folder available to Windows host, e.g. Linux folder shared via
# Samba.
WINDOWS_WORKSPACE := $(ROOT)/windows_workspace


# Include overriding configuration
-include release.config

#
# Check prerequisite variables
#
ifeq ($(RELEASE_TAG),)
$(error RELEASE_TAG variable can not be empty)
endif

ifneq ($(filter upload, $(MAKECMDGOALS)),)
ifeq ($(RELEASE_NAME),)
$(error RELEASE_NAME variable can not be empty for "upload" target)
endif
endif

#
# Internal variables
#
CP = rsync -a
GIT = git
PYTHON = /depot/Python-3.4.3/bin/python3
SSH = ssh

# RELEASE_TAG is a literal Git tag, like arc-2016.09-rc1.
# RELEASE in this case would be 2016.09-rc1. However remove -release suffix
# that is used for final release tags.
# RELEASE_BRANCH in this case would be 2016.09.
RELEASE := $(patsubst %-release,%,$(shell cut -s -d- -f2- <<< $(RELEASE_TAG)))
RELEASE_BRANCH := $(shell cut -s -d- -f2 <<< $(RELEASE_TAG))

ifeq ($(RELEASE_BRANCH),)
$(error RELEASE_TAG variable must be in format xxx-YYYY.MM)
endif

#
# Helpers
#

# Ensure that group has write access.
define create_dir
	mkdir -m775 -p $@
endef

# Create tarball for release
#
# :param $1 - name of directory to tar. Directory must be in the $O.
define create_tar
       cd $O && tar caf $1$(TAR_EXT) $1/
endef

# Create windows tarball for release. Difference with standard `create_tar` is
# that hard links are dereferenced, because they are notsupported in 7-zip -
# hard links are turned into 0-byte files.
#
# :param $1 - name of directory to tar. Directory must
# be in the $O.
define create_windows_tar
       cd $O && tar caf $1$(TAR_EXT) --hard-dereference $1/
endef

# :param $1 - name of directory to zip.
define create_zip
	cd $O && zip -q -r $1.zip $1/
endef

# Clone git repository
# $1 - Git URL
# $2 - directory name
ifeq ($(GIT_REFERENCE_ROOT),)
define git_clone_url
	$(GIT) clone -q $1 $(ROOT)/$2
endef
else
define git_clone_url
	$(GIT) clone -q --reference=$(GIT_REFERENCE_ROOT)/$2 \
	    $1 $(ROOT)/$2
endef
endif

# Clone git repository
# $1 - tool name
# $2 - directory name
define git_clone
    $(call git_clone_url,$(GIT_URL_BASE)/$1.git,$2)
endef

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

# Intermediate location for build directories. Toolchain will have it's own
# bd-{elf32,uclibc}, so this is only for OpenOCD ATM.
BUILD_DIR = $(ROOT)/build

# Toolchain: source tarball
# This variable should use .. instead of $(ROOT) so that tar will auto-remove
# .. from file paths. Perhaps this ugliness can be fixed with --transform?
TOOLS_SOURCE_CONTENTS := $(addprefix ../,binutils gcc gdb newlib toolchain uClibc)
TOOLS_SOURCE_DIR := arc_gnu_$(RELEASE)_sources

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
ARC_LINUX_TRIPLET := arc-snps-linux-uclibc

# Toolchain: native linux toolchain
TOOLS_LINUXLE_HS_DIR_NATIVE := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_archs_native_install

# Toolchain PDF User Guide.
PDF_DOC_FILE := $(abspath $(ROOT)/toolchain/doc/_build/latex/GNU_Toolchain_for_ARC.pdf)

# IDE: vanilla Eclipse variables
ECLIPSE_VERSION := mars-1
ECLIPSE_VANILLA_ZIP_WIN := eclipse-cpp-$(ECLIPSE_VERSION)-win32.zip
ECLIPSE_VANILLA_TGZ_LINUX := eclipse-cpp-$(ECLIPSE_VERSION)-linux-gtk-x86_64.tar.gz
# Coma separated list
ECLIPSE_REPO := http://download.eclipse.org/releases/mars
# Coma separated list
ECLIPSE_PREREQ :=  org.eclipse.tm.terminal.control,org.eclipse.tm.terminal.connector.serial,org.eclipse.tm.terminal.view.core,org.eclipse.tm.terminal.view.ui
ECLIPSE_DL_LINK_BASE := http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/mars/1

# Java.
JRE_TGZ_LINUX := jre-$(JAVA_VERSION)-linux-x64.tar.gz
JRE_TGZ_WIN   := jre-$(JAVA_VERSION)-windows-i586.tar.gz

# IDE: output related variables
IDE_INSTALL_LINUX := arc_gnu_$(RELEASE)_ide_linux_install
IDE_EXE_WIN := arc_gnu_$(RELEASE)_ide_win_install.exe
IDE_TGZ_LINUX := $(IDE_INSTALL_LINUX).tar.gz
# IDE plugins are built separately, and contain only RELEASE_BRANCH in the
# name, not the whole RELEASE.
IDE_PLUGINS_ZIP := arc_gnu_$(RELEASE_BRANCH)_ide_plugins.zip

# Linux
LINUX_IMAGES_DIR = linux_images
LINUX_AXS103_UIMAGE = uImage_axs103
LINUX_AXS103_ROOTFS_CPIO = rootfs_axs103.cpio
LINUX_AXS103_ROOTFS_TAR = rootfs_axs103.tgz

# OpenOCD
OOCD_DIR_LINUX := arc_gnu_$(RELEASE)_openocd_linux_install
OOCD_DIR_WIN := arc_gnu_$(RELEASE)_openocd_win_install
OOCD_SRC_DIR := $(ROOT)/openocd
OOCD_BUILD_DIR_LINUX := $(BUILD_DIR)/openocd_linux
OOCD_BUILD_DIR_WIN := $(BUILD_DIR)/openocd_win

# Documentation package
DOCS_DIR := arc_gnu_$(RELEASE)_docs

# List of files that will be uploaded to GitHub Release.
UPLOAD_ARTIFACTS = \
    $(TOOLS_SOURCE_DIR)$(TAR_EXT) \
    $(TOOLS_ELFLE_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXLE_700_DIR_LINUX)$(TAR_EXT) \
    $(TOOLS_LINUXLE_HS_DIR_LINUX)$(TAR_EXT) \
    $(UPLOAD_ARTIFACTS-y)

UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_ELFBE_DIR_LINUX)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_LINUXBE_700_DIR_LINUX)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_LINUXBE_HS_DIR_LINUX)$(TAR_EXT)

UPLOAD_ARTIFACTS-$(ENABLE_DOCS_PACKAGE) += $(DOCS_DIR)$(TAR_EXT)

UPLOAD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_TGZ_LINUX)
UPLOAD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_PLUGINS_ZIP)
UPLOAD_ARTIFACTS-$(ENABLE_NATIVE_TOOLS) += $(TOOLS_LINUXLE_HS_DIR_NATIVE)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(IDE_EXE_WIN)

# List of files that will be deployed internally. Is a superset of "upload"
# artifacts.
DEPLOY_ARTIFACTS = \
    $(UPLOAD_ARTIFACTS) \
    $(DEPLOY_ARTIFACTS-y)

DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD) += $(OOCD_DIR_LINUX)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_DIR_WIN)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_DIR_WIN).zip
DEPLOY_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFLE_DIR_WIN)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFBE_DIR_WIN)$(TAR_EXT)
# Include the directory here, because it is passed to rsync, and if that would
# be individual file name, then files would end up in deploy destination
# directly, instead of the linux images dir.
DEPLOY_ARTIFACTS-$(ENABLE_LINUX_IMAGES) += $(LINUX_IMAGES_DIR)

# Artifacts for unpacked builds
DEPLOY_BUILD_ARTIFACTS = \
    $(TOOLS_ELFLE_DIR_LINUX) \
    $(TOOLS_LINUXLE_700_DIR_LINUX) \
    $(TOOLS_LINUXLE_HS_DIR_LINUX) \
    $(DEPLOY_BUILD_ARTIFACTS-y)

DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_ELFBE_DIR_LINUX)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_LINUXBE_700_DIR_LINUX)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_LINUXBE_HS_DIR_LINUX)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_INSTALL_LINUX)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_NATIVE_TOOLS) += $(TOOLS_LINUXLE_HS_DIR_NATIVE)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_OPENOCD) += $(OOCD_DIR_LINUX)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_DIR_WIN)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFLE_DIR_WIN)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFBE_DIR_WIN)
# Linux images are not in this list, because directory names in this list are
# processed, but linux_images doesn't conform to the convention expected by the
# processing.

# md5sum
MD5SUM_FILE := md5.sum

#
# Human friendly aliases
#
.PHONY: source-tarball elf-le-build elf-be-build elf-le elf-be \
    windows ide openocd-win \
    openocd openocd-tar openocd-build openocd-install openocd-configure openocd-bootstrap

BUILD_DEPS += \
    $O/.stamp_source_tarball \
    $O/.stamp_elf_le_tarball \
    $O/.stamp_linux_le_700_tarball \
    $O/.stamp_linux_le_hs_tarball \
    $(BUILD_DEPS-y)

BUILD_DEPS-$(ENABLE_BIG_ENDIAN) += $O/.stamp_elf_be_tarball
BUILD_DEPS-$(ENABLE_BIG_ENDIAN) += $O/.stamp_linux_be_700_tarball
BUILD_DEPS-$(ENABLE_BIG_ENDIAN) += $O/.stamp_linux_be_hs_tarball

BUILD_DEPS-$(ENABLE_DOCS_PACKAGE) += $O/$(DOCS_DIR)$(TAR_EXT)

BUILD_DEPS-$(ENABLE_IDE) += $O/.stamp_ide_linux_tar
BUILD_DEPS-$(ENABLE_IDE) += $O/$(IDE_PLUGINS_ZIP)
BUILD_DEPS-$(ENABLE_NATIVE_TOOLS) += $O/.stamp_linux_le_hs_native_tarball
BUILD_DEPS-$(ENABLE_OPENOCD) += $O/$(OOCD_DIR_LINUX)$(TAR_EXT)
BUILD_DEPS-$(ENABLE_OPENOCD_WIN) += $O/$(OOCD_DIR_WIN)$(TAR_EXT)
BUILD_DEPS-$(ENABLE_OPENOCD_WIN) += $O/$(OOCD_DIR_WIN).zip
BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER) += $O/.stamp_elf_le_windows_tarball
BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER) += $O/.stamp_elf_be_windows_tarball

BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)
BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_CPIO)
BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_TAR)

# Cannot include IDE_EXE_WIN into BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER),
# because it is generated on the Windows host, after `make build`.

# Build all components that can be built on Linux hosts.
.PHONY: build
build: $(BUILD_DEPS)

ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
$O/$(MD5SUM_FILE): $O/$(IDE_EXE_WIN)
endif

$O/$(MD5SUM_FILE): $(BUILD_DEPS)
	cd $O && md5sum $(UPLOAD_ARTIFACTS) > $@

.PHONY: md5sum
md5sum: $O/$(MD5SUM_FILE)

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
	$(call git_clone,gcc,gcc)
	$(call git_clone,binutils-gdb,gdb)
	$(call git_clone,newlib,newlib)
	$(call git_clone_url,https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git,linux)
	$(call git_clone,uClibc,uClibc)
ifeq ($(ENABLE_OPENOCD),y)
	$(call git_clone,openocd,openocd)
endif


.PHONY: copy-external
copy-external: | $O
ifeq ($(ENABLE_IDE),y)

ifeq ($(IDE_PLUGIN_LOCATION),)
	$(error IDE_PLUGIN_LOCATION must be set to do copy-external)
endif
ifeq ($(THIRD_PARTY_SOFTWARE_LOCATION),)
	$(error THIRD_PARTY_SOFTWARE_LOCATION must be set to do copy-external)
endif

	# Copy IDE plugin
	$(CP) $(IDE_PLUGIN_LOCATION)/$(IDE_PLUGINS_ZIP) $O

	# Copy JRE. Original tarballs from Oracle do not have .tar in filenames.
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_TGZ_LINUX:.tar.gz=.gz) \
	    $O/$(JRE_TGZ_LINUX)
ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_TGZ_WIN:.tar.gz=.gz) \
	    $O/$(JRE_TGZ_WIN)
endif

	# Copy Eclipse
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_TGZ_LINUX) $O
ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_ZIP_WIN) $O
endif
endif

.PHONY: prerequisites
prerequisites: clone copy-external


.PHONY: distclean
distclean: clean
	rm -rf $(ROOT)/{binutils,gcc,gdb,newlib,linux,uClibc}
	rm -rf $(ROOT)/openocd

#
# Build targets
#
DIRS += $O

# Create source tarball
$O/.stamp_source_tarball:
	tar --exclude-vcs -c -z -f $O/$(TOOLS_SOURCE_DIR)$(TAR_EXT) --exclude=$O \
	    --transform="s|^|arc_gnu_$(RELEASE)_sources/|" $(TOOLS_SOURCE_CONTENTS)
	touch $@


# Build PDF. Do it after source tarball, so that intermediate files will not
# slip into source tarball.
TOOLS_ALL_DEPS-$(ENABLE_PDF_DOCS) += $(PDF_DOC_FILE)
$(PDF_DOC_FILE): $O/.stamp_source_tarball
	$(MAKE) -C doc clean
	$(MAKE) -C doc latexpdf

# $1 - destination directory.
ifeq ($(ENABLE_PDF_DOCS),y)
define copy_pdf_doc_file
	$(CP) $(PDF_DOC_FILE) $1/share/doc/
endef
else
define copy_pdf_doc_file
endef
endif

$O/.stamp_elf_le_built: $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_ELFLE_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --no-uclibc
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFLE_DIR_LINUX))
	touch $@

$O/.stamp_elf_be_built: $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_ELFBE_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --big-endian \
	    --no-uclibc
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFBE_DIR_LINUX))
	touch $@

$O/.stamp_elf_le_tarball: $O/.stamp_elf_le_built
	$(call create_tar,$(TOOLS_ELFLE_DIR_LINUX))
	touch $@

$O/.stamp_elf_be_tarball: $O/.stamp_elf_be_built
	$(call create_tar,$(TOOLS_ELFBE_DIR_LINUX))
	touch $@

$O/.stamp_linux_le_700_built: $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXLE_700_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --cpu arc700 \
	    --no-elf32
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUXLE_700_DIR_LINUX))
	touch $@

$O/.stamp_linux_le_hs_built: $O/.stamp_linux_le_700_built $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXLE_HS_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --cpu hs38 \
	    --no-elf32
	cp -al $O/$(TOOLS_LINUXLE_700_DIR_LINUX)/arc-snps-linux-uclibc/sysroot \
	    $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)/arc-snps-linux-uclibc/sysroot-arc700
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUXLE_HS_DIR_LINUX))
	touch $@

$O/.stamp_linux_be_700_built: $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXBE_700_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --big-endian \
	    --cpu arc700 \
	    --no-elf32
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUXBE_700_DIR_LINUX))
	touch $@

$O/.stamp_linux_be_hs_built: $O/.stamp_linux_be_700_built $(TOOLS_ALL_DEPS-y)
	./build-all.sh $(BUILDALLFLAGS) --install-dir $O/$(TOOLS_LINUXBE_HS_DIR_LINUX) \
	    --release-name "$(RELEASE)" \
	    --big-endian \
	    --cpu hs38 \
	    --no-elf32
	cp -al $O/$(TOOLS_LINUXBE_700_DIR_LINUX)/arceb-snps-linux-uclibc/sysroot \
	    $O/$(TOOLS_LINUXBE_HS_DIR_LINUX)/arceb-snps-linux-uclibc/sysroot-arc700
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUXBE_HS_DIR_LINUX))
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

$O/.stamp_elf_le_windows_built: $O/.stamp_elf_le_built $(TOOLS_ALL_DEPS-y)
	PATH=$(shell readlink -e $O/$(TOOLS_ELFLE_DIR_LINUX)/bin):$$PATH \
	     ./build-all.sh $(BUILDALLFLAGS) \
	     --install-dir $O/$(TOOLS_ELFLE_DIR_WIN) --no-uclibc \
	     --release-name "$(RELEASE)" \
	     --host $(WINDOWS_TRIPLET) --no-system-expat \
	     --no-elf32-gcc-stage1
	$(call copy_mingw_dlls,$O/$(TOOLS_ELFLE_DIR_WIN),arc-elf32)
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFLE_DIR_WIN))
	touch $@

$O/.stamp_elf_be_windows_built: $O/.stamp_elf_be_built $(TOOLS_ALL_DEPS-y)
	# Install toolchain in the same dir as little endian
	PATH=$(shell readlink -e $O/$(TOOLS_ELFBE_DIR_LINUX))/bin:$$PATH \
	     ./build-all.sh $(BUILDALLFLAGS) \
	     --install-dir $O/$(TOOLS_ELFBE_DIR_WIN) --no-uclibc --big-endian \
	     --release-name "$(RELEASE)" \
	     --host $(WINDOWS_TRIPLET) --no-system-expat \
	     --no-elf32-gcc-stage1
	$(call copy_mingw_dlls,$O/$(TOOLS_ELFBE_DIR_WIN),arceb-elf32)
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFBE_DIR_WIN))
	touch $@

$O/.stamp_elf_le_windows_tarball: $O/.stamp_elf_le_windows_built
	$(call create_windows_tar,$(TOOLS_ELFLE_DIR_WIN))
	touch $@

$O/.stamp_elf_be_windows_tarball: $O/.stamp_elf_be_windows_built
	$(call create_windows_tar,$(TOOLS_ELFBE_DIR_WIN))
	touch $@


#
# Linux
#

# Latest stable release is 2016.05 ATM, but it doesn't support Linux 4.7, which
# is required for this toolchain.
BUILDROOT_VERSION = 2016.08-rc2
BUILDROOT_TAR = buildroot-$(BUILDROOT_VERSION).tar.bz2
BUILDROOT_URL = https://buildroot.org/downloads/$(BUILDROOT_TAR)
BUILDROOT_SRC_DIR = $(BUILD_DIR)/buildroot
BUILDROOT_AXS103_BUILD_DIR = $(BUILD_DIR)/buildroot_axs103
BUILDROOT_AXS103_DEFCONFIG := $(ROOT)/toolchain/extras/buildroot/axs103.defconfig
BUILDROOT_AXS103_MAKEFLAGS = -C $(BUILDROOT_SRC_DIR) \
	O=$(abspath $(BUILDROOT_AXS103_BUILD_DIR)) \
	ARC_TOOLCHAIN_PATH=$(realpath $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)) \
	LINUX_SRC_PATH=$(realpath $(ROOT)/linux) \
	DEFCONFIG=$(BUILDROOT_AXS103_DEFCONFIG)

# Download Buildroot
$(BUILD_DIR)/$(BUILDROOT_TAR):
	wget -nv -O $@ $(BUILDROOT_URL)

# Prepare Buildroot source directory
$(BUILDROOT_SRC_DIR): $(BUILD_DIR)/$(BUILDROOT_TAR) | $(BUILD_DIR)
	mkdir -p $@
	tar -C $@ --strip-components=1 -x -a -f $<

DIRS += $O/$(LINUX_IMAGES_DIR)

# Configure Buildroot for AXS103
$(BUILDROOT_AXS103_BUILD_DIR)/.config: $(BUILDROOT_SRC_DIR) $(BUILDROOT_AXS103_DEFCONFIG)
	$(MAKE) $(BUILDROOT_AXS103_MAKEFLAGS) distclean
	$(MAKE) $(BUILDROOT_AXS103_MAKEFLAGS) defconfig

# Build images for AXS103
$O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE): $(BUILDROOT_AXS103_BUILD_DIR)/.config \
    | $O/$(LINUX_IMAGES_DIR)
	$(MAKE) $(BUILDROOT_AXS103_MAKEFLAGS) all
	cp -afl $(BUILDROOT_AXS103_BUILD_DIR)/images/uImage \
	    $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)
	cp -afl $(BUILDROOT_AXS103_BUILD_DIR)/images/rootfs.cpio \
	    $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_CPIO)
	cp -afl $(BUILDROOT_AXS103_BUILD_DIR)/images/rootfs.tar.gz \
	    $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_TAR)

$O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_CPIO): \
    | $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)

$O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_TAR): \
    | $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)

linux-images: $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)
linux-images: $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_CPIO)
linux-images: $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_TAR)

#
# Native toolchain build
#
$O/.stamp_linux_le_hs_native_built: $O/.stamp_linux_le_hs_built $(TOOLS_ALL_DEPS-y)
	PATH=$(shell readlink -e $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)/bin):$$PATH \
	     ./build-all.sh $(BUILDALLFLAGS) \
	     --no-elf32 \
	     --cpu hs38 \
	     --release-name "$(RELEASE)" \
	     --host arc-snps-linux-uclibc \
	     --native \
	     --no-system-expat \
	     --install-dir $O/$(TOOLS_LINUXLE_HS_DIR_NATIVE)
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUXLE_HS_DIR_NATIVE))
	touch $@

$O/.stamp_linux_le_hs_native_tarball: $O/.stamp_linux_le_hs_native_built
	$(call create_tar,$(TOOLS_LINUXLE_HS_DIR_NATIVE))
	touch $@

#
# IDE related targets
#
ifeq ($(ENABLE_IDE),y)

$O/$(ECLIPSE_VANILLA_TGZ_LINUX):
	wget -nv -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_TGZ_LINUX)&r=1'

$O/$(ECLIPSE_VANILLA_ZIP_WIN):
	wget -nv -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_ZIP_WIN)&r=1'

# Install ARC plugins from .zip file and install prerequisites in Eclipse.
# Similar invocation is in windows/build-release.sh. Those invocations must be
# in sync.
$O/.stamp_ide_linux_eclipse: $O/$(ECLIPSE_VANILLA_TGZ_LINUX) $O/$(IDE_PLUGINS_ZIP)
	mkdir -m775 -p $O/$(IDE_INSTALL_LINUX)
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
	$O/$(OOCD_DIR_LINUX)$(TAR_EXT) \
	$O/.stamp_ide_linux_eclipse \
	$O/.stamp_elf_be_built $O/.stamp_elf_le_built \
	$O/.stamp_linux_be_hs_built $O/.stamp_linux_le_hs_built
	cp -al $O/$(TOOLS_ELFLE_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_ELFBE_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_LINUXLE_HS_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	cp -al $O/$(TOOLS_LINUXBE_HS_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	mkdir -m775 $O/$(IDE_INSTALL_LINUX)/eclipse/jre
	tar xaf $O/$(JRE_TGZ_LINUX) -C $O/$(IDE_INSTALL_LINUX)/eclipse/jre \
	    --strip-components=1
	cp -al $O/$(OOCD_DIR_LINUX)/* $O/$(IDE_INSTALL_LINUX)
	tar caf $O/$(IDE_TGZ_LINUX) -C $O $(IDE_INSTALL_LINUX)
	touch $@
endif

#
# OpenOCD
#
ifeq ($(ENABLE_OPENOCD),y)

.PHONY: openocd-linux
openocd-linux: $O/$(OOCD_DIR_LINUX)$(TAR_EXT)

DIRS += $(OOCD_BUILD_DIR_LINUX)


# Bootstrap is common to Linux and Windows.
$(OOCD_SRC_DIR)/configure:
	cd $(OOCD_SRC_DIR) && ./bootstrap


# Configure OpenOCD
$(OOCD_BUILD_DIR_LINUX)/Makefile: $(OOCD_SRC_DIR)/configure \
    | $(OOCD_BUILD_DIR_LINUX)
	cd $(OOCD_BUILD_DIR_LINUX) && $(OOCD_SRC_DIR)/configure \
	    --enable-ftdi --disable-werror \
	    --prefix=$(abspath $O/$(OOCD_DIR_LINUX))


# Build OpenOCD
define OOCD_BUILD_CMD
	$(MAKE) -C $(OOCD_BUILD_DIR_$1) all pdf
endef

$(OOCD_BUILD_DIR_LINUX)/src/openocd: $(OOCD_BUILD_DIR_LINUX)/Makefile
	$(call OOCD_BUILD_CMD,LINUX)


# Instal OpenOCD
define OOCD_INSTALL_CMD
	$(MAKE) -C $(OOCD_BUILD_DIR_$1) install install-pdf
endef

$O/$(OOCD_DIR_LINUX)/bin/openocd: $(OOCD_BUILD_DIR_LINUX)/src/openocd
	$(call OOCD_INSTALL_CMD,LINUX)


# Tarball for OpenOCD
$O/$(OOCD_DIR_LINUX)$(TAR_EXT): $O/$(OOCD_DIR_LINUX)/bin/openocd
	$(call create_tar,$(OOCD_DIR_LINUX))

#
# OpenOCD for Windows
#
ifeq ($(ENABLE_OPENOCD_WIN),y)

.PHONY: openocd-win
openocd-win: $O/$(OOCD_DIR_WIN)$(TAR_EXT) $O/$(OOCD_DIR_WIN).zip

DIRS += $(OOCD_BUILD_DIR_WIN)

#
# Libusb for Windows
#
$(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2:
	wget -O $@ 'http://downloads.sourceforge.net/project/libusb/libusb-1.0/libusb-$(LIBUSB_VERSION)/libusb-$(LIBUSB_VERSION).tar.bz2?r=&use_mirror='


$(BUILD_DIR)/libusb_src: $(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2
	tar -C $(BUILD_DIR) -xaf $< --transform='s/libusb-$(LIBUSB_VERSION)/libusb_src/'


# It looks like that libusb Makefile is not parallel-friendly, it fails with error
# 	mv: cannot stat `.deps/libusb_1_0_la-core.Tpo': No such file or directory
# in parallel build, therefore we have to force sequential build on it.
.PHONY: libusb-install
libusb-install: $(BUILD_DIR)/libusb_install/lib/libusb-1.0.a
$(BUILD_DIR)/libusb_install/lib/libusb-1.0.a: $(BUILD_DIR)/libusb_src
	cd $< && \
	./configure --host=$(WINDOWS_TRIPLET) --disable-shared --enable-static \
		--prefix=$(abspath $(BUILD_DIR)/libusb_install)
	$(MAKE) -C $< -j1
	$(MAKE) -C $< install


# Configure OpenOCD for Windows.
$(OOCD_BUILD_DIR_WIN)/Makefile: $(OOCD_SRC_DIR)/configure
$(OOCD_BUILD_DIR_WIN)/Makefile: $(BUILD_DIR)/libusb_install/lib/libusb-1.0.a
$(OOCD_BUILD_DIR_WIN)/Makefile: | $(OOCD_BUILD_DIR_WIN)

$(OOCD_BUILD_DIR_WIN)/Makefile:
	cd $(OOCD_BUILD_DIR_WIN) && \
	PKG_CONFIG_PATH=$(abspath $(BUILD_DIR)/libusb_install)/lib/pkgconfig \
	$(OOCD_SRC_DIR)/configure \
	    --enable-ftdi --disable-werror \
	    --disable-shared --enable-static \
	    --host=$(WINDOWS_TRIPLET) \
	    PKG_CONFIG=pkg-config \
	    --prefix=$(abspath $O/$(OOCD_DIR_WIN))


# Build OpenOCD for Windows.
$(OOCD_BUILD_DIR_WIN)/src/openocd.exe: $(OOCD_BUILD_DIR_WIN)/Makefile
	$(call OOCD_BUILD_CMD,WIN)


# Install OpenOCD for Windows.
$O/$(OOCD_DIR_WIN)/bin/openocd.exe: $(OOCD_BUILD_DIR_WIN)/src/openocd.exe
	$(call OOCD_INSTALL_CMD,WIN)


# Create tarball for OpenOCD for Windows.
$O/$(OOCD_DIR_WIN)$(TAR_EXT): $O/$(OOCD_DIR_WIN)/bin/openocd.exe
	$(call create_tar,$(OOCD_DIR_WIN))


# Create zip for OpenOCD for Windows.
$O/$(OOCD_DIR_WIN).zip: $O/$(OOCD_DIR_WIN)/bin/openocd.exe
	$(call create_zip,$(OOCD_DIR_WIN))

endif # ifeq ($(ENABLE_OPENOCD_WIN),y)

endif # ifeq ($(ENABLE_OPENOCD),y)


#
# Create workspace for Windows script
#
ifeq ($(ENABLE_WINDOWS_INSTALLER),y)

.PHONY: windows-workspace
windows-workspace: $O/.stamp_windows_workspace

$(WINDOWS_WORKSPACE):
	mkdir -m775 -p $@/packages

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

endif

#
# Retrieve Windows installer
#
ifeq ($(ENABLE_WINDOWS_INSTALLER),y)

.PHONY: copy-windows-installer
copy-windows-installer: $O/$(IDE_EXE_WIN)

$O/$(IDE_EXE_WIN): $(WINDOWS_WORKSPACE)/$(IDE_EXE_WIN)
	$(CP) $< $@

endif

#
# Documentation package
#
DIRS += $O/$(DOCS_DIR)
$O/$(DOCS_DIR)$(TAR_EXT): $O/.stamp_elf_le_built | $O/$(DOCS_DIR)
	$(CP) $O/$(TOOLS_ELFLE_DIR_LINUX)/share/doc/ $O/$(DOCS_DIR)
	$(call create_tar,$(DOCS_DIR))


#
# Create tag
#
create-tag:
	./tag-release.sh $(RELEASE_TAG)
ifeq ($(ENABLE_OPENOCD),y)
	# Semihardcoded OpeOCD branch is ugly, but is OK for now.
	# Initially I used --git-dir, however it doesn't work properly with
	# `checkout' - actual files were left in original state.
	cd $(OOCD_SRC_DIR) && \
	    $(GIT) checkout arc-0.9-dev-$(RELEASE_BRANCH) && \
	    $(GIT) tag $(RELEASE_TAG)
endif

#
# Push tag
#
push-tag:
	./push-release.sh $(RELEASE_TAG)
ifeq ($(ENABLE_OPENOCD),y)
	cd $(OOCD_SRC_DIR) && \
	    $(GIT) push origin $(RELEASE_TAG)
endif

#
# Deploy to shared file system
#
.PHONY: deploy
deploy: $O/$(MD5SUM_FILE) $(addprefix $O/,$(DEPLOY_ARTIFACTS))
ifeq ($(DEPLOY_DESTINATION),)
	$(error DEPLOY_DESTINATION must be set to run 'deploy' target)
endif
	$(CP) $^ $(DEPLOY_DESTINATION)/$(RELEASE)

#
# Deploy unpacked builds which can be used directly
#

# When copying directories, rsync doesn the "cd" to
# DEPLOY_BUILD_ARTIFACTS/$(RELEASE), which doesn't exist yet. Hence it is
# required to create build directory before copying into it.

ifeq ($(findstring :,$(DEPLOY_BUILD_DESTINATION)),)
  DEPLOY_BUILD_DESTINATION_CMD=mkdir -m775 -p $(DEPLOY_BUILD_DESTINATION)/$(RELEASE)
  DEPLOY_BUILD_LINK_CMD=ln -fsT $(RELEASE) $(DEPLOY_BUILD_DESTINATION)/latest
else
  DEPLOY_BUILD_DESTINATION_HOST=$(shell cut -d: -f1 <<< "$(DEPLOY_BUILD_DESTINATION)")
  DEPLOY_BUILD_DESTINATION_PATH=$(shell cut -d: -f2 <<< "$(DEPLOY_BUILD_DESTINATION)")
  DEPLOY_BUILD_DESTINATION_CMD=$(SSH) $(DEPLOY_BUILD_DESTINATION_HOST) \
    'mkdir -m775 -p $(DEPLOY_BUILD_DESTINATION_PATH)/$(RELEASE)'
  DEPLOY_BUILD_LINK_CMD=$(SSH) $(DEPLOY_BUILD_DESTINATION_HOST) \
    'ln -fsT $(RELEASE) $(DEPLOY_BUILD_DESTINATION_PATH)/latest'
endif

.PHONY: .deploy_build_destdir
.deploy_build_destdir:
ifeq ($(DEPLOY_BUILD_DESTINATION),)
	$(error DEPLOY_BUILD_DESTINATION must be set to run 'deploy-build' target)
endif
	$(DEPLOY_BUILD_DESTINATION_CMD)


# Cannot make "prebuilt" part of the pattern to get it stripped, because we
# have an IDE package, which has "ide" insead of "prebuilt".
.deploy-toolchain-build-%: $O/arc_gnu_$(RELEASE)_%_install .deploy_build_destdir
	$(CP) $</ $(DEPLOY_BUILD_DESTINATION)/$(RELEASE)/$(*:prebuilt_%=%)

# Copying is done by dependency targets.
.PHONY: .deploy-toolchain-build
.deploy-toolchain-build: $(addprefix .deploy-toolchain-build-,\
$(patsubst arc_gnu_$(RELEASE)_%_install,%,$(DEPLOY_BUILD_ARTIFACTS)))

.PHONY: .deploy-linux-images
.deploy-linux-images: .deploy_build_destdir
	$(CP) $O/$(LINUX_IMAGES_DIR) $(DEPLOY_BUILD_DESTINATION)/$(RELEASE)

# Create a symlink
.PHONY: deploy-build
deploy-build: .deploy-toolchain-build .deploy-linux-images
	$(DEPLOY_BUILD_LINK_CMD)


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
