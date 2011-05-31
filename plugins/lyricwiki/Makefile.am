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
    -I$(top_srcdir)/src \
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libLyricwikidir = $(libdir)/xnoise

libLyricwiki_LTLIBRARIES = libLyricwiki.la

libLyricwiki_la_SOURCES = \
    xnoise-lyricwiki.vala \
    xnoise-lyricwiki-registration.vala \
    $(NULL)

libLyricwiki_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/lyricwiki \
    --vapidir $(top_srcdir)/src \
    --pkg libsoup-2.4 \
    --pkg libxml-2.0 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libLyricwiki_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libLyricwiki_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

#lyricwikiinformation_DATA = Lyricwiki.xnplugin
#lyricwikiinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = Lyricwiki.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libLyricwiki_DATA) \
    $(libLyricwiki_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libLyricwiki_la_vala.stamp \
    Makefile.in \
    $(NULL)


