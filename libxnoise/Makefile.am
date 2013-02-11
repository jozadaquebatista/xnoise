NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
    $(NULL)

INCLUDES = \
    -include $(CONFIG_HEADER) \
    $(XNOISE_CFLAGS) \
    -DXN_DATADIR=\"$(datadir)/xnoise/\" \
    -DXN_UIDIR=\"$(datadir)/xnoise/ui/\" \
    -DXN_PLUGINSDIR=\"$(libdir)/xnoise\" \
    -DXN_LICENSEDIR=\"$(datadir)/xnoise/license/\" \
    -DXN_LOCALE_DIR=\"${datarootdir}/locale\" \
    -I$(top_builddir) \
    -I$(top_srcdir)/bindings/c \
    $(NULL)

libxnoise_hdir = $(includedir)/xnoise
libxnoise_h_HEADERS = xnoise-1.0.h

BUILT_SOURCES = \
    xnoise-1.0.vapi \
    xnoise-1.0.h \
    $(NULL)
    
libxnoisedir = $(libdir)/xnoise

lib_LTLIBRARIES = libxnoise.la

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
    DataSource/xnoise-data-source.vala \
    DBus/xnoise-dbus.vala \
    DBus/xnoise-dbus-thumbnailer.vala \
    DBus/xnoise-desktop-notifications.vala \
    DockableMedia/History/xnoise-dockable-playlist-lastplayed.vala \
    DockableMedia/History/xnoise-lastplayed-treeview.vala \
    DockableMedia/History/xnoise-lastplayed-treeview-model.vala \
    DockableMedia/MusicBrowser/xnoise-music-browser-dockable.vala \
    DockableMedia/MusicBrowser/xnoise-music-browser.vala \
    DockableMedia/MusicBrowser/xnoise-music-browser-model.vala \
    DockableMedia/MostPlayed/xnoise-dockable-playlist-mostplayed.vala \
    DockableMedia/MostPlayed/xnoise-mostplayed-treeview.vala \
    DockableMedia/MostPlayed/xnoise-mostplayed-treeview-model.vala \
    DockableMedia/StreamListing/xnoise-dockable-streams.vala \
    DockableMedia/StreamListing/xnoise-treeview-streams.vala \
    DockableMedia/StreamListing/xnoise-treeview-streams-model.vala \
    DockableMedia/VideoListing/xnoise-dockable-videos.vala \
    DockableMedia/VideoListing/xnoise-treeview-videos.vala \
    DockableMedia/VideoListing/xnoise-treeview-videos-model.vala \
    DockableMedia/xnoise-dockable-media.vala \
    DockableMedia/xnoise-dockable-media-manager.vala \
    ExtDev/AndroidPlayer/xnoise-android-item-handler.vala \
    ExtDev/AndroidPlayer/xnoise-android-player-device.vala \
    ExtDev/AndroidPlayer/xnoise-android-player-main-view.vala \
    ExtDev/AndroidPlayer/xnoise-android-player-tree-store.vala \
    ExtDev/AndroidPlayer/xnoise-android-player-tree-view.vala \
    ExtDev/AudioPlayer/xnoise-audio-item-handler.vala \
    ExtDev/AudioPlayer/xnoise-audio-player-device.vala \
    ExtDev/AudioPlayer/xnoise-audio-player-main-view.vala \
    ExtDev/AudioPlayer/xnoise-audio-player-tree-store.vala \
    ExtDev/AudioPlayer/xnoise-audio-player-tree-view.vala \
    ExtDev/AudioPlayer/xnoise-audio-player-temp-db.vala \
    ExtDev/CddaDevice/xnoise-cdda-device.vala \
    ExtDev/CddaDevice/xnoise-cdda-item-handler.vala \
    ExtDev/CddaDevice/xnoise-cdda-main-view.vala \
    ExtDev/CddaDevice/xnoise-cdda-tree-view.vala \
    ExtDev/GenericPlayer/xnoise-generic-player-item-handler.vala \
    ExtDev/GenericPlayer/xnoise-generic-player-device.vala \
    ExtDev/GenericPlayer/xnoise-generic-player-main-view.vala \
    ExtDev/GenericPlayer/xnoise-generic-player-tree-store.vala \
    ExtDev/GenericPlayer/xnoise-generic-player-tree-view.vala \
    ExtDev/xnoise-device.vala \
    ExtDev/xnoise-device-main-view.vala \
    ExtDev/xnoise-device-manager.vala \
    ExtraWidgets/AboutDialog/xnoise-about.vala \
    ExtraWidgets/AddMedia/xnoise-add-media-widget.vala \
    ExtraWidgets/AlbumArtView/xnoise-albumart-cellarea.vala \
    ExtraWidgets/AlbumArtView/xnoise-albumart-view.vala \
    ExtraWidgets/AlbumArtView/xnoise-icons-model.vala \
    ExtraWidgets/Fullscreen/xnoise-fullscreen-progressbar.vala \
    ExtraWidgets/Fullscreen/xnoise-fullscreen-toolbar.vala \
    ExtraWidgets/Settings/xnoise-settings-widget.vala \
    ExtraWidgets/VideoScreen/xnoise-videoscreen.vala \
    ExtraWidgets/xnoise-app-menu-button.vala \
    ExtraWidgets/xnoise-cell-renderer-thumb.vala \
    ExtraWidgets/xnoise-combo-media-selector.vala \
    ExtraWidgets/xnoise-control-button.vala \
    ExtraWidgets/xnoise-equalizer-widget.vala \
    ExtraWidgets/xnoise-first-start-widget.vala \
    ExtraWidgets/xnoise-main-view-notebook.vala \
    ExtraWidgets/xnoise-media-source-widget.vala \
    ExtraWidgets/xnoise-play-pause-button.vala \
    ExtraWidgets/xnoise-serial-button.vala \
    ExtraWidgets/xnoise-trackinfo-bar.vala \
    ExtraWidgets/xnoise-tree-media-selector.vala \
    ExtraWidgets/xnoise-volume-slider-button.vala \
    GlobalAccess/xnoise-global-access.vala \
    IconRepo/xnoise-icon-cache.vala \
    IconRepo/xnoise-icon-repo.vala \
    ItemHandlers/AddAllToTracklist/xnoise-handler-add-all-to-tracklist.vala \
    ItemHandlers/AddToTracklist/xnoise-handler-add-to-tracklist.vala \
    ItemHandlers/EditTags/xnoise-handler-edit-tags.vala \
    ItemHandlers/EditTags/xnoise-tag-album-editor.vala \
    ItemHandlers/EditTags/xnoise-tag-artist-editor.vala \
    ItemHandlers/EditTags/xnoise-tag-genre-editor.vala \
    ItemHandlers/EditTags/xnoise-tag-title-editor.vala \
    ItemHandlers/MoveToTrash/xnoise-handler-move-to-trash.vala \
    ItemHandlers/PlayItem/xnoise-handler-play-item.vala \
    ItemHandlers/RemoveTrack/xnoise-handler-remove-track.vala \
    ItemHandlers/ShowInFilemanager/xnoise-handler-show-in-file-manager.vala \
    ItemHandlers/xnoise-external-queryable.vala \
    ItemHandlers/xnoise-item.vala \
    ItemHandlers/xnoise-item-converter.vala \
    ItemHandlers/xnoise-item-handler.vala \
    ItemHandlers/xnoise-item-handler-manager.vala \
    ItemHandlers/xnoise-playlist-queryable.vala \
    ItemHandlers/xnoise-tree-queryable.vala \
    Lyrics/xnoise-i-lyrics.vala \
    Lyrics/xnoise-i-lyrics-provider.vala \
    Lyrics/xnoise-lyrics-loader.vala \
    Lyrics/xnoise-lyrics-view.vala \
    Main/xnoise-main.vala \
    MainWindow/xnoise-main-window.vala \
    Parameter/xnoise-i-params.vala \
    Parameter/xnoise-parameter.vala \
    Player/xnoise-gst-equalizer.vala \
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
    PluginModule/xnoise-plugin-switch-widget.vala \
    Resources/xnoise-resources.vala \
    ScreensaverManager/xnoise-screensaver-manager.vala \
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
    Utils/xnoise-album-data.vala \
    Utils/xnoise-local-schemes.vala \
    Utils/xnoise-media-extensions.vala \
    Utils/xnoise-media-importer.vala \
    Utils/xnoise-media-stream-schemes.vala \
    Utils/xnoise-misc.vala \
    Utils/xnoise-remote-schemes.vala \
    Utils/xnoise-track-data.vala \
    Utils/xnoise-utilities.vala \
    $(NULL)

