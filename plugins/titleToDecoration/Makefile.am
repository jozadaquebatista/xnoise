NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

AM_CPPFLAGS = \
    $(XNOISE_CFLAGS) \
    -DXN_PACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DXN_DATADIR='"$(datadir)"' \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(NULL)

libTitleToDecorationdir = $(libdir)/xnoise

libTitleToDecoration_LTLIBRARIES = libTitleToDecoration.la

libTitleToDecoration_la_SOURCES = \
    xnoise-title-to-decoration.vala \
    xnoise-title-to-decoration-registration.vala \
    $(NULL)

libTitleToDecoration_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/titleToDecoration \
    --vapidir $(top_srcdir)/libxnoise \
    --vapidir $(top_srcdir)/bindings/vala \
    --pkg libtaginfo_c \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libTitleToDecoration_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libTitleToDecoration_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

#TitleToDecorationinformation_DATA = TitleToDecoration.xnplugin
#TitleToDecorationinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = TitleToDecoration.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libTitleToDecoration_DATA) \
    $(libTitleToDecoration_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libTitleToDecoration_la_vala.stamp \
    Makefile.in \
    $(NULL)


