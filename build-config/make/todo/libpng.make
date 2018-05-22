#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2018 Mark Tsai<marktsai0316@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libpng
#
# http://www.libpng.org/pub/png/libpng.html
# https://sourceforge.net/projects/libpng/files/libpng16/1.6.34/libpng-1.6.34.tar.gz
# http://jyhshin.pixnet.net/blog/post/26588031-build-libpng
#-------------------------------------------------------------------------------

LIBPNG_VERSION		= 1.6.34
LIBPNG_MAJOR_VERSION	= $(word 1,$(wordlist 1,2,$(subst ., ,$(LIBPNG_VERSION))))$(word 2,$(wordlist 1,2,$(subst ., ,$(LIBPNG_VERSION))))
LIBPNG_TARBALL		= libpng-$(LIBPNG_VERSION).tar.gz
LIBPNG_TARBALL_URLS	+= $(ONIE_MIRROR) https://sourceforge.net/projects/libpng/files/libpng$(LIBPNG_MAJOR_VERSION)/$(LIBPNG_VERSION)
LIBPNG_BUILD_DIR	= $(USER_BUILDDIR)/libpng
LIBPNG_DIR		= $(LIBPNG_BUILD_DIR)/libpng-$(LIBPNG_VERSION)

LIBPNG_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/libpng-download
LIBPNG_SOURCE_STAMP	= $(USER_STAMPDIR)/libpng-source
LIBPNG_CONFIGURE_STAMP	= $(USER_STAMPDIR)/libpng-configure
LIBPNG_BUILD_STAMP	= $(USER_STAMPDIR)/libpng-build
LIBPNG_INSTALL_STAMP	= $(STAMPDIR)/libpng-install
LIBPNG_STAMP		= $(LIBPNG_SOURCE_STAMP) \
			  $(LIBPNG_CONFIGURE_STAMP) \
			  $(LIBPNG_BUILD_STAMP) \
			  $(LIBPNG_INSTALL_STAMP)

PHONY += libpng libpng-download libpng-source libpng-configure \
	 libpng-build libpng-install libpng-clean libpng-download-clean

#LIBPNGLIBS = libz.so libz.so.1 libz.so.$(LIBPNG_VERSION)

libpng: $(LIBPNG_STAMP)

DOWNLOAD += $(LIBPNG_DOWNLOAD_STAMP)
libpng-download: $(LIBPNG_DOWNLOAD_STAMP)
$(LIBPNG_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream libpng ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LIBPNG_TARBALL) $(LIBPNG_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LIBPNG_SOURCE_STAMP)
libpng-source: $(LIBPNG_SOURCE_STAMP)
$(LIBPNG_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LIBPNG_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream libpng ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LIBPNG_BUILD_DIR) $(DOWNLOADDIR)/$(LIBPNG_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LIBPNG_NEW_FILES = $(shell test -d $(LIBPNG_DIR) && test -f $(LIBPNG_BUILD_STAMP) && \
	              find -L $(LIBPNG_DIR) -newer $(LIBPNG_BUILD_STAMP) -type f -print -quit)
endif

libpng-configure: $(LIBPNG_CONFIGURE_STAMP)
$(LIBPNG_CONFIGURE_STAMP): $(LIBPNG_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure libpng-$(LIBPNG_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
		CC=$(CROSSPREFIX)gcc				\
		AR=$(CROSSPREFIX)ar				\
		RANLIB=$(CROSSPREFIX)ranlib			\
		CPP=$(CROSSPREFIX)cpp				\
		STRIP=$(CROSSPREFIX)strip			\
	    cd $(LIBPNG_DIR) &&					\
	    $(LIBPNG_DIR)/configure				\
		--host=$(TARGET)				\
		--prefix=/usr
	$(Q) touch $@

libpng-build: $(LIBPNG_BUILD_STAMP)
$(LIBPNG_BUILD_STAMP): $(LIBPNG_CONFIGURE_STAMP) $(LIBPNG_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building libpng-$(LIBPNG_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(LIBPNG_DIR)				\
		CC=$(CROSSPREFIX)gcc				\
		AR=$(CROSSPREFIX)ar				\
		RANLIB=$(CROSSPREFIX)ranlib			\
		CPP=$(CROSSPREFIX)cpp				\
		DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(LIBPNG_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

libpng-install: $(LIBPNG_INSTALL_STAMP)
$(LIBPNG_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LIBPNG_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing libpng in $(SYSROOTDIR) ===="
	$(Q) for file in $(LIBPNGLIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	done
	$(Q) touch $@

USER_CLEAN += libpng-clean
libpng-clean:
	$(Q) rm -rf $(LIBPNG_BUILD_DIR)
	$(Q) rm -f $(LIBPNG_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += libpng-download-clean
libpng-download-clean:
	$(Q) rm -f $(LIBPNG_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LIBPNG_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
