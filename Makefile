.POSIX:

include version.mk
include config.mk

.PHONY: all bin lib install uninstall clean

all: bin lib

bin: $(SHED) $(SHEDC)

lib: $(LIBSHED) $(UTILS)

build:
	mkdir build

$(SHED): build $(LIBSHED)
	sed "s|./utils.sh|$(LIB_LOC)/$(UTILS)|g" shed.sh | \
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" | \
	sed "s|@DOC@|$(DOC_LOC)|" > build/$@
	chmod 755 build/$@
	sed "s|@VERSION@|$(VERSION)|g" shed.1.in > build/shed.1

$(SHEDC): build $(LIBSHED)
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" shedc.sh > build/$@
	chmod 755 build/$@

$(LIBSHED): build $(UTILS)
	sed "s|@VERSION@|$(VERSION)|g" libshed.sh | \
	sed "s|./utils.sh|$(LIB_LOC)/$(UTILS)|g" > build/$@
	chmod 755 build/$@

$(UTILS): build
	cp -f utils.sh build/$@
	chmod 755 build/$@

install: all
	mkdir -p $(BIN_LOC)
	mkdir -p $(LIB_LOC)
	mkdir -p $(DOC_LOC)
	mkdir -p $(MAN_LOC)
	mkdir -p $(DOC_LOC)/examples
	cp -vf build/$(SHED)  $(LIB_LOC)/$(SHED)
	cp -vf build/$(SHEDC) $(LIB_LOC)/$(SHEDC)
	cp -vf build/$(LIBSHED)  $(LIB_LOC)/$(LIBSHED)
	cp -vf build/$(UTILS)  $(LIB_LOC)/$(UTILS)
	cp -vf shed.rc $(DOC_LOC)/shed.rc
	cp -vf loglevel.rc $(DOC_LOC)/loglevel.rc
	cp -vrf examples/* $(DOC_LOC)/examples
	cp -vf docs/how_it_works.md $(DOC_LOC)/how_it_works.md
	cp -vf docs/architecture.md $(DOC_LOC)/architecture.md
	cp -vf build/shed.1 $(MAN_LOC)/shed.1
	ln -sf $(LIB_LOC)/$(SHED)  $(BIN_LOC)/shed
	ln -sf $(LIB_LOC)/$(SHEDC) $(BIN_LOC)/shedc

uninstall:
	rm -vf $(BIN_LOC)/shed
	rm -vf $(BIN_LOC)/shedc
	rm -vf $(DOC_LOC)/shed.rc
	rm -vf $(MAN_LOC)/shed.1
	rm -vr $(DOC_LOC)/examples

clean:
	rm -vrf build
