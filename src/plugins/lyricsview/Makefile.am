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

BUILT_SOURCES = libLyricsview.vala.stamp

libLyricsviewdir = $(libdir)/xnoise

libLyricsview_LTLIBRARIES = libLyricsview.la

libLyricsview_la_VALASOURCES = \
	xnoise-lyricsview.vala \
	xnoise-lyricsview-registration.vala \
	$(NULL)

libLyricsview_la_SOURCES = \
	$(libLyricsview_la_VALASOURCES:.vala=.c) \
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
	--vapidir $(top_srcdir)/src/xnoise \
	--pkg xnoise-1.0 \
	--basedir $(top_srcdir)/src/plugins/lyricsview

libLyricsview.vala.stamp: $(libLyricsview_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libLyricsview_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-lsoup-2.4 \
	-module -avoid-version

libLyricsview_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

lyricsviewinformation_DATA = Lyricsview.xnplugin
lyricsviewinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLyricsview_DATA) \
	$(libLyricsview_la_VALASOURCES) \
	libLyricsview.vala.stamp \
	$(Lyricsviewinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLyricsview.vala.stamp \
	Makefile.in \
	$(NULL)


