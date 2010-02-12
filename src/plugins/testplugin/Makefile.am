NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	$(NULL)

AM_CPPFLAGS = \
	$(XNOISE_CFLAGS) \
	-DPACKAGE_DATADIR=\""$(pkgdatadir)"\" \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/src/xnoise -DDATA_DIR='"$(datadir)"' \
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
	--vapidir $(top_srcdir)/src/xnoise \
	--basedir $(top_srcdir)/src/plugins/testplugin \
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

