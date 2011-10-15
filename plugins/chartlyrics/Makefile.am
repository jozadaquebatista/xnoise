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

libchartlyricsdir = $(libdir)/xnoise

libchartlyrics_LTLIBRARIES = libchartlyrics.la

libchartlyrics_la_SOURCES = \
    xnoise-chartlyrics.vala \
    xnoise-chartlyrics-registration.vala \
    $(NULL)

libchartlyrics_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/chartlyrics \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg libxml-2.0 \
    --pkg libsoup-2.4 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libchartlyrics_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libchartlyrics_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

#chartlyricsinformation_DATA = chartlyrics.xnplugin
#chartlyricsinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = chartlyrics.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libchartlyrics_DATA) \
    $(libchartlyrics_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    *.xnplugin \
    libchartlyrics_la_vala.stamp \
    Makefile.in \
    $(NULL)


