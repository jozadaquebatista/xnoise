NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISETITLETODECORATION_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(NULL)

BUILT_SOURCES = libTitleToDecoration.vala.stamp

libTitleToDecorationdir = $(libdir)/xnoise

libTitleToDecoration_LTLIBRARIES = libTitleToDecoration.la

libTitleToDecoration_la_VALASOURCES = \
	xnoise-title-to-decoration.vala \
	xnoise-title-to-decoration-registration.vala \
	$(NULL)

libTitleToDecoration_la_SOURCES = \
	$(libTitleToDecoration_la_VALASOURCES:.vala=.c) \
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
	--basedir $(top_srcdir)/src/plugins/titleToDecoration

libTitleToDecoration.vala.stamp: $(libTitleToDecoration_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libTitleToDecoration_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libTitleToDecoration_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

TitleToDecorationinformation_DATA = TitleToDecoration.xnplugin
TitleToDecorationinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libTitleToDecoration_DATA) \
	$(libTitleToDecoration_la_VALASOURCES) \
	libTitleToDecoration.vala.stamp \
	$(TitleToDecorationinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libTitleToDecoration.vala.stamp \
	Makefile.in \
	$(NULL)


