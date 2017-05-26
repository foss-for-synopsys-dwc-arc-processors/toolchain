Installation
============

.. contents:: Table of Contents
   :local:

Using installer for Windows
---------------------------

Windows users are advised to use our Windows installer for Eclipse for GNU
Toolchain for IDE, that can be downloaded from this `releases
page <https://github.com/foss-for-synopsys-dwc-arc-processors/arc_gnu_eclipse/releases>`_.
Installer already contains all of the necessary components.

ARC GNU IDE should be installed in the path no longer than 50 characters and
cannot contain white spaces.

.. figure:: images/install/run_arc_gnu_1.1.0_win_install.exe.png

   Run arc_gnu_2015.06_ide_win_install.exe

.. figure:: images/install/license_page.png

   Accept Synopsys FOSS notice

.. figure:: images/install/components_page.png

   Choose components to be installed

.. figure:: images/install/choose_installer_paths.png

   Choose installer paths

.. figure:: images/install/installation_completed.png

   Installation Completed

Manual installation on Linux and Windows
----------------------------------------

Downloading Eclipse
~~~~~~~~~~~~~~~~~~~

Download Eclipse IDE for C/C++ Developers, that already contains CDT from `this page <https://www.eclipse.org/downloads/>`_

Downloading latest plugins
~~~~~~~~~~~~~~~~~~~~~~~~~~

User can get this plug-in from website URL
https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases/,
this is an archived version of the GNU ARC Eclipse plug-in update site, the
file name is arc_gnu_<version>_ide_plugins.zip

.. figure:: images/install/components_of_arc_gnu_plugins_zip.png

   Components of arc_gnu_ide_plugins.zip

.. figure:: images/install/components_of_arc_gnu_plugins_zip_features.png

   Components of arc_gnu_ide_plugins.zip features

.. figure:: images/install/components_of_arc_gnu_plugins_zip_plugins.png

   Components of arc_gnu_ide_plugins.zip plugins


Installing into Eclipse
~~~~~~~~~~~~~~~~~~~~~~~

To run ARC plugins for Eclipse, it is required to have Target Terminal plugin
installed in Eclipse.

**For ARC GNU 2016.03 and earlier:**

In Eclipse go to "Help", then "Install new Software",
press "Add" button to the right of "Work with" combo box and add new software
repository http://download.eclipse.org/tm/updates/3.7:

.. figure:: images/install/adding_new_repository.png

   Adding new repository

Select this repository under "Work with" and install "Target Management
Terminal (Deprecated)" plugin from "TM Terminal and RSE 3.7 Main Features" group.

.. figure:: images/install/installation_of_eclipse_terminal_plugin.png

   Installation of Eclipse terminal plugin

**For more recent versions:**

Install "TM Terminal" plugin from Mars repository.

.. figure:: images/install/installation_of_tm_terminal.png

   Installation of TM Terminal in Eclipse

After downloading arc_gnu_ide_plugins.zip successfully, user also can install it
from local by pointing Eclipse to it: ``Eclipse -> Install New Software -> Add ->
Archive ->`` select arc_gnu_ide_plugins.zip file. Unzip this archived folder, there
will be six components in it.

.. figure:: images/install/install_from_local_pc.png

   Install from local PC

.. figure:: images/install/check_gnu_arc_c++_development_support.png

   Check GNU ARC C++ Development Support

.. figure:: images/install/get_copyright_by_clicking_more.png

   Get copyright by clicking "more"

.. figure:: images/install/get_general_information_by_clicking_more.png

   Get General Information by clicking "more"

.. figure:: images/install/get_license_agreement_by_clicking_more.png

   Get License Agreement by clicking "more"

.. figure:: images/install/install_details.png

   10 Install Details

.. figure:: images/install/accept_the_terms_of_license_agreement.png

   Accept the terms of license agreement

.. figure:: images/install/install_arc_gnu_ide_plugin.png

   Install ARC GNU IDE Plugin

.. figure:: images/install/warning_about_this_plugin_installation.png

   Warning about this plugins installation

