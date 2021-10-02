##############################################################################
# Copyright (C) 2014-2017 Synopsys Inc.
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

# Whether to build big endian toolchain
ENABLE_BIG_ENDIAN := y

# Whether to create a separate documentation package
ENABLE_DOCS_PACKAGE := n

# Whether to build and upload IDE
ENABLE_IDE := y

# Whether to build and upload IDE on macOS
ENABLE_IDE_MACOS := y

# Whether to build or download GNU IDE Plugins
ENABLE_IDE_PLUGINS_BUILD := y

# Whether to build Linux images
ENABLE_LINUX_IMAGES := n

# Whether to build Toolchain for elf32 targets.
ENABLE_ELF_TOOLS := y

# Whether to build Toolchain for Linux targets.
ENABLE_UCLIBC_TOOLS := y

# Whether to build native toolchain for ARC HS Linux.
ENABLE_NATIVE_TOOLS := y

# Whether to build toolchain for Linux/glibc targets.
ENABLE_GLIBC_TOOLS := y

# Whether to build toolchain for arc64 targets.
ENABLE_ARC64_TOOLS := y

# Whether to build and upload OpenOCD for Linux.
ENABLE_OPENOCD := y

# Whether to build and upload OpenOCD for Windows/macOS.
# Requires ENABLE_OPENOCD to be set to 'y'.
ENABLE_OPENOCD_WIN := y
ENABLE_OPENOCD_MAC := y

# Whether to build Toolchain PDF documentation. This affects only the
# "toolchain" repository - PDF documents from gcc, binutils, etc are always
# created, regardless of this option.
ENABLE_PDF_DOCS := y

# Whether to create a source tarball.
ENABLE_SOURCE_TARBALL := y

# Whether to build and upload windows installer.
# Requires ENABLE_OPENOCD_WIN to be set to 'y'.
ENABLE_WINDOWS_INSTALLER := y

# URL base for git repositories.
GIT_URL_BASE := git@github.com:foss-for-synopsys-dwc-arc-processors

# Whether there is a directory that contains already cloned git repositories
# that can be used as a git reference. If specified than it *must* contain
# copies of all repositories that will be used.
GIT_REFERENCE_ROOT :=

# This path to prebuilt IDE plugins should be set only if
# ENABLE_IDE_PLUGINS_BUILD is 'n'.
IDE_PLUGIN_LOCATION :=

# libusb is used by the OpenOCD for
LIBUSB_VERSION := 1.0.23

ROOT := $(realpath ..)

THIRD_PARTY_SOFTWARE_LOCATION :=

# Triplet of Mingw toolchain.
WINDOWS_TRIPLET := i686-w64-mingw32

# Triplet of osxcross toolchain
MACOS_TRIPLET := x86_64-apple-darwin14

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

# Identify host system (used in release tarball names).
ifeq ($(shell uname -s),Linux)
HOST := linux
else
ifeq ($(shell uname -s),Darwin)
HOST := macos
else
$(error Unknown OS: $(shell uname -s). Only Linux and macOS (Darwin) are supported.)
endif
endif

CP = rsync -a
GIT = git
PYTHON = /depot/Python-3.4.3/bin/python3
SSH = ssh
WGET = wget
# Always have `-nv`.
override WGETFLAGS += -nv
CHECKSUM := shasum -a256 -b

ifneq ($(HOST),macos)
LOCAL_CP := cp -al
else
# macOS' `cp` doesn't support hardlinks and `-l`.
LOCAL_CP := cp -a
endif

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
	tar czf $1$(TAR_EXT) -C $O --owner=0 --group=0 $1/
endef

# Create windows tarball for release. Difference with standard `create_tar` is
# that hard links are dereferenced, because they are notsupported in 7-zip -
# hard links are turned into 0-byte files.
#
# :param $1 - name of directory to tar. Directory must
# be in the $O.
define create_windows_tar
	tar czf $1$(TAR_EXT) -C $O --owner=0 --group=0 --hard-dereference $1/
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

# Copy prebuilt toolchain into workspace
# $1 - name of source directory in directory with prebuilt toolchains
# $2 - name of destination directory to save
define copy_prebuilt
	$(CP) --chmod=u+w --ignore-existing $(PREBUILT_TOOLCHAINS_DIR)/$1/ $O/$2/
	chmod u+w $O/$2
endef

#
# Build flags common to all toolchains
#

BUILDALLFLAGS := --disable-werror --strip --no-auto-pull \
--no-auto-checkout --elf32-strip-target-libs

# Disable Python and ISL, because those libraries are not shipped with the
# toolchain, and without explicit 'no' ./configure might grab system version of
# library as a dependency and it will not work for the user, who will have a
# different version of library on their system.
EXTRA_CONFIG_FLAGS += --with-python=no --with-isl=no
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
TOOLS_SOURCE_CONTENTS := $(addprefix ../,binutils gcc gdb glibc newlib toolchain uclibc-ng openocd)
TOOLS_SOURCE_DIR := arc_gnu_$(RELEASE)_sources

# Toolchain: baremetal for Linux hosts
TOOLS_ELFLE_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_le_$(HOST)_install
TOOLS_ELFBE_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_be_$(HOST)_install

# Toolchain: baremetal for Windows hosts
TOOLS_ELFLE_WIN_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_le_win_install
TOOLS_ELFBE_WIN_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_be_win_install

# Toolchain: linux
TOOLS_UCLIBC_LE_700_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_arc700_$(HOST)_install
TOOLS_UCLIBC_BE_700_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_uclibc_be_arc700_$(HOST)_install
TOOLS_UCLIBC_LE_HS_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_archs_$(HOST)_install
TOOLS_UCLIBC_BE_HS_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_uclibc_be_archs_$(HOST)_install
TOOLS_UCLIBC_LE_HS38FPU_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_uclibc_le_hs38fpu_$(HOST)_install

# Toolchain: macOS
TOOLS_ELFLE_MAC_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_le_mac_install
TOOLS_ELFBE_MAC_DIR := arc_gnu_$(RELEASE)_prebuilt_elf32_be_mac_install

# Toolchain: linux with glibc.
TOOLS_GLIBC_LE_HS_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_glibc_le_archs_$(HOST)_install
TOOLS_GLIBC_BE_HS_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_glibc_be_archs_$(HOST)_install

# Toolchain: native linux toolchain
TOOLS_GLIBC_LE_HS_NATIVE_DIR := arc_gnu_$(RELEASE)_prebuilt_glibc_le_archs_native_install

