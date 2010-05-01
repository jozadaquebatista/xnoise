NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISEPLUGINSCORE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/../xnoise/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(LIBXML_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(NULL)

libLyricsflydir = $(libdir)/xnoise

libLyricsfly_LTLIBRARIES = libLyricsfly.la

libLyricsfly_la_SOURCES = \
	xnoise-lyricsfly.vala \
	xnoise-lyricsfly-registration.vala \
	$(NULL)

libLyricsfly_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/../xnoise/vapi \
	--vapidir $(top_srcdir)/../xnoise/src/xnoise \
	--basedir $(top_srcdir)/src/lyricsfly \
	--pkg xnoise-1.0 \
	--pkg libxml-2.0 \
	--pkg libsoup-2.4 \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libLyricsfly_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libLyricsfly_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
	$(LIBXML_LIBS) \
	$(LIBSOUP_LIBS) \
	$(NULL)

Lyricsflyinformation_DATA = Lyricsfly.xnplugin
Lyricsflyinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLyricsfly_DATA) \
	$(libLyricsfly_la_SOURCES) \
	$(Lyricsflyinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLyricsfly_la_vala.stamp \
	Makefile.in \
	$(NULL)

