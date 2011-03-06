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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
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
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libDatabaseLyrics_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libDatabaseLyrics_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

databaseLyricsinformation_DATA = DatabaseLyrics.xnplugin
databaseLyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libDatabaseLyrics_DATA) \
    $(libDatabaseLyrics_la_SOURCES) \
    $(databaseLyricsinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libDatabaseLyrics_la_vala.stamp \
    Makefile.in \
    $(NULL)


