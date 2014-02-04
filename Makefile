# Makefile
DESTDIR ?= devel

all: build
	@echo 'Come on!'

build_environment:
	mkdir -p ${DESTDIR}/auto
	cp /usr/share/doc/live-build/examples/auto/* ${DESTDIR}/auto/

prepare_configure: build_environment
	@echo '#!/bin/sh' > ${DESTDIR}/auto/config
	@echo '' >> ${DESTDIR}/auto/config
	@echo 'lb config noauto \' >> ${DESTDIR}/auto/config
	@echo '		--architectures i386 \' >> ${DESTDIR}/auto/config
	@echo '		--linux-flavours 686-pae \' >> ${DESTDIR}/auto/config
	@echo '		--bootappend-live \' >> ${DESTDIR}/auto/config
	@echo '		"boot=live config keyboard-layouts=es,es" \' >> ${DESTDIR}/auto/config
	@echo '		"${@}"' >> ${DESTDIR}/auto/config

make_config: prepare_configure
	cd ${DESTDIR} && lb config

add_repos: make_config
	@echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${DESTDIR}/config/archives/gcodis.list.chroot
	curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x8AE35B96C3FD5CD9' | sed -n '/^-----BEGIN/,/^-----END/'p > ${DESTDIR}/config/archives/gcodis.key.chroot
	@echo "deb http://serveis.guifi.net/debian guifi/" > ${DESTDIR}/config/archives/serveis.list.chroot
	curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x2E484DAB' | sed -n '/^-----BEGIN/,/^-----END/'p > ${DESTDIR}/config/archives/serveis.key.chroot

add_packages: add_repos
	echo "openssh-server openssh-client" > ${DESTDIR}/config/package-lists/ssh.list.chroot
	echo "getinconf-client" > ${DESTDIR}/config/package-lists/tinc.list.chroot
	echo "curl unzip make avahi-utils" > ${DESTDIR}/config/package-lists/avahi.list.chroot
	echo "mysql-server" > ${DESTDIR}/config/package-lists/mysql.list.chroot
	echo "python g++ make checkinstall" > ${DESTDIR}/config/package-lists/node.list.chroot

hooks: add_packages
	cp hooks/* ${DESTDIR}/config/hooks/

build: hooks
	cd ${DESTDIR} && lb build

clean:
	cd ${DESTDIR} && lb clean
