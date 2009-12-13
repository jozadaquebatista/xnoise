NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISELASTFMCOVERS_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	-I/usr/include/libsoup-2.4 \
	$(NULL)

BUILT_SOURCES = libLastfmCovers.vala.stamp

libLastfmCoversdir = $(libdir)/xnoise

libLastfmCovers_LTLIBRARIES = libLastfmCovers.la

libLastfmCovers_la_VALASOURCES = \
	xnoise-lastfm-covers.vala \
	xnoise-lastfm-covers-registration.vala \
	$(NULL)

libLastfmCovers_la_SOURCES = \
	$(libLastfmCovers_la_VALASOURCES:.vala=.c) \
	$(NULL)

VALA_CFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg gtk+-2.0 \
	--pkg posix \
	--pkg sqlite3 \
	--pkg gio-2.0 \
	--pkg gstreamer-0.10 \
	--pkg taglib_c \
	--pkg unique-1.0 \
	--pkg gmodule-2.0 \
	--pkg libxml-2.0 \
	--pkg libsoup-2.4 \
	--vapidir $(top_srcdir)/src/xnoise \
	--pkg xnoise-1.0 \
	--basedir $(top_srcdir)/src/plugins/lastfmCovers

libLastfmCovers.vala.stamp: $(libLastfmCovers_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libLastfmCovers_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-lsoup-2.4 \
	-module -avoid-version

libLastfmCovers_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

lastfmcovers_DATA = lastfmCovers.xnplugin
lastfmcoversdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLastfmCovers_DATA) \
	$(libLastfmCovers_la_VALASOURCES) \
	libLastfmCovers.vala.stamp \
	$(lastfmcovers_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLastfmCovers.vala.stamp \
	Makefile.in \
	$(NULL)


