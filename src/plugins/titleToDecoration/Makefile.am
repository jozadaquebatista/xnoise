NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(NULL)

libTitleToDecorationdir = $(libdir)/xnoise

libTitleToDecoration_LTLIBRARIES = libTitleToDecoration.la

libTitleToDecoration_la_SOURCES = \
	xnoise-title-to-decoration.vala \
	xnoise-title-to-decoration-registration.vala \
	$(NULL)

libTitleToDecoration_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/xnoise \
	--basedir $(top_srcdir)/src/plugins/titleToDecoration \
	--pkg xnoise-1.0 \
	@XNOISE_PACKAGES@ \
	$(NULL)

libTitleToDecoration_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libTitleToDecoration_la_LIBADD = \
	$(XNOISE_LIBS) \
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


