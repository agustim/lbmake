# lbmake - Live-Build Make

Build and package the Clommunity distro

## Build

	sudo make

## Test

Once the image has been created, you can test it out as follows:

	qemu-system-i386 --cdrom devel/binary.hybrid.iso

If you have a relatively recent computer, appending `--enable-kvm` should take
advantage of hardware virtualization and make it work much faster.

In order to test the installation and setup of the distro, you can create a
disk image and use it as well:

	qemu-img create -f qcow2 disk.qcow2 4G
	qemu-system-i386 -enable-kvm -cdrom devel/binary.hybrid.iso -hda disk.qcow2
