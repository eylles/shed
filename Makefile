.POSIX:
PREFIX = ${HOME}/.local
BIN_LOC = $(DESTDIR)$(PREFIX)/bin
LIB_LOC = $(DESTDIR)$(PREFIX)/lib/shed
.PHONY: all install uninstall clean
GITTAG = $(shell git describe --tags 2>/dev/null)
VERS = v0.2.0
VERSION = $(if $(GITTAG),$(GITTAG),$(VERS))
SHED = shed.$(VERSION)
SHEDC = shedc.$(VERSION)

all: $(SHED) $(SHEDC)

$(SHED):
	sed "s|@VERSION@|$(VERSION)|g" shed > $@
	chmod 755 $@

$(SHEDC):
	sed "s|@VERSION@|$(VERSION)|g" shedc > $@
	chmod 755 $@

install:
	mkdir -p $(BIN_LOC)
	mkdir -p $(LIB_LOC)
	cp -vf $(SHED)  $(LIB_LOC)/$(SHED)
	cp -vf $(SHEDC) $(LIB_LOC)/$(SHEDC)
	ln -sf $(LIB_LOC)/$(SHED)  $(BIN_LOC)/shed
	ln -sf $(LIB_LOC)/$(SHEDC) $(BIN_LOC)/shedc

uninstall:
	rm -vf $(BIN_LOC)/shed
	rm -vf $(BIN_LOC)/shedc

clean:
	rm $(SHED)
	rm $(SHEDC)
