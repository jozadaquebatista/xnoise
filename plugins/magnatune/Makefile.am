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

libMagnatunedir = $(libdir)/xnoise

libMagnatune_LTLIBRARIES = libMagnatune.la

libMagnatune_la_SOURCES = \
    magnatune.vala \
    magnatune-db-reader.vala \
    magnatune-registration.vala \
    $(NULL)

libMagnatune_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/magnatune \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libMagnatune_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libMagnatune_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

plugindir = $(libdir)/xnoise
plugin_in_files = Magnatune.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libMagnatune_DATA) \
    $(libMagnatune_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libMagnatune_la_vala.stamp \
    Makefile.in \
    $(NULL)


