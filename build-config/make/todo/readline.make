#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2018 Mark Tsai<marktsai0316@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of readline library
#
# https://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz
# https://packages.ubuntu.com/artful/libreadline7
#-------------------------------------------------------------------------------

READLINE_VERSION	= 7.0
READLINE_TARBALL	= readline-$(READLINE_VERSION).tar.gz
READLINE_TARBALL_URLS	+= $(ONIE_MIRROR) https://ftp.gnu.org/gnu/readline/
#PPP_BUILD_DIR		= $(MBUILDDIR)/readline
READLINE_BUILD_DIR	= $(USER_BUILDDIR)/readline
READLINE_DIR		= $(READLINE_BUILD_DIR)/readline-$(READLINE_VERSION)

#READLINE_SRCPATCHDIR	= $(PATCHDIR)/readline
READLINE_PATCHDIR	= $(READLINE_BUILD_DIR)/patch
READLINE_DOWNLOAD_STAMP = $(DOWNLOADDIR)/readline-download
READLINE_SOURCE_STAMP	= $(USER_STAMPDIR)/readline-source
READLINE_PATCH_STAMP	= $(USER_STAMPDIR)/readline-patch
READLINE_CONFIGURE_STAMP = $(USER_STAMPDIR)/readline-configure
READLINE_BUILD_STAMP	= $(USER_STAMPDIR)/readline-build
READLINE_INSTALL_STAMP	= $(STAMPDIR)/readline-install
READLINE_STAMP		= $(READLINE_SOURCE_STAMP) \
			  $(READLINE_PATCH_STAMP) \
			  $(READLINECONFIGURE_STAMP) \
			  $(READLINE_BUILD_STAMP) \
			  $(READLINE_INSTALL_STAMP)

PHONY += readline readline-download readline-source readline-patch readline-configure\
	 readline-build readline-install readline-clean \
	 readline-download-clean

# What to install.
#TO_BIN= lua luac
#TO_INC= lua.h luaconf.h lualib.h lauxlib.h lua.hpp
#TO_LIB= liblua.a
#TO_MAN= lua.1 luac.1


READLINE_SRCPATCHDIR = $(shell \
			   test -d $(PATCHDIR)/readline && \
			   echo "$(PATCHDIR)/readline")

ifneq ($(READLINE_SRCPATCHDIR),)
  READLINE_SRCPATCHDIR_FILES = $(READLINE_SRCPATCHDIR)/*
endif

MACHINE_READLINE_PATCHDIR = $(shell \
			   test -d $(MACHINEDIR)/readline && \
			   echo "$(MACHINEDIR)/readline")

ifneq ($(MACHINE_READLINE_PATCHDIR),)
  MACHINE_READLINE_PATCHDIR_FILES = $(MACHINE_READLINE_PATCHDIR)/*
endif

readline: $(READLINE_STAMP)

DOWNLOAD += $(READLINE_DOWNLOAD_STAMP)
readline-download: $(READLINE_DOWNLOAD_STAMP)
$(READLINE_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream readline ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(READLINE_TARBALL) $(READLINE_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(READLINE_SOURCE_STAMP)
readline-source: $(READLINE_SOURCE_STAMP)
$(READLINE_SOURCE_STAMP): $(TREE_STAMP) $(READLINE_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream readline ===="
	$(Q) $(SCRIPTDIR)/extract-package $(READLINE_BUILD_DIR) $(DOWNLOADDIR)/$(READLINE_TARBALL)
	$(Q) touch $@

readline-patch: $(READLINE_PATCH_STAMP)
$(READLINE_PATCH_STAMP): $(READLINE_SRCPATCHDIR_FILES) $(MACHINE_READLINE_PATCHDIR_FILES) $(READLINE_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching readline-$(READLINE_VERSION) ===="
ifneq ($(READLINE_SRCPATCHDIR),)
	$(Q) $(SCRIPTDIR)/apply-patch-series $(READLINE_SRCPATCHDIR)/series $(READLINE_DIR)
endif
	$(Q) touch $@


ifndef MAKE_CLEAN
READLINE_NEW_FILES = $(shell test -d $(READLINE_DIR) && test -f $(READLINE_BUILD_STAMP) && \
	              find -L $(READLINE_DIR) -newer $(READLINE_BUILD_STAMP) -type f -print -quit)
endif

readline-configure: $(READLINE_CONFIGURE_STAMP)
$(READLINE_CONFIGURE_STAMP): $(READLINE_PATCH_STAMP) $(READLINE_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure readline-$(READLINE_VERSION) ===="
	echo $(TARGET)
	$(Q) cd $(READLINE_DIR) &&  PATH='$(CROSSBIN):$(PATH)' \
	 	$(READLINE_DIR)/configure 			\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET) 				\
		CFLAGS="$(ONIE_CFLAGS)" 			\
		LDFLAGS="$(ONIE_LDFLAGS)" 
	$(Q) touch $@


readline-build: $(READLINE_BUILD_STAMP)
$(READLINE_BUILD_STAMP): $(READLINE_NEW_FILES) $(READLINE_PATCH_STAMP) $(READLINE_CONFIGURE_STAMP) $| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building readline-$(READLINE_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(READLINE_DIR) 
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(READLINE_DIR) install
	$(Q) touch $@

readline-install: $(READLINE_INSTALL_STAMP)
$(READLINE_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(READLINE_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing readline in $(SYSROOTDIR) ===="
	echo "kkkkkkkkkkkkkkkkkkkk"
	#$(Q) touch $@


USER_CLEAN += readline-clean
readline-clean:
	$(Q) rm -rf $(READLINE_BUILD_DIR)
	$(Q) rm -f $(READLINE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += readline-download-clean
readline-download-clean:
	$(Q) rm -f $(READLINE_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(READLINE_TARBALL)


#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
