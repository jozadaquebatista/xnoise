NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    -include $(CONFIG_HEADER) \
    $(XNOISE_CFLAGS) \
    -DDATADIR=\"$(datadir)/xnoise/\" \
    -DUIDIR=\"$(datadir)/xnoise/ui/\" \
    -DPLUGINSDIR=\"$(libdir)/xnoise\" \
    -DLICENSEDIR=\"$(datadir)/xnoise/license/\" \
    -DLOCALE_DIR=\"${datarootdir}/locale\" \
    $(NULL)

libxnoise_hdir = $(includedir)/xnoise
libxnoise_h_HEADERS = xnoise-1.0.h

BUILT_SOURCES = \
    xnoise-1.0.vapi \
    xnoise-1.0.h \
    $(NULL)
    
libxnoisedir = $(libdir)/xnoise

libxnoise_LTLIBRARIES = libxnoise.la

libxnoise_la_SOURCES = \
    AlbumImages/xnoise-album-image.vala \
    AlbumImages/xnoise-album-image-loader.vala \
    AlbumImages/xnoise-i-album-cover-image.vala \
    AlbumImages/xnoise-i-album-cover-image-provider.vala \
    Application/xnoise-application.vala \
    BackgroundWorker/xnoise-worker.vala \
    Database/xnoise-db-reader.vala \
    Database/xnoise-db-creator.vala \
    Database/xnoise-db-writer.vala \
    DBus/xnoise-dbus.vala \
    DockableMedia/DynamicPlaylists/xnoise-dockable-playlist-mostplayed.vala \
    DockableMedia/DynamicPlaylists/xnoise-mostplayed-treeview.vala \
    DockableMedia/DynamicPlaylists/xnoise-mostplayed-treeview-model.vala \
    DockableMedia/xnoise-dockable-media.vala \
    ExtraWidgets/AboutDialog/xnoise-about.vala \
    ExtraWidgets/AddMediaDialog/xnoise-add-media-dialog.vala \
    ExtraWidgets/Fullscreen/xnoise-fullscreen-progressbar.vala \
    ExtraWidgets/Fullscreen/xnoise-fullscreen-toolbar.vala \
    ExtraWidgets/SettingsDialog/xnoise-settings-dialog.vala \
    ExtraWidgets/VideoScreen/xnoise-videoscreen.vala \
    ExtraWidgets/xnoise-app-menu-button.vala \
    ExtraWidgets/xnoise-control-button.vala \
    ExtraWidgets/xnoise-play-pause-button.vala \
    ExtraWidgets/xnoise-serial-button.vala \
    ExtraWidgets/xnoise-trackinfo-bar.vala \
    ExtraWidgets/xnoise-volume-slider-button.vala \
    GlobalAccess/xnoise-global-access.vala \
    IconRepo/xnoise-icon-repo.vala \
    ItemHandlers/AddAllToTracklist/xnoise-handler-add-all-to-tracklist.vala \
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
    Lyrics/xnoise-i-lyrics.vala \
    Lyrics/xnoise-i-lyrics-provider.vala \
    Lyrics/xnoise-lyrics-loader.vala \
    Lyrics/xnoise-lyrics-view.vala \
    Main/xnoise-main.vala \
    MainWindow/xnoise-main-window.vala \
    MediaBrowser/xnoise-media-browser-dockable.vala \
    MediaBrowser/xnoise-media-browser.vala \
    MediaBrowser/xnoise-media-browser-model.vala \
    Parameter/xnoise-i-params.vala \
    Parameter/xnoise-parameter.vala \
    Player/xnoise-gst-player.vala \
    PlaylistReader/xnoise-playlist-abstract-file-reader.vala \
    PlaylistReader/xnoise-playlist-general.vala \
    PlaylistReader/xnoise-playlist-entry.vala \
    PlaylistReader/xnoise-playlist-entry-collection.vala \
    PlaylistReader/xnoise-playlist-reader.vala \
    PlaylistReader/ASX/xnoise-playlist-asx-file-reader.vala \
    PlaylistReader/WPL/xnoise-playlist-wpl-file-reader.vala \
    PlaylistReader/M3U/xnoise-playlist-m3u-file-reader.vala \
    PlaylistReader/PLS/xnoise-playlist-pls-file-reader.vala \
    PlaylistReader/XSPF/xnoise-playlist-xspf-file-reader.vala \
    PluginModule/xnoise-plugin.vala \
    PluginModule/xnoise-plugin-information.vala \
    PluginModule/xnoise-plugin-interface.vala \
    PluginModule/xnoise-plugin-loader.vala \
    PluginModule/xnoise-plugin-manager-tree.vala \
    ScreensaverManager/xnoise-screensaver-manager.vala \
    Services/xnoise-services.vala \
    SimpleMarkup/xnoise-markup-node.vala \
    SimpleMarkup/xnoise-markup-reader.vala \
    SimpleMarkup/xnoise-markup-writer.vala \
    Statistics/xnoise-statistics.vala \
    TagAccess/xnoise-tag-reader.vala \
    TagAccess/xnoise-tag-writer.vala \
    TrackList/xnoise-text-column.vala \
    TrackList/xnoise-tracklist.vala \
    TrackList/xnoise-tracklist-column.vala \
    TrackList/xnoise-tracklist-model.vala \
    TrayIcon/xnoise-tray-icon.vala \
    UserInfoSystem/xnoise-info-bar.vala \
    UserInfoSystem/xnoise-user-info.vala \
    Utils/xnoise-local-schemes.vala \
    Utils/xnoise-media-extensions.vala \
    Utils/xnoise-media-importer.vala \
    Utils/xnoise-media-stream-schemes.vala \
    Utils/xnoise-misc.vala \
    Utils/xnoise-remote-schemes.vala \
    Utils/xnoise-track-data.vala \
    $(NULL)

