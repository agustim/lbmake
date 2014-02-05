# Makefile
DESTDIR ?= devel
ARCH ?= i386
FLAVOUR ?= 686-pae
BINARYIMAGE ?= iso-hybrid

all: build

build_environment:
	mkdir -p ${DESTDIR}/auto
	cp /usr/share/doc/live-build/examples/auto/* ${DESTDIR}/auto/

prepare_configure: build_environment
	@echo 'lb config noauto \
		--binary-images ${BINARYIMAGE} \
		--architectures ${ARCH} \
		--linux-flavours ${FLAVOUR} \
		--bootappend-live "boot=live config keyboard-layouts=es,es" \
		"${@}"' > ${DESTDIR}/auto/config

make_config: prepare_configure
	cd ${DESTDIR} && lb config

GET_KEY = curl -s 'http://pgp.mit.edu/pks/lookup?op=get&search=0xKEY_ID' | sed -n '/^-----BEGIN/,/^-----END/p'

add_repos: make_config
	@echo "deb http://repo.clommunity-project.eu/debian unstable/" > ${DESTDIR}/config/archives/gcodis.list.chroot
	$(subst KEY_ID,8AE35B96C3FD5CD9, ${GET_KEY}) > ${DESTDIR}/config/archives/gcodis.key.chroot
	@echo "deb http://serveis.guifi.net/debian guifi/" > ${DESTDIR}/config/archives/serveis.list.chroot
	$(subst KEY_ID,2E484DAB, ${GET_KEY}) > ${DESTDIR}/config/archives/serveis.key.chroot

add_packages: add_repos
	@echo "openssh-server openssh-client" > ${DESTDIR}/config/package-lists/ssh.list.chroot
	@echo "getinconf-client" > ${DESTDIR}/config/package-lists/tinc.list.chroot
	@echo "curl unzip make avahi-utils" > ${DESTDIR}/config/package-lists/avahi.list.chroot
	@echo "tahoe-lafs" > ${DESTDIR}/config/package-lists/tahoe.list.chroot
	@echo "mysql-server" > ${DESTDIR}/config/package-lists/mysql.list.chroot
	@echo "python2.7 g++ make checkinstall" > ${DESTDIR}/config/package-lists/nodejs.list.chroot
	@echo "openjdk-6-jre" > ${DESTDIR}/config/package-lists/java.list.chroot
	@echo "locales" > ${DESTDIR}/config/package-lists/locale.list.chroot

hooks: add_packages
	mkdir -p ${DESTDIR}/config/hooks
	cp hooks/* ${DESTDIR}/config/hooks/

build: hooks
	cd ${DESTDIR} && lb build

clean:
	cd ${DESTDIR} && lb clean

.PHONY: all build_environment prepare_configure make_config add_repos add_packages hooks build_environment clean
