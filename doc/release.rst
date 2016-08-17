Creating Toolchain Release
==========================


Introduction
------------

``release.mk`` is a makefile to create prebuilt packages of GNU Toolchain for
ARC. It relies on other scripts in toolchain repository to build components.

To build a release GNU Toolchain for ARC processors, several prerequisites
should be installed and/or built before running a ``release.mk`` which does most
of the work. List of prerequisites to build toolchain is list in toolchain
``README.md`` file. Note that there are extra dependencies to build toolchain
for Windows hosts, in addition to those that are required to build toolchain for
Linux hosts. To build IDE distributables, both for Windows and for Linux, a zip
file with Eclipse CDT plugins for ARC is required (see
:envvar:`IDE_PLUGIN_LOCATION`). To create Windows installer several MinGW and
MSYS components are required (path set by
:envvar:`THIRD_PARTY_SOFTWARE_LOCATION`). For a list of MinGW and MSYS packages,
please refer to `windows-installer/README.md` section "Prerequisites".

There are several variables that can be set to disable particular components,
like Windows installer or OpenOCD, however those are not specifically tested, so
may not really work. By default ``release.mk`` will build all of the possible
components.  It is also possible to invoke particular Make targets directly to
get only a limited set of distributales, however it is not possible to make
further targets like :option:`deploy` or :option:`upload` to use only this
limited set of files (there is always an option to modify ``release.mk`` to get
desired results).


Building Prerequisites
----------------------

Eclipse plugin for ARC
^^^^^^^^^^^^^^^^^^^^^^

.. warning:: This section doesn't cover a ``build/Makefile`` file in
   ``arc_gnu_eclipse`` repository which automates build process with ant.

Build Eclipse plugin for ARC following those guidelines:
https://github.com/foss-for-synopsys-dwc-arc-processors/arc_gnu_eclipse/wiki/Creating-Eclipse-plugins-release-zip-file
Create and push respective git tag::

    $ pushd arc_gnu_eclipse
    $ git tag arc-2016.03
    $ git push -u origin arc-2016.03
    $ popd


Environment Variables
---------------------

Those are make variables which can be set either as a parameters to make, like
``make PARAM=VALUE`` or they can be specified in the ``release.config`` file
that will be sourced by ``release.mk``.

.. envvar:: CONFIG_STATIC_TOOLCHAIN

   Whether to build toolchain linked dynamically or statically. Note this
   affects the toolchain executable files, not the target libraries.

   Possible values
      ``y`` and ``n``
   Default value
      ``n``