libxnoise_la_VALAFLAGS = \
    --library libxnoise-1.0 \
    --header=xnoise-1.0.h \
    --vapi=xnoise-1.0.vapi \
    --thread \
    --pkg gio-2.0 \
    --vapidir $(top_srcdir)/vapi \
    --basedir $(top_srcdir)/libxnoise \
    @XNOISE_PACKAGES@ \
    $(NULL)

libxnoise_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -export-dynamic \
    $(NULL)

libxnoise_la_LIBADD = \
    $(XNOISE_LIBS) \
    -lgstpbutils-0.10 \
    $(NULL)

VAPI_FILES = xnoise-1.0.vapi
DEPS_FILES = xnoise-1.0.deps

vapidir = $(VAPIDIR)
vapi_DATA = $(VAPI_FILES) $(DEPS_FILES)

EXTRA_DIST = \
    $(VAPI_FILES) \
    $(DEPS_FILES) \
    $(BUILT_SOURCES) \
    $(libxnoise_DATA) \
    $(libxnoise_la_SOURCES) \
    $(NULL)

DISTCLEANFILES = \
    *.c \
    libxnoise_la_vala.stamp \
    Makefile.in \
    AlbumImages/*.c \
    Application/*.c \
    BackgroundWorker/*.c \
    Database/*.c \
    DBus/*.c \
    ExtraWidgets/*.c \
    ExtraWidgets/AboutDialog/*.c \
    ExtraWidgets/AddMediaDialog/*.c \
    ExtraWidgets/Fullscreen/*.c \
    ExtraWidgets/SettingsDialog/*.c \
    ExtraWidgets/VideoScreen/*.c \
    GlobalAccess/*.c \
    ItemHandlers/*.c \
    ItemHandlers/AddAllToTracklist/*.c \
    ItemHandlers/AddToTracklist/*.c \
    ItemHandlers/EditTags/*.c \
    ItemHandlers/PlayItem/*.c \
    ItemHandlers/RemoveTrack/*.c \
    Lyrics/*.c \
    Main/*.c \
    MainWindow/*.c \
    MediaBrowser/*.c \
    Parameter/*.c \
    Player/*.c \
    PlaylistReader/*.c \
    PlaylistReader/ASX/*.c \
    PlaylistReader/M3U/*.c \
    PlaylistReader/PLS/*.c \
    PlaylistReader/WPL/*.c \
    PlaylistReader/XSPF/*.c \
    PluginModule/*.c \
    ScreensaverManager/*.c \
    Services/*.c \
    SimpleMarkup/*.c \
    TagAccess/*.c \
    TrackList/*.c \
    TrayIcon/*.c \
    UserInfoSystem/*.c \
    Utils/*.c \
    $(NULL)

