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
    $(LIBDBUS_GLIB_CFLAGS) \
    $(NULL)

libmediakeysdir = $(libdir)/xnoise

libmediakeys_LTLIBRARIES = libmediakeys.la

libmediakeys_la_SOURCES = \
    xnoise-mediakeys.vala \
    xnoise-mediakeys-registration.vala \
    $(NULL)

libmediakeys_la_VALAFLAGS = \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/src/mediakeys \
    --pkg dbus-glib-1 \
    @XNOISEPLUGINSCORE_PACKAGES@ \
    $(NULL)

libmediakeys_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -module -avoid-version

libmediakeys_la_LIBADD = \
    $(XNOISEPLUGINSCORE_LIBS) \
    $(LIBDBUS_GLIB_LIBS) \
    $(NULL)

mediakeysinformation_DATA = mediakeys.xnplugin
mediakeysinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
    $(libmediakeys_DATA) \
    $(libmediakeys_la_SOURCES) \
    $(mediakeysinformation_DATA) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libmediakeys_la_vala.stamp \
    Makefile.in \
    $(NULL)

