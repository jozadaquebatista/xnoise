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
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
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
    --vapidir $(top_srcdir)/libxnoise \
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

plugindir = $(libdir)/xnoise
plugin_in_files = lastfmCovers.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libLastfmCovers_DATA) \
    $(libLastfmCovers_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libLastfmCovers_la_vala.stamp \
    Makefile.in \
    $(NULL)


