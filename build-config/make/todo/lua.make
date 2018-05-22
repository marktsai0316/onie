#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2018 Mark Tsai<marktsai0316@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of lua
#
# http://www.lua.org/ftp/lua-5.3.4.tar.gz
# https://packages.ubuntu.com/search?suite=xenial&section=all&arch=any&keywords=lua5.3&searchon=names
#-------------------------------------------------------------------------------

LUA_VERSION		= 5.3.4
LUA_TARBALL		= lua-$(LUA_VERSION).tar.gz
LUA_TARBALL_URLS	+= $(ONIE_MIRROR)  http://www.lua.org/ftp/
#PPP_BUILD_DIR		= $(MBUILDDIR)/ppp
LUA_BUILD_DIR		= $(USER_BUILDDIR)/lua
LUA_DIR			= $(LUA_BUILD_DIR)/lua-$(LUA_VERSION)

#PPP_SRCPATCHDIR	= $(PATCHDIR)/lua
LUA_PATCHDIR		= $(LUA_BUILD_DIR)/patch
LUA_DOWNLOAD_STAMP 	= $(DOWNLOADDIR)/lua-download
LUA_SOURCE_STAMP	= $(USER_STAMPDIR)/lua-source
LUA_PATCH_STAMP		= $(USER_STAMPDIR)/lua-patch
LUA_CONFIGURE_STAMP	= $(USER_STAMPDIR)/lua-configure
LUA_BUILD_STAMP		= $(USER_STAMPDIR)/lua-build
LUA_INSTALL_STAMP	= $(STAMPDIR)/lua-install
LUA_STAMP		= $(LUA_SOURCE_STAMP) \
			  $(LUA_PATCH_STAMP) \
			  $(LUA_CONFIGURE_STAMP) \
			  $(LUA_BUILD_STAMP) \
			  $(LUA_INSTALL_STAMP)

PHONY += lua lua-download lua-source lua-patch lua-configure\
	 lua-build lua-install lua-clean \
	 lua-download-clean

#in /usr/lib/pppd/$(PPP_VERSION)
# What to install.
#TO_BIN= lua luac
#TO_INC= lua.h luaconf.h lualib.h lauxlib.h lua.hpp
#TO_LIB= liblua.a
#TO_MAN= lua.1 luac.1


LUA_SRCPATCHDIR = $(shell \
			   test -d $(PATCHDIR)/lua && \
			   echo "$(PATCHDIR)/lua")

ifneq ($(LUA_SRCPATCHDIR),)
  LUA_SRCPATCHDIR_FILES = $(LUA_SRCPATCHDIR)/*
endif

MACHINE_LUA_PATCHDIR = $(shell \
			   test -d $(MACHINEDIR)/lua && \
			   echo "$(MACHINEDIR)/lua")

ifneq ($(MACHINE_LUA_PATCHDIR),)
  MACHINE_LUA_PATCHDIR_FILES = $(MACHINE_LUA_PATCHDIR)/*
endif

lua: $(LUA_STAMP)

DOWNLOAD += $(LUA_DOWNLOAD_STAMP)
lua-download: $(LUA_DOWNLOAD_STAMP)
$(LUA_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream lua ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LUA_TARBALL) $(LUA_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LUA_SOURCE_STAMP)
lua-source: $(LUA_SOURCE_STAMP)
$(LUA_SOURCE_STAMP): $(TREE_STAMP) $(LUA_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream lua ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LUA_BUILD_DIR) $(DOWNLOADDIR)/$(LUA_TARBALL)
	$(Q) touch $@

lua-patch: $(LUA_PATCH_STAMP)
$(LUA_PATCH_STAMP): $(LUA_SRCPATCHDIR_FILES) $(MACHINE_LUA_PATCHDIR_FILES) $(LUA_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching lua-$(LUA_VERSION) ===="
ifneq ($(LUA_SRCPATCHDIR),)
	$(Q) $(SCRIPTDIR)/apply-patch-series $(LUA_SRCPATCHDIR)/series $(LUA_DIR)
endif
	$(Q) touch $@


ifndef MAKE_CLEAN
LUA_NEW_FILES = $(shell test -d $(LUA_DIR) && test -f $(LUA_BUILD_STAMP) && \
	              find -L $(LUA_DIR) -newer $(LUA_BUILD_STAMP) -type f -print -quit)
endif

lua-configure: $(LUA_CONFIGURE_STAMP)
$(LUA_CONFIGURE_STAMP): $(LUA_PATCH_STAMP) $(LUA_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure lua-$(LUA_VERSION) ===="
	$(Q) touch $@


lua-build: $(LUA_BUILD_STAMP)
$(LUA_BUILD_STAMP): $(LUA_NEW_FILES) $(LUA_PATCH_STAMP) $(LUA_CONFIGURE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building lua-$(LUA_VERSION) ===="
	#$(SYSCFLAGS) $(MYCFLAGS) $(SYSLDFLAGS) $(MYLDFLAGS) $(SYSLIBS) $(MYLIBS)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LUA_DIR) CROSS_COMPILE=$(CROSSPREFIX) echo
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LUA_DIR) CROSS_COMPILE=$(CROSSPREFIX) linux
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LUA_DIR) CROSS_COMPILE=$(CROSSPREFIX) INSTALL_TOP=$(DEV_SYSROOT)/usr/local install
	#make CC=arm-elf-gcc MYLDFLAGS=-Wl,-elf2flt posix
	#$(Q) touch $@

lua-install: $(LUA_INSTALL_STAMP)
$(LUA_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LUA_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing lua in $(SYSROOTDIR) ===="
	#$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LUA_DIR) CROSS_COMPILE=$(CROSSPREFIX) INSTALL_TOP=$(DEV_SYSROOT)/usr/local install
	$(Q) touch $@


USER_CLEAN += lua-clean
lua-clean:
	$(Q) rm -rf $(LUA_BUILD_DIR)
	$(Q) rm -f $(LUA_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += lua-download-clean
lua-download-clean:
	$(Q) rm -f $(LUA_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LUA_TARBALL)


#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
