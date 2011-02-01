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
    $(LIBXML_CFLAGS) \
    $(LIBSOUP_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    -I$(top_srcdir)/src \
    $(NULL)

libchartlyricsdir = $(libdir)/xnoise

libchartlyrics_LTLIBRARIES = libchartlyrics.la

libchartlyrics_la_SOURCES = \
    xnoise-chartlyrics.vala \
    xnoise-chartlyrics-registration.vala \
    $(NULL)

libchartlyrics_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/chartlyrics \
    --vapidir $(top_srcdir)/src \
    --pkg libxml-2.0 \
    --pkg libsoup-2.4 \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libchartlyrics_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libchartlyrics_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(LIBXML_LIBS) \
    $(LIBSOUP_LIBS) \
    $(NULL)

chartlyricsinformation_DATA = chartlyrics.xnplugin
chartlyricsinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libchartlyrics_DATA) \
    $(libchartlyrics_la_SOURCES) \
    $(chartlyricsinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libchartlyrics_la_vala.stamp \
    Makefile.in \
    $(NULL)

