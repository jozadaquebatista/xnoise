NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISEPLUGINSCORE_CFLAGS) \
	$(LIBNOTIFY_CFLAGS) \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/../xnoise/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(LIBNOTIFY_CFLAGS) \
	$(NULL)

libnotificationsdir = $(libdir)/xnoise

libnotifications_LTLIBRARIES = libnotifications.la

libnotifications_la_SOURCES = \
	xnoise-notifications.vala \
	xnoise-notifications-registration.vala \
	$(NULL)

libnotifications_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/../xnoise/vapi \
	--vapidir $(top_srcdir)/../xnoise/src/xnoise \
	--basedir $(top_srcdir)/src/notifications \
	--pkg xnoise-1.0 \
	--pkg libnotify \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libnotifications_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libnotifications_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
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

