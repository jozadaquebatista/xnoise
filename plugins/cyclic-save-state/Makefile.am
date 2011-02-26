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

libCyclicSaveStatedir = $(libdir)/xnoise

libCyclicSaveState_LTLIBRARIES = libCyclicSaveState.la

libCyclicSaveState_la_SOURCES = \
    xnoise-cyclic-save-state.vala \
    xnoise-cyclic-save-state-registration.vala \
    $(NULL)

libCyclicSaveState_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/plugins/cyclic-save-state \
    --vapidir $(top_srcdir)/src \
    --pkg xnoise-1.0 \
    @XNOISE_PACKAGES@ \
    $(NULL)

libCyclicSaveState_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libCyclicSaveState_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(NULL)

CyclicSaveStateinformation_DATA = CyclicSaveState.xnplugin
CyclicSaveStateinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libCyclicSaveState_DATA) \
    $(libCyclicSaveState_la_SOURCES) \
    $(CyclicSaveStateinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libCyclicSaveState_la_vala.stamp \
    Makefile.in \
    $(NULL)


