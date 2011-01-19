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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libLeoslyricsdir = $(libdir)/xnoise

libLeoslyrics_LTLIBRARIES = libLeoslyrics.la

libLeoslyrics_la_SOURCES = \
    xnoise-leoslyrics.vala \
    xnoise-leoslyrics-registration.vala \
    $(NULL)

libLeoslyrics_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/leoslyrics \
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


