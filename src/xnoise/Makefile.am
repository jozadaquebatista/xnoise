NULL = 

AM_CPPFLAGS = \
	-DDATADIR=\"$(datadir)/xnoise/\" \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPLUGINSDIR=\"$(libdir)/xnoise\" \
	-DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
	-include $(CONFIG_HEADER) \
	-I/usr/include/libsoup-2.4 \
	$(XNOISE_CFLAGS) \
	$(NULL)

VALA_CFLAGS = \
	--vapidir $(srcdir)/../../vapi \
	--thread \
	--vapi=$(srcdir)/xnoise-1.0.vapi \
	--pkg config \
	--pkg gtk+-2.0 \
	--pkg gdk-2.0 \
	--pkg gdk-x11-2.0 \
	--pkg gdk-pixbuf-2.0 \
	--pkg posix \
	--pkg sqlite3 \
	--pkg gio-2.0 \
	--pkg gstreamer-0.10 \
	--pkg gstreamer-interfaces-0.10 \
	--pkg taglib_c \
	--pkg unique-1.0 \
	--pkg gmodule-2.0 \
	--pkg libxml-2.0 \
	--pkg libsoup-2.4 \
	--thread \
	-H $(srcdir)/xnoise.h \
	--basedir $(top_srcdir)/src

BUILT_SOURCES = xnoise.vala.stamp

bin_PROGRAMS = xnoise

xnoise_VALASOURCES = \
	xnoise-app-starter.vala \
	xnoise-main.vala \
	xnoise-gst-player.vala \
	xnoise-main-window.vala \
	xnoise-about.vala \
	xnoise-parameter.vala \
	xnoise-db-browser.vala \
	xnoise-db-writer.vala \
	xnoise-media-browser.vala \
	xnoise-add-media-dialog.vala \
	xnoise-tag-reader.vala \
	xnoise-tracklist.vala \
	xnoise-misc.vala \
	xnoise-videoscreen.vala \
	xnoise-settings-dialog.vala \
	xnoise-plugin.vala \
	xnoise-plugin-loader.vala \
	xnoise-plugin-information.vala \
	xnoise-plugin-interface.vala \
	xnoise-plugin-manager-tree.vala \
	xnoise-album-image.vala \
	xnoise-lyrics-loader.vala \
	xnoise-leoslyrics.vala
	$(NULL)

xnoise_SOURCES = \
	$(xnoise_VALASOURCES:.vala=.c) \
	$(xnoise_VALASOURCES:.vala=.h) \
	$(NULL)

xnoise.vala.stamp: $(xnoise_VALASOURCES)
	$(VALAC) -C \
	$(VALA_CFLAGS) $^
	touch $@

xnoise_LDADD = \
	$(XNOISE_LIBS) \
	-lsoup-2.4 \
	$(NULL)
	
VAPI_FILES = xnoise-1.0.vapi
DEPS_FILES = xnoise-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(NULL)

libxnoiseincdir = $(includedir)/xnoise-1.0

libxnoiseinc_HEADERS = xnoise.h
	
EXTRA_DIST = \
	$(xnoise_VALASOURCES) \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	xnoise.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	xnoise.vala.stamp \
	Makefile.in \
	$(NULL)

