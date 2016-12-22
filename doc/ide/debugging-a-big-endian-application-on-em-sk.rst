Debugging a big endian Application on EM Starter Kit
====================================================

.. note::

   This page was written for ARC EM Starter Kit 1.0. It is mostly applicable
   to later versions of ARC EM Starter Kit, but there are some minor differences.

The EM Starter Kit comes with 4 pre-installed little endian configurations.
User wishing to work with big endian configuration can use the procedure below
to program a big endian .bit file, using the Digilent Adept Software. Big
endian .bit file is not a part of the EM Starter Kit Software package, Synopsys
will provide it on request.

1. Ensure that EM Starter Kit is powered ON and connected to the host PC

2. On the EM Starter Kit, close jumper J8 as shown in images below:

.. figure:: images/big_endian/j8_jumper_default.jpg

   J8 Jumper in factory default position

After closing the jumper:

.. figure:: images/big_endian/j8_jumper_closed.jpg

   J8 Jumper in closed position

3. Download the Digilent Adept 2.13.1 System Software for Windows from
   http://www.digilentinc.com/Products/Detail.cfm?Prod=ADEPT2

4. Open the "Adept" utility

.. figure:: images/big_endian/adept_before_init_chain.png

   Adept Utility before Initializing Chain

5. Press "Initialize chain". There should be only one device in a chain: XC6SLX45.

.. figure:: images/big_endian/adept_shows_device.png

   XC6SLX45 Device shown after Initialization

6. Press "Browse" button and navigate to location of your big endian .bit file

7. Press "Program" button.

8. Return  Jumper J8 to its initial position.

9. There are no big endian configuration files for OpenOCD, so to debug your
   application you should use the same configuration file as for little endian
   one: ``$INSTALL_DIR/share/openocd/scripts/board/snps_em_sk.cfg``, but in the file
   ``$INSTALL_DIR\share\openocd\scripts\target\snps_em_sk_fpga.cfg`` replace
   ``-endian little`` with ``-endian big``.

The EM Starter Kit will now use the selected big-endian FPGA image until the
board is powered off or until reconfiguration by pressing the FPGA
configuration button located above the “C” in the “ARC” log on the board. Refer
to EM Starter Kit documentation for more details.
