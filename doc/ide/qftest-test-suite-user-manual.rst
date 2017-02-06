QfTest Test Suite User Manual
=============================

.. contents:: Table of Contents
   :local:

Qf-Test Installation
--------------------

Information about Qf-Test installation may be found
`here <http://sp-sg/sites/arc_automation/SitePages/QF-Test/Users.aspx>`_.


Workflow
--------

1. Open **project_templates_tests.qft** test-suite in Qf-Test.
2. Connect your board to your computer, choose the core, configure drivers (for
   OpenOCD on Windows).
3. Set test-suite parameters for your test run (board, core, gdbServer and
   other options).
4. Set debugger behaviour in "Debugger/Options" menu. You can set "Break on
   uncaught exceptions" option and then your test-run will stop if uncaught
   exception has been thrown. When on pause you can investigate what caused the
   exception in the run-log and edit test-suite commands if necessary, then
   continue if you've fixed the problem. Similarly if you set "Break on
   error/warning/caught exception" test run will stop in these cases. However, if
   you want to just run all the test in succession without breaking, unset all
   these options. You can also set breakpoints on some nodes.

   For more information about debugger read Qf-Test manual.

5. Start test run (press **Start** button while the top-most **Test-suite** node
   is selected).
6. Depending on the parameters set one or more test-sets will be executed. Each
   test-set corresponds to one project with one configuration and consists of 3
   test-cases: ``build``, ``setDebugSettings`` and ``debug``. If one of these test-cases
   fails, following test-cases will not be executed.
7. After test run is finished, you can see the results in the bottom right
   corner of the Qf-Test window, where numbers of successful, failed and skipped
   tests are shown. You can also see the run-log by pressing ``Ctrl+L`` or choosing
   the test-suite at the bottom of the "Run" menu. In the run-log window you can
   choose "File/Create HTML/XML report", then accept default options and see the
   generated HTML report in your browser.



Setting test-suite parameters
-----------------------------

Select the top-most **Test-suite** node of your test-suite. On the right side of
the Qf-Test window information about the test-suite will appear. In the variable
definitions section test-suite parameters are listed. Required fields are

* **board** - available values are: `nsim`, `emsk1.1`, `emsk2.2`, `axs101` and
  `axs103`.

  In case selected board is not `nsim`, you have to specify
  * **gdbServer**: `openocd` or `ashling`;
  * **core**. Here is a table of available cores:

  +--------+---------+----------+--------+
  | emsk1.1| emsk2.2 | axs101   | axs103 |
  +========+=========+==========+========+
  | em4    | em7d    | arc600#1 | hs36   |
  +--------+---------+----------+--------+
  | em6    | em9d    | arc600#2 |        |
  +--------+---------+----------+--------+
  |        | em11d   | em6      |        |
  +--------+---------+----------+--------+
  |        |         | arc700   |        |
  +--------+---------+----------+--------+

* **eclipsedir**  - directory with the eclipse that will be tested;
* **workspace** - workspace for eclipse to use for test projects.

Optional fields for all tests:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* **language** - either `c`, `c++` or may be left blank. If blank, both
  languages will be tested.
* **mode** - `build` or `debug`. If left blank, the value is considered as
  `debug`. `Build` mode only tests that projects can be built and no problems
  are detected. In `debug` mode it is tested that projects that are built
  successfully can be run and output is checked.
* **ignoreProblems**: `true` or `false`. Normally if project is not built or
  some problems are detected (and shown on the "Problems" tab in Eclipse), we
  do not try to run it. But if you set **ignoreProblems** = `true`, project will
  be run even if there are problems on the "Problems" tab (but not if project is
  not built). However, if there are problems detected, the ``build`` test-case
  will be considered as failed even if **ignoreProblems** is set. Default value --
  `false`.
* **configuration** - `Debug`, `Release`. By default, every created project
  has two build configurations - `Debug` and `Release`. Choose which of these
  configurations you want to test.  If left blank, both these configurations will
  be run.


nSIM parameters
~~~~~~~~~~~~~~~

To run nSIM tests you need to specify

+ **nsimdrv** - nsim executable file with full path;

Optional fields for nSIM:

+ **toolchain**: one of *em*, *hs*, *600* and *700*. If blank, projects for all
  of the toolchains will be tested;
+ **endian**: *little*, *big*. If blank, both endianness' projects are run;
+ **tcf**. If you specify TCF, project will be tested only on this TCF, but in
  this case you have to specify toolchain and endianness as well. This TCF will
  be taken from the directory ``tcf/toolchain/endian/`` relative to the test suite
  location, so the available values are the names of files in this directory
  (without extension).

