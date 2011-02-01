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
    -I$(top_srcdir)/src \
    $(NULL)

libxnoisetestdir = $(libdir)/xnoise

libxnoisetest_LTLIBRARIES = libxnoisetest.la

libxnoisetest_la_SOURCES = \
    xnoise-testplugin.vala \
    xnoise-testplugin-registration.vala \
    $(NULL)

libxnoisetest_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/testplugin \
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libxnoisetest_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libxnoisetest_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

xnoisetestinformation_DATA = xnoisetest.xnplugin
xnoisetestinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libxnoisetest_DATA) \
    $(libxnoisetest_la_SOURCES) \
    $(xnoisetestinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libxnoisetest_la_vala.stamp \
    Makefile.in \
    $(NULL)