# Toolchain: arc64
TOOLS_ELF_ARC64_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_arc64_elf_$(HOST)_install
TOOLS_LINUX_ARC64_HOST_DIR := arc_gnu_$(RELEASE)_prebuilt_arc64_glibc_$(HOST)_install

# Toolchain PDF User Guide.
PDF_DOC_FILE := $(abspath $(ROOT)/toolchain/doc/_build/pdf/GNU_Toolchain_for_ARC.pdf)

# IDE: vanilla Eclipse variables
ECLIPSE_VERSION := 2020-03-R-incubation
ECLIPSE_VANILLA_WIN_ZIP := eclipse-cpp-$(ECLIPSE_VERSION)-win32-x86_64.zip
ECLIPSE_VANILLA_LINUX_TGZ := eclipse-cpp-$(ECLIPSE_VERSION)-linux-gtk-x86_64.tar.gz
ECLIPSE_VANILLA_MACOS_TGZ := eclipse-cpp-$(ECLIPSE_VERSION)-macosx-cocoa-x86_64.tar.gz

# Coma separated list
ECLIPSE_DL_LINK_BASE := http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2020-03/R

# Java. Note that filenames might differ from originals to ensure consistent
# JAVA_VERSION content.
JAVA_VERSION := 11.0.1_13
JRE_LINUX_TGZ := OpenJDK11-jre_x64_linux_openj9_$(JAVA_VERSION).tar.gz
JRE_WIN_ZIP := OpenJDK11-jre_x64_windows_openj9_$(JAVA_VERSION).zip

# IDE: output related variables
IDE_LINUX_INSTALL := arc_gnu_$(RELEASE)_ide_$(HOST)_install
IDE_MACOS_INSTALL := arc_gnu_$(RELEASE)_ide_mac_install
IDE_WIN_EXE := arc_gnu_$(RELEASE)_ide_win_install.exe
IDE_LINUX_TGZ := $(IDE_LINUX_INSTALL).tar.gz
IDE_MACOS_TGZ := $(IDE_MACOS_INSTALL).tar.gz
IDE_PLUGINS_ZIP := arc_gnu_$(RELEASE)_ide_plugins.zip

# Linux
LINUX_IMAGES_DIR = linux_images
LINUX_AXS103_UIMAGE = uImage_axs103
LINUX_AXS103_ROOTFS_CPIO = rootfs_axs103.cpio
LINUX_AXS103_ROOTFS_TAR = rootfs_axs103.tgz

# OpenOCD
OOCD_HOST_DIR := arc_gnu_$(RELEASE)_openocd_$(HOST)_install
OOCD_WIN_DIR := arc_gnu_$(RELEASE)_openocd_win_install
OOCD_MAC_DIR := arc_gnu_$(RELEASE)_openocd_mac_install
OOCD_SRC_DIR := $(ROOT)/openocd
OOCD_BUILD_HOST_DIR := $(BUILD_DIR)/openocd_$(HOST)
OOCD_BUILD_WIN_DIR := $(BUILD_DIR)/openocd_win
OOCD_BUILD_MAC_DIR := $(BUILD_DIR)/openocd_mac

# Documentation package
DOCS_DIR := arc_gnu_$(RELEASE)_docs

# List of files that will be uploaded to GitHub Release.
UPLOAD_ARTIFACTS = $(UPLOAD_ARTIFACTS-y)

UPLOAD_ARTIFACTS-$(ENABLE_ELF_TOOLS) += $(TOOLS_ELFLE_HOST_DIR)$(TAR_EXT)

ifeq ($(ENABLE_ELF_TOOLS),y)
UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_ELFBE_HOST_DIR)$(TAR_EXT)
endif

UPLOAD_ARTIFACTS-$(ENABLE_SOURCE_TARBALL) += $(TOOLS_SOURCE_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_UCLIBC_TOOLS) += $(TOOLS_UCLIBC_LE_700_HOST_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_UCLIBC_TOOLS) += $(TOOLS_UCLIBC_LE_HS_HOST_DIR)$(TAR_EXT)

ifeq ($(ENABLE_UCLIBC_TOOLS),y)
UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_UCLIBC_BE_700_HOST_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_UCLIBC_BE_HS_HOST_DIR)$(TAR_EXT)
endif

UPLOAD_ARTIFACTS-$(ENABLE_GLIBC_TOOLS) += $(TOOLS_GLIBC_LE_HS_HOST_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_GLIBC_TOOLS) += $(TOOLS_GLIBC_BE_HS_HOST_DIR)$(TAR_EXT)

UPLOAD_ARTIFACTS-$(ENABLE_ARC64_TOOLS) += $(TOOLS_ELF_ARC64_HOST_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_ARC64_TOOLS) += $(TOOLS_LINUX_ARC64_HOST_DIR)$(TAR_EXT)

UPLOAD_ARTIFACTS-$(ENABLE_DOCS_PACKAGE) += $(DOCS_DIR)$(TAR_EXT)

UPLOAD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_LINUX_TGZ)
UPLOAD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_PLUGINS_ZIP)
UPLOAD_ARTIFACTS-$(ENABLE_NATIVE_TOOLS) += $(TOOLS_GLIBC_LE_HS_NATIVE_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(IDE_WIN_EXE)
UPLOAD_ARTIFACTS-$(ENABLE_IDE_MACOS) += $(IDE_MACOS_TGZ)
UPLOAD_ARTIFACTS-$(ENABLE_IDE_MACOS) += $(TOOLS_ELFLE_MAC_DIR)$(TAR_EXT)
UPLOAD_ARTIFACTS-$(ENABLE_IDE_MACOS) += $(TOOLS_ELFBE_MAC_DIR)$(TAR_EXT)

# List of files that will be deployed internally. Is a superset of "upload"
# artifacts.
DEPLOY_ARTIFACTS = $(UPLOAD_ARTIFACTS) $(DEPLOY_ARTIFACTS-y)

DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD) += $(OOCD_HOST_DIR)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD_MAC) += $(OOCD_MAC_DIR)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_WIN_DIR)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_WIN_DIR).zip
DEPLOY_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFLE_WIN_DIR)$(TAR_EXT)
DEPLOY_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFBE_WIN_DIR)$(TAR_EXT)
# Include the directory here, because it is passed to rsync, and if that would
# be individual file name, then files would end up in deploy destination
# directly, instead of the linux images dir.
DEPLOY_ARTIFACTS-$(ENABLE_LINUX_IMAGES) += $(LINUX_IMAGES_DIR)

