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

libMediawatcherdir = $(libdir)/xnoise

libMediawatcher_LTLIBRARIES = libMediawatcher.la

libMediawatcher_la_SOURCES = \
	xnoise-mediawatcher.vala \
	xnoise-mediawatcher-registration.vala \
	$(NULL)

libMediawatcher_la_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/../xnoise/vapi \
	--vapidir $(top_srcdir)/../xnoise/src/xnoise \
	--basedir $(top_srcdir)/src/mediawatcher \
	--pkg xnoise-1.0 \
	--pkg gio-2.0 \
	@XNOISEPLUGINSCORE_PACKAGES@ \
	$(NULL)

libMediawatcher_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libMediawatcher_la_LIBADD = \
	$(XNOISEPLUGINSCORE_LIBS) \
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


