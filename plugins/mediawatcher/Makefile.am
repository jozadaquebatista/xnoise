NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISE_CFLAGS) \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DDATADIR='"$(datadir)"' \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
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
    --basedir $(top_srcdir)/plugins/mediawatcher \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg gio-2.0 \
    --pkg xnoise-1.0 \
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


