#!/bin/bash
#set -x
###########################################################################################################
# rk.sh
#	2018 by T. Castillo Girona
#	<toni.castillo AT upc.edu>
#	http://disbauxes.upc.es
#	@disbauxes
#	After installing a new kernel (make bzImage , blah blah), this script makes sure to:
#	
#	1) Set the current stable running kernel as the default one.
#	2) Add the "panic=TIMEOUT" value to /etc/default/grub.
#	3) Modify the GRUB_DEFAULT entry in /etc/default/grub to "saved"
#	4) Re-generates grub.cfg by calling update-grub.
#	5) Finally, it reboots into the next kernel with grub-reboot.
#
#	Tested on:
#		Debian Wheezy
#		Debian Jessie
#		Debian Stretch.
#
#		Ubuntu Trusty (14.04)
#		Ubuntu Xenial LTS (16.04)
#
###########################################################################################################

# Default timeout for rebooting the kernel when PANIC.
TIMEOUT=10
DOREBOOT="n"

###########################################################################################################
# change_default_entry
#	it sets GRUB_DEFAULT to saved in /etc/default/grub
#	Returns: 0 if the change has been done, or 1 otherwise.
###########################################################################################################
change_default_entry () {
	# If the change has already been done, do nothing and return 0:
	cat /etc/default/grub|grep "GRUB_DEFAULT=saved" > /dev/null && return 0
	# Otherwise, make sure we can write on it:
	test -w /etc/default/grub
	if [ $? -eq 0 ]; then
		sed -i '/GRUB_DEFAULT=/c\GRUB_DEFAULT=saved' /etc/default/grub
		# MAke sure the change has been done:
		cat /etc/default/grub|grep "GRUB_DEFAULT=saved" > /dev/null
		return $?
	else
		return 1
	fi
}

###########################################################################################################
# set_kernel_panic_timeout
#	It sets the desired TIMEOUT to the variable GRUB_CMDLINE_LINUX_DEFAULT in
#	/etc/default/grub.
#
#	The TIMEOUT is read from the cli as the first parameter to the script,
#	otherwise TIMEOUT is used instead.
#
#	Returns 0 on success, 1 otherwise.
#	Args:	$0, timeout to use.
###########################################################################################################
set_kernel_panic_timeout () {
	mytimeout=$1
	test -w /etc/default/grub
	if [ $? -eq 0 ]; then
		cat /etc/default/grub|grep "GRUB_CMDLINE_LINUX_DEFAULT"|grep "panic=" > /dev/null
		if [ $? -eq 0 ]; then
			# Replace the current panic timeout entry:
			sed -i "s/panic=[0-9]\+/panic=$mytimeout/" /etc/default/grub
		else
			# Add the panic option:
			sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&panic=$mytimeout /" /etc/default/grub
		fi
		# Make sure it's already there:
		cat /etc/default/grub|grep "GRUB_CMDLINE_LINUX_DEFAULT"|grep "panic=" > /dev/null && return 0
		return $?
	else
		return 1
	fi
}

###########################################################################################################
#	get_grub_entry
#		Returns a string holding the GRUB's menu entry for the given kernel version or "" otherwise.
###########################################################################################################
get_grub_entry () {
	mykernel=$1
	test -r /boot/grub/grub.cfg || exit 0
	cat /boot/grub/grub.cfg |grep "menuentry" |grep "$mykernel'"|awk -F"'"  '{print $2}'
}

###########################################################################################################
# set_default_running_kernel
#	This will call grub-set-default with the current running kernel and re-generate
#	/boot/grub/grub.cfg and /boot/grub/grubenv accordingly by calling update-grub
###########################################################################################################
set_default_running_kernel () {
	mykernel=`uname -r`
	krn=`get_grub_entry $mykernel` 
	# Unable to get the current running kernel entry from grub:
	if [ -z "$krn" ]; then
		return 1
	fi
	echo "Default Running Kernel: ${krn}"
	# Otherwise, set as default under the submenu:
	grub-set-default "`format_grub_meny_entry`${krn}"
	return $?
}

###########################################################################################################
# reboot_into_the_new_kernel
#	Gets the right entry for the passed kernel from grub.cfg and reboots into it by calling
#	grub-reboot
###########################################################################################################
reboot_into_the_new_kernel () {
	mykernel=$1
	# Get grub entry:
	rkrn=`get_grub_entry $mykernel`
	if [ -z "$rkrn" ]; then
		return 1
	fi
	# Let's reboot:
	echo "Rebooting into the new installed kernel: ${rkrn} ... "
	grub-reboot "`format_grub_meny_entry`${rkrn}"
	return $?
}

