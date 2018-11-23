# RebootIntoKernel

This simple Bash script automatises some common tasks usually performed when
installing a customised or newer Linux Kernel by hand, to prevent the system
from crashing when a Kernel Panic arises after rebooting into the new kernel.

# Tested on

The script parses **/boot/grub/grub.cfg** in a naive way, so it has been
only tested on Debian and Ubuntu systems. Some other GNU/Linux distros may
as well work fine, but you should consider modifying the
**format_grub_meny_entry** function accordingly.

Tested on the following GNU/Linux distros:

	* Debian Wheezy.
	* Debian Jessie.
	* Debian Stretch.
	* Ubuntu Trusty.
	* Ubuntu Xenial.

# Installation

	git clone https://github.com/nonamed01/RebootIntoKernel.git

# Usage

Get help:

	./rk.sh -h

Get GRUB's menu entry for the current running kernel:

	./rk.sh -g `uname -r`

Reboot automatically into kernel **4.19.2-amd64** and, if a **Kernel Panic**
arises, reboot into the current running one after 5 seconds:

	./rk.sh -t 5 -r -k 4.19.2-amd64

# Use cases

After customising your running kernel, or after installing a newer one by hand with the
distro-agnostic and old-fashioned **make bzImage ; make modules ...,**, once you have the 
vmlinuz and initrd files in **/boot/**, you can make use of this script to reboot into this new
kernel and safely get back to the current running and stable one if an awful **Kernel
Panic** is triggered.

# Behind the scenes

This script performs the following tasks behind the scenes:

1) Adds (or updates) the **panic** variable to **GRUB_CMDLINE_LINUX_DEFAULT** in
   the **/etc/defaults/grub**.

2) Sets the variable **GRUB_DEFAULT** to **saved** in **/etc/default/grub**.

3) Sets the current running kernel as the **saved** one by calling **grub-set-default**. Then,
it updates **/boot/grub/grub.cfg** by calling **update-grub**.

4) Sets the kernel to boot into the next reboot by calling **grub-reboot**.

5) Reboots the computer inmediately (if **-r** is given).

# Demo

./rk.sh -t 20 -k 4.19.4

Timeout of 20 seconds for kernel panic set.

Default Running Kernel: Debian GNU/Linux, with Linux 4.9.0-8-amd64

Rebooting into the new installed kernel: Debian GNU/Linux, with Linux 4.19.4 ... 

Do you want to reboot now [yn] ?

y

Connection to HOST closed by remote host.

Connection to HOST closed.