# Artifacts for unpacked builds
DEPLOY_BUILD_ARTIFACTS = \
    $(TOOLS_ELFLE_HOST_DIR) \
    $(DEPLOY_BUILD_ARTIFACTS-y)

DEPLOY_BUILD_ARTIFACTS-$(ENABLE_UCLIBC_TOOLS) += $(TOOLS_UCLIBC_LE_700_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_UCLIBC_TOOLS) += $(TOOLS_UCLIBC_LE_HS_HOST_DIR)

DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_ELFBE_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_UCLIBC_BE_700_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_BIG_ENDIAN) += $(TOOLS_UCLIBC_BE_HS_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_GLIBC_TOOLS) += $(TOOLS_GLIBC_LE_HS_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_GLIBC_TOOLS) += $(TOOLS_GLIBC_BE_HS_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_IDE) += $(IDE_LINUX_INSTALL)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_NATIVE_TOOLS) += $(TOOLS_GLIBC_LE_HS_NATIVE_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_OPENOCD) += $(OOCD_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_OPENOCD_WIN) += $(OOCD_WIN_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFLE_WIN_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_WINDOWS_INSTALLER) += $(TOOLS_ELFBE_WIN_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_IDE_MACOS) += $(TOOLS_ELFLE_MAC_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_IDE_MACOS) += $(TOOLS_ELFBE_MAC_DIR)

DEPLOY_BUILD_ARTIFACTS-$(ENABLE_ARC64_TOOLS) += $(TOOLS_ELF_ARC64_HOST_DIR)
DEPLOY_BUILD_ARTIFACTS-$(ENABLE_ARC64_TOOLS) += $(TOOLS_LINUX_ARC64_HOST_DIR)

# Linux images are not in this list, because directory names in this list are
# processed, but linux_images doesn't conform to the convention expected by the
# processing.

CHECKSUM_FILE := checksum.txt

#
# Human friendly aliases
#
.PHONY: source-tarball elf-le-build elf-be-build elf-le elf-be \
    windows ide openocd-win \
    openocd-linux

BUILD_DEPS = $(BUILD_DEPS-y)

BUILD_DEPS-$(ENABLE_ELF_TOOLS) += $O/.stamp_elf_le_tarball

ifeq ($(ENABLE_ELF_TOOLS),y)
BUILD_DEPS-$(ENABLE_ELF_TOOLS) += $O/.stamp_elf_be_tarball
endif

BUILD_DEPS-$(ENABLE_SOURCE_TARBALL) += $O/.stamp_source_tarball
BUILD_DEPS-$(ENABLE_UCLIBC_TOOLS) += $O/.stamp_uclibc_le_700_tarball
BUILD_DEPS-$(ENABLE_UCLIBC_TOOLS) += $O/.stamp_uclibc_le_hs_tarball

ifeq ($(ENABLE_UCLIBC_TOOLS),y)
BUILD_DEPS-$(ENABLE_BIG_ENDIAN) += $O/.stamp_uclibc_be_700_tarball
BUILD_DEPS-$(ENABLE_BIG_ENDIAN) += $O/.stamp_uclibc_be_hs_tarball
endif

BUILD_DEPS-$(ENABLE_GLIBC_TOOLS) += $O/.stamp_glibc_le_hs_tarball
BUILD_DEPS-$(ENABLE_GLIBC_TOOLS) += $O/.stamp_glibc_be_hs_tarball

BUILD_DEPS-$(ENABLE_ARC64_TOOLS) += $O/.stamp_arc64_elf_tarball
BUILD_DEPS-$(ENABLE_ARC64_TOOLS) += $O/.stamp_arc64_linux_tarball

BUILD_DEPS-$(ENABLE_DOCS_PACKAGE) += $O/$(DOCS_DIR)$(TAR_EXT)

BUILD_DEPS-$(ENABLE_IDE) += $O/.stamp_ide_linux_tar
BUILD_DEPS-$(ENABLE_IDE_MACOS) += $O/.stamp_ide_macos_tar
BUILD_DEPS-$(ENABLE_IDE_MACOS) += $O/.stamp_elf_le_mac_tarball
BUILD_DEPS-$(ENABLE_IDE_MACOS) += $O/.stamp_elf_be_mac_tarball
BUILD_DEPS-$(ENABLE_IDE_PLUGINS_BUILD) += $O/$(IDE_PLUGINS_ZIP)
BUILD_DEPS-$(ENABLE_NATIVE_TOOLS) += $O/.stamp_glibc_le_hs_native_tarball
BUILD_DEPS-$(ENABLE_OPENOCD) += $O/$(OOCD_HOST_DIR)$(TAR_EXT)
BUILD_DEPS-$(ENABLE_OPENOCD_MAC) += $O/$(OOCD_MAC_DIR)$(TAR_EXT)
BUILD_DEPS-$(ENABLE_OPENOCD_WIN) += $O/$(OOCD_WIN_DIR)$(TAR_EXT)
BUILD_DEPS-$(ENABLE_OPENOCD_WIN) += $O/$(OOCD_WIN_DIR).zip
BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER) += $O/.stamp_elf_le_windows_tarball
BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER) += $O/.stamp_elf_be_windows_tarball
BUILD_DEPS-$(ENABLE_WINDOWS_INSTALLER) += $O/$(IDE_WIN_EXE)

BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_UIMAGE)
BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_CPIO)
BUILD_DEPS-$(ENABLE_LINUX_IMAGES) += $O/$(LINUX_IMAGES_DIR)/$(LINUX_AXS103_ROOTFS_TAR)

# Build all components that can be built on Linux hosts.
.PHONY: build
build: $(BUILD_DEPS)

ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
$O/$(CHECKSUM_FILE): $O/$(IDE_WIN_EXE)
endif

$O/$(CHECKSUM_FILE): $(BUILD_DEPS)
	cd $O && $(CHECKSUM) $(UPLOAD_ARTIFACTS) > $@

.PHONY: checksum
checksum: $O/$(CHECKSUM_FILE)

source-tarball: $O/.stamp_source_tarball

elf-le-build: $O/.stamp_elf_le_built

elf-be-build: $O/.stamp_elf_be_built

elf-le: $O/.stamp_elf_le_tarball

elf-be: $O/.stamp_elf_be_tarball

.PHONY: glibc-le
glibc-le: $O/.stamp_glibc_le_hs_tarball

