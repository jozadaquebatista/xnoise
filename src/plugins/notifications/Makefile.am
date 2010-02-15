NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(LIBNOTIFY_CFLAGS) \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	-I/usr/include/libnotify \
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
	--vapidir $(top_srcdir)/src/xnoise \
	--basedir $(top_srcdir)/src/plugins/notifications \
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

