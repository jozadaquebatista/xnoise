NULL = 

AM_CPPFLAGS = \
	-DDATADIR=\"$(datadir)/xnoise/\" \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
	$(XNOISE_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

VALA_CFLAGS = \
	--vapidir $(srcdir)/../../vapi \
	--thread \
	--pkg config \
	--pkg gtk+-2.0 \
	--pkg posix \
	--pkg sqlite3 \
	--pkg gio-2.0 \
	--pkg gstreamer-0.10 \
	--pkg taglib_c \
	--pkg unique-1.0
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
	xnoise-music-browser.vala \
	xnoise-music-dir-dialog.vala \
	xnoise-tag-reader.vala \
	xnoise-tracklist.vala \
	xnoise-misc.vala \
	xnoise-settings-dialog.vala \
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
	$(NULL)

EXTRA_DIST = \
	$(xnoise_VALASOURCES) \
	xnoise.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	*.h \
	xnoise.vala.stamp \
	Makefile.in \
	$(NULL)