libxnoise_la_VALAFLAGS = \
    --library libxnoise-1.0 \
    --header=xnoise-1.0.h \
    --vapi=xnoise-1.0.vapi \
    --thread \
    --pkg gio-2.0 \
    --vapidir $(top_srcdir)/vapi \
    --vapidir $(top_srcdir)/bindings/vala \
    --pkg taginfo_c \
    --basedir $(top_srcdir)/libxnoise \
    @XNOISE_PACKAGES@ \
    $(NULL)

if HAVE_MIN_GTK_34
    libxnoise_la_VALAFLAGS+= -D HAVE_MIN_GTK_34
endif

libxnoise_la_LDFLAGS = \
    $(PLUGIN_LIBTOOL_FLAGS) \
    -export-dynamic \
    $(NULL)

libxnoise_la_LIBADD = \
    $(XNOISE_LIBS) \
    $(top_builddir)/bindings/c/libtaginfo_c.la \
    -lgstpbutils-1.0 \
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
    DataSource/*.c \
    DBus/*.c \
    ExtDev/*.c \
    ExtDev/AndroidPlayer/*.c \
    ExtDev/AudioPlayer/*.c \
    ExtDev/GenericPlayer/*.c \
    DockableMedia/*.c \
    DockableMedia/History/*.c \
    DockableMedia/MusicBrowser/*.c \
    DockableMedia/MostPlayed/*.c \
    DockableMedia/StreamListing/*.c \
    DockableMedia/VideoListing/*.c \
    ExtraWidgets/*.c \
    ExtraWidgets/AboutDialog/*.c \
    ExtraWidgets/AddMedia/*.c \
    ExtraWidgets/AlbumArtView/*.c \
    ExtraWidgets/Fullscreen/*.c \
    ExtraWidgets/Settings/*.c \
    ExtraWidgets/VideoScreen/*.c \
    GlobalAccess/*.c \
    IconRepo/*.c \
    ItemHandlers/*.c \
    ItemHandlers/AddAllToTracklist/*.c \
    ItemHandlers/AddToTracklist/*.c \
    ItemHandlers/EditTags/*.c \
    ItemHandlers/MoveToTrash/*.c \
    ItemHandlers/PlayItem/*.c \
    ItemHandlers/RemoveTrack/*.c \
    ItemHandlers/ShowInFilemanager/*.c \
    Lyrics/*.c \
    Main/*.c \
    MainWindow/*.c \
    Parameter/*.c \
    Player/*.c \
    PlaylistReader/*.c \
    PlaylistReader/ASX/*.c \
    PlaylistReader/M3U/*.c \
    PlaylistReader/PLS/*.c \
    PlaylistReader/WPL/*.c \
    PlaylistReader/XSPF/*.c \
    PluginModule/*.c \
    Resources/*.c \
    ScreensaverManager/*.c \
    Services/*.c \
    SimpleMarkup/*.c \
    Statistics/*.c \
    TagAccess/*.c \
    TrackList/*.c \
    TrayIcon/*.c \
    UserInfoSystem/*.c \
    Utils/*.c \
    $(NULL)


