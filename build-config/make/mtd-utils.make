#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mtd-utils
#

MTDUTILS_VERSION	= 1.5.2
MTDUTILS_COMMIT		= e4c8885bddac201ba0ef88560d6444f39e1ff870
MTDUTILS_TARBALL	= mtd-utils-$(MTDUTILS_VERSION).tar.gz
MTDUTILS_TARBALL_URLS	+= $(ONIE_MIRROR) http://git.infradead.org/mtd-utils.git/snapshot
MTDUTILS_BUILD_DIR	= $(USER_BUILDDIR)/mtd-utils
MTDUTILS_DIR		= $(MTDUTILS_BUILD_DIR)/mtd-utils-e4c8885

MTDUTILS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/mtd-utils-$(MTDUTILS_VERSION)-download
MTDUTILS_SOURCE_STAMP	= $(USER_STAMPDIR)/mtd-utils-source
MTDUTILS_BUILD_STAMP	= $(USER_STAMPDIR)/mtd-utils-build
MTDUTILS_INSTALL_STAMP	= $(STAMPDIR)/mtd-utils-install
MTDUTILS_STAMP		= $(MTDUTILS_SOURCE_STAMP) \
			  $(MTDUTILS_BUILD_STAMP) \
			  $(MTDUTILS_INSTALL_STAMP)

MTDBINS = mkfs.jffs2 mkfs.ubifs ubinize ubiformat ubinfo mtdinfo 
UBIBINS = ubiattach ubimkvol ubidetach ubirmvol

PHONY += mtd-utils mtd-utils-download mtd-utils-source mtd-utils-build \
	 mtd-utils-install mtd-utils-clean mtd-utils-download-clean

mtd-utils: $(MTDUTILS_STAMP)

DOWNLOAD += $(MTDUTILS_DOWNLOAD_STAMP)
mtd-utils-download: $(MTDUTILS_DOWNLOAD_STAMP)
$(MTDUTILS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(MTDUTILS_COMMIT).tar.gz $(MTDUTILS_TARBALL_URLS)
	$(Q) cd $(DOWNLOADDIR) && ln -fs $(MTDUTILS_COMMIT).tar.gz $(MTDUTILS_TARBALL)
	$(Q) touch $@

SOURCE += $(MTDUTILS_SOURCE_STAMP)
mtd-utils-source: $(MTDUTILS_SOURCE_STAMP)
$(MTDUTILS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(MTDUTILS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/extract-package $(MTDUTILS_BUILD_DIR) $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
MTDUTILS_NEW_FILES = $(shell test -d $(MTDUTILS_DIR) && test -f $(MTDUTILS_BUILD_STAMP) && \
	              find -L $(MTDUTILS_DIR) -newer $(MTDUTILS_BUILD_STAMP) -type f -print -quit)
endif

mtd-utils-build: $(MTDUTILS_BUILD_STAMP)
$(MTDUTILS_BUILD_STAMP): $(MTDUTILS_NEW_FILES) $(UTILLINUX_BUILD_STAMP) \
			 $(LZO_BUILD_STAMP) $(ZLIB_BUILD_STAMP) \
			 $(MTDUTILS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR)				\
		PREFIX=$(DEV_SYSROOT)/usr			\
		CROSS=$(CROSSPREFIX)				\
		CFLAGS="-g $(ONIE_CFLAGS)"			\
                WITHOUT_XATTR=1
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR)				\
		PREFIX=$(DEV_SYSROOT)/usr			\
		CROSS=$(CROSSPREFIX)				\
		CFLAGS="-g $(ONIE_CFLAGS)"			\
                WITHOUT_XATTR=1                                 \
                install
	$(Q) touch $@

mtd-utils-install: $(MTDUTILS_INSTALL_STAMP)
$(MTDUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MTDUTILS_BUILD_STAMP) $(UTILLINUX_INSTALL_STAMP) \
				$(LZO_INSTALL_STAMP) $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mtdutils in $(SYSROOTDIR) ===="
	$(Q) for file in $(MTDBINS) ; do \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
	done
        #if UBI utils from busybox are not installed, use the mtdtools versions
	$(Q) for file in $(UBIBINS) ; do \
		if [ ! -f $(SYSROOTDIR)/usr/sbin/$$file ] ; \
		then \
			cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
		fi; \
	done
	$(Q) touch $@

USER_CLEAN += mtd-utils-clean
mtd-utils-clean:
	$(Q) rm -rf $(MTDUTILS_BUILD_DIR)
	$(Q) rm -f $(MTDUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += mtd-utils-download-clean
mtd-utils-download-clean:
	$(Q) rm -f $(MTDUTILS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(MTDUTILS_COMMIT).tar.gz \
		   $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
