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
    $(APPI_CFLAGS) \
    -I$(top_srcdir)/libxnoise \
    $(NULL)

libxnoiseappindicatordir = $(libdir)/xnoise

libxnoiseappindicator_LTLIBRARIES = libxnoiseappindicator.la

libxnoiseappindicator_la_SOURCES = \
    xnoise-app-indicator.vala \
    xnoise-app-indicator-registration.vala \
    $(NULL)

libxnoiseappindicator_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/app_indicator \
    --vapidir $(top_srcdir)/libxnoise \
    --vapidir $(top_srcdir)/bindings/vala \
    --pkg libtaginfo_c \
    --pkg appindicator3-0.1 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libxnoiseappindicator_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libxnoiseappindicator_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(APPI_LIBS) \
    $(NULL)

plugindir = $(libdir)/xnoise
plugin_in_files = xnoise-app-indicator.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libxnoiseappindicator_DATA) \
    $(libxnoiseappindicator_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libxnoiseappindicator_la_vala.stamp \
    Makefile.in \
    $(NULL)

