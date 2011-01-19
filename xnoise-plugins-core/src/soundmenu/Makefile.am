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

libsoundmenudir = $(libdir)/xnoise

libsoundmenu_LTLIBRARIES = libsoundmenu.la

libsoundmenu_la_SOURCES = \
    xnoise-sound-menu.vala \
    xnoise-sound-menu-registration.vala \
    $(NULL)

libsoundmenu_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/soundmenu \
    --pkg indicate \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libsoundmenu_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libsoundmenu_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(LIBINDICATE_LIBS) \
    $(NULL)

soundmenuinformation_DATA = soundmenu.xnplugin
soundmenuinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libsoundmenu_DATA) \
    $(libsoundmenu_la_SOURCES) \
    $(soundmenuinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libsoundmenu_la_vala.stamp \
    Makefile.in \
    $(NULL)

