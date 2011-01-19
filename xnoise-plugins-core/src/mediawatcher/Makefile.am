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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
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
    --basedir $(top_srcdir)/src/mediawatcher \
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