###########################################################################################################
# format_grub_meny_entry
#	It returns the appropiate menuentry before the actual menu we want, depending on
#	the release version (Wheezy does not use submenus, for instance(
###########################################################################################################
format_grub_meny_entry () {
	v=`cat /etc/debian_version|cut -d"." -f1`
	case "$v" in
		7)
			# Debian Wheezy does not have submenus
			echo ""
			;;
		8|9)
			# Debian Jessie and Stretch does use submenus:
			echo "Advanced options for Debian GNU/Linux>"
			;;
		*)
			# Maybe it's an Ubuntu distro?
			lsb_release -a|grep Ubuntu >/dev/null
			if [ $? -eq 0 ]; then
				# Do we have valid GRUB entries?
				cat /boot/grub/grub.cfg|grep "Advanced options for Ubuntu" >/dev/null
				if [ $? -eq 0 ]; then
					echo "Advanced options for Ubuntu>"
				fi
			fi
			;;
	esac
}

###########################################################################################################
# show_usage
#	Shows how to run the script.
###########################################################################################################
show_usage () {
	clear
	echo "Reboot into New Installed Kernel, 2018 by T. Castillo Girona"
	echo " Usage: $0 [-t TIMEOUT] [-r] -k new_kernel"
	echo " Usage: $0 -g kernel_version"
	echo " Usage: $0 -h"
	echo "Examples: "
	echo " $0 -g \`uname -r\`"
	echo " $0 -t 5 -r -k 4.19-0-5-amd64"
	echo " $0 -k 4.19-0-5-amd64"
}

# Process some options from the CLI:
while getopts "t:g:k:rh" opt; do
	case "$opt" in
		t)
			# Set the desired timeout:
			TIMEOUT="$OPTARG"
			;;
		g)
			# Get the GRUB's entry for the given kernel
			kentry=`get_grub_entry "$OPTARG"`
			if [ -z "$kentry" ]; then
				echo "[ERROR]: unable to find Kernel $OPTARG GRUB's entry."
			else
				echo $kentry
			fi
			exit $?
			;;
		k)
			# Sets the new kernel to reboot into:
			NEWKERNEL=$OPTARG
			# Make sure it does exist!!!
			test -r /boot/vmlinuz-${NEWKERNEL}
			if [ ! $? -eq 0 ]; then
				echo "[ERROR]: /boot/vmlinuz-${NEWKERNEL} doest not exist!"
				exit 1
			fi
			;;
		r)
			# Set the automatic reboot:
			DOREBOOT="y"
			;;
		h)
			show_usage
			exit 0
			;;
	esac
done

# If we do not have a valid NEWKERNEL, we show the usage and quit:
if [ -z "$NEWKERNEL" ]; then
	show_usage
	exit 0
fi

# 1) Make sure to set GRUB_DEFAULT to saved:
change_default_entry
if [ $? -eq 1 ]; then
	echo "[ERROR]: Unable to set GRUB_DEFAULT to saved; exiting ... "
	exit 1
fi

# 2) Add the "panic=TIMEOUT" option to /etc/default/grub:
set_kernel_panic_timeout $TIMEOUT
if [ $? -eq 1 ]; then
	echo "[ERROR]: Unable to set panic=$TIMEOUT to /etc/default/grub; exiting ... "
	exit 2
else
	echo "Timeout of $TIMEOUT seconds for kernel panic set."
fi

# 3) Make sure to set the current running kernel as the default one
# and re-generate /boot/grub.cfg (that will include the new installed kernel):
set_default_running_kernel
if [ $? -eq 1 ]; then
	echo "[ERROR]: Unable to set the default kernel as the running one!!!"
	exit 3
fi
# Update grub:
update-grub 2>/dev/null

# Finally, we reboot into the new installed kernel ...
reboot_into_the_new_kernel $NEWKERNEL
if [ $? -eq 1 ]; then
	echo "[ERROR]: Unable to reboot into the new installed kernel ${NEWKERNEL}".
	exit 4
else
	# Reboot now (ask if DOREBOOT is not already "y"):
	if [ "$DOREBOOT" != "y" ]; then
		echo "Do you want to reboot now [yn] ?"
		read r
		if [ $r == "y" ]; then
			/sbin/shutdown -r now "Rebooting into the new kernel: $NEWKERNEL ... "
		else
			echo "Changes made; don't forget to reboot ..."
			exit 0
		fi
	else
		# Automatic reboot:
		/sbin/shutdown -r now "Rebooting into the new kernel: $NEWKERNEL ... "
	fi
fi