.. envvar:: DEPLOY_BUILD_DESTINATION

   Where to copy unpacked engineering build. Location is in format
   ``[hostname:]/path``. A directory named ``${RELEASE_TAG##-arc}`` will be
   created in the target path and will contain unpacked directories. Directories
   names are different from those that are in the tarballs - namely useless
   cruft is avoided and verion is not mentioned as well, so that it is easier to
   use those directories via symbolic links. For example, for tarball
   arc_gnu_2016.09-eng006_prebuilt_elf32_le_linux_install.tar.gz build directory
   will be elf32_le_linux.

.. envvar:: DEPLOY_DESTINATION

   Where to copy release distributables. Location is in format
   ``[hostname:]/path``. A directory named ``${RELEASE_TAG##-arc}`` will be
   created in the target path and will contain all deploy artifacts. So for
   ``RELEASE_TAG = arc-2016.03-alpha1`` directory will be ``2016.03-alpha1``, while
   for ``RELEASE_TAG = arc-2016.03`` it will be ``2016.03``.

.. envvar:: ENABLE_DOCS_PACKAGE

   Whether to build separate packages with just documentation PDF files.

   Possible values
      ``y`` and ``n``
   Default value
      ``n``

.. envvar:: ENABLE_IDE

   Whether to build and upload IDE distributable package.  Note that build
   script for Windows installer always assumes presence of IDE, therefore it is
   not possible to build it when this option is ``n``.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``


.. envvar:: ENABLE_LINUX_IMAGES

   Whether to build and deploy Linux images built with this toolchain. This
   targets uses Buildroot to build rootfs and uImage for AXS103.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``


.. envvar:: ENABLE_NATIVE_TOOLS

   Whether to build and upload native toolchain. Currently toolchain is built
   only for ARC HS Linux.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``


.. envvar:: ENABLE_OPENOCD

   Whether to build and upload OpenOCD distributable package for Linux. IDE
   targets will not work if OpenOCD is disabled. Therefore if this is ``n``,
   then :envvar:``ENABLE_IDE`` and :envvar:`ENABLE_WINDOWS_INSTALLER`` also must
   be ``n``.

   Possible values:
      ``y`` and ``n``

   Default value:
      ``y``

.. envvar:: ENABLE_OPENOCD_WIN

   Whether to build and upload OpenOCD for Windows. This target currently
   depends on :envvar:`ENABLE_OPENOCD`, which causes source code to be cloned
   for OpenOCD. OpenOCD for Windows build will download and build libusb library
   and is a prerequisite for IDE for Windows build.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``


.. envvar:: ENABLE_WINDOWS_INSTALLER

   Whether to build and upload Windows installer for toolchain and IDE. While
   building of installer can be also skipped simply by not invoking respective
   make targets, installer files still will be in the list of files that should
   be deployed and uploaded to GitHub, therefore this variable should be set to
   ``n`` for installer to be completely skipped. This variable also disables
   build of the toolchain for Windows as well.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``

.. envvar:: GIT_REFERENCE_ROOT

   Root location of existing source tree with all toolchain components Git
   repositories. Those repositorie swill be used as a reference when cloning
   source tree - this reduces time to clone and disk space consumed. Note that
   all of the components must exist in reference root, otherwise clone will
   fail.

.. envvar:: IDE_PLUGIN_LOCATION

   Location of ARC plugin for Eclipse. This must be a directory and plugin file
   must have a name ``arc_gnu_${RELEASE_TAG##arc-}_ide_plugin.zip``. File will
   be copied with rsync therefore location may be prefixed with hostname
   separated by semicolon, as in ``host:/path``.


.. envvar:: LIBUSB_VERSION

   Version of Libusb used for OpenOCD build for Windows.

   Default value
      1.0.20


.. envvar:: RELEASE_NAME

   Name of the release, for example "GNU Toolchain for ARC Processors, 2016.03".

.. envvar:: RELEASE_TAG

   Git tag for this release. Tag is used literaly and can be for example,
   arc-2016.03-alpha1.


.. envvar:: THIRD_PARTY_SOFTWARE_LOCATION

   Location of 3rd party software, namely Java Runtime Environment (JRE) and
   Eclipse tarballs.


.. envvar:: WINDOWS_TRIPLET

   Triplet of MinGW toolchain to do a cross-build of toolchain for Windows.

   Default value
      i686-w64-mingw32


.. envvar:: WINDOWS_WORKSPACE

   Path to a directory that is present on build host and is also somehow
   available on a Windows host where Windows installer will be built. Basic
   scenario is when this location is on the Linux hosts, shared via Samba/CIFS
   and mounted on Windows host. Note that on Windows path to this directory,
   should be as short as possible , because Eclipse contains very long file
   names, while old NSIS uses ancient Windows APIs, which are pretty limited in
   the maximum file length. As a result build might fail due to too long path,
   if :envvar`WINDOWS_LOCATION` is too long on Windows host.


Make targets
------------

.. option:: build

   Build all distributable components that can be built on RHEL hosts. The
   only components that are not built by this target are:

   * OpenOCD for Windows - (has to be built on Ubuntu
   * ARC plugins for Eclipse - built by external job
   * Windows installer - created on Windows hosts. This tasks would depend on
     toolchain created by :option:`build` target.

   This target is affected by :envvar:`RELEASE_TAG`.

.. option:: copy-windows-installer

   Copy Windows installer, created by ``windows-installer/build-installer.sh``
   from :envvar:`WINDOWS_WORKSPACE` to ``release_output`` directory.

.. option:: create-tag

   Create Git tags for released components. Required environment variables:
   :envvar:`RELEASE_TAG`, :envvar:`RELEASE_NAME`. OpenOCD must have a branch
   named ``arc-0.9-dev-${RELEASE_BRANCH}``, where ``RELEASE_BRANCH`` is a bare
   release, evaluated from the tag, so for :envvar:`RELEASE_TAG` of
   ``arc-2016.09-eng003``, ``RELEASE_BRANCH`` would be ``2016.09``.

.. option:: deploy

   Deploy build artifacts to remote locations. It deploys same files as those
   that are released, and a few extra ones (like Windows toolchain tarballs).
   This target just copies deploy artifacts to location specified by
   :envvar:`DEPLOY_DESTINATION`. This target depends on
   :envvar:`DEPLOY_DESTINATION` and on :envvar:`WINDOWS_WORKSPACE`.

.. option:: distclean

   Remove all cloned sources as well as build artifacts.

.. option:: prerequisites

   Clone sources of toolchain components from GitHub. Copy external components
   from specified locations. Is affected by following environment variables:
   :envvar:`RELEASE_TAG`, :envvar:`GIT_REFERENCE_ROOT` (optional),
   :envvar:`IDE_PLUGIN_LOCATION`,
   :envvar:`THIRD_PARTY_SOFTWARE_LOCATION`.

.. option:: push-tag

   Push Git tags to GitHub.

.. option:: upload

   Upload release distributables to GitHub Releases. A new GitHub "Release" is
   created and bound to the Git tag specified in :envvar:`RELEASE_TAG`. This
   target also depends on :envvar:`RELEASE_NAME` to specify name of release on
   GitHub.

.. option:: windows-workspace

   Create a workspace to run ``windows-installer/build-installer.sh`` script.
   Location of workspace is specified with :envvar:`WINDOWS_WORKSPACE`.
   ``build-installer.sh`` script will create an installer in the workspace
   directory. To copy installer from workspace to ``release_output`` use
   :option:`copy-windows-installer`.


Invocation
----------

Release process consists of several sequential steps that should be done in the
specified order. Some custom modifications can be done in between those steps.

First, create directory-workspace::

    $ mkdir arc-2016.03
    $ cd arc-2016.03

Clone the ``toolchain`` repository::

    $ git clone -b arc-dev \
      https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git

That command uses an HTTPS protocol to do Git clone - other protocols may be
used as well. This documentation assumes the default case where ``arc-dev``
branch is the base for the release.

.. note::
   Currently ``tag-release.sh`` script used in the release process has a check
   that ensures that current branch is a developemnt branch by checking that
   branch name ends in ``-dev``.

First setup required make variables in the ``release.config`` file that will be
sourced by ``release.mk`` (``...`` must be replaced with an actual paths)::

    $ cat release.config
    RELEASE_TAG=arc-2016.03
    IDE_PLUGIN_LOCATION=...
    THIRD_PARTY_SOFTWARE_LOCATION=...
    GIT_REFERENCE_ROOT=...
    WINDOWS_WORKSPACE=...

Fetch prerequisites (git repositories and external packages)::

    $ make -f release.mk prerequisites

Create git tags::

    $ make -f release.mk create-tag

Build toolchain::

    $ make -f release.mk build

Prepare workspace for Windows installer build script. Note that target
location, as specified by :envvar:`WINDOWS_WORKSPACE` should be shared with
Windows host on which installer will be built. ::

    $ make -f release.mk windows-workspace

On Windows host, build installer using ``windows-installer/build-installer.sh``
script. Note that this script requires a basic cygwin environment. ::

    $ RELEASE_BRANCH=2016.03 toolchain/windows-installer/build-installer.sh

Copy Windows installer from :envvar:`WINDOWS_WORKSPACE` into
``release_output``::

    $ make -f release.mk copy-windows-installer

Deploy toolchain to required locations. This target may be called multiple
times with different :envvar:`DEPLOY_DESTINATION` values::

    $ make -f release.mk deploy DEPLOY_DESTINATION=<site1:/pathA>
    $ make -f release.mk deploy DEPLOY_DESTINATION=<site2:/pathB>

Similarly, unpacked builds can be deployed to multiple locations::

    $ make -f release.mk deploy-build DEPLOY_BUILD_DESTINATION=<site1:/pathC>
    $ make -f release.mk deploy-build DEPLOY_BUILD_DESTINATION=<site2:/pathD>

Push tags to remote repositories::

    $ make -f release.mk push-tag

Finally, upload assets to GitHub Releases::

    $ make -f release.mk upload

.. vim: set tw=80 expandtab sts=3 sw=3 ts=3: 
