NULL =

AM_CPPFLAGS = \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)/xnoise/\" \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPLUGINSDIR=\"$(libdir)/xnoise\" \
	-DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
	$(XNOISE_CFLAGS) \
	$(NULL)

bin_PROGRAMS = xnoise

BUILT_SOURCES = \
	xnoise-1.0.vapi \
	xnoise.h \
	$(NULL)

xnoise_SOURCES = \
	xnoise-about.vala \
	xnoise-add-media-dialog.vala \
	xnoise-album-image.vala \
	xnoise-album-image-loader.vala \
	xnoise-app-starter.vala \
	xnoise-db-browser.vala \
	xnoise-db-creator.vala \
	xnoise-db-writer.vala \
	xnoise-global-information.vala \
	xnoise-gst-player.vala \
	xnoise-lyrics-loader.vala \
	xnoise-lyrics-view.vala \
	xnoise-main.vala \
	xnoise-main-window.vala \
	xnoise-media-browser.vala \
	xnoise-media-browser-model.vala \
	xnoise-misc.vala \
	xnoise-parameter.vala \
	xnoise-plugin.vala \
	xnoise-plugin-loader.vala \
	xnoise-plugin-information.vala \
	xnoise-plugin-interface.vala \
	xnoise-plugin-manager-tree.vala \
	xnoise-settings-dialog.vala \
	xnoise-tag-reader.vala \
	xnoise-tracklist.vala \
	xnoise-tracklist-model.vala \
	xnoise-videoscreen.vala \
	$(NULL)

xnoise_VALAFLAGS = \
	--vapidir $(srcdir)/../../vapi \
	--vapi=$(srcdir)/xnoise-1.0.vapi \
	--pkg config \
	--basedir $(top_srcdir)/src \
	--thread \
	--header $(srcdir)/xnoise.h \
	@XNOISE_PACKAGES@ \
	$(NULL)

xnoise_LDADD = \
	$(XNOISE_LIBS) \
	$(NULL)

xnoise_LDFLAGS = -export-dynamic

VAPI_FILES = xnoise-1.0.vapi
DEPS_FILES = xnoise-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

MAINTAINERCLEANFILES = Makefile.in $(BUILT_SOURCES)

EXTRA_DIST = \
	$(VAPI_FILES) \
	$(DEPS_FILES) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	xnoise_vala.stamp \
	Makefile.in \
	$(NULL)

