.. highlightlang:: none

Debugging Linux Applications
============================

This article describes how to debug user-space applications on the Linux on
ARC.


Building toolchain
------------------

In most cases it should be enough to use binary distribution of GNU Toolchain
for ARC, which can be downloaded from `our Releases page
<https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases>`_.
If toolchain in binary distribution doesn't fit some particular requirements,
then instruction to build toolchain from source can be found in README.md file
in the ``toolchain`` repository.


Building Linux
--------------

The simple guide to build kernel can be found in this manual page
:doc:`kernel-build`. More instructions can be found in ARC Linux `wiki
<https://github.com/foss-for-synopsys-dwc-arc-processors/linux/wiki>`_ and in
the Internet in general.


Configuring target system
-------------------------

Information in this section is not specific to ARC, it is given here just for
convenience - there are other ways to achieve same result.


Configuring networking
^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Ethernet model is not available in standalone nSIM simulation.

By default target system will not bring up networking device. To do this::

    [arclinux] $ ifconfig eth0 up

If network to which board or virtual platform is attached has a DHCP server,
then run DHCP client::

    [arclinux] $ udhcpc

If there is no DHCP server, then configure networking manually::

    [arclinux] $ ifconfig eth0 <IP_ADDRESS> netmask <IP_NETMASK>
    [arclinux] $ route add default gw <NETWORK_GATEWAY> eth0

Where ``<IP_ADDRESS>`` is an IP address to assign to ARC Linux, ``<IP_NETMASK>`` is
a mask of this network, ``<NETWORK_GATEWAY>`` is default gateway of network.

To gain access to the Internet DNS must servers must be configured. This is
usually not required when using DHCP, because in this case information about
DNS servers is provided via DHCP. To configure DNS manually, create
``/etc/resolv.conf`` which lists DNS servers by IP. For example::

    nameserver 8.8.8.8
    nameserver 8.8.4.4

That will connect ARC Linux to the network.


Configuring NFS
^^^^^^^^^^^^^^^

To ease process of delivering target application into the ARC Linux it is
recommended to configure NFS share and mount it on the ARC Linux.

Install NFS server on the development host (in this example it is Ubuntu)::

    $ sudo apt-get install nfs-kernel-server

Edit ``/etc/exports``: describe you public folder there. For example::

    /home/arc/snps/pub *(rw,no_subtree_check,anonuid=1000,anongid=1000,all_squash)

Restart NFS server::

    $ sudo service nfs-kernel-server restart

Open required ports in firewall. To make things easier this example will open
*all* ports for the hosts in the ``tap0`` network::

    $ sudo ufw allow from 192.168.218.0/24 to 192.168.218.1

Now you can mount your share on the target::

    [arclinux] # mount -t nfs -o nolock,rw 192.168.218.1:/home/arc/snps/pub /mnt

Public share will be mounted to the ``/mnt`` directory.


Additional services
^^^^^^^^^^^^^^^^^^^

Another thing that might be useful is to have network services like telnet,
ftp, etc, that will run on ARC Linux.  First make sure that desired service is
available in the Busybox configuration. Run ``make menuconfig`` from Busybox
directory or ``make busybox-menuconfig`` if you are using Buildroot. Make sure
that "inetd" server is enabled. Select required packages (telnet, ftpd, etc)
and save configuration.  Rebuild busybox (run ``make busybox-rebuild`` if you
are using Buildroot).

Then configure inetd daemon. Refer to inetd documentation to learn how to do
this. In the simple case it is required to create ``/etc/inetd.conf`` file on
the target system with following contents::

    ftp     stream  tcp nowait  root    /usr/sbin/ftpd      ftpd -w /
    telnet  stream  tcp nowait  root    /usr/sbin/telnetd   telnetd -i -l /bin/sh

Thus inetd will allow connections to ftpd and telnetd servers on the target
system. Other services can be added if required.

Rebuild and update rootfs and vmlinux. Start rebuilt system and run `inetd` to
start inetd daemon on target::

    [arclinux] $ inetd


Debugging applications with gdbserver
-------------------------------------

It is assumed that one or another way  application to debug is on to the target
system. Run application on target with gdbserver::

    [arclinux] $ gdbserver :49101 <application-to-debug> [application arguments]

TCP port number could any port not occupied by another application. Then run
GDB on the host::

    $ arc-linux-gdb <application-to-debug>

Then set sysroot directory path. Sysroot is a "mirror" of the target system
file system: it contains copies of the applications and shared libraries
installed on the target system. Path to the sysroot directory should be set to
allow GDB to step into shared libraries functions. Note that shared libraries
and applications on the target system can be stripped from the debug symbols to
preserve disk space, while files in the sysroot shouldn't be stripped. In case
of Buildroot-generated rootfs sysroot directory can be found under
``<BUILDROOT_OUTPUT>/staging``.::

    (gdb) set sysroot <SYSROOT_PATH>

Then connect to the remote gdbserver::

    (gdb) target remote <TARGET_IP>:49101

You can find ``<TARGET_IP>`` via running ``ifconfig`` on the target system. TCP
port must much the one used when starting up gdbserver. It is important that
sysroot should be set before connecting to remote target, otherwise GDB might
have issues with stepping into shared libraries functions.

Then you can your debug session as usual. In the simplest case::

    (gdb) continue


Debugging applications with native GDB
--------------------------------------

Starting from GNU Toolchain for ARC release 2014.08 it is possible to build
full GDB to run natively on ARC Linux. Starting from GNU Tooolchain for ARC
release 2015.06 native GDB is automatically built for uClibc toolchain (can be
disabled by ``--no-native-gdb`` option). In GNU Toolchain prebuilt tarballs
native GDB binary can be found in sysroot directory:
``arc-snps-linux-uclibc/sysroot/usr/bin/gdb``

With native GDB it is possible to debug applications the same way as it is done
on the host system without gdbserver.