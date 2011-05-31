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

#CyclicSaveStateinformation_DATA = CyclicSaveState.xnplugin
#CyclicSaveStateinformationdir = $(libdir)/xnoise
plugindir = $(libdir)/xnoise
plugin_in_files = CyclicSaveState.xnplugin.desktop.in

%.xnplugin: %.xnplugin.desktop.in $(INTLTOOL_MERGE) $(wildcard $(top_srcdir)/po/*po) ; $(INTLTOOL_MERGE) $(top_srcdir)/po $< $@ -d -u -c $(top_builddir)/po/.intltool-merge-cache

plugin_DATA = $(plugin_in_files:.xnplugin.desktop.in=.xnplugin)

EXTRA_DIST = \
    $(plugin_in_files) \
    $(libCyclicSaveState_DATA) \
    $(libCyclicSaveState_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libCyclicSaveState_la_vala.stamp \
    Makefile.in \
    $(NULL)


