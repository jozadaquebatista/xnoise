NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(LIBXML_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(NULL)

libLeoslyricsdir = $(libdir)/xnoise

libLeoslyrics_LTLIBRARIES = libLeoslyrics.la

libLeoslyrics_la_SOURCES = \
	xnoise-leoslyrics.vala \
	xnoise-leoslyrics-registration.vala \
	$(NULL)

libLeoslyrics_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/xnoise \
	--basedir $(top_srcdir)/src/plugins/leoslyrics \
	--pkg xnoise-1.0 \
	--pkg libsoup-2.4 \
	--pkg libxml-2.0 \
	@XNOISE_PACKAGES@ \
	$(NULL)

libLeoslyrics_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libLeoslyrics_la_LIBADD = \
	$(XNOISE_LIBS) \
	$(LIBXML_LIBS) \
	$(LIBSOUP_LIBS) \
	$(NULL)

leoslyricsinformation_DATA = Leoslyrics.xnplugin
leoslyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libLeoslyrics_DATA) \
	$(libLeoslyrics_la_SOURCES) \
	$(leoslyricsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libLeoslyrics_la_vala.stamp \
	Makefile.in \
	$(NULL)


