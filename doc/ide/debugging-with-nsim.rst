Debugging with nSIM
===================

It is expected that you have already built your application and created a
debug configuration for it. About how to do it you can read on the following
pages:

* :ref:`Building an Application <building-user-guide>`
* :ref:`Creating a Debug Configuration <creating-a-debug-configuration>`


Specifying nSIM properties
--------------------------

.. figure:: images/debugging/nsim/nsim_tab.png

   Choosing nSIM on debug tab

In this tab, user needs to indicate correct properties file/TCF file for
current CPU core. In general it is recommended to use TCF files, because
they are generated from the Build Configuration Registers and thus most
reliably describe target core. nSIM Properties files contain list of
key-values for nSIM properties which allow to describe target core and
additional simulation features, full list of properties is documented in the
nSIM User Guide.  It is possible to specify both TCF and properties file,
with properties file being able to override parameters set in TCF. For
example, if you have a TCF for a little endian core, but would like to
simulate it as a big endian, it is possible to create an properties file
that will set only a single property for big endian, then in IDE GUI in nSIM
GDBserver settings specify paths to both TCF and properties file and that
will give a desired results.


Other available options:
   * **JIT** checkbox enables Just-In-Time compilation. You can also specify a number
     of threads to use in JIT mode.
   * **GNU host I/O support**, if checked, enables nSIM GNU host I/O support. It means
     that input/output requests from application will be handled by nSIM and redirected
     to the host system. This could be used, for example, to enable functions in the
     C library, such as ``printf()`` and ``scanf()``. This option works only if the application
     is built with the ARC GCC compiler and ``--specs=nsim.specs`` flag is used.
   * **Enable Exception**, **Memory Exception** and **Invalid Instruction Exception**
     options, if checked, tell nSIM to simulate all exceptions, memory exceptions and
     invalid instruction exceptions, respectively. If one of these options is unchecked
     and corresponding exception happens, nSIM will exit with an error instead.
   * **Working Directory** is a directory from which nSIM GDB server will be
     started. By default it is project location. This option might be useful if
     your program works with files. To open a file, you can instead of its
     absolute path provide a path relative to the specified working directory.

Debugging an application
------------------------

To debug application using nSIM, press **Debug** button of IDE.


.. figure:: images/debugging/nsim/nsim_debug.png

   Debugging with nSIM gdbserver

.. figure:: images/debugging/nsim/nsim_debug_window.png

   Debug Window

.. figure:: images/debugging/nsim/nsim_output.png

   nSIM gdbserver output in console
