NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISE_CFLAGS) \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DDATADIR='"$(datadir)"' \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/src \
    $(X11_CFLAGS) \
    $(GDKX11_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libmediakeysdir = $(libdir)/xnoise

libmediakeys_LTLIBRARIES = libmediakeys.la

libmediakeys_la_SOURCES = \
    xnoise-mediakeys.vala \
    xnoise-mediakeys-registration.vala \
    $(NULL)

libmediakeys_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/mediakeys \
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libmediakeys_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libmediakeys_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(X11_LIBS) \
    $(GDKX11_LIBS) \
    $(NULL)

#mediakeysinformation_DATA = mediakeys.xnplugin
#mediakeysinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = mediakeys.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libmediakeys_DATA) \
    $(libmediakeys_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libmediakeys_la_vala.stamp \
    Makefile.in \
    $(NULL)

