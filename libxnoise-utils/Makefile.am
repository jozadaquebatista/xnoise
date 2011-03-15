NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

INCLUDES = \
	$(LIBXNOISEUTILS_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-DDATADIR='"$(datadir)"' \
	-DLOCALE_DIR=\"${datarootdir}/locale\" \
	-include $(CONFIG_HEADER) \
	$(LIBXML_CFLAGS) \
	$(NULL)

xnoiseutils_hdir = $(includedir)/libxnoiseutils-1.0
xnoiseutils_h_HEADERS = libxnoiseutils.h

BUILT_SOURCES = \
	libxnoiseutils-1.0.vapi \
	libxnoiseutils.h \
	$(NULL)
	
libxnoiseutilsdir = $(libdir)/xnoise

libxnoiseutils_LTLIBRARIES = libxnoiseutils.la

libxnoiseutils_la_SOURCES = \
	pl-abstract-file-reader.vala \
	pl-general.vala \
	pl-item.vala \
	pl-item-collection.vala \
	pl-reader.vala \
	simple-xml-reader.vala \
	simple-xml-node.vala \
	ASX/pl-asx-file-reader.vala \
	WPL/pl-wpl-file-reader.vala \
	M3U/pl-m3u-file-reader.vala \
	PLS/pl-pls-file-reader.vala \
	XSPF/pl-xspf-file-reader.vala \
	$(NULL)


libxnoiseutils_la_VALAFLAGS = \
	--library libxnoiseutils \
	--header=libxnoiseutils.h \
	--vapi=libxnoiseutils-1.0.vapi \
	--thread \
	--pkg gio-2.0 \
	--vapidir $(top_srcdir)/vapi \
	--basedir $(top_srcdir)/libxnoise-utils \
	@LIBXNOISEUTILS_PACKAGES@ \
	$(NULL)

libxnoiseutils_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-export-dynamic \
	$(NULL)

libxnoiseutils_la_LIBADD = \
	$(LIBXNOISEUTILS_LIBS) \
	$(LIBXML_LIBS) \
	$(NULL)

VAPI_FILES = libxnoiseutils-1.0.vapi
DEPS_FILES = libxnoiseutils-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

MAINTAINERCLEANFILES = Makefile.in $(BUILT_SOURCES)

EXTRA_DIST = \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(BUILT_SOURCES) \
	$(libxnoiseutils_DATA) \
	$(libxnoiseutils_la_SOURCES) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libxnoiseutils_la_vala.stamp \
	Makefile.in \
	$(NULL)

