NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISEPLUGINSCORE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/../xnoise/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(NULL)

libTitleToDecorationdir = $(libdir)/xnoise

libTitleToDecoration_LTLIBRARIES = libTitleToDecoration.la

libTitleToDecoration_la_SOURCES = \
	xnoise-title-to-decoration.vala \
	xnoise-title-to-decoration-registration.vala \
	$(NULL)

libTitleToDecoration_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/../xnoise/vapi \
	--vapidir $(top_srcdir)/../xnoise/src/xnoise \
	--basedir $(top_srcdir)/src/titleToDecoration \
	--pkg xnoise-1.0 \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libTitleToDecoration_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libTitleToDecoration_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
	$(NULL)

TitleToDecorationinformation_DATA = TitleToDecoration.xnplugin
TitleToDecorationinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libTitleToDecoration_DATA) \
	$(libTitleToDecoration_la_SOURCES) \
	$(TitleToDecorationinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libTitleToDecoration_la_vala.stamp \
	Makefile.in \
	$(NULL)


