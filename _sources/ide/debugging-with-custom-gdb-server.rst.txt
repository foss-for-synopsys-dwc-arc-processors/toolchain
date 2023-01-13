Debugging with Custom GDB Server
================================

It is expected here that you have already built your application and created a
debug configuration for it. About how to do it you can read on the following
pages:

* :ref:`Building an Application <building-user-guide>`
* :ref:`Creating a Debug Configuration <creating-a-debug-configuration>`

Specifying custom GDB server properties
---------------------------------------

.. figure:: images/debugging/custom_gdb/custom_gdb_tab.png

   Custom GDB Server tab

You can use some other GDB server. In that case you should specify a path to
this server executable file, its command-line arguments and also commands to
be passed to the GDB client. These are on the **Commands** tab of the dialog.

.. figure:: images/debugging/commands_tab.png

   Commands tab


OpenOCD as a custom GDB server
------------------------------

To use OpenOCD as a custom GDB server, user needs to specify command line options
for OpenOCD. It is not necessary to specify any commands for GDB on the
**Commands** tab, it will connect to OpenOCD automatically.

.. figure:: images/debugging/custom_gdb/custom_properties.png

   Custom GDB server properties

.. figure:: images/debugging/custom_gdb/custom_debug_session.png

   Debugging using custom GDB server
