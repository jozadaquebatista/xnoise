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
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libLastfmCoversdir = $(libdir)/xnoise

libLastfmCovers_LTLIBRARIES = libLastfmCovers.la

libLastfmCovers_la_SOURCES = \
    xnoise-lastfm-covers.vala \
    xnoise-lastfm-covers-registration.vala \
    $(NULL)

libLastfmCovers_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/lastfmCovers \
    --pkg libxml-2.0 \
    --pkg libsoup-2.4 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libLastfmCovers_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libLastfmCovers_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

lastfmcovers_DATA = lastfmCovers.xnplugin
lastfmcoversdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libLastfmCovers_DATA) \
    $(libLastfmCovers_la_SOURCES) \
    $(lastfmcovers_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libLastfmCovers_la_vala.stamp \
    Makefile.in \
    $(NULL)


