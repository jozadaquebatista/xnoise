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

libmprisdir = $(libdir)/xnoise

libmpris_LTLIBRARIES = libmpris.la

libmpris_la_SOURCES = \
    xnoise-mpris.vala \
    xnoise-mpris-registration.vala \
    $(NULL)

libmpris_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/mpris \
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libmpris_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libmpris_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

#mprisinformation_DATA = mpris.xnplugin
#mprisinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = mpris.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libmpris_DATA) \
    $(libmpris_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libmpris_la_vala.stamp \
    Makefile.in \
    $(NULL)

