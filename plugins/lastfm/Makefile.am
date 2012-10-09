NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = icons \
    $(NULL)

INCLUDES = \
    $(XNOISE_CFLAGS) \
    -DXN_UIDIR=\"$(datadir)/xnoise/ui/\" \
    -DXN_PACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DXN_DATADIR='"$(datadir)"' \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    -I$(top_srcdir)/libxnoise \
    $(LIBSOUP_CFLAGS) \
    $(NULL)

liblastfmdir = $(libdir)/xnoise

liblastfm_LTLIBRARIES = liblastfm.la

liblastfm_la_SOURCES = \
    vlfm-session.vala \
    vlfm-artist.vala \
    vlfm-album.vala \
    vlfm-track.vala \
    vlfm-web-access.vala \
    vlfm-util.vala \
    xnoise-lastfm.vala \
    xnoise-lastfm-registration.vala \
    $(NULL)

liblastfm_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/lastfm \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg libsoup-2.4 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

liblastfm_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

liblastfm_la_LIBADD = \
    $(LIBSOUP_LIBS) \
    $(XNOISE_LIBS) \
    $(NULL)

plugindir = $(libdir)/xnoise
plugin_in_files = lastfm.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(liblastfm_DATA) \
    $(liblastfm_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    liblastfm_la_vala.stamp \
    Makefile.in \
    $(NULL)

