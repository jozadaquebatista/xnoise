NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISEPLUGINSCORE_CFLAGS) \
    -DDATA_DIR='"$(datadir)"' \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libLyricsflydir = $(libdir)/xnoise

libLyricsfly_LTLIBRARIES = libLyricsfly.la

libLyricsfly_la_SOURCES = \
    xnoise-lyricsfly.vala \
    xnoise-lyricsfly-registration.vala \
    $(NULL)

libLyricsfly_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/lyricsfly \
    --pkg libxml-2.0 \
    --pkg libsoup-2.4 \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libLyricsfly_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libLyricsfly_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

Lyricsflyinformation_DATA = Lyricsfly.xnplugin
Lyricsflyinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libLyricsfly_DATA) \
    $(libLyricsfly_la_SOURCES) \
    $(Lyricsflyinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libLyricsfly_la_vala.stamp \
    Makefile.in \
    $(NULL)

