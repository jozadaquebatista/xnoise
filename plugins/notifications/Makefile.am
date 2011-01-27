NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(XNOISE_CFLAGS) \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-DDATADIR='"$(datadir)"' \
	-DLOCALE_DIR=\"${datarootdir}/locale\" \
	-include $(CONFIG_HEADER) \
	$(LIBNOTIFY_CFLAGS) \
	-DGIO_DISABLE_DEPRECATED=1 \
	-DGDK_DISABLE_DEPRECATED=1 \
	-DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
	-DG_DISABLE_DEPRECATED=1 \
	-DPANGO_DISABLE_DEPRECATED=1 \
	-DGSEAL_ENABLE=1 \
	$(NULL)

libnotificationsdir = $(libdir)/xnoise

libnotifications_LTLIBRARIES = libnotifications.la

libnotifications_la_SOURCES = \
	xnoise-notifications.vala \
	xnoise-notifications-registration.vala \
	$(NULL)

libnotifications_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--basedir $(top_srcdir)/plugins/notifications \
	--pkg xnoise-1.0 \
	--pkg libnotify \
	@XNOISE_PACKAGES@ \
	$(NULL)

libnotifications_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libnotifications_la_LIBADD = \
	$(XNOISE_LIBS) \
	$(LIBNOTIFY_LIBS) \
	$(NULL)

notificationsinformation_DATA = notifications.xnplugin
notificationsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libnotifications_DATA) \
	$(libnotifications_la_SOURCES) \
	$(notificationsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libnotifications_la_vala.stamp \
	Makefile.in \
	$(NULL)

