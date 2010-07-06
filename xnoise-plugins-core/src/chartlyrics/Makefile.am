NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(XNOISEPLUGINSCORE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-DDATA_DIR='"$(datadir)"' \
	-DLOCALE_DIR=\"${datarootdir}/locale\" \
	-include $(CONFIG_HEADER) \
	$(LIBXML_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(NULL)

libchartlyricsdir = $(libdir)/xnoise

libchartlyrics_LTLIBRARIES = libchartlyrics.la

libchartlyrics_la_SOURCES = \
	xnoise-chartlyrics.vala \
	xnoise-chartlyrics-registration.vala \
	$(NULL)

libchartlyrics_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--basedir $(top_srcdir)/src/chartlyrics \
	--pkg xnoise-1.0 \
	--pkg libxml-2.0 \
	--pkg libsoup-2.4 \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libchartlyrics_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libchartlyrics_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
	$(LIBXML_LIBS) \
	$(LIBSOUP_LIBS) \
	$(NULL)

chartlyricsinformation_DATA = chartlyrics.xnplugin
chartlyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libchartlyrics_DATA) \
	$(libchartlyrics_la_SOURCES) \
	$(chartlyricsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libchartlyrics_la_vala.stamp \
	Makefile.in \
	$(NULL)


