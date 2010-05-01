NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(XNOISEPLUGINSCORE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/../xnoise/src/xnoise -DDATA_DIR='"$(datadir)"' \
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
	--vapidir $(top_srcdir)/../xnoise/vapi \
	--basedir $(top_srcdir)/src/leoslyrics \
	--pkg xnoise-1.0 \
	--pkg libsoup-2.4 \
	--pkg libxml-2.0 \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libLeoslyrics_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libLeoslyrics_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
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


