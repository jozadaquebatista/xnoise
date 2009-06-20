NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	$(XNOISETEST_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
	$(NULL)

BUILT_SOURCES = libxnoisetest.vala.stamp

libxnoisetestdir = $(libdir)/xnoise

libxnoisetest_LTLIBRARIES = libxnoisetest.la

libxnoisetest_la_VALASOURCES = \
	xnoise-testplugin.vala \
	xnoise-testplugin-registration.vala \
	$(NULL)

libxnoisetest_la_SOURCES = \
	$(libxnoisetest_la_VALASOURCES:.vala=.c) \
	$(NULL)

VALA_CFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg gtk+-2.0 \
	--pkg posix \
	--pkg sqlite3 \
	--pkg gio-2.0 \
	--pkg gstreamer-0.10 \
	--pkg taglib_c \
	--pkg unique-1.0 \
	--pkg gmodule-2.0 \
	--vapidir $(top_srcdir)/src/xnoise \
	--pkg xnoise-1.0 \
	--basedir $(top_srcdir)/src/plugins/testplugin

libxnoisetest.vala.stamp: $(libxnoisetest_la_VALASOURCES)
	$(VALAC) -C  $(VALA_CFLAGS) $^
	touch $@

libxnoisetest_la_LDFLAGS = \
	$(PLUGIN_LIBTOOL_FLAGS) \
	-module -avoid-version

libxnoisetest_la_LIBADD = \
	$(XNOISETEST_LIBS) \
	$(NULL)

xnoisetestinformation_DATA = xnoisetest.xnplugin
xnoisetestinformationdir = $(libdir)/xnoise

EXTRA_DIST = \
	$(libxnoisetest_DATA) \
	$(libxnoisetest_la_VALASOURCES) \
	libxnoisetest.vala.stamp \
	$(xnoisetestinformation_DATA) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	libxnoisetest.vala.stamp \
	Makefile.in \
	$(NULL)


