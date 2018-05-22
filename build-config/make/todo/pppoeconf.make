#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2018 Mark Tsai<marktsai0316@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of pppoeconf
#
# Depends: ppp, whiptail, gettext, sed
#
# refer to https://packages.ubuntu.com/xenial/pppoeconf
# refer to http://archive.ubuntu.com/ubuntu/pool/main/p/pppoeconf/pppoeconf_1.21ubuntu1.tar.gz
# https://packages.ubuntu.com/artful/libreadline7
#-------------------------------------------------------------------------------

PPPOECONF_VERSION	= 1.21
PPPOECONF_TARBALL	= pppoeconf_$(PPPOECONF_VERSION)ubuntu1.tar.gz
PPPOECONF_TARBALL_URLS	+= $(ONIE_MIRROR) http://archive.ubuntu.com/ubuntu/pool/main/p/pppoeconf
#PPP_BUILD_DIR		= $(MBUILDDIR)/pppoeconf
PPPOECONF_BUILD_DIR	= $(USER_BUILDDIR)/pppoeconf
PPPOECONF_DIR		= $(PPPOECONF_BUILD_DIR)/pppoeconf-$(PPPOECONF_VERSION)

#PPPOECONF_SRCPATCHDIR	= $(PATCHDIR)/pppoeconf
PPPOECONF_PATCHDIR	= $(PPPOECONF_BUILD_DIR)/patch
PPPOECONF_DOWNLOAD_STAMP = $(DOWNLOADDIR)/pppoeconf-download
PPPOECONF_SOURCE_STAMP	= $(USER_STAMPDIR)/pppoeconf-source
PPPOECONF_PATCH_STAMP	= $(USER_STAMPDIR)/pppoeconf-patch
PPPOECONF_CONFIGURE_STAMP = $(USER_STAMPDIR)/pppoeconf-configure
PPPOECONF_BUILD_STAMP	= $(USER_STAMPDIR)/pppoeconf-build
PPPOECONF_INSTALL_STAMP	= $(STAMPDIR)/pppoeconf-install
PPPOECONF_STAMP		= $(PPPOECONF_SOURCE_STAMP) \
			  $(PPPOECONF_PATCH_STAMP) \
			  $(PPPOECONFCONFIGURE_STAMP) \
			  $(PPPOECONF_BUILD_STAMP) \
			  $(PPPOECONF_INSTALL_STAMP)

PHONY += pppoeconf pppoeconf-download pppoeconf-source pppoeconf-patch pppoeconf-configure\
	 pppoeconf-build pppoeconf-install pppoeconf-clean \
	 pppoeconf-download-clean

# What to install.
#TO_BIN= lua luac
#TO_INC= lua.h luaconf.h lualib.h lauxlib.h lua.hpp
#TO_LIB= liblua.a
#TO_MAN= lua.1 luac.1


PPPOECONF_SRCPATCHDIR = $(shell \
			   test -d $(PATCHDIR)/pppoeconf && \
			   echo "$(PATCHDIR)/pppoeconf")

ifneq ($(PPPOECONF_SRCPATCHDIR),)
  PPPOECONF_SRCPATCHDIR_FILES = $(PPPOECONF_SRCPATCHDIR)/*
endif

MACHINE_PPPOECONF_PATCHDIR = $(shell \
			   test -d $(MACHINEDIR)/pppoeconf && \
			   echo "$(MACHINEDIR)/pppoeconf")

ifneq ($(MACHINE_PPPOECONF_PATCHDIR),)
  MACHINE_PPPOECONF_PATCHDIR_FILES = $(MACHINE_PPPOECONF_PATCHDIR)/*
endif

pppoeconf: $(PPPOECONF_STAMP)

DOWNLOAD += $(PPPOECONF_DOWNLOAD_STAMP)
pppoeconf-download: $(PPPOECONF_DOWNLOAD_STAMP)
$(PPPOECONF_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream pppoeconf ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(PPPOECONF_TARBALL) $(PPPOECONF_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(PPPOECONF_SOURCE_STAMP)
pppoeconf-source: $(PPPOECONF_SOURCE_STAMP)
$(PPPOECONF_SOURCE_STAMP): $(TREE_STAMP) $(PPPOECONF_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream pppoeconf ===="
	$(Q) $(SCRIPTDIR)/extract-package $(PPPOECONF_BUILD_DIR) $(DOWNLOADDIR)/$(PPPOECONF_TARBALL)
	$(Q) touch $@

pppoeconf-patch: $(PPPOECONF_PATCH_STAMP)
$(PPPOECONF_PATCH_STAMP): $(PPPOECONF_SRCPATCHDIR_FILES) $(MACHINE_PPPOECONF_PATCHDIR_FILES) $(PPPOECONF_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching pppoeconf-$(PPPOECONF_VERSION) ===="
ifneq ($(PPPOECONF_SRCPATCHDIR),)
	$(Q) $(SCRIPTDIR)/apply-patch-series $(PPPOECONF_SRCPATCHDIR)/series $(PPPOECONF_DIR)
endif
	$(Q) touch $@


ifndef MAKE_CLEAN
PPPOECONF_NEW_FILES = $(shell test -d $(PPPOECONF_DIR) && test -f $(PPPOECONF_BUILD_STAMP) && \
	              find -L $(PPPOECONF_DIR) -newer $(PPPOECONF_BUILD_STAMP) -type f -print -quit)
endif

pppoeconf-configure: $(PPPOECONF_CONFIGURE_STAMP)
$(PPPOECONF_CONFIGURE_STAMP): $(PPPOECONF_PATCH_STAMP) $(PPPOECONF_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure pppoeconf-$(PPPOECONF_VERSION) ===="
	$(Q) touch $@


pppoeconf-build: $(PPPOECONF_BUILD_STAMP)
$(PPPOECONF_BUILD_STAMP): $(PPPOECONF_NEW_FILES) $(PPPOECONF_PATCH_STAMP) $(PPPOECONF_CONFIGURE_STAMP) $| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building pppoeconf-$(PPPOECONF_VERSION) to $(DEV_SYSROOT) ===="
	$(Q) install -d $(DEV_SYSROOT)/usr/sbin && \
	install -m755 $(PPPOECONF_DIR)/pppoeconf $(DEV_SYSROOT)/usr/sbin && \
	echo "Copy pppoeconf to $(DEV_SYSROOT) is complete"
	$(Q) touch $@

pppoeconf-install: $(PPPOECONF_INSTALL_STAMP)
$(PPPOECONF_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(PPPOECONF_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing pppoeconf in $(SYSROOTDIR) ===="
	$(Q) install -d $(SYSROOTDIR)/usr/sbin && \
	install -m755 $(DEV_SYSROOT)/usr/sbin/pppoeconf $(SYSROOTDIR)/usr/sbin && \
	echo "Copy pppoeconf to $(SYSROOTDIR) is complete"
	$(Q) touch $@


USER_CLEAN += pppoeconf-clean
pppoeconf-clean:
	$(Q) rm -rf $(PPPOECONF_BUILD_DIR)
	$(Q) rm -f $(PPPOECONF_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += pppoeconf-download-clean
pppoeconf-download-clean:
	$(Q) rm -f $(PPPOECONF_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(PPPOECONF_TARBALL)


#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
