Plugin preferences
==================

ARC plugins in IDE support preferences that can alter their behaviour. These
preferences are unlikely to be useful for end-user, so they are not exposed via
GUI, but they can be modified via preferences files located in Eclipse workspace
folder in ``.metadata/.plugins/org.eclipse.core.runtime/.settings`` folder.

Debugger plugin preferences
---------------------------

Debugger plugin preferences are located in file ``com.arc.embeddedcdt.prefs``.

gdbserver_startup_delay
   Delay in milliseconds that this plugin wait for after starting gdbserver and
   before starting the GDB, thus allowing server to start listening on TCP port.
   Default value is 500.

gdbserver_use_adaptive_delay
   Whether to try to use adaptive server startup delay or use only default fixed
   delay time. Default value is true.

gdbserver_startup_timeout
   Amount of time in milliseconds given to gdbserver to start in adaptive
   startup procedure. Default value is 30000.

gdbserver_startup_delay_step
   Amount of time to sleep in milliseconds after adaptive gdbserver startup
   delay procedure failed to connect to the server. In practice this can be very
   small, because Socket.connect() itself waits for 1 second. However I've
   measured this value on my machine, so I'm not sure it is equally valid
   everywhere, so I leave this is a possible parameter to modify if needed.
   Default value is 1.

nsim_pass_reconnect_option
   Whether to start nSIM with option -reconnect. This is required for adaptive
   delay to work with nSIM. Default value is true.