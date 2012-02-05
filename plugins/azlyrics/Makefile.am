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
    -I$(top_srcdir)/libxnoise \
    $(NULL)

libazlyricsdir = $(libdir)/xnoise

libazlyrics_LTLIBRARIES = libazlyrics.la

libazlyrics_la_SOURCES = \
    xnoise-azlyrics.vala \
    xnoise-azlyrics-registration.vala \
    $(NULL)

libazlyrics_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/azlyrics \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg libxml-2.0 \
    --pkg libsoup-2.4 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libazlyrics_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libazlyrics_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

plugindir = $(libdir)/xnoise
plugin_in_files = azlyrics.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libazlyrics_DATA) \
    $(libazlyrics_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    *.xnplugin \
    libazlyrics_la_vala.stamp \
    Makefile.in \
    $(NULL)


