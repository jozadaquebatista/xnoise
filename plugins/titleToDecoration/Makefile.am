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
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
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
    --basedir $(top_srcdir)/plugins/titleToDecoration \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libTitleToDecoration_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libTitleToDecoration_la_LIBADD = \
    $(XNOISE_LIBS) \
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


