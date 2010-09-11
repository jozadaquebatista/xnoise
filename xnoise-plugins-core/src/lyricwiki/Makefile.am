NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISEPLUGINSCORE_CFLAGS) \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DDATA_DIR='"$(datadir)"' \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
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
    --basedir $(top_srcdir)/src/lyricwiki \
    --pkg libsoup-2.4 \
    --pkg libxml-2.0 \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libLyricwiki_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libLyricwiki_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

lyricwikiinformation_DATA = Lyricwiki.xnplugin
lyricwikiinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libLyricwiki_DATA) \
    $(libLyricwiki_la_SOURCES) \
    $(lyricwikiinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libLyricwiki_la_vala.stamp \
    Makefile.in \
    $(NULL)


