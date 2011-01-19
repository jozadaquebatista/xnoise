NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    $(XNOISEPLUGINSCORE_CFLAGS) \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
    -DDATA_DIR='"$(datadir)"' \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -include $(CONFIG_HEADER) \
    $(LIBINDICATE_CFLAGS) \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

libmprisdir = $(libdir)/xnoise

libmpris_LTLIBRARIES = libmpris.la

libmpris_la_SOURCES = \
    xnoise-mpris.vala \
    xnoise-mpris-registration.vala \
    $(NULL)

libmpris_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/mpris \
    --pkg indicate \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libmpris_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libmpris_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(LIBINDICATE_LIBS) \
    $(NULL)

mprisinformation_DATA = mpris.xnplugin
mprisinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libmpris_DATA) \
    $(libmpris_la_SOURCES) \
    $(mprisinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libmpris_la_vala.stamp \
    Makefile.in \
    $(NULL)