.PHONY: glibc-be
glibc-be: $O/.stamp_glibc_be_hs_tarball

windows: $O/.stamp_elf_le_windows_tarball $O/.stamp_elf_be_windows_tarball

ide: $O/.stamp_ide_linux_tar $O/$(IDE_PLUGINS_ZIP)

#
# Initial preparations
#

.PHONY: clone
clone:
	# $(call git_clone,binutils-gdb,binutils)
	# $(call git_clone,gcc,gcc)
	# $(call git_clone,binutils-gdb,gdb)
	# $(call git_clone,newlib,newlib)
	# $(call git_clone_url,https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git,linux)
	# $(call git_clone_url,git@github.com:wbx-github/uclibc-ng.git,uclibc-ng)
	$(call git_clone,arc_gnu_eclipse,arc_gnu_eclipse)
ifeq ($(ENABLE_OPENOCD),y)
	$(call git_clone,openocd,openocd)
endif
# ifeq ($(ENABLE_GLIBC_TOOLS),y)
# 	$(call git_clone,glibc,glibc)
# endif


.PHONY: copy-external
copy-external: | $O
ifeq ($(ENABLE_IDE),y)

ifeq ($(THIRD_PARTY_SOFTWARE_LOCATION),)
	$(error THIRD_PARTY_SOFTWARE_LOCATION must be set to do copy-external)
endif

ifneq ($(ENABLE_IDE_PLUGINS_BUILD),y)
ifeq ($(IDE_PLUGIN_LOCATION),)
	$(error IDE_PLUGIN_LOCATION must be set to do copy-external)
endif
	# Copy IDE Plugin
	$(CP) $(IDE_PLUGIN_LOCATION)/$(IDE_PLUGINS_ZIP) $O
endif

	# Copy JRE.
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_LINUX_TGZ) $O/$(JRE_LINUX_TGZ)

ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(JRE_WIN_ZIP) $O/$(JRE_WIN_ZIP)
endif

	# Copy Eclipse
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_MACOS_TGZ) $O
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_LINUX_TGZ) $O

ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
	$(CP) $(THIRD_PARTY_SOFTWARE_LOCATION)/$(ECLIPSE_VANILLA_WIN_ZIP) $O
endif
endif

.PHONY: prerequisites
prerequisites: clone copy-external


.PHONY: distclean
distclean: clean
	rm -rf $(ROOT)/{binutils,gcc,gdb,newlib,linux,uclibc-ng}
	rm -rf $(ROOT)/openocd

#
# Build targets
#
DIRS += $O
TOOLS_ALL_ORDER_DEPS-y += $O

# Create source tarball
$O/.stamp_source_tarball: | $(TOOLS_ALL_ORDER_DEPS-y)
	tar --exclude-vcs -c -z -f $O/$(TOOLS_SOURCE_DIR)$(TAR_EXT) --exclude=$O \
	    --transform="s|^|arc_gnu_$(RELEASE)_sources/|" $(TOOLS_SOURCE_CONTENTS)
	touch $@


TOOLS_ALL_DEPS-$(ENABLE_PDF_DOCS) += $(PDF_DOC_FILE)
ifeq ($(ENABLE_SOURCE_TARBALL),y)
$(PDF_DOC_FILE): $O/.stamp_source_tarball
endif
$(PDF_DOC_FILE):
	$(MAKE) -C doc clean
	$(MAKE) -C doc pdf

# $1 - destination directory.
ifeq ($(ENABLE_PDF_DOCS),y)
define copy_pdf_doc_file
	mkdir -p $1/share/doc/
	$(CP) $(PDF_DOC_FILE) $1/share/doc/
endef
else
define copy_pdf_doc_file
endef
endif

$O/.stamp_elf_le_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-multilib-elf32,$(TOOLS_ELFLE_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFLE_HOST_DIR))
	touch $@

$O/.stamp_elf_be_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-multilib-elf32,$(TOOLS_ELFBE_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFBE_HOST_DIR))
	touch $@

$O/.stamp_elf_le_tarball: $O/.stamp_elf_le_built
	$(call create_tar,$(TOOLS_ELFLE_HOST_DIR))
	touch $@

$O/.stamp_elf_be_tarball: $O/.stamp_elf_be_built
	$(call create_tar,$(TOOLS_ELFBE_HOST_DIR))
	touch $@

$O/.stamp_uclibc_le_700_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-arc700-linux-uclibc,$(TOOLS_UCLIBC_LE_700_HOST_DIR))
	touch $@

$O/.stamp_uclibc_be_700_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-arc700-linux-uclibc,$(TOOLS_UCLIBC_BE_700_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_UCLIBC_BE_700_HOST_DIR))
	touch $@

$O/.stamp_uclibc_le_hs_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-archs-linux-uclibc,$(TOOLS_UCLIBC_LE_HS_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_UCLIBC_LE_HS_HOST_DIR))
	touch $@

$O/.stamp_uclibc_be_hs_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-archs-linux-uclibc,$(TOOLS_UCLIBC_BE_HS_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_UCLIBC_BE_HS_HOST_DIR))
	touch $@

$O/.stamp_glibc_le_hs_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-archs-linux-gnu,$(TOOLS_GLIBC_LE_HS_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_GLIBC_LE_HS_HOST_DIR))
	touch $@

$O/.stamp_glibc_be_hs_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-archs-linux-gnu,$(TOOLS_GLIBC_BE_HS_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_GLIBC_BE_HS_HOST_DIR))
	touch $@

$O/.stamp_arc64_elf_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc64-unknown-elf,$(TOOLS_ELF_ARC64_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELF_ARC64_HOST_DIR))

$O/.stamp_arc64_linux_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc64-snps-linux-gnu,$(TOOLS_LINUX_ARC64_HOST_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_LINUX_ARC64_HOST_DIR))

$O/.stamp_uclibc_le_700_tarball: $O/.stamp_uclibc_le_700_built
	$(call create_tar,$(TOOLS_UCLIBC_LE_700_HOST_DIR))
	touch $@

$O/.stamp_uclibc_le_hs_tarball: $O/.stamp_uclibc_le_hs_built
	$(call create_tar,$(TOOLS_UCLIBC_LE_HS_HOST_DIR))
	touch $@

$O/.stamp_uclibc_be_700_tarball: $O/.stamp_uclibc_be_700_built
	$(call create_tar,$(TOOLS_UCLIBC_BE_700_HOST_DIR))
	touch $@

