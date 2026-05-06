.POSIX:
PREFIX = ${HOME}/.local
BIN_LOC = $(DESTDIR)$(PREFIX)/bin
LIB_LOC = $(DESTDIR)$(PREFIX)/lib/shed
DOC_LOC = $(DESTDIR)$(PREFIX)/share/doc/shed
MANPREFIX = $(PREFIX)/share/man
.PHONY: all install uninstall clean
GITTAG = $(shell git describe --tags 2>/dev/null)
VERS = v0.2.0
VERSION = $(if $(GITTAG),$(GITTAG),$(VERS))
SHED = shed.$(VERSION)
SHEDC = shedc.$(VERSION)
LIBSHED = libshed.$(VERSION)
UTILS = utils.$(VERSION)

all: $(SHED) $(SHEDC) $(LIBSHED) $(UTILS)

$(SHED):
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g; s|./utils.sh|$(LIB_LOC)/$(UTILS)|g; s|@DOC@|$(DOC_LOC)|" \
		shed.sh > $@
	chmod 755 $@
	sed "s|@VERSION@|$(VERSION)|g" shed.1.in > shed.1

$(SHEDC):
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" shedc.sh > $@
	chmod 755 $@

$(LIBSHED):
	sed "s|@VERSION@|$(VERSION)|g; s|./utils.sh|$(LIB_LOC)/$(UTILS)|g" \
		libshed.sh > $@
	chmod 755 $@

$(UTILS):
	cp -f utils.sh $@
	chmod 755 $@

install: all
	mkdir -p $(BIN_LOC)
	mkdir -p $(LIB_LOC)
	mkdir -p $(DOC_LOC)
	mkdir -p $(MANPREFIX)
	cp -vf $(SHED)  $(LIB_LOC)/$(SHED)
	cp -vf $(SHEDC) $(LIB_LOC)/$(SHEDC)
	cp -vf $(LIBSHED)  $(LIB_LOC)/$(LIBSHED)
	cp -vf $(UTILS)  $(LIB_LOC)/$(UTILS)
	cp -vf shed.rc $(DOC_LOC)/shed.rc
	cp -vf shed.1 $(MANPREFIX)/man1/shed.1
	ln -sf $(LIB_LOC)/$(SHED)  $(BIN_LOC)/shed
	ln -sf $(LIB_LOC)/$(SHEDC) $(BIN_LOC)/shedc

uninstall:
	rm -vf $(BIN_LOC)/shed
	rm -vf $(BIN_LOC)/shedc
	rm -vf $(DOC_LOC)/shed.rc
	rm -vf $(MANPREFIX)/man1/shed.1

clean:
	rm $(SHED)
	rm $(SHEDC)
	rm $(LIBSHED)
	rm $(UTILS)
	rm shed.1
