# Makefile
DESTDIR ?= devel
ARCH ?= i386
FLAVOUR ?= 686-pae
IMAGE ?= iso-hybrid # or iso, hdd, tar or netboot
INSTALL ?= live # or businesscard, netinst, cdrom...
CPATH ?= /var/lib/lxc/
CNAME ?= gcodis
MACGEN ?= $(shell echo $$(date +%N))
MACADDR ?= $(shell echo $$(echo ${MACGEN}|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$$/02:\1:\2:\3:\4:\5/'))
ROOTPWD ?= root
MACHINENAME ?= gcodis

GET_KEY := curl -s 'http://pgp.mit.edu/pks/lookup?op=get&search=0xKEY_ID' | sed -n '/^-----BEGIN/,/^-----END/p'
ARCHDIR := ${DESTDIR}/config/archives
PKGDIR := ${DESTDIR}/config/package-lists
HOOKDIR := ${DESTDIR}/config/hooks
CUSTDIR := ${DESTDIR}/config/custom

NAME := Clommunity distro
SPLASH_TITLE := ${NAME}
SPLASH_SUBTITLE := ${ARCH} ${FLAVOUR}
TIMESTAMP := $(shell date -u '+%d %b %Y %R %Z')
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_HASH := $(shell git rev-parse --short=12 HEAD)

all: build

describe: packages
	@cat packages

build_environment:
	mkdir -p ${DESTDIR}/auto
	cp /usr/share/doc/live-build/examples/auto/* ${DESTDIR}/auto/

prepare_configure: build_environment
	echo 'lb config noauto \
		--binary-images ${IMAGE} \
		--architectures ${ARCH} \
		--linux-flavours ${FLAVOUR} \
		--debian-installer ${INSTALL} \
		--bootappend-live "boot=live config keyboard-layouts=es,es" \
		--apt-indices false \
		"$${@}"' > ${DESTDIR}/auto/config

make_config: prepare_configure
	cd ${DESTDIR} && lb config

add_repos: make_config
	which curl >/dev/null
	mkdir -p ${ARCHDIR}
	echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${ARCHDIR}/gcodis.list.chroot
	$(subst KEY_ID,8AE35B96C3FD5CD9, ${GET_KEY}) > ${ARCHDIR}/gcodis.key.chroot
	echo "deb http://serveis.guifi.net/debian guifi/" > ${ARCHDIR}/serveis.list.chroot
	$(subst KEY_ID,2E484DAB, ${GET_KEY}) > ${ARCHDIR}/serveis.key.chroot

add_packages: add_repos
	mkdir -p ${PKGDIR}
	while IFS=':	' read name pkgs; do \
		echo $$pkgs > ${PKGDIR}/$$name.list.chroot; \
	done < packages

hooks: add_packages
	mkdir -p ${HOOKDIR}
	cp hooks/* ${HOOKDIR}/

custom: hooks res/clommunity.png
	mkdir -p ${CUSTDIR}
	convert res/clommunity.png -gravity NorthWest -background black \
		-bordercolor black -border 80x50 -extent 640x480 \
		-fill white -pointsize 28 -gravity NorthWest -annotate +330+55 \
		"${SPLASH_TITLE}\n${SPLASH_SUBTITLE}" \
		-fill white -pointsize 20 -gravity NorthWest -annotate +330+120 \
		"${TIMESTAMP}\n${GIT_BRANCH}@${GIT_HASH}" \
		${CUSTDIR}/splash.png

build: .build

.build: custom
	cd ${DESTDIR} && lb build
	@touch .build

container:
	mkdir ${DESTDIR}/tmp/
	mkdir -p /mnt/tmp/
	mkdir -p ${CPATH}/${CNAME}/
	mount -o loop ${DESTDIR}/binary.hybrid.iso ${DESTDIR}/tmp/
	mount ${DESTDIR}/tmp/live/filesystem.squashfs /mnt/tmp/
	ls ${CPATH}/${CNAME}/ | grep "rootfs" || cp -rf /mnt/tmp/ /${CPATH}/${CNAME}/rootfs

	# Patch for local resolv.conf
	/bin/cat /etc/resolv.conf >> ${CPATH}/${CNAME}/rootfs/etc/resolv.conf

	# Begin with LXC configuration
	grep -q "^lxc.rootfs" ${CPATH}/${CNAME}/config 2>/dev/null || echo "lxc.rootfs = ${CPATH}/${CNAME}/rootfs" > ./lxc/config && cat ./lxc/basic.conf >> ./lxc/config

	# Network configuration
	printf "## Network\nlxc.network.type         = veth\nlxc.network.flags               =up\nlxc.network.hwaddr         =${MACADDR}\n#.lxc.network.link         = vmbr\nlxc.network.link                = lxcbr0\nlxc.network.name              = eth0" >> ./lxc/config
	#Copying configuration
	mv --force ./lxc/config ${CPATH}/${CNAME}/

	# Copying chroot to rootfs
	rm ${CPATH}/${CNAME}/rootfs/etc/inittab && cp ./lxc/inittab ${CPATH}/${CNAME}/rootfs/etc/
	mkdir -p ${CPATH}/${CNAME}/rootfs/selinux
	echo 0 > ${CPATH}/${CNAME}/rootfs/selinux/enforce
	echo "root:${ROOTPWD}" | chroot ${CPATH}/${CNAME}/rootfs/ chpasswd
	echo "${MACHINENAME}" > ${CPATH}/${CNAME}/rootfs/etc/hostname
	mkdir -p ${CPATH}/${CNAME}/rootfs/dev/net
	chroot ${CPATH}/${CNAME}/rootfs/ /bin/mknod /dev/net/tun c 10 200

	# Config interfaces
	printf "\n auto eth0\niface eth0 inet dhcp\n" >> ${CPATH}/${CNAME}/rootfs/etc/network/interfaces

	#Configuring locales in chroot
	chroot ${CPATH}/${CNAME}/rootfs/ sed -i "s/^# en_US/en_US/" /etc/locale.gen
	chroot ${CPATH}/${CNAME}/rootfs/ grep -v "^#" /etc/locale.gen
	chroot ${CPATH}/${CNAME}/rootfs/ /usr/sbin/locale-gen
	chroot ${CPATH}/${CNAME}/rootfs/ update-locale LANG=en_US.UTF-8

	#Enabling Avahi
	sed -i "s%^rlimit-nproc%#&%" ${CPATH}/${CNAME}/rootfs/etc/avahi/avahi-daemon.conf
	chmod 1777 ${CPATH}/${CNAME}/rootfs/tmp

	#Solving mySQL issues
	chroot ${CPATH}/${CNAME}/rootfs/ sh -c "chown -R mysql /var/lib/mysql"

	sleep 2
	# Removing redundant files and unmounting partitions
	umount /mnt/tmp/
	rm -r /mnt/tmp
	umount ${DESTDIR}/tmp/
	rm -r ${DESTDIR}/tmp

clean:
	cd ${DESTDIR} && lb clean
	@rm -f .build

.PHONY: all describe build_environment prepare_configure make_config add_repos add_packages hooks custom build container clean
