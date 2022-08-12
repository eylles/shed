.POSIX:
PREFIX = ~/.local
.PHONY: install uninstall


install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	chmod 755 shed
	cp -vf shed ${DESTDIR}${PREFIX}/bin/shed
	chmod 755 shedc
	cp -vf shedc ${DESTDIR}${PREFIX}/bin/shedc
uninstall:
	rm -vf ${DESTDIR}${PREFIX}/bin/shed
	rm -vf ${DESTDIR}${PREFIX}/bin/shedc

