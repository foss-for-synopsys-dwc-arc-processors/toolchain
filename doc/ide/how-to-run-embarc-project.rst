How to Run embARC Projects
==========================

Generating IDE projects and documentation
-----------------------------------------

.. note::
   In embARC releases both IDE projects and documentation are already generated,
   so these steps should be done only if you want to test the latest version of
   embARC.

1. Checkout arc_open_project repository. Create ide_projects folder in root
   directory, then run tools/scripts/ide_gen/ide_projects_gen.sh. This script
   calls python scripts, and for them to run correctly you need to use Python
   version 2.7.9.

2. To compile projects that use Wi-Fi, submodules middleware/lwip and
   middleware/lwip-contrib are needed. These repositories are private, but
   contents of these directories can be copied from the latest release of
   embARC. Although using not the latest versions of them might lead to
   errors.

3. In doc/ directory there is a makefile that can be used for generating a
   documentation. To generate it doxygen is used, and it might be necessary to
   use doxygen from depot/ since old version of doxygen could lead to errors.
   In this documentation there is an **Examples** page with an overview of IDE
   projects and **Examples Usage Guide** where you can find how to prepare for
   running projects, for example, how to connect Pmod Wifi and Pmod TMP2 to your
   board.

Running IDE projects
--------------------

1. To import them in IDE you should select your workspace to
   <embARC_root>/ide_projects/emsk_xx/gnu.

2. Import projects using 'General/Existing Projects into Workspace'.

6. WiFi hotspot used for running examples that use WiFi should be named 'embARC'
   with password 'qazwsxedc'.

.. note::
   When testing embARC projects, should be checked:

   * Pmod TMP2 and Pmod WiFi
   * baremetal, contiki and freertos projects

   All this can be checked if running, for example, projects
   ``baremetal_arc_feature_interrupt``, ``contiki_sensor`` and
   ``freertos_net_httpserver``.
