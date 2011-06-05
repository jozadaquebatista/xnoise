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
    $(LIBINDICATE_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libsoundmenudir = $(libdir)/xnoise

libsoundmenu_LTLIBRARIES = libsoundmenu.la

libsoundmenu_la_SOURCES = \
    xnoise-sound-menu.vala \
    xnoise-sound-menu-registration.vala \
    $(NULL)

libsoundmenu_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/soundmenu \
    --vapidir $(top_srcdir)/src \
    --pkg indicate \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libsoundmenu_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libsoundmenu_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBINDICATE_LIBS) \
    $(NULL)

#soundmenuinformation_DATA = soundmenu.xnplugin
#soundmenuinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = soundmenu.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libsoundmenu_DATA) \
    $(libsoundmenu_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libsoundmenu_la_vala.stamp \
    Makefile.in \
    $(NULL)

