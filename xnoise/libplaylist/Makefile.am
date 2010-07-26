NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(LIBPLAYLIST_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-DDATA_DIR='"$(datadir)"' \
	-DLOCALE_DIR=\"${datarootdir}/locale\" \
	-include $(CONFIG_HEADER) \
	$(LIBXML_CFLAGS) \
	$(NULL)

playlist_hdir = $(includedir)/libplaylist-1.0
playlist_h_HEADERS = libplaylist.h

BUILT_SOURCES = \
	libplaylist-1.0.vapi \
	libplaylist.h \
	$(NULL)
	
libplaylistdir = $(libdir)

libplaylist_LTLIBRARIES = libplaylist.la

libplaylist_la_SOURCES = \
	pl-abstract-file-reader.vala \
	pl-abstract-file-writer.vala \
	pl-general.vala \
	pl-data.vala \
	pl-data-collection.vala \
	pl-reader.vala \
	pl-writer.vala \
	ASX/pl-asx-file-reader.vala \
	ASX/pl-asx-file-writer.vala \
	WPL/pl-wpl-file-reader.vala \
	WPL/pl-wpl-file-writer.vala \
	M3U/pl-m3u-file-reader.vala \
	M3U/pl-m3u-file-writer.vala \
	PLS/pl-pls-file-reader.vala \
	PLS/pl-pls-file-writer.vala \
	XSPF/pl-xspf-file-reader.vala \
	XSPF/pl-xspf-file-writer.vala \
	$(NULL)


libplaylist_la_VALAFLAGS = \
	--library libplaylist \
	--header=libplaylist.h --vapi=libplaylist-1.0.vapi \
	--thread \
	--pkg gio-2.0 \
	--pkg libxml-2.0 \
	--vapidir $(top_srcdir)/vapi \
	--basedir $(top_srcdir)/libplaylist \
	@LIBPLAYLIST_PACKAGES@ \
	$(NULL)

libplaylist_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-export-dynamic \
	$(NULL)

libplaylist_la_LIBADD = \
	$(LIBPLAYLIST_LIBS) \
	$(LIBXML_LIBS) \
	$(NULL)

VAPI_FILES = libplaylist-1.0.vapi
DEPS_FILES = libplaylist-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

MAINTAINERCLEANFILES = Makefile.in $(BUILT_SOURCES)

EXTRA_DIST = \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES) \
	$(libplaylist_DATA) \
	$(libplaylist_la_SOURCES) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libplaylist_la_vala.stamp \
	Makefile.in \
	$(NULL)

