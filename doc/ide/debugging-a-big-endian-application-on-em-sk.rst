Debugging a big endian Application on EM Starter Kit
====================================================

The EM Starter Kit comes with 4 pre-installed little endian configurations.
User wishing to work with big endian configuration can use the procedure below
to program a big endian .bit file, using the Digilent Adept Software. Big
endian .bit file is not a part of the EM Starter Kit Software package.


Instruction for Windows
-----------------------

1. Ensure that EM Starter Kit is powered ON and connected to the host PC

2. On the EM Starter Kit, close jumper J8 as shown in images below:

.. figure:: images/big_endian/j8_jumper_default.jpg

   J8 Jumper in factory default position

After closing the jumper:

.. figure:: images/big_endian/j8_jumper_closed.jpg

   J8 Jumper in closed position

3. Download the Digilent Adept 2 System Software for Windows from
   http://store.digilentinc.com/digilent-adept-2-download-only/

4. Open the "Adept" utility

.. figure:: images/big_endian/adept_before_init_chain.png

   Adept Utility before Initializing Chain

5. Press "Initialize chain". There should be only one device in a chain:
   XC6SLX150 (XC6SLX45 for ARC EM Starter Kit 1.x)

.. figure:: images/big_endian/adept_shows_device.png

   XC6SLX{150,45} Device shown after Initialization

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


Instructions for Linux
----------------------

Follow step 1 through 3 from Windows section to properly configure board and
download Adept software. To program FPGA it is required to install both
"runtime" and "utilities" packages. After installing utilities and setting
jumpers appropriately, use Digilent command-line utilities::

	$ djtgcfg enum
	Found 1 device(s)

	Device: TE0604-03
	    Product Name:   JTAG-ONB4
	    User Name:      TE0604-03
	    Serial Number:  25163300005A

	$ djtgcfg init -d TE0604-03
	Initializing scan chain...
	Found Device ID: 4401d093

	Found 1 device(s):
	    Device 0: XC6SLX150

	$ djtgcfg prog -d TE0604-03 -i 0 -f <bit_file>
	Programming device. Do not touch your board. This may take a few minutes...
	Programming succeeded.
