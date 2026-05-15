###################
# shed versioning #
###################

# version determined by git
GITTAG = $(shell git describe --tags 2>/dev/null)
# last release tag
VERS = v0.3.0
# actual version number that will be used
VERSION = $(if $(GITTAG),$(GITTAG),$(VERS))