$O/.stamp_uclibc_be_hs_tarball: $O/.stamp_uclibc_be_hs_built
	$(call create_tar,$(TOOLS_UCLIBC_BE_HS_HOST_DIR))
	touch $@

$O/.stamp_glibc_le_hs_tarball: $O/.stamp_glibc_le_hs_built
	$(call create_tar,$(TOOLS_GLIBC_LE_HS_HOST_DIR))
	touch $@

$O/.stamp_glibc_be_hs_tarball: $O/.stamp_glibc_be_hs_built
	$(call create_tar,$(TOOLS_GLIBC_BE_HS_HOST_DIR))
	touch $@

$O/.stamp_arc64_elf_tarball: $O/.stamp_arc64_elf_built
	$(call create_tar,$(TOOLS_ELF_ARC64_HOST_DIR))
	touch $@

$O/.stamp_arc64_linux_tarball: $O/.stamp_arc64_linux_built
	$(call create_tar,$(TOOLS_LINUX_ARC64_HOST_DIR))
	touch $@

#
# macOS toolchain
#

$O/.stamp_elf_le_mac_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-elf32-macos,$(TOOLS_ELFLE_MAC_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFLE_MAC_DIR))
	touch $@

$O/.stamp_elf_be_mac_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-elf32-macos,$(TOOLS_ELFBE_MAC_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFBE_MAC_DIR))
	touch $@

$O/.stamp_elf_le_mac_tarball: $O/.stamp_elf_le_mac_built
	$(call create_tar,$(TOOLS_ELFLE_MAC_DIR))
	touch $@

$O/.stamp_elf_be_mac_tarball: $O/.stamp_elf_be_mac_built
	$(call create_tar,$(TOOLS_ELFBE_MAC_DIR))
	touch $@

#
# Windows build
#

ifeq ($(ENABLE_WINDOWS_INSTALLER),y)
WINDOWS_SYSROOT := $(shell $(WINDOWS_TRIPLET)-gcc -print-sysroot)/mingw
endif

