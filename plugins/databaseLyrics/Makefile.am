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

libDatabaseLyricsdir = $(libdir)/xnoise

libDatabaseLyrics_LTLIBRARIES = libDatabaseLyrics.la

libDatabaseLyrics_la_SOURCES = \
    xnoise-database-lyrics.vala \
    xnoise-database-lyrics-registration.vala \
    $(NULL)

libDatabaseLyrics_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/databaseLyrics \
    --vapidir $(top_srcdir)/libxnoise \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libDatabaseLyrics_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libDatabaseLyrics_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

#databaseLyricsinformation_DATA = DatabaseLyrics.xnplugin
#databaseLyricsinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = DatabaseLyrics.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libDatabaseLyrics_DATA) \
    $(libDatabaseLyrics_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.xnplugin \
    *.c \
    libDatabaseLyrics_la_vala.stamp \
    Makefile.in \
    $(NULL)


