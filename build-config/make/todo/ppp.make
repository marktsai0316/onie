#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#  Copyright (C) 2018 Mark Tsai<marktsai0316@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of ppp
#
# refer to http://www.linuxfromscratch.org/blfs/view/6.3/basicnet/ppp.html
# 
#-------------------------------------------------------------------------------

PPP_VERSION		= 2.4.7
PPP_TARBALL		= ppp-$(PPP_VERSION).tar.gz
PPP_TARBALL_URLS	+= $(ONIE_MIRROR)  http://samba.org/ftp/ppp
#PPP_BUILD_DIR		= $(MBUILDDIR)/ppp
PPP_BUILD_DIR		= $(USER_BUILDDIR)/ppp
PPP_DIR			= $(PPP_BUILD_DIR)/ppp-$(PPP_VERSION)

#PPP_SRCPATCHDIR	= $(PATCHDIR)/ppp
PPP_PATCHDIR		= $(PPP_BUILD_DIR)/patch
PPP_DOWNLOAD_STAMP 	= $(DOWNLOADDIR)/ppp-download
PPP_SOURCE_STAMP	= $(USER_STAMPDIR)/ppp-source
PPP_PATCH_STAMP		= $(USER_STAMPDIR)/ppp-patch
PPP_CONFIGURE_STAMP	= $(USER_STAMPDIR)/ppp-configure
PPP_BUILD_STAMP		= $(USER_STAMPDIR)/ppp-build
PPP_INSTALL_STAMP	= $(STAMPDIR)/ppp-install
PPP_STAMP		= $(PPP_SOURCE_STAMP) \
			  $(PPP_PATCH_STAMP) \
			  $(PPP_CONFIGURE_STAMP) \
			  $(PPP_BUILD_STAMP) \
			  $(PPP_INSTALL_STAMP)

PHONY += ppp ppp-download ppp-source ppp-patch ppp-configure\
	 ppp-build ppp-install ppp-clean \
	 ppp-download-clean

#in /usr/lib/pppd/$(PPP_VERSION)
PPP_LIBS = minconn.so passprompt.so passwordfd.so winbind.so rp-pppoe.so pppoatm.so pppol2tp.so openl2tp.so radius.so radattr.so radrealms.so

PPP_SBINS = chat pppoe-discovery pppd pppstats pppdump

PPP_BINS = pon poff plog

PPP_SRCPATCHDIR = $(shell \
			   test -d $(PATCHDIR)/ppp && \
			   echo "$(PATCHDIR)/ppp")