# Helper function to copy mingw .dll files to installation directories with
# executable files. There are several directories and for simplicity all .dlls
# are copied to all target location.
#
# :param $1 - toolchain installation directory, e.g. $O/$(TOOLS_ELFLE_WIN_DIR).
# :param $2 - toolchain triplet, e.g. arc-elf32, arceb-elf32, etc.
ifneq ($(CONFIG_STATIC_TOOLCHAIN),y)
define copy_mingw_dlls
	for t in $(addprefix $1/,bin $2/bin libexec/gcc/$2/*/); do\
		cp -a $(WINDOWS_SYSROOT)/bin/* $$t ; \
	done
endef
endif

$O/.stamp_elf_le_windows_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-elf32-win,$(TOOLS_ELFLE_WIN_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFLE_WIN_DIR))
	touch $@

$O/.stamp_elf_be_windows_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arceb-elf32-win,$(TOOLS_ELFBE_WIN_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_ELFBE_WIN_DIR))
	touch $@

$O/.stamp_elf_le_windows_tarball: $O/.stamp_elf_le_windows_built
	$(call create_windows_tar,$(TOOLS_ELFLE_WIN_DIR))
	touch $@

$O/.stamp_elf_be_windows_tarball: $O/.stamp_elf_be_windows_built
	$(call create_windows_tar,$(TOOLS_ELFBE_WIN_DIR))
	touch $@


#
# Common build directory.
#
DIRS += $(BUILD_DIR)

#
# Linux
#

BUILDROOT_VERSION = 2018.08.2
BUILDROOT_TAR = buildroot-$(BUILDROOT_VERSION).tar.bz2
BUILDROOT_URL = https://buildroot.org/downloads/$(BUILDROOT_TAR)
BUILDROOT_SRC_DIR = $(BUILD_DIR)/buildroot
BUILDROOT_AXS103_BUILD_DIR = $(BUILD_DIR)/buildroot_axs103
BUILDROOT_AXS103_DEFCONFIG := $(ROOT)/toolchain/extras/buildroot/axs103.defconfig
BUILDROOT_AXS103_MAKEFLAGS = -C $(BUILDROOT_SRC_DIR) \
	O=$(abspath $(BUILDROOT_AXS103_BUILD_DIR)) \
	ARC_TOOLCHAIN_PATH=$(realpath $O/$(TOOLS_UCLIBC_LE_HS_HOST_DIR)) \
	LINUX_SRC_PATH=$(realpath $(ROOT)/linux) \
	DEFCONFIG=$(BUILDROOT_AXS103_DEFCONFIG)

# Download Buildroot
$(BUILD_DIR)/$(BUILDROOT_TAR):
	$(WGET) $(WGETFLAGS) -O $@ $(BUILDROOT_URL)

# Prepare Buildroot source directory
$(BUILDROOT_SRC_DIR): $(BUILD_DIR)/$(BUILDROOT_TAR) | $(BUILD_DIR)
	mkdir -p $@
	tar -C $@ --strip-components=1 -x -a -f $<

DIRS += $O/$(LINUX_IMAGES_DIR)

# Configure Buildroot for AXS103
$(BUILDROOT_AXS103_BUILD_DIR)/.config: $(BUILDROOT_AXS103_DEFCONFIG)
$(BUILDROOT_AXS103_BUILD_DIR)/.config: | $(BUILDROOT_SRC_DIR)
$(BUILDROOT_AXS103_BUILD_DIR)/.config:
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
$O/.stamp_glibc_le_hs_native_built: $(TOOLS_ALL_DEPS-y) | $(TOOLS_ALL_ORDER_DEPS-y)
	$(call copy_prebuilt,arc-archs-native-gnu,$(TOOLS_GLIBC_LE_HS_NATIVE_DIR))
	$(call copy_pdf_doc_file,$O/$(TOOLS_GLIBC_LE_HS_NATIVE_DIR))
	touch $@

$O/.stamp_glibc_le_hs_native_tarball: $O/.stamp_glibc_le_hs_native_built
	$(call create_tar,$(TOOLS_GLIBC_LE_HS_NATIVE_DIR))
	touch $@

#
# IDE related targets
#
ifeq ($(ENABLE_IDE),y)

$O/$(ECLIPSE_VANILLA_LINUX_TGZ):
	$(WGET) $(WGETFLAGS) -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_LINUX_TGZ)&r=1'

$O/$(ECLIPSE_VANILLA_WIN_ZIP):
	$(WGET) $(WGETFLAGS) -O $@ '$(ECLIPSE_DL_LINK_BASE)/$(ECLIPSE_VANILLA_WIN_ZIP)&r=1'

#
# Building IDE Plugins
#
ifeq ($(ENABLE_IDE_PLUGINS_BUILD),y)

IDE_PLUGIN_SRC_DIR=$(ROOT)/arc_gnu_eclipse
IDE_PLUGIN_BUILD_DIR=$(IDE_PLUGIN_SRC_DIR)/build
IDE_PLUGIN_OUT_DIR=$(IDE_PLUGIN_SRC_DIR)/repository/target/

$O/$(IDE_PLUGINS_ZIP):
	cd $(IDE_PLUGIN_SRC_DIR) && $(IDE_PLUGIN_BUILD_DIR)/build-repository.sh
	$(CP) $(IDE_PLUGIN_OUT_DIR)/repository-*-SNAPSHOT.zip $@

endif

# Install ARC plugins from .zip file and install prerequisites in Eclipse.
# Similar invocation is in windows/build-release.sh. Those invocations must be
# in sync.
$O/.stamp_ide_linux_eclipse: $O/$(ECLIPSE_VANILLA_LINUX_TGZ) $O/$(IDE_PLUGINS_ZIP)
	mkdir -m775 -p $O/$(IDE_LINUX_INSTALL)
	tar xf $< -C $O/$(IDE_LINUX_INSTALL)
	unzip $O/${IDE_PLUGINS_ZIP} -d $O/$(IDE_LINUX_INSTALL)/eclipse/dropins
	rm -f $O/$(IDE_LINUX_INSTALL)/eclipse/dropins/artifacts.jar
	rm -f $O/$(IDE_LINUX_INSTALL)/eclipse/dropins/content.jar
	echo "-Dosgi.instance.area.default=@user.home/ARC_GNU_IDE_Workspace" >> $O/$(IDE_LINUX_INSTALL)/eclipse/eclipse.ini
	touch $@

$O/.stamp_ide_linux_tar: \
	$O/$(OOCD_HOST_DIR)$(TAR_EXT) \
	$O/.stamp_ide_linux_eclipse \
	$O/.stamp_elf_be_built $O/.stamp_elf_le_built \
	$O/.stamp_uclibc_be_hs_built $O/.stamp_uclibc_le_hs_built
	$(LOCAL_CP) $O/$(TOOLS_ELFLE_HOST_DIR)/* $O/$(IDE_LINUX_INSTALL)
	$(LOCAL_CP) $O/$(TOOLS_ELFBE_HOST_DIR)/* $O/$(IDE_LINUX_INSTALL)
	$(LOCAL_CP) $O/$(TOOLS_UCLIBC_LE_HS_HOST_DIR)/* $O/$(IDE_LINUX_INSTALL)
	$(LOCAL_CP) $O/$(TOOLS_UCLIBC_BE_HS_HOST_DIR)/* $O/$(IDE_LINUX_INSTALL)
	mkdir -p -m775 $O/$(IDE_LINUX_INSTALL)/eclipse/jre
	# OpenJ9 tarball has paths starting with `./jdk-11.0.1_13-jre`, thus it is
	# needed to strip 2 components instead of 1.
	tar xf $O/$(JRE_LINUX_TGZ) -C $O/$(IDE_LINUX_INSTALL)/eclipse/jre \
	    --strip-components=2
	$(LOCAL_CP) $O/$(OOCD_HOST_DIR)/* $O/$(IDE_LINUX_INSTALL)
	tar czf $O/$(IDE_LINUX_TGZ) -C $O --owner=0 --group=0 $(IDE_LINUX_INSTALL)
	touch $@

#
# IDE on macOS
#
$O/.stamp_ide_macos_eclipse: $O/$(ECLIPSE_VANILLA_MACOS_TGZ) $O/$(IDE_PLUGINS_ZIP)
	mkdir -m775 -p $O/$(IDE_MACOS_INSTALL)
	tar xf $< -C $O/$(IDE_MACOS_INSTALL)
	unzip $O/$(IDE_PLUGINS_ZIP) -d $O/$(IDE_MACOS_INSTALL)/Eclipse.app/Contents/Eclipse/dropins
	rm -f $O/$(IDE_MACOS_INSTALL)/Eclipse.app/Contents/Eclipse/dropins/artifacts.jar
	rm -f $O/$(IDE_MACOS_INSTALL)/Eclipse.app/Contents/Eclipse/dropins/content.jar
	echo "-Dosgi.instance.area.default=@user.home/ARC_GNU_IDE_Workspace" >> $O/$(IDE_MACOS_INSTALL)/Eclipse.app/Contents/Eclipse/eclipse.ini
	touch $@

$O/.stamp_ide_macos_tar: \
	$O/$(OOCD_MAC_DIR)$(TAR_EXT) \
	$O/.stamp_ide_macos_eclipse \
	$O/.stamp_elf_le_mac_built $O/.stamp_elf_be_mac_built
	$(LOCAL_CP) $O/$(TOOLS_ELFLE_MAC_DIR)/* $O/$(IDE_MACOS_INSTALL)
	$(LOCAL_CP) $O/$(TOOLS_ELFBE_MAC_DIR)/* $O/$(IDE_MACOS_INSTALL)
	mkdir -p -m775 $O/$(IDE_MACOS_INSTALL)/eclipse/jre
	$(LOCAL_CP) $O/$(OOCD_MAC_DIR)/* $O/$(IDE_MACOS_INSTALL)
	tar czf $O/$(IDE_MACOS_TGZ) -C $O --owner=0 --group=0 $(IDE_MACOS_INSTALL)
	touch $@

endif

#
# OpenOCD
#

.PHONY: openocd-linux
openocd-linux: $O/$(OOCD_HOST_DIR)$(TAR_EXT)

DIRS += $(OOCD_BUILD_HOST_DIR)


# Bootstrap is common to Linux and Windows.
$(OOCD_SRC_DIR)/configure:
	cd $(OOCD_SRC_DIR) && ./bootstrap


# Configure OpenOCD
$(OOCD_BUILD_HOST_DIR)/Makefile: | $(OOCD_SRC_DIR)/configure \
	$(OOCD_BUILD_HOST_DIR)

$(OOCD_BUILD_HOST_DIR)/Makefile:
	cd $(OOCD_BUILD_HOST_DIR) && \
		$(OOCD_SRC_DIR)/configure \
	    --enable-ftdi --disable-werror \
	    --disable-libusb0 \
	    PKG_CONFIG_PATH=$(abspath $(BUILD_DIR)/libusb_$(HOST)_install)/lib/pkgconfig \
	    PKG_CONFIG=pkg-config \
	    --prefix=$(abspath $O/$(OOCD_HOST_DIR))


# Build OpenOCD
define OOCD_BUILD_CMD
	$(MAKE) -C $(OOCD_BUILD_$1_DIR) all pdf LC_ALL=C
endef

$(OOCD_BUILD_HOST_DIR)/src/openocd: $(OOCD_BUILD_HOST_DIR)/Makefile
	$(call OOCD_BUILD_CMD,HOST)


# Instal OpenOCD
define OOCD_INSTALL_CMD
	$(MAKE) -C $(OOCD_BUILD_$1_DIR) install install-pdf
endef

$O/$(OOCD_HOST_DIR)/bin/openocd: $(OOCD_BUILD_HOST_DIR)/src/openocd
	$(call OOCD_INSTALL_CMD,HOST)


# Tarball for OpenOCD
$O/$(OOCD_HOST_DIR)$(TAR_EXT): $O/$(OOCD_HOST_DIR)/bin/openocd
	$(call create_tar,$(OOCD_HOST_DIR))

#
# OpenOCD for Windows
#
.PHONY: openocd-win
openocd-win: $O/$(OOCD_WIN_DIR)$(TAR_EXT) $O/$(OOCD_WIN_DIR).zip

DIRS += $(OOCD_BUILD_WIN_DIR)

#
# Libusb for Windows
#
$(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2: | $(BUILD_DIR)

$(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2:
	$(WGET) $(WGETFLAGS) -O $@ \
		'https://github.com/libusb/libusb/releases/download/v$(LIBUSB_VERSION)/libusb-$(LIBUSB_VERSION).tar.bz2'


$(BUILD_DIR)/libusb_$(HOST)_src: $(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2
	tar -C $(BUILD_DIR) -xf $< --transform='s/libusb-$(LIBUSB_VERSION)/libusb_$(HOST)_src/'


# udev should be disabled, to avoid dependency on libudev.so, because various
# distributions might have different versions (CentOS 6 uses libudev.so.0,
# while CentOS 7 uses libudev.so.1).
.PHONY: libusb-linux-install
libusb-linux-install: $(BUILD_DIR)/libusb_$(HOST)_install/lib/libusb-1.0.a
$(BUILD_DIR)/libusb_$(HOST)_install/lib/libusb-1.0.a: $(BUILD_DIR)/libusb_$(HOST)_src
	cd $< && \
	./configure --disable-shared --enable-static \
		--disable-udev \
		--prefix=$(abspath $(BUILD_DIR)/libusb_$(HOST)_install)
	$(MAKE) -C $< -j1
	$(MAKE) -C $< install


$(BUILD_DIR)/libusb_win_src: $(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2
	tar -C $(BUILD_DIR) -xf $< --transform='s/libusb-$(LIBUSB_VERSION)/libusb_win_src/'


# It looks like that libusb Makefile is not parallel-friendly, it fails with error
# 	mv: cannot stat `.deps/libusb_1_0_la-core.Tpo': No such file or directory
# in parallel build, therefore we have to force sequential build on it.
.PHONY: libusb-win-install
libusb-win-install: $(BUILD_DIR)/libusb_win_install/lib/libusb-1.0.a
$(BUILD_DIR)/libusb_win_install/lib/libusb-1.0.a: $(BUILD_DIR)/libusb_win_src
	cd $< && \
	./configure --host=$(WINDOWS_TRIPLET) --disable-shared --enable-static \
		--prefix=$(abspath $(BUILD_DIR)/libusb_win_install)
	$(MAKE) -C $< -j1
	$(MAKE) -C $< install


# Configure OpenOCD for Windows.
$(OOCD_BUILD_WIN_DIR)/Makefile: | $(OOCD_SRC_DIR)/configure
$(OOCD_BUILD_WIN_DIR)/Makefile: $(BUILD_DIR)/libusb_win_install/lib/libusb-1.0.a
$(OOCD_BUILD_WIN_DIR)/Makefile: | $(OOCD_BUILD_WIN_DIR)

$(OOCD_BUILD_WIN_DIR)/Makefile:
	cd $(OOCD_BUILD_WIN_DIR) && \
	PKG_CONFIG_PATH=$(abspath $(BUILD_DIR)/libusb_win_install)/lib/pkgconfig \
	$(OOCD_SRC_DIR)/configure \
	    --enable-ftdi --disable-werror \
	    --disable-shared --enable-static \
	    --disable-libusb0 \
	    --host=$(WINDOWS_TRIPLET) \
	    PKG_CONFIG=pkg-config \
	    --prefix=$(abspath $O/$(OOCD_WIN_DIR))


# Build OpenOCD for Windows.
$(OOCD_BUILD_WIN_DIR)/src/openocd.exe: $(OOCD_BUILD_WIN_DIR)/Makefile
	$(call OOCD_BUILD_CMD,WIN)


# Install OpenOCD for Windows.
$O/$(OOCD_WIN_DIR)/bin/openocd.exe: $(OOCD_BUILD_WIN_DIR)/src/openocd.exe
	$(call OOCD_INSTALL_CMD,WIN)


# Create tarball for OpenOCD for Windows.
$O/$(OOCD_WIN_DIR)$(TAR_EXT): $O/$(OOCD_WIN_DIR)/bin/openocd.exe
	$(call create_tar,$(OOCD_WIN_DIR))


# Create zip for OpenOCD for Windows.
$O/$(OOCD_WIN_DIR).zip: $O/$(OOCD_WIN_DIR)/bin/openocd.exe
	$(call create_zip,$(OOCD_WIN_DIR))

#
# OpenOCD for macOS
#

.PHONY: openocd-mac
openocd-mac: $O/$(OOCD_MAC_DIR)$(TAR_EXT)

DIRS += $(OOCD_BUILD_MAC_DIR)

#
# Libusb for macOS
#
$(BUILD_DIR)/libusb_mac_src: $(BUILD_DIR)/libusb-$(LIBUSB_VERSION).tar.bz2
	tar -C $(BUILD_DIR) -xf $< --transform='s/libusb-$(LIBUSB_VERSION)/libusb_mac_src/'


# It looks like that libusb Makefile is not parallel-friendly, it fails with error
# 	mv: cannot stat `.deps/libusb_1_0_la-core.Tpo': No such file or directory
# in parallel build, therefore we have to force sequential build on it.
.PHONY: libusb-mac-install
libusb-mac-install: $(BUILD_DIR)/libusb_mac_install/lib/libusb-1.0.a
$(BUILD_DIR)/libusb_mac_install/lib/libusb-1.0.a: $(BUILD_DIR)/libusb_mac_src
	cd $< && \
	CC=o64-clang ./configure --host=$(MACOS_TRIPLET) --disable-shared --enable-static \
		--prefix=$(abspath $(BUILD_DIR)/libusb_mac_install)
	$(MAKE) -C $< -j1
	$(MAKE) -C $< install


# Configure OpenOCD for macOS.
$(OOCD_BUILD_MAC_DIR)/Makefile: | $(OOCD_SRC_DIR)/configure
$(OOCD_BUILD_MAC_DIR)/Makefile: $(BUILD_DIR)/libusb_mac_install/lib/libusb-1.0.a
$(OOCD_BUILD_MAC_DIR)/Makefile: | $(OOCD_BUILD_MAC_DIR)

$(OOCD_BUILD_MAC_DIR)/Makefile:
	cd $(OOCD_BUILD_MAC_DIR) && \
	LDFLAGS="-framework IOKit -framework CoreFoundation" \
	CC=o64-clang $(OOCD_SRC_DIR)/configure \
	    --enable-ftdi --disable-werror \
	    --disable-shared --enable-static \
	    --disable-libusb0 \
	    --host=$(MACOS_TRIPLET) \
	    PKG_CONFIG=pkg-config \
		PKG_CONFIG_PATH=$(abspath $(BUILD_DIR)/libusb_mac_install)/lib/pkgconfig \
	    --prefix=$(abspath $O/$(OOCD_MAC_DIR))


# Build OpenOCD for macOS.
$(OOCD_BUILD_MAC_DIR)/src/openocd: $(OOCD_BUILD_MAC_DIR)/Makefile
	$(call OOCD_BUILD_CMD,MAC)


# Install OpenOCD for macOS.
$O/$(OOCD_MAC_DIR)/bin/openocd: $(OOCD_BUILD_MAC_DIR)/src/openocd
	$(call OOCD_INSTALL_CMD,MAC)


# Create tarball for OpenOCD for macOS.
$O/$(OOCD_MAC_DIR)$(TAR_EXT): $O/$(OOCD_MAC_DIR)/bin/openocd
	$(call create_tar,$(OOCD_MAC_DIR))


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
	$(CP) $O/$(TOOLS_ELFLE_WIN_DIR)$(TAR_EXT) \
	      $O/$(TOOLS_ELFBE_WIN_DIR)$(TAR_EXT) \
	      $O/$(IDE_PLUGINS_ZIP) \
	      $O/$(OOCD_WIN_DIR)$(TAR_EXT) \
	      $O/$(ECLIPSE_VANILLA_WIN_ZIP) \
	      $O/$(JRE_WIN_ZIP) \
	      $(addprefix $(THIRD_PARTY_SOFTWARE_LOCATION)/,make coreutils) \
	      $(WINDOWS_WORKSPACE)/packages/
	$(CP) $(ROOT)/toolchain $(WINDOWS_WORKSPACE)/

	touch $@
endif

#
# Retrieve Windows installer
#
ifeq ($(ENABLE_WINDOWS_INSTALLER),y)

$O/$(IDE_WIN_EXE): $(WINDOWS_WORKSPACE)/$(IDE_WIN_EXE)
	$(CP) $< $@

$(WINDOWS_WORKSPACE)/$(IDE_WIN_EXE): $O/.stamp_windows_workspace \
	| $(WINDOWS_WORKSPACE)
	cd $(WINDOWS_WORKSPACE) && \
		RELEASE_TAG=$(RELEASE_TAG) toolchain/windows-installer/build-installer.sh

endif

#
# Documentation package
#
DIRS += $O/$(DOCS_DIR)
$O/$(DOCS_DIR)$(TAR_EXT): $O/.stamp_elf_le_built | $O/$(DOCS_DIR)
	$(CP) $O/$(TOOLS_ELFLE_HOST_DIR)/share/doc/ $O/$(DOCS_DIR)
	$(call create_tar,$(DOCS_DIR))


#
# Create tag
#
create-openocd-tag:
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
push-openocd-tag:
ifeq ($(ENABLE_OPENOCD),y)
	cd $(OOCD_SRC_DIR) && \
	    $(GIT) push origin $(RELEASE_TAG)
endif

#
# Deploy to shared file system
#
.PHONY: deploy
deploy: $O/$(CHECKSUM_FILE) $(addprefix $O/,$(DEPLOY_ARTIFACTS))
ifeq ($(DEPLOY_DESTINATION),)
	$(error DEPLOY_DESTINATION must be set to run 'deploy' target)
endif
	$(CP) $^ $(DEPLOY_DESTINATION)/$(RELEASE)
	$(DEPLOY_LINK_CMD)

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

ifeq ($(findstring :,$(DEPLOY_DESTINATION)),)
  DEPLOY_LINK_CMD=ln -fsT $(RELEASE) $(DEPLOY_DESTINATION)/latest
else
  DEPLOY_DESTINATION_HOST=$(shell cut -d: -f1 <<< "$(DEPLOY_DESTINATION)")
  DEPLOY_DESTINATION_PATH=$(shell cut -d: -f2 <<< "$(DEPLOY_DESTINATION)")
  DEPLOY_LINK_CMD=$(SSH) $(DEPLOY_DESTINATION_HOST) \
    'ln -fsT $(RELEASE) $(DEPLOY_DESTINATION_PATH)/latest'
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
deploy-build: .deploy-toolchain-build
	$(DEPLOY_BUILD_LINK_CMD)

ifeq ($(ENABLE_LINUX_IMAGES),y)
deploy-build: .deploy-linux-images
endif


#
# Upload
#
# This is not a part of a default target. Upload should be triggered manually.
# RELEASE_TAG and RELEASE_NAME mustbe set to something
upload: $O/$(CHECKSUM_FILE)
	$(PYTHON) github/create-release.py --owner=foss-for-synopsys-dwc-arc-processors \
	    --project=toolchain --tag=$(RELEASE_TAG) --draft \
	    --release-id=$(RELEASE) \
	    --name="$(RELEASE_NAME)" \
	    --prerelease --oauth-token=$(shell cat ~/.github_oauth_token) \
	    --checksum-file=$O/$(CHECKSUM_FILE) \
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
