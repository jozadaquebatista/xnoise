NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

bin_PROGRAMS = xnoise

INCLUDES = \
    -include $(CONFIG_HEADER) \
    $(XNOISE_CFLAGS) \
    -DDATADIR=\"$(datadir)/xnoise/\" \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPLUGINSDIR=\"$(libdir)/xnoise\" \
    -DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    -DGIO_DISABLE_DEPRECATED=1 \
    -DGDK_DISABLE_DEPRECATED=1 \
    -DGDK_PIXBUF_DISABLE_DEPRECATED=1 \
    -DG_DISABLE_DEPRECATED=1 \
    -DPANGO_DISABLE_DEPRECATED=1 \
    -DGSEAL_ENABLE=1 \
    $(NULL)

xnoisedir = $(includedir)/xnoise-1.0
xnoise_HEADERS = xnoise.h

BUILT_SOURCES = \
    xnoise-1.0.vapi \
    xnoise.h \
    $(NULL)

xnoise_SOURCES = \
    xnoise.vala \
    xnoise-main.vala \
    AlbumImages/xnoise-album-image-loader.vala \
    AlbumImages/xnoise-i-album-cover-image.vala \
    AlbumImages/xnoise-i-album-cover-image-provider.vala \
    ItemHandlers/AddToTracklist/xnoise-handler-add-to-tracklist.vala \
    ItemHandlers/EditTags/xnoise-handler-edit-tags.vala \
    ItemHandlers/EditTags/xnoise-tag-artistalbum-editor.vala \
    ItemHandlers/EditTags/xnoise-tag-title-editor.vala \
    ItemHandlers/PlayItem/xnoise-handler-play-item.vala \
    ItemHandlers/RemoveTrack/xnoise-handler-remove-track.vala \
    ItemHandlers/xnoise-item.vala \
    ItemHandlers/xnoise-item-converter.vala \
    ItemHandlers/xnoise-item-handler.vala \
    ItemHandlers/xnoise-item-handler-manager.vala \
    Database/xnoise-db-browser.vala \
    Database/xnoise-db-creator.vala \
    Database/xnoise-db-writer.vala \
    Lyrics/xnoise-i-lyrics.vala \
    Lyrics/xnoise-i-lyrics-provider.vala \
    Lyrics/xnoise-lyrics-loader.vala \
    Models/xnoise-media-browser-model.vala \
    Models/xnoise-tracklist-model.vala \
    Player/xnoise-gst-player.vala \
    Plugin/xnoise-plugin.vala \
    Plugin/xnoise-plugin-loader.vala \
    Plugin/xnoise-plugin-information.vala \
    Plugin/xnoise-plugin-interface.vala \
    Services/xnoise-services.vala \
    TagAccess/xnoise-tag-reader.vala \
    TagAccess/xnoise-tag-writer.vala \
    TrayIcon/xnoise-tray-icon.vala \
    Utils/xnoise-app-starter.vala \
    Utils/xnoise-i-params.vala \
    Utils/xnoise-global-access.vala \
    Utils/xnoise-media-importer.vala \
    Utils/xnoise-misc.vala \
    Utils/xnoise-parameter.vala \
    Utils/xnoise-screensaver-manager.vala \
    Utils/xnoise-track-data.vala \
    Utils/xnoise-user-info.vala \
    Utils/xnoise-worker.vala \
    Widgets/xnoise-about.vala \
    Widgets/xnoise-add-media-dialog.vala \
    Widgets/xnoise-album-image.vala \
    Widgets/xnoise-control-button.vala \
    Widgets/xnoise-fullscreen-toolbar.vala \
    Widgets/xnoise-info-bar.vala \
    Widgets/xnoise-lyrics-view.vala \
    Widgets/xnoise-main-window.vala \
    Widgets/xnoise-media-browser.vala \
    Widgets/xnoise-play-pause-button.vala \
    Widgets/xnoise-plugin-manager-tree.vala \
    Widgets/xnoise-settings-dialog.vala \
    Widgets/xnoise-text-column.vala \
    Widgets/xnoise-trackinfo-bar.vala \
    Widgets/xnoise-tracklist.vala \
    Widgets/xnoise-track-progressbar.vala \
    Widgets/xnoise-videoscreen.vala \
    Widgets/xnoise-volume-slider-button.vala \
    $(NULL)

VALAFLAGS = \
    --basedir $(top_srcdir)/src \
    --thread \
    --vapidir $(top_srcdir)/vapi \
    --vapidir $(top_srcdir)/libxnoise-utils \
    --pkg libxnoiseutils-1.0 \
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

EXTRA_DIST = \
    $(VAPI_FILES) \
    $(DEPS_FILES) \
    $(BUILT_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    ItemHandlers/*.c \
    ItemHandlers/AddToTracklist/*.c \
    ItemHandlers/PlayItem/*.c \
    ItemHandlers/RemoveTrack/*.c \
    Database/*.c \
    Utils/*.c \
    Widgets/*.c \
    TrayIcon/*.c \
    Player/*.c \
    Plugin/*.c \
    Models/*.c \
    xnoise_vala.stamp \
    Makefile.in \
    $(NULL)

