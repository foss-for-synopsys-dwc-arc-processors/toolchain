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
:envvar:`IDE_PLUGIN_LOCATION`). To create Windows installer a distributable of
OpenOCD for Windwos is required (see :envvar:`OPENOCD_WINDOWS_LOCATION`) and
several MinGW and MSYS components are required (path set by
:envvar:`THIRD_PARTY_SOFTWARE_LOCATION`). For a list of MinGW and MSYS packages,
please refer to `windows-installer/README.md` section "Prerequisites".

Currently ``release.mk`` doesn't properly support ability to select particular
release packages to build, so, for example, it is not possible to select that
only toolchain for Linux distributalbes are required. While it is possible to
invoke particular Make targets directly to get only a limited set of
distributales, it is not possible to make further targets like :option:`deploy`
or :option:`upload` to use only this limited set of files (there is always an
option to modify ``release.mk`` to get desired results).


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


OpenOCD for Windows
^^^^^^^^^^^^^^^^^^^

OpenOCD for Windows cannot be linked with MinGW tools from EPEL, instead they
should be built on Ubuntu::

    $ sudo apt-get install libtool git-core build-essential autoconf automake \
      texinfo texlive pkg-config gcc-mingw-w64
    $ mkdir openocd_build
    $ cd openocd_build

Copy here extracted FTD2xx drivers, like::

    $ mv ~/tmp/CDM\ v2.12.00\ WHQL\ Certified/ ftd2xx

Get Makefile.openocd from toolchain repository::

    $ wget https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/\
      blob/arc-dev/windows-installer/Makefile.openocd

Get source and checkout to tag::

    $ git clone https://github.com/foss-for-synopsys-dwc-arc-processors/openocd.git
    $ pushd openocd
    $ git checkout arc-2016.03
    $ popd

Build. :envvar:`INSTALL_DIR` is a destination where OpenOCD for Windows will be
installed::

    $ make -f Makefile.openocd \
      INSTALL_DIR=/media/sf_akolesov/pub/arc_gnu_2016.03_openocd_win_install


Environment Variables
---------------------

.. envvar:: DEPLOY_DESTINATION

   Where to copy release distributables. Location is in format
   ``[hostname:]/path``.

.. envvar:: ENABLE_IDE

   Whether to build and upload IDE distributable package.  Note that build
   script for Windows installer always assumes presence of IDE, therefore it is
   not possible to build it when this option is ``n``.

   Possible values
      ``y`` and ``n``
   Default value
      ``y``

.. envvar:: ENABLE_OPENOCD

   Whether to build and upload OpenOCD distributable package. IDE targets will
   not work if OpenOCD is disabled. Therefore if this is ``n``, then
   :envvar:``ENABLE_IDE`` and :envvar:`ENABLE_WINDOWS_INSTALLER`` also must be
   ``n``.

   Possible values:
      ``y`` and ``n``

   Default value:
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
   must have a name ``arc_gnu_${RELEASE}_ide_plugin.zip``. File will be copied
   with rsync therefore location may be prefixed with hostname separated by
   semicolon, as in ``host:/path``.

.. envvar:: OPENOCD_WINDOWS_LOCATION

   Location of OpenOCD build for Windows. Similar to
   :envvar:`IDE_PLUGIN_LOCATION` that must be a directory with name of format
   ``arc_gnu_${RELEASE}_opencd_win_install``.

.. envvar:: RELEASE

   Specifies toolchain release. Can be any string, for example 2016.03,
   2015.12, etc.

.. envvar:: RELEASE_NAME

   Name of the release, for example "GNU Toolchain for ARC Processors, 2016.03".

.. envvar:: RELEASE_TAG

   Git tag for this release. Tag is used literaly and can be for example,
   arc-2016.03-alpha1. Note that in Synopsys release candidates are created to
   become release, therefore for 2016.03 RC1 value of :envvar:`RELEASE` is
   ``2016.03``, while value of :envvar:`RELEASE_TAG` is ``arc-2016.03-rc1``.

.. envvar:: THIRD_PARTY_SOFTWARE_LOCATION

   Location of 3rd party software, namely Java Runtime Environment (JRE) and
   Eclipse tarballs.

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

   This target is affected by :envvar:`RELEASE`.

.. option:: copy-windows-installer

   Copy Windows installer, created by ``windows-installer/build-installer.sh``
   from :envvar:`WINDOWS_WORKSPACE` to ``release_output`` directory.

.. option:: create-tag

   Create Git tags for released components. Required environment variables:
   :envvar:`RELEASE`, :envvar:`RELEASE_NAME`. OpenOCD must have a branch named
   ``arc-0.9-dev-${RELEASE}``.

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
   :envvar:`RELEASE`, :envvar:`GIT_REFERENCE_ROOT` (optional),
   :envvar:`IDE_PLUGIN_LOCATION`, :envvar:`OPENOCD_WINDOWS_LOCATION`,
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
    RELEASE=2016.03
    RELEASE_TAG=arc-2016.03
    IDE_PLUGIN_LOCATION=...
    OPENOCD_WINDOWS_LOCATION=...
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

    $ RELEASE=2016.03 toolchain/windows-installer/build-installer.sh

Copy Windows installer from :envvar:`WINDOWS_WORKSPACE` into
``release_output``::

    $ make -f release.mk copy-windows-installer

Deploy toolchain to required locations. This target may be called multiple
times with different :envvar:`DEPLOY_DESTINATION` values::

    $ make -f release.mk deploy DEPLOY_DESTINATION=<site1:/pathA>
    $ make -f release.mk deploy DEPLOY_DESTINATION=<site2:/pathB>

Push tags to remote repositories::

    $ make -f release.mk push-tag

Finally, upload assets to GitHub Releases::

    $ make -f release.mk upload

.. vim: set tw=80 expandtab sts=3 sw=3 ts=3: 
