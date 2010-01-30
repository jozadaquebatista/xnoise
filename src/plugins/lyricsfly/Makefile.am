NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISELYRICSLYRICSFLY_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	-I/usr/include/libsoup-2.4 \
	$(NULL)

BUILT_SOURCES = libLyricsfly.vala.stamp

libLyricsflydir = $(libdir)/xnoise

libLyricsfly_LTLIBRARIES = libLyricsfly.la

libLyricsfly_la_VALASOURCES = \
	xnoise-lyricsfly.vala \
	xnoise-lyricsfly-registration.vala \
	$(NULL)

libLyricsfly_la_SOURCES = \
	$(libLyricsfly_la_VALASOURCES:.vala=.c) \
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
	--basedir $(top_srcdir)/src/plugins/lyricsfly

libLyricsfly.vala.stamp: $(libLyricsfly_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libLyricsfly_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-lsoup-2.4 \
	-module -avoid-version

libLyricsfly_la_LIBADD = \
	$(XNOISELYRICSFLY_LIBS) \
	$(NULL)

Lyricsflyinformation_DATA = Lyricsfly.xnplugin
Lyricsflyinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLyricsfly_DATA) \
	$(libLyricsfly_la_VALASOURCES) \
	libLyricsfly.vala.stamp \
	$(Lyricsflyinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLyricsfly.vala.stamp \
	Makefile.in \
	$(NULL)

