NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISECHARTLYRICS_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	-I/usr/include/libsoup-2.4 \
	$(NULL)

BUILT_SOURCES = libchartlyrics.vala.stamp

libchartlyricsdir = $(libdir)/xnoise

libchartlyrics_LTLIBRARIES = libchartlyrics.la

libchartlyrics_la_VALASOURCES = \
	xnoise-chartlyrics.vala \
	xnoise-chartlyrics-registration.vala \
	$(NULL)

libchartlyrics_la_SOURCES = \
	$(libchartlyrics_la_VALASOURCES:.vala=.c) \
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
	--basedir $(top_srcdir)/src/plugins/chartlyrics

libchartlyrics.vala.stamp: $(libchartlyrics_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libchartlyrics_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-lsoup-2.4 \
	-module -avoid-version

libchartlyrics_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

chartlyricsinformation_DATA = chartlyrics.xnplugin
chartlyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libchartlyrics_DATA) \
	$(libchartlyrics_la_VALASOURCES) \
	libchartlyrics.vala.stamp \
	$(chartlyricsinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libchartlyrics.vala.stamp \
	Makefile.in \
	$(NULL)


