.POSIX:
PREFIX = ${HOME}/.local
BIN_LOC = $(DESTDIR)$(PREFIX)/bin
LIB_LOC = $(DESTDIR)$(PREFIX)/lib/shed
DOC_LOC = $(DESTDIR)$(PREFIX)/share/doc/shed
.PHONY: all install uninstall clean
GITTAG = $(shell git describe --tags 2>/dev/null)
VERS = v0.2.0
VERSION = $(if $(GITTAG),$(GITTAG),$(VERS))
SHED = shed.$(VERSION)
SHEDC = shedc.$(VERSION)
LIBSHED = libshed.$(VERSION)

all: $(SHED) $(SHEDC) $(LIBSHED)

$(SHED):
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g; s|@DOC@|$(DOC_LOC)|" shed > $@
	chmod 755 $@

$(SHEDC):
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" shedc > $@
	chmod 755 $@

$(LIBSHED):
	sed "s|@VERSION@|$(VERSION)|g" libshed.sh > $@
	chmod 755 $@

install: all
	mkdir -p $(BIN_LOC)
	mkdir -p $(LIB_LOC)
	mkdir -p $(DOC_LOC)
	cp -vf $(SHED)  $(LIB_LOC)/$(SHED)
	cp -vf $(SHEDC) $(LIB_LOC)/$(SHEDC)
	cp -vf $(LIBSHED)  $(LIB_LOC)/$(LIBSHED)
	cp -vf shed.rc $(DOC_LOC)/shed.rc
	ln -sf $(LIB_LOC)/$(SHED)  $(BIN_LOC)/shed
	ln -sf $(LIB_LOC)/$(SHEDC) $(BIN_LOC)/shedc

uninstall:
	rm -vf $(BIN_LOC)/shed
	rm -vf $(BIN_LOC)/shedc
	rm -vf $(DOC_LOC)/shed.rc

clean:
	rm $(SHED)
	rm $(SHEDC)
	rm $(LIBSHED)