.. figure:: images/install/restarting_eclipse.png

   Restarting Eclipse

Ignore the Security Warning, and click "Ok", after restarting Eclipse IDE, the
installation is finished. If user install plug-in successfully, the "ARC" icon
will show up in "About Eclipse".

.. figure:: images/install/plug-in_in_eclipse_ide.png

   Plug-in in Eclipse IDE

Click the "ARC" icon; user will get detailed plug-in features information.

.. figure:: images/install/about_eclipse_elf32_plug-in_features.png

   About Eclipse ELF32 Plug-in Features

Click the "Installation Details" button, the Features and Plug-ins will also show up.

.. figure:: images/install/arc_gnu_plugin_plug-ins.png

   ARC GNU plugin Plug-ins

.. figure:: images/install/arc_gnu_plugin_features.png

   ARC GNU plugin Features


Updating existing plugin
------------------------

To update the existing plugin, as shown in the figure below, and
the version of this current plugin is for example "1.1.0.201402280630",
follow same instructrions as plugin installation.

.. figure:: images/install/arc_gnu_plugin_features.png

   ARC GNU plugin Features

.. figure:: images/install/current_arc_gnu_ide_plugin.png

   Current ARC GNU IDE plugin

.. figure:: images/install/installation_of_latest_plugin.png

   Installation of latest plugin

.. figure:: images/install/updated_arc_gnu_ide_plugin.png

   Updated ARC GNU IDE plugin

.. figure:: images/install/general_information_of_the_latest_plugin.png

   General Information of the latest plugin

.. figure:: images/install/installed_details_of_the_latest_plugin.png

   Installed details of the latest plugin

.. figure:: images/install/update_existing_plugins_sucessfully.png

   Upate exiting plugins successfully

.. figure:: images/install/updated_arc_gnu_plugin_features.png

   Updated ARC GNU plugin Features

.. figure:: images/install/updated_arc_gnu_plugin_plug-ins.png

   Updated ARC GNU plugin Plug-ins

Installing plugin on Linux host
-------------------------------

If you plan to connect to UART port on target board with RxTx plugin controlled
by IDE you need to change permissions of directory /var/lock in your system.
Usually by default only users with root access are allowed to write into this
directory, however RxTx tries to write file into this directory, so unless you
are ready to run IDE with sudo, you need to allow write access to /var/lock
directory for everyone. Note that if /var/lock is a symbolic link to another
directory then you need to change permissions for this directory as well. For
example to set required permissions on Fedora: ::

    $ ls -l /var/lock
    lrwxrwxrwx. 1 root root 11 Jun 27  2013 /var/lock -> ../run/lock
    $ ls -ld /run/lock/
    drwxr-xr-x. 8 root root 160 Mar 28 17:32 /run/lock/
    $ sudo chmod go+w /run/lock
    $ ls -ld /run/lock/
    drwxrwxrwx. 8 root root 160 Mar 28 17:32 /run/lock/

If it is not possible or not desirable to change permissions for this directory
then serial port connection must be disable in Eclipse debugger configuration
window.

If it is required to connect to UART of a development system, then another
problem that might happen is permissions to open UART device.  For example on
Ubuntu 14.04 only root and members of ``dialout`` group can use /dev/ttyUSB1
(typical UART port for boards based on FT2232 chip). Thus to use connect to
those port user must be made member of ``dialout`` group. Command to do this: ::

    $ sudo usermod -a -G dialout `whoami`

If OpenOCD is used, then it is required to set up proper permissions for
devices to allow OpenOCD to connect to those devices. Create file
``/etc/udev/rules.d/99-ftdi.rulesi`` with the following contents: ::

    # allow users to claim the device
    # Digilent HS1 and similiar products
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0664", GROUP="plugdev"
    # Digilent HS2
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0664", GROUP="plugdev"

Then add yourself to ``plugdev`` group: ::

    $ sudo usermod -a -G plugdev `whoami`

Then restart udev and relogin to system, so changes will take effect.::

    $ sudo udevadm control --reload-rules
    # Disconnect JTAG cable from host, then connect again.

Even better is to reboot the system.

