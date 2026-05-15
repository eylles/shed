#################################
# shed build time configuration #
#################################

# installation prefix
PREFIX = /usr/local
# executables location
BIN_LOC = $(DESTDIR)$(PREFIX)/bin
# libraries location
LIB_LOC = $(DESTDIR)$(PREFIX)/lib/shed
# docs and examples location
DOC_LOC = $(DESTDIR)$(PREFIX)/share/doc/shed
# manpage location
MAN_LOC = $(DESTDIR)$(PREFIX)/share/man/man1
# shed executable versioned name
SHED = shed.$(VERSION)
# shedc executable versioned name
SHEDC = shedc.$(VERSION)
# libshed versioned name
LIBSHED = libshed.$(VERSION)
# utils lib versioned name
UTILS = utils.$(VERSION)
