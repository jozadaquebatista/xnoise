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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libsoundmenu2dir = $(libdir)/xnoise

libsoundmenu2_LTLIBRARIES = libsoundmenu2.la

libsoundmenu2_la_SOURCES = \
    xnoise-sound-menu-2.vala \
    xnoise-sound-menu-2-registration.vala \
    $(NULL)

libsoundmenu2_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/soundmenu2 \
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libsoundmenu2_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libsoundmenu2_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

#soundmenu2information_DATA = soundmenu2.xnplugin
#soundmenu2informationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = soundmenu2.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libsoundmenu2_DATA) \
    $(libsoundmenu2_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libsoundmenu2_la_vala.stamp \
    Makefile.in \
    $(NULL)

