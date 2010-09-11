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
    $(NULL)

libTitleToDecorationdir = $(libdir)/xnoise

libTitleToDecoration_LTLIBRARIES = libTitleToDecoration.la

libTitleToDecoration_la_SOURCES = \
    xnoise-title-to-decoration.vala \
    xnoise-title-to-decoration-registration.vala \
    $(NULL)

libTitleToDecoration_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/titleToDecoration \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libTitleToDecoration_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libTitleToDecoration_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(NULL)

TitleToDecorationinformation_DATA = TitleToDecoration.xnplugin
TitleToDecorationinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libTitleToDecoration_DATA) \
    $(libTitleToDecoration_la_SOURCES) \
    $(TitleToDecorationinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libTitleToDecoration_la_vala.stamp \
    Makefile.in \
    $(NULL)


