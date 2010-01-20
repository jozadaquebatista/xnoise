NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISENOTIFICATIONS_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(NULL)

BUILT_SOURCES = libnotifications.vala.stamp

libnotificationsdir = $(libdir)/xnoise

libnotifications_LTLIBRARIES = libnotifications.la

libnotifications_la_VALASOURCES = \
	xnoise-notifications.vala \
	xnoise-notifications-registration.vala \
	$(NULL)

libnotifications_la_SOURCES = \
	$(libnotifications_la_VALASOURCES:.vala=.c) \
	$(NULL)

VALA_CFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg libnotify \
	--pkg gtk+-2.0 \
	--pkg posix \
	--pkg sqlite3 \
	--pkg gio-2.0 \
	--pkg gstreamer-0.10 \
	--pkg taglib_c \
	--pkg unique-1.0 \
	--pkg gmodule-2.0 \
	--vapidir $(top_srcdir)/src/xnoise \
	--pkg xnoise-1.0 \
	--basedir $(top_srcdir)/src/plugins/notifications

libnotifications.vala.stamp: $(libnotifications_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libnotifications_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libnotifications_la_LIBADD = \
	$(XNOISENOTIFICATIONS_LIBS) \
	$(NULL)

notificationsinformation_DATA = notifications.xnplugin
notificationsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libnotifications_DATA) \
	$(libnotifications_la_VALASOURCES) \
	libnotifications.vala.stamp \
	$(notificationsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libnotifications.vala.stamp \
	Makefile.in \
	$(NULL)


