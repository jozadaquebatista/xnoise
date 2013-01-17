NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISE_CFLAGS) \
    -DXN_PACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DXN_DATADIR='"$(datadir)"' \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(UBUNTUONEUI_CFLAGS) \
    $(NULL)
    
noinst_DATA = \
    u1ms.vapi

libUbuntuOnedir = $(libdir)/xnoise

libUbuntuOne_LTLIBRARIES = libUbuntuOne.la

libUbuntuOne_la_SOURCES = \
    ubuntuone.vala \
    ubuntuone-registration.vala \
    $(NULL)

libUbuntuOne_la_VALAFLAGS = \
    --thread \
    --vapidir ./ \
    --pkg u1ms \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/ubuntuone \
    --vapidir $(top_srcdir)/libxnoise \
    --vapidir $(top_srcdir)/bindings/vala \
    --pkg taginfo_c \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libUbuntuOne_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libUbuntuOne_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(UBUNTUONEUI_LIBS) \
    $(NULL)

plugindir = $(libdir)/xnoise
plugin_in_files = UbuntuOne.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(noinst_DATA) \
    $(plugin_in_files) \
    $(libUbuntuOne_DATA) \
    $(libUbuntuOne_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libUbuntuOne_la_vala.stamp \
    Makefile.in \
    $(NULL)


