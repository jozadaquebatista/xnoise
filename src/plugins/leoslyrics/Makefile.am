NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISELEOSLYRICS_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	-I/usr/include/libsoup-2.4 \
	$(NULL)

BUILT_SOURCES = libLeoslyrics.vala.stamp

libLeoslyricsdir = $(libdir)/xnoise

libLeoslyrics_LTLIBRARIES = libLeoslyrics.la

libLeoslyrics_la_VALASOURCES = \
	xnoise-leoslyrics.vala \
	xnoise-leoslyrics-registration.vala \
	$(NULL)

libLeoslyrics_la_SOURCES = \
	$(libLeoslyrics_la_VALASOURCES:.vala=.c) \
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
	--basedir $(top_srcdir)/src/plugins/leoslyrics

libLeoslyrics.vala.stamp: $(libLeoslyrics_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libLeoslyrics_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-lsoup-2.4 \
	-module -avoid-version

libLeoslyrics_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

leoslyricsinformation_DATA = Leoslyrics.xnplugin
leoslyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLeoslyrics_DATA) \
	$(libLeoslyrics_la_VALASOURCES) \
	libLeoslyrics.vala.stamp \
	$(Leoslyricsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLeoslyrics.vala.stamp \
	Makefile.in \
	$(NULL)