ifneq ($(PPP_SRCPATCHDIR),)
  PPP_SRCPATCHDIR_FILES = $(PPP_SRCPATCHDIR)/*
endif

MACHINE_PPP_PATCHDIR = $(shell \
			   test -d $(MACHINEDIR)/ppp && \
			   echo "$(MACHINEDIR)/ppp")

ifneq ($(MACHINE_PPP_PATCHDIR),)
  MACHINE_PPP_PATCHDIR_FILES = $(MACHINE_PPP_PATCHDIR)/*
endif

ppp: $(PPP_STAMP)

DOWNLOAD += $(PPP_DOWNLOAD_STAMP)
ppp-download: $(PPP_DOWNLOAD_STAMP)
$(PPP_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream ppp ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(PPP_TARBALL) $(PPP_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(PPP_SOURCE_STAMP)
ppp-source: $(PPP_SOURCE_STAMP)
$(PPP_SOURCE_STAMP): $(TREE_STAMP) $(PPP_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream ppp ===="
	$(Q) $(SCRIPTDIR)/extract-package $(PPP_BUILD_DIR) $(DOWNLOADDIR)/$(PPP_TARBALL)
	$(Q) touch $@

ppp-patch: $(PPP_PATCH_STAMP)
$(PPP_PATCH_STAMP): $(PPP_SRCPATCHDIR_FILES) $(MACHINE_PPP_PATCHDIR_FILES) $(PPP_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching ppp-$(PPP_VERSION) ===="
	ls $(PPP_SRCPATCHDIR)
ifneq ($(PPP_SRCPATCHDIR),)
	echo "ghfggffg"
	$(Q) $(SCRIPTDIR)/apply-patch-series $(PPP_SRCPATCHDIR)/series $(PPP_DIR)
endif
	$(Q) touch $@


ifndef MAKE_CLEAN
PPP_NEW_FILES = $(shell test -d $(PPP_DIR) && test -f $(PPP_BUILD_STAMP) && \
	              find -L $(PPP_DIR) -newer $(PPP_BUILD_STAMP) -type f -print -quit)
endif

ppp-configure: $(PPP_CONFIGURE_STAMP)
$(PPP_CONFIGURE_STAMP): $(PPP_SOURCE_STAMP) $(PPP_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure ppp-$(PPP_VERSION) ===="
	$(Q) cd $(PPP_DIR) &&					\
	    $(PPP_DIR)/configure				\
		--prefix=/usr
	$(Q) touch $@

define TTT
#!/bin/sh
if [ "$USEPEERDNS" = "1" ] && [ -s /etc/ppp/resolv.conf ]
then
        install -m 644 /etc/ppp/resolv.conf /etc/resolv.conf
fi
endef 

export TTT

ppp-build: $(PPP_BUILD_STAMP)
$(PPP_BUILD_STAMP): $(PPP_NEW_FILES) $(PPP_PATCH_STAMP) $(PPP_CONFIGURE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building ppp-$(PPP_VERSION) ===="
	#CROSS_COMPILE=$(CROSSPREFIX)
	echo $(CROSSPREFIX)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	 $(MAKE) -C $(PPP_DIR) CC=$(CROSSPREFIX)gcc
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(PPP_DIR) INSTROOT=$(DEV_SYSROOT) install install-etcppp
	$(Q) install -d $(DEV_SYSROOT)/etc/ppp/peers && \
	install -m755 $(PPP_DIR)/scripts/{pon,poff,plog} $(DEV_SYSROOT)/usr/bin && \
	install -m644 $(PPP_DIR)/scripts/pon.1 $(DEV_SYSROOT)/usr/share/man/man1
	#touch $(DEV_SYSROOT)/etc/ppp/pap-secrets
	#chmod 600 $(DEV_SYSROOT)/etc/ppp/pap-secrets
	echo "$$TTT" > $(DEV_SYSROOT)/etc/ppp/ip-up
	#chmod 755 $(DEV_SYSROOT)/etc/ppp/ip-up
	$(Q) touch $@

ppp-install: $(PPP_INSTALL_STAMP)
$(PPP_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(PPP_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing ppp in $(SYSROOTDIR) ===="
	#ls -la $(DEV_SYSROOT)/usr/lib/pppd/$(PPP_VERSION)
	$(Q)install -d $(SYSROOTDIR)/usr/lib/pppd/$(PPP_VERSION)/ && \
	for file in $(PPP_LIBS) ; do \
		rm -f $(SYSROOTDIR)/usr/lib/pppd/$(PPP_VERSION)/$$file ; \
		cp -av $(DEV_SYSROOT)/usr/lib/pppd/$(PPP_VERSION)/$$file $(SYSROOTDIR)/usr/lib/pppd/$(PPP_VERSION)/ ; \
		chmod 755 $(SYSROOTDIR)/usr/lib/pppd/$(PPP_VERSION)/$$file ; \
	done
	$(Q) install -d $(SYSROOTDIR)/usr/sbin && \
	for file in $(PPP_SBINS) ; do \
		rm -f $(SYSROOTDIR)/usr/sbin/$$file && \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin ; \
		chmod 755 $(SYSROOTDIR)/usr/sbin/$$file ; \
	done
	$(Q) install -d $(SYSROOTDIR)/usr/bin && \
	for file in $(PPP_BINS) ; do \
		rm -f $(SYSROOTDIR)/usr/bin/$$file && \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin ; \
		chmod 755 $(SYSROOTDIR)/usr/bin/$$file ; \
	done
	$(Q) touch $@


USER_CLEAN += ppp-clean
ppp-clean:
	$(Q) rm -rf $(PPP_BUILD_DIR)
	$(Q) rm -f $(PPP_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += ppp-download-clean
ppp-download-clean:
	$(Q) rm -f $(PPP_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(PPP_TARBALL)


#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
