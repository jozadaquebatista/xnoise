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

libMediawatcherdir = $(libdir)/xnoise

libMediawatcher_LTLIBRARIES = libMediawatcher.la

libMediawatcher_la_SOURCES = \
	xnoise-mediawatcher.vala \
	xnoise-mediawatcher-registration.vala \
	$(NULL)

libMediawatcher_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--vapidir $(top_srcdir)/src/xnoise \
	--basedir $(top_srcdir)/src/plugins/mediawatcher \
	--pkg xnoise-1.0 \
	--pkg gio-2.0 \
	@XNOISE_PACKAGES@ \
	$(NULL)

libMediawatcher_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libMediawatcher_la_LIBADD = \
	$(XNOISE_LIBS) \
	$(NULL)

mediawatcherinformation_DATA = Mediawatcher.xnplugin
mediawatcherinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libMediawatcher_DATA) \
	$(libMediawatcher_la_SOURCES) \
	$(mediawatcherinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libMediawatcher_la_vala.stamp \
	Makefile.in \
	$(NULL)