EMSK and AXS10x parameters (optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ **template** - for EMSK there are "Hello World" and empty templates
  available. You can choose the template to be tested by setting **template**
  equal to *hello* or *empty*. If left blank, both templates will be used
  (if this field is left blank then some tests fail, because memory_error
  appears before main and exit when debugging, it happens for unknown reasons,
  so a template field needs to be filled now). 
+ **mcpu** - mcpu flag to be passed to compiler. For ARC 600 there is only one
  mcpu value: ``arc600``, for ARC 700 - ``arc700``. For ARC EM values are: ``em``,
  ``arcem``, ``em4``, ``em4_dmips``, ``em4_fpus`` and ``em4_fpuda``, for ARC HS: ``hs``,
  ``archs``, ``hs34``, ``hs38``, ``hs38_linux``.

However, if using this option, you have to be careful since not all of the
options are applicable to all of the cores that can be used. For every project
template and every board and core there is a list of mcpu values that will be
run if this field is left blank. Usually there are only one of two values in
these lists. For example, "Hello World for EMSK 1.1 Project" on EM4 will be run
only using `em4_dmips` mcpu value, but "Empty Project for EM4" will use `em4`
and `em4_dmips`.

The lists of the mcpu values to be used by default can be found in the
"template" data table of the top-most "debug" test-set's data driver.

OpenOCD and Ashling parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ **openocd** - OpenOCD executable file with full path;
+ **ashlingBinPath** - Ashling executable with full path;
+ **ashlingXmlDir** - directory containing XML target description files and
  arc-reg-files;
+ **comPort** - on Windows if you want to check UART output, you have to
  specify the COM port of your connected board from "Devices and Printers"
  dialog. Use only the number, without the "COM" prefix. For example, if your
  "Devices and Printers" shows "COM5", put "5" in this field. If left blank,
  output just will not be checked.


Other parameters
~~~~~~~~~~~~~~~~

There are **sourceFileDir**, **sourceFile**, **tcfDir** and **client**
parameters with default values set in the variable definitions section of
test-suite. There is no need to override these values from test run to test run,
but **tcfDir** and **sourceFileDir** should point to ``tcf/`` and ``src/``
directories respectively (relative to test-suite location) and **sourceFile**
should contain the name of the file to be used as source file for empty
projects.

Variable **client** is qf-test internal and can be set to any value.


Launching test-suite from command line
--------------------------------------

There is a command that can be used to run test-suite from command line:

``qftest -batch -variable <NAME>=<VALUE> arc_gnu_ide_tests.qft``

All the variables needed for the test execution should be set to appropriate
values here or in the test-suite "Variable definitions" section. Values set from
command line override the values set in the test-suite.

There are other parameters for command line qf-test execution, see "Test
execution" chapter of Qf-Test manual.


Known problems and how to fix them
----------------------------------

+ It has been noticed that sometimes Eclipse stops recognizing some components.
  For example, there might be a sequence that starts debug session, with
  ``waitForComponent()`` procedure in the middle of it that fails with
  ``ComponentNotFound`` exception, but you can see that this component in fact
  appeared in Eclipse. I'm not sure why this happens, but setting a breakpoint on
  the failing node, waiting for the component to appear and recording this component
  again (press **Start recording** button, mouse click on the component, then stop
  recording and see the result in the "Extras" section) and replacing the old
  component with the new one fixes the problem.

.. note::

   Note that after component is recorded it often needs to be edited. Open
   "Extras" section, choose the command that uses the component, then press
   ``Ctrl+W`` to locate component in the "Windows and components" section. It often
   helps to delete all the information from the "Structure" and "Geometry"
   sections of the component information. Also it might be necessary to edit
   "Feature" and "Extra features" sections, so that this component would be
   recognized for projects with names different from the name of the project you
   were testing when recorded this component.

+ Another thing that might cause questions is that when qf-test checks UART
  "Hello World" output, it uses an image instead of text, so the "Hello World"
  might be there, but the image might not be the same. It's impossible to check
  text here because apparently Terminal view shows an image, so I'd suggest user
  should just record his image and replace the old image in test-suite with his new
  one and run the tests against it. Another solution is to just check in run-log that
  every time ``Check image`` procedure failed, there in fact was "Hello World" in
  Terminal view (Qf-Test provides screenshots of Eclipse window at the times
  exceptions occur, they are available in run-log).
