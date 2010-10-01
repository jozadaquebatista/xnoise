NULL =

bin_PROGRAMS = xnoise

INCLUDES = \
	-include $(CONFIG_HEADER) \
	$(XNOISE_CFLAGS) \
	-DDATADIR=\"$(datadir)/xnoise/\" \
	-DUIDIR=\"$(datadir)/xnoise/ui/\" \
	-DPLUGINSDIR=\"$(libdir)/xnoise\" \
	-DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
	-DLOCALE_DIR=\"${datarootdir}/locale\" \
	$(NULL)

xnoisedir = $(includedir)/xnoise-1.0
xnoise_HEADERS = xnoise.h

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
	xnoise-control-button.vala \
	xnoise-db-browser.vala \
	xnoise-db-creator.vala \
	xnoise-db-writer.vala \
	xnoise-fullscreen-toolbar.vala \
	xnoise-global-access.vala \
	xnoise-gst-player.vala \
	xnoise-info-bar.vala \
	xnoise-lyrics-loader.vala \
	xnoise-lyrics-view.vala \
	xnoise-main.vala \
	xnoise-main-window.vala \
	xnoise-media-browser.vala \
	xnoise-media-browser-model.vala \
	xnoise-media-importer.vala \
	xnoise-misc.vala \
	xnoise-parameter.vala \
	xnoise-play-pause-button.vala \
	xnoise-plugin.vala \
	xnoise-plugin-loader.vala \
	xnoise-plugin-information.vala \
	xnoise-plugin-interface.vala \
	xnoise-plugin-manager-tree.vala \
	xnoise-screensaver-manager.vala \
	xnoise-settings-dialog.vala \
	xnoise-tag-reader.vala \
	xnoise-tag-writer.vala \
	xnoise-text-column.vala \
	xnoise-tracklist.vala \
	xnoise-tracklist-model.vala \
	xnoise-track-progressbar.vala \
	xnoise-tray-icon.vala \
	xnoise-user-info.vala \
	xnoise-videoscreen.vala \
	xnoise-volume-slider-button.vala \
	xnoise-worker.vala \
	$(NULL)

VALAFLAGS = \
	--basedir $(top_srcdir)/src \
	--pkg config \
	--thread \
	--vapidir $(srcdir)/../vapi \
	--vapi=$(srcdir)/xnoise-1.0.vapi \
	--header=$(srcdir)/xnoise.h \
	@XNOISE_PACKAGES@ \
	$(NULL)

xnoise_LDADD = \
	$(XNOISE_LIBS) \
	-lgstpbutils-0.10 \
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
	$(BUILT_SOURCES) \
	$(NULL)

DISTCLEANFILES = \
	*.c \
	xnoise_vala.stamp \
	Makefile.in \
	$(NULL)

