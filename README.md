# RebootIntoKernel

This simple Bash script automatizes some common tasks usually performed when
installing a customized or newer Linux Kernel by hand, to prevent the system
from crashing when a Kernel Panic arises after rebooting into the new kernel.

# Installation

	git clone https://github.com/nonamed01/RebootIntoKernel.git

# Usage

	Get help:
		./rk.sh -h

	Get GRUB's menu entry for the current running kernel:
		./rk.sh -g `uname -r`

	Reboot automatically into the kernel 4.19.2-amd64 and, if a Kernel Panic
	arises, reboot into the current running one after 5 seconds:
		./rk.sh -t 5 -r -k 4.19.2-amd64
