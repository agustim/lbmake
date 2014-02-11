# Makefile
DESTDIR ?= devel
ARCH ?= i386
FLAVOUR ?= 686-pae
IMAGE ?= iso-hybrid

GET_KEY := curl -s 'http://pgp.mit.edu/pks/lookup?op=get&search=0xKEY_ID' | sed -n '/^-----BEGIN/,/^-----END/p'
ARCHDIR := ${DESTDIR}/config/archives
PKGDIR := ${DESTDIR}/config/package-lists
HOOKDIR := ${DESTDIR}/config/hooks
CUSTDIR := ${DESTDIR}/config/custom

NAME := Clommunity distro 
SPLASH_TITLE := ${NAME}${ARCH}
TIMESTAMP := $(shell date -u '+%d %b %Y %R %Z')
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_HASH := $(shell git rev-parse --short=12 HEAD)

all: build

build_environment:
	mkdir -p ${DESTDIR}/auto
	cp /usr/share/doc/live-build/examples/auto/* ${DESTDIR}/auto/ 

prepare_configure: build_environment
	echo 'lb config noauto \
		--binary-images ${IMAGE} \
		--architectures ${ARCH} \
		--linux-flavours ${FLAVOUR} \
		--bootappend-live "boot=live config keyboard-layouts=es,es" \
		--debian-installer live \
		--apt-indices false \
		"$${@}"' > ${DESTDIR}/auto/config

make_config: prepare_configure
	cd ${DESTDIR} && lb config

add_repos: make_config
	mkdir -p ${ARCHDIR}
	echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${ARCHDIR}/gcodis.list.chroot
	$(subst KEY_ID,8AE35B96C3FD5CD9, ${GET_KEY}) > ${ARCHDIR}/gcodis.key.chroot
	echo "deb http://serveis.guifi.net/debian guifi/" > ${ARCHDIR}/serveis.list.chroot
	$(subst KEY_ID,2E484DAB, ${GET_KEY}) > ${ARCHDIR}/serveis.key.chroot

add_packages: add_repos
	mkdir -p ${PKGDIR}
	echo "openssh-server openssh-client" > ${PKGDIR}/ssh.list.chroot
	echo "getinconf-client" > ${PKGDIR}/tinc.list.chroot
	echo "curl unzip make avahi-utils" > ${PKGDIR}/avahi.list.chroot
	echo "tahoe-lafs" > ${PKGDIR}/tahoe.list.chroot
	echo "mysql-server" > ${PKGDIR}/mysql.list.chroot
	echo "python2.7 g++ make checkinstall" > ${PKGDIR}/nodejs.list.chroot
	echo "openjdk-6-jre" > ${destdir}/java.list.chroot
	echo "locales" > ${PKGDIR}/locale.list.chroot

hooks: add_packages
	mkdir -p ${HOOKDIR}
	cp hooks/* ${HOOKDIR}/

custom: hooks res/clommunity.png
	mkdir -p ${CUSTDIR}
	convert res/clommunity.png -gravity NorthWest -background black \
		-bordercolor black -border 30x30 -extent 640x480 \
		-fill white -pointsize 28 -gravity NorthWest -annotate +265+55 \
		"${SPLASH_TITLE}\n${TIMESTAMP}\n${GIT_BRANCH}@${GIT_HASH}" \
		${CUSTDIR}/splash.png

build: custom
	cd ${DESTDIR} && lb build

clean:
	cd ${DESTDIR} && lb clean

.PHONY: all build_environment prepare_configure make_config add_repos add_packages hooks custom build clean
