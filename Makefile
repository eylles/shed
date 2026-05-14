.POSIX:

include version.mk
include config.mk

.PHONY: all install uninstall clean

all: $(SHED) $(SHEDC) $(LIBSHED) $(UTILS)

$(SHED):
	sed "s|./utils.sh|$(LIB_LOC)/$(UTILS)|g" shed.sh | \
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" | \
	sed "s|@DOC@|$(DOC_LOC)|" > $@
	chmod 755 $@
	sed "s|@VERSION@|$(VERSION)|g" shed.1.in > shed.1

$(SHEDC):
	sed "s|./libshed.sh|$(LIB_LOC)/$(LIBSHED)|g" shedc.sh > $@
	chmod 755 $@

$(LIBSHED):
	sed "s|@VERSION@|$(VERSION)|g" libshed.sh | \
	sed "s|./utils.sh|$(LIB_LOC)/$(UTILS)|g" > $@
	chmod 755 $@

$(UTILS):
	cp -f utils.sh $@
	chmod 755 $@

install: all
	mkdir -p $(BIN_LOC)
	mkdir -p $(LIB_LOC)
	mkdir -p $(DOC_LOC)
	mkdir -p $(MAN_LOC)
	cp -vf $(SHED)  $(LIB_LOC)/$(SHED)
	cp -vf $(SHEDC) $(LIB_LOC)/$(SHEDC)
	cp -vf $(LIBSHED)  $(LIB_LOC)/$(LIBSHED)
	cp -vf $(UTILS)  $(LIB_LOC)/$(UTILS)
	cp -vf shed.rc $(DOC_LOC)/shed.rc
	cp -vf shed.1 $(MAN_LOC)/shed.1
	ln -sf $(LIB_LOC)/$(SHED)  $(BIN_LOC)/shed
	ln -sf $(LIB_LOC)/$(SHEDC) $(BIN_LOC)/shedc

uninstall:
	rm -vf $(BIN_LOC)/shed
	rm -vf $(BIN_LOC)/shedc
	rm -vf $(DOC_LOC)/shed.rc
	rm -vf $(MAN_LOC)/shed.1

clean:
	rm -f $(SHED)
	rm -f $(SHEDC)
	rm -f $(LIBSHED)
	rm -f $(UTILS)
	rm -f shed.1
