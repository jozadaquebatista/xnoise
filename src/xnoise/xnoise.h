
#ifndef ____XNOISE_H__
#define ____XNOISE_H__

#include <glib.h>
#include <glib-object.h>
#include <unique/unique.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>
#include <gst/gst.h>
#include <float.h>
#include <math.h>
#include <gdk/gdk.h>
#include <gdk-pixbuf/gdk-pixdata.h>

G_BEGIN_DECLS


#define XNOISE_TYPE_APP_STARTER (xnoise_app_starter_get_type ())
#define XNOISE_APP_STARTER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_APP_STARTER, XnoiseAppStarter))
#define XNOISE_APP_STARTER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_APP_STARTER, XnoiseAppStarterClass))
#define XNOISE_IS_APP_STARTER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_APP_STARTER))
#define XNOISE_IS_APP_STARTER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_APP_STARTER))
#define XNOISE_APP_STARTER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_APP_STARTER, XnoiseAppStarterClass))

typedef struct _XnoiseAppStarter XnoiseAppStarter;
typedef struct _XnoiseAppStarterClass XnoiseAppStarterClass;
typedef struct _XnoiseAppStarterPrivate XnoiseAppStarterPrivate;

#define XNOISE_TYPE_MAIN (xnoise_main_get_type ())
#define XNOISE_MAIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_MAIN, XnoiseMain))
#define XNOISE_MAIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_MAIN, XnoiseMainClass))
#define XNOISE_IS_MAIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_MAIN))
#define XNOISE_IS_MAIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_MAIN))
#define XNOISE_MAIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_MAIN, XnoiseMainClass))

typedef struct _XnoiseMain XnoiseMain;
typedef struct _XnoiseMainClass XnoiseMainClass;
typedef struct _XnoiseMainPrivate XnoiseMainPrivate;

#define XNOISE_TYPE_MAIN_WINDOW (xnoise_main_window_get_type ())
#define XNOISE_MAIN_WINDOW(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_MAIN_WINDOW, XnoiseMainWindow))
#define XNOISE_MAIN_WINDOW_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_MAIN_WINDOW, XnoiseMainWindowClass))
#define XNOISE_IS_MAIN_WINDOW(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_MAIN_WINDOW))
#define XNOISE_IS_MAIN_WINDOW_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_MAIN_WINDOW))
#define XNOISE_MAIN_WINDOW_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_MAIN_WINDOW, XnoiseMainWindowClass))

typedef struct _XnoiseMainWindow XnoiseMainWindow;
typedef struct _XnoiseMainWindowClass XnoiseMainWindowClass;

#define XNOISE_TYPE_PLUGIN_LOADER (xnoise_plugin_loader_get_type ())
#define XNOISE_PLUGIN_LOADER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PLUGIN_LOADER, XnoisePluginLoader))
#define XNOISE_PLUGIN_LOADER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PLUGIN_LOADER, XnoisePluginLoaderClass))
#define XNOISE_IS_PLUGIN_LOADER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PLUGIN_LOADER))
#define XNOISE_IS_PLUGIN_LOADER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PLUGIN_LOADER))
#define XNOISE_PLUGIN_LOADER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PLUGIN_LOADER, XnoisePluginLoaderClass))

typedef struct _XnoisePluginLoader XnoisePluginLoader;
typedef struct _XnoisePluginLoaderClass XnoisePluginLoaderClass;

#define XNOISE_TYPE_GST_PLAYER (xnoise_gst_player_get_type ())
#define XNOISE_GST_PLAYER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_GST_PLAYER, XnoiseGstPlayer))
#define XNOISE_GST_PLAYER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_GST_PLAYER, XnoiseGstPlayerClass))
#define XNOISE_IS_GST_PLAYER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_GST_PLAYER))
#define XNOISE_IS_GST_PLAYER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_GST_PLAYER))
#define XNOISE_GST_PLAYER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_GST_PLAYER, XnoiseGstPlayerClass))

typedef struct _XnoiseGstPlayer XnoiseGstPlayer;
typedef struct _XnoiseGstPlayerClass XnoiseGstPlayerClass;
typedef struct _XnoiseGstPlayerPrivate XnoiseGstPlayerPrivate;

#define XNOISE_TYPE_VIDEO_SCREEN (xnoise_video_screen_get_type ())
#define XNOISE_VIDEO_SCREEN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_VIDEO_SCREEN, XnoiseVideoScreen))
#define XNOISE_VIDEO_SCREEN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_VIDEO_SCREEN, XnoiseVideoScreenClass))
#define XNOISE_IS_VIDEO_SCREEN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_VIDEO_SCREEN))
#define XNOISE_IS_VIDEO_SCREEN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_VIDEO_SCREEN))
#define XNOISE_VIDEO_SCREEN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_VIDEO_SCREEN, XnoiseVideoScreenClass))

typedef struct _XnoiseVideoScreen XnoiseVideoScreen;
typedef struct _XnoiseVideoScreenClass XnoiseVideoScreenClass;

#define XNOISE_TYPE_IPARAMS (xnoise_iparams_get_type ())
#define XNOISE_IPARAMS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_IPARAMS, XnoiseIParams))
#define XNOISE_IS_IPARAMS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_IPARAMS))
#define XNOISE_IPARAMS_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), XNOISE_TYPE_IPARAMS, XnoiseIParamsIface))

typedef struct _XnoiseIParams XnoiseIParams;
typedef struct _XnoiseIParamsIface XnoiseIParamsIface;
typedef struct _XnoiseMainWindowPrivate XnoiseMainWindowPrivate;

#define XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON (xnoise_main_window_play_pause_button_get_type ())
#define XNOISE_MAIN_WINDOW_PLAY_PAUSE_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON, XnoiseMainWindowPlayPauseButton))
#define XNOISE_MAIN_WINDOW_PLAY_PAUSE_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON, XnoiseMainWindowPlayPauseButtonClass))
#define XNOISE_MAIN_WINDOW_IS_PLAY_PAUSE_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON))
#define XNOISE_MAIN_WINDOW_IS_PLAY_PAUSE_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON))
#define XNOISE_MAIN_WINDOW_PLAY_PAUSE_BUTTON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_PLAY_PAUSE_BUTTON, XnoiseMainWindowPlayPauseButtonClass))

typedef struct _XnoiseMainWindowPlayPauseButton XnoiseMainWindowPlayPauseButton;
typedef struct _XnoiseMainWindowPlayPauseButtonClass XnoiseMainWindowPlayPauseButtonClass;

#define XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON (xnoise_main_window_previous_button_get_type ())
#define XNOISE_MAIN_WINDOW_PREVIOUS_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON, XnoiseMainWindowPreviousButton))
#define XNOISE_MAIN_WINDOW_PREVIOUS_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON, XnoiseMainWindowPreviousButtonClass))
#define XNOISE_MAIN_WINDOW_IS_PREVIOUS_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON))
#define XNOISE_MAIN_WINDOW_IS_PREVIOUS_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON))
#define XNOISE_MAIN_WINDOW_PREVIOUS_BUTTON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_PREVIOUS_BUTTON, XnoiseMainWindowPreviousButtonClass))

typedef struct _XnoiseMainWindowPreviousButton XnoiseMainWindowPreviousButton;
typedef struct _XnoiseMainWindowPreviousButtonClass XnoiseMainWindowPreviousButtonClass;

#define XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON (xnoise_main_window_next_button_get_type ())
#define XNOISE_MAIN_WINDOW_NEXT_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON, XnoiseMainWindowNextButton))
#define XNOISE_MAIN_WINDOW_NEXT_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON, XnoiseMainWindowNextButtonClass))
#define XNOISE_MAIN_WINDOW_IS_NEXT_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON))
#define XNOISE_MAIN_WINDOW_IS_NEXT_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON))
#define XNOISE_MAIN_WINDOW_NEXT_BUTTON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_NEXT_BUTTON, XnoiseMainWindowNextButtonClass))

typedef struct _XnoiseMainWindowNextButton XnoiseMainWindowNextButton;
typedef struct _XnoiseMainWindowNextButtonClass XnoiseMainWindowNextButtonClass;

#define XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON (xnoise_main_window_stop_button_get_type ())
#define XNOISE_MAIN_WINDOW_STOP_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON, XnoiseMainWindowStopButton))
#define XNOISE_MAIN_WINDOW_STOP_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON, XnoiseMainWindowStopButtonClass))
#define XNOISE_MAIN_WINDOW_IS_STOP_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON))
#define XNOISE_MAIN_WINDOW_IS_STOP_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON))
#define XNOISE_MAIN_WINDOW_STOP_BUTTON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_STOP_BUTTON, XnoiseMainWindowStopButtonClass))

typedef struct _XnoiseMainWindowStopButton XnoiseMainWindowStopButton;
typedef struct _XnoiseMainWindowStopButtonClass XnoiseMainWindowStopButtonClass;

#define XNOISE_TYPE_ALBUM_IMAGE (xnoise_album_image_get_type ())
#define XNOISE_ALBUM_IMAGE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImage))
#define XNOISE_ALBUM_IMAGE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImageClass))
#define XNOISE_IS_ALBUM_IMAGE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_ALBUM_IMAGE))
#define XNOISE_IS_ALBUM_IMAGE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_ALBUM_IMAGE))
#define XNOISE_ALBUM_IMAGE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImageClass))

typedef struct _XnoiseAlbumImage XnoiseAlbumImage;
typedef struct _XnoiseAlbumImageClass XnoiseAlbumImageClass;

#define XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR (xnoise_main_window_song_progress_bar_get_type ())
#define XNOISE_MAIN_WINDOW_SONG_PROGRESS_BAR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR, XnoiseMainWindowSongProgressBar))
#define XNOISE_MAIN_WINDOW_SONG_PROGRESS_BAR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR, XnoiseMainWindowSongProgressBarClass))
#define XNOISE_MAIN_WINDOW_IS_SONG_PROGRESS_BAR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR))
#define XNOISE_MAIN_WINDOW_IS_SONG_PROGRESS_BAR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR))
#define XNOISE_MAIN_WINDOW_SONG_PROGRESS_BAR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_SONG_PROGRESS_BAR, XnoiseMainWindowSongProgressBarClass))

typedef struct _XnoiseMainWindowSongProgressBar XnoiseMainWindowSongProgressBar;
typedef struct _XnoiseMainWindowSongProgressBarClass XnoiseMainWindowSongProgressBarClass;

#define XNOISE_TYPE_MEDIA_BROWSER (xnoise_media_browser_get_type ())
#define XNOISE_MEDIA_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_MEDIA_BROWSER, XnoiseMediaBrowser))
#define XNOISE_MEDIA_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_MEDIA_BROWSER, XnoiseMediaBrowserClass))
#define XNOISE_IS_MEDIA_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_MEDIA_BROWSER))
#define XNOISE_IS_MEDIA_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_MEDIA_BROWSER))
#define XNOISE_MEDIA_BROWSER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_MEDIA_BROWSER, XnoiseMediaBrowserClass))

typedef struct _XnoiseMediaBrowser XnoiseMediaBrowser;
typedef struct _XnoiseMediaBrowserClass XnoiseMediaBrowserClass;

#define XNOISE_TYPE_TRACK_LIST (xnoise_track_list_get_type ())
#define XNOISE_TRACK_LIST(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_TRACK_LIST, XnoiseTrackList))
#define XNOISE_TRACK_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_TRACK_LIST, XnoiseTrackListClass))
#define XNOISE_IS_TRACK_LIST(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_TRACK_LIST))
#define XNOISE_IS_TRACK_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_TRACK_LIST))
#define XNOISE_TRACK_LIST_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_TRACK_LIST, XnoiseTrackListClass))

typedef struct _XnoiseTrackList XnoiseTrackList;
typedef struct _XnoiseTrackListClass XnoiseTrackListClass;

#define XNOISE_TYPE_DIRECTION (xnoise_direction_get_type ())
typedef struct _XnoiseMainWindowNextButtonPrivate XnoiseMainWindowNextButtonPrivate;
typedef struct _XnoiseMainWindowPreviousButtonPrivate XnoiseMainWindowPreviousButtonPrivate;
typedef struct _XnoiseMainWindowStopButtonPrivate XnoiseMainWindowStopButtonPrivate;
typedef struct _XnoiseMainWindowPlayPauseButtonPrivate XnoiseMainWindowPlayPauseButtonPrivate;
typedef struct _XnoiseMainWindowSongProgressBarPrivate XnoiseMainWindowSongProgressBarPrivate;

#define XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON (xnoise_main_window_volume_slider_button_get_type ())
#define XNOISE_MAIN_WINDOW_VOLUME_SLIDER_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON, XnoiseMainWindowVolumeSliderButton))
#define XNOISE_MAIN_WINDOW_VOLUME_SLIDER_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON, XnoiseMainWindowVolumeSliderButtonClass))
#define XNOISE_MAIN_WINDOW_IS_VOLUME_SLIDER_BUTTON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON))
#define XNOISE_MAIN_WINDOW_IS_VOLUME_SLIDER_BUTTON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON))
#define XNOISE_MAIN_WINDOW_VOLUME_SLIDER_BUTTON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_MAIN_WINDOW_TYPE_VOLUME_SLIDER_BUTTON, XnoiseMainWindowVolumeSliderButtonClass))

typedef struct _XnoiseMainWindowVolumeSliderButton XnoiseMainWindowVolumeSliderButton;
typedef struct _XnoiseMainWindowVolumeSliderButtonClass XnoiseMainWindowVolumeSliderButtonClass;
typedef struct _XnoiseMainWindowVolumeSliderButtonPrivate XnoiseMainWindowVolumeSliderButtonPrivate;

#define XNOISE_TYPE_ABOUT_DIALOG (xnoise_about_dialog_get_type ())
#define XNOISE_ABOUT_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_ABOUT_DIALOG, XnoiseAboutDialog))
#define XNOISE_ABOUT_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_ABOUT_DIALOG, XnoiseAboutDialogClass))
#define XNOISE_IS_ABOUT_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_ABOUT_DIALOG))
#define XNOISE_IS_ABOUT_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_ABOUT_DIALOG))
#define XNOISE_ABOUT_DIALOG_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_ABOUT_DIALOG, XnoiseAboutDialogClass))

typedef struct _XnoiseAboutDialog XnoiseAboutDialog;
typedef struct _XnoiseAboutDialogClass XnoiseAboutDialogClass;
typedef struct _XnoiseAboutDialogPrivate XnoiseAboutDialogPrivate;

#define XNOISE_TYPE_PARAMS (xnoise_params_get_type ())
#define XNOISE_PARAMS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PARAMS, XnoiseParams))
#define XNOISE_PARAMS_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PARAMS, XnoiseParamsClass))
#define XNOISE_IS_PARAMS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PARAMS))
#define XNOISE_IS_PARAMS_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PARAMS))
#define XNOISE_PARAMS_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PARAMS, XnoiseParamsClass))

typedef struct _XnoiseParams XnoiseParams;
typedef struct _XnoiseParamsClass XnoiseParamsClass;
typedef struct _XnoiseParamsPrivate XnoiseParamsPrivate;

#define XNOISE_TYPE_DB_BROWSER (xnoise_db_browser_get_type ())
#define XNOISE_DB_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_DB_BROWSER, XnoiseDbBrowser))
#define XNOISE_DB_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_DB_BROWSER, XnoiseDbBrowserClass))
#define XNOISE_IS_DB_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_DB_BROWSER))
#define XNOISE_IS_DB_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_DB_BROWSER))
#define XNOISE_DB_BROWSER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_DB_BROWSER, XnoiseDbBrowserClass))

typedef struct _XnoiseDbBrowser XnoiseDbBrowser;
typedef struct _XnoiseDbBrowserClass XnoiseDbBrowserClass;
typedef struct _XnoiseDbBrowserPrivate XnoiseDbBrowserPrivate;

#define XNOISE_TYPE_TRACK_DATA (xnoise_track_data_get_type ())

#define XNOISE_TYPE_MEDIA_TYPE (xnoise_media_type_get_type ())
typedef struct _XnoiseTrackData XnoiseTrackData;

#define XNOISE_TYPE_TITLE_MTYPE_ID (xnoise_title_mtype_id_get_type ())
typedef struct _XnoiseTitle_MType_Id XnoiseTitle_MType_Id;

#define XNOISE_TYPE_DB_WRITER (xnoise_db_writer_get_type ())
#define XNOISE_DB_WRITER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_DB_WRITER, XnoiseDbWriter))
#define XNOISE_DB_WRITER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_DB_WRITER, XnoiseDbWriterClass))
#define XNOISE_IS_DB_WRITER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_DB_WRITER))
#define XNOISE_IS_DB_WRITER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_DB_WRITER))
#define XNOISE_DB_WRITER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_DB_WRITER, XnoiseDbWriterClass))

typedef struct _XnoiseDbWriter XnoiseDbWriter;
typedef struct _XnoiseDbWriterClass XnoiseDbWriterClass;
typedef struct _XnoiseDbWriterPrivate XnoiseDbWriterPrivate;
typedef struct _XnoiseMediaBrowserPrivate XnoiseMediaBrowserPrivate;
typedef struct _XnoiseTrackListPrivate XnoiseTrackListPrivate;

#define XNOISE_TYPE_TRACK_STATE (xnoise_track_state_get_type ())

#define XNOISE_TYPE_BROWSER_COLUMN (xnoise_browser_column_get_type ())

#define XNOISE_TYPE_BROWSER_COLLECTION_TYPE (xnoise_browser_collection_type_get_type ())

#define XNOISE_TYPE_REPEAT (xnoise_repeat_get_type ())

#define XNOISE_TYPE_TRACK_LIST_COLUMN (xnoise_track_list_column_get_type ())

#define GST_TYPE_STREAM_TYPE (gst_stream_type_get_type ())
typedef struct _XnoiseVideoScreenPrivate XnoiseVideoScreenPrivate;

#define XNOISE_TYPE_SETTINGS_DIALOG (xnoise_settings_dialog_get_type ())
#define XNOISE_SETTINGS_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialog))
#define XNOISE_SETTINGS_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialogClass))
#define XNOISE_IS_SETTINGS_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_SETTINGS_DIALOG))
#define XNOISE_IS_SETTINGS_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_SETTINGS_DIALOG))
#define XNOISE_SETTINGS_DIALOG_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialogClass))

typedef struct _XnoiseSettingsDialog XnoiseSettingsDialog;
typedef struct _XnoiseSettingsDialogClass XnoiseSettingsDialogClass;
typedef struct _XnoiseSettingsDialogPrivate XnoiseSettingsDialogPrivate;

#define XNOISE_TYPE_PLUGIN (xnoise_plugin_get_type ())
#define XNOISE_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PLUGIN, XnoisePlugin))
#define XNOISE_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PLUGIN, XnoisePluginClass))
#define XNOISE_IS_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PLUGIN))
#define XNOISE_IS_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PLUGIN))
#define XNOISE_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PLUGIN, XnoisePluginClass))

typedef struct _XnoisePlugin XnoisePlugin;
typedef struct _XnoisePluginClass XnoisePluginClass;
typedef struct _XnoisePluginPrivate XnoisePluginPrivate;

#define XNOISE_TYPE_PLUGIN_INFORMATION (xnoise_plugin_information_get_type ())
#define XNOISE_PLUGIN_INFORMATION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PLUGIN_INFORMATION, XnoisePluginInformation))
#define XNOISE_PLUGIN_INFORMATION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PLUGIN_INFORMATION, XnoisePluginInformationClass))
#define XNOISE_IS_PLUGIN_INFORMATION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PLUGIN_INFORMATION))
#define XNOISE_IS_PLUGIN_INFORMATION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PLUGIN_INFORMATION))
#define XNOISE_PLUGIN_INFORMATION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PLUGIN_INFORMATION, XnoisePluginInformationClass))

typedef struct _XnoisePluginInformation XnoisePluginInformation;
typedef struct _XnoisePluginInformationClass XnoisePluginInformationClass;
typedef struct _XnoisePluginLoaderPrivate XnoisePluginLoaderPrivate;
typedef struct _XnoisePluginInformationPrivate XnoisePluginInformationPrivate;

#define XNOISE_TYPE_IPLUGIN (xnoise_iplugin_get_type ())
#define XNOISE_IPLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_IPLUGIN, XnoiseIPlugin))
#define XNOISE_IS_IPLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_IPLUGIN))
#define XNOISE_IPLUGIN_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), XNOISE_TYPE_IPLUGIN, XnoiseIPluginIface))

typedef struct _XnoiseIPlugin XnoiseIPlugin;
typedef struct _XnoiseIPluginIface XnoiseIPluginIface;

#define XNOISE_TYPE_PLUGIN_MANAGER_TREE (xnoise_plugin_manager_tree_get_type ())
#define XNOISE_PLUGIN_MANAGER_TREE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PLUGIN_MANAGER_TREE, XnoisePluginManagerTree))
#define XNOISE_PLUGIN_MANAGER_TREE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PLUGIN_MANAGER_TREE, XnoisePluginManagerTreeClass))
#define XNOISE_IS_PLUGIN_MANAGER_TREE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PLUGIN_MANAGER_TREE))
#define XNOISE_IS_PLUGIN_MANAGER_TREE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PLUGIN_MANAGER_TREE))
#define XNOISE_PLUGIN_MANAGER_TREE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PLUGIN_MANAGER_TREE, XnoisePluginManagerTreeClass))

typedef struct _XnoisePluginManagerTree XnoisePluginManagerTree;
typedef struct _XnoisePluginManagerTreeClass XnoisePluginManagerTreeClass;
typedef struct _XnoisePluginManagerTreePrivate XnoisePluginManagerTreePrivate;
typedef struct _XnoiseAlbumImagePrivate XnoiseAlbumImagePrivate;

struct _XnoiseAppStarter {
	GObject parent_instance;
	XnoiseAppStarterPrivate * priv;
};

struct _XnoiseAppStarterClass {
	GObjectClass parent_class;
};

struct _XnoiseMain {
	GObject parent_instance;
	XnoiseMainPrivate * priv;
	XnoiseMainWindow* main_window;
	XnoisePluginLoader* plugin_loader;
	XnoiseGstPlayer* gPl;
};

struct _XnoiseMainClass {
	GObjectClass parent_class;
};

struct _XnoiseGstPlayer {
	GObject parent_instance;
	XnoiseGstPlayerPrivate * priv;
	XnoiseVideoScreen* videoscreen;
	GstElement* playbin;
};

struct _XnoiseGstPlayerClass {
	GObjectClass parent_class;
};

/*Interfaces*/
struct _XnoiseIParamsIface {
	GTypeInterface parent_iface;
	void (*read_params_data) (XnoiseIParams* self);
	void (*write_params_data) (XnoiseIParams* self);
};

struct _XnoiseMainWindow {
	GtkWindow parent_instance;
	XnoiseMainWindowPrivate * priv;
	gboolean _seek;
	XnoiseVideoScreen* videoscreen;
	GtkLabel* showvideolabel;
	gboolean is_fullscreen;
	gboolean drag_on_da;
	GtkEntry* searchEntryMB;
	XnoiseMainWindowPlayPauseButton* playPauseButton;
	XnoiseMainWindowPreviousButton* previousButton;
	XnoiseMainWindowNextButton* nextButton;
	XnoiseMainWindowStopButton* stopButton;
	GtkButton* repeatButton;
	GtkNotebook* browsernotebook;
	GtkNotebook* tracklistnotebook;
	GtkImage* repeatImage;
	XnoiseAlbumImage* albumimage;
	GtkLabel* repeatLabel;
	XnoiseMainWindowSongProgressBar* songProgressBar;
	double current_volume;
	XnoiseMediaBrowser* mediaBr;
	XnoiseTrackList* trackList;
	GtkWindow* fullscreenwindow;
	GtkImage* playpause_popup_image;
};

struct _XnoiseMainWindowClass {
	GtkWindowClass parent_class;
};

typedef enum  {
	XNOISE_DIRECTION_NEXT = 0,
	XNOISE_DIRECTION_PREVIOUS
} XnoiseDirection;

/**
* A NextButton is a Gtk.Button that initiates playback of the previous item
*/
struct _XnoiseMainWindowNextButton {
	GtkButton parent_instance;
	XnoiseMainWindowNextButtonPrivate * priv;
};

struct _XnoiseMainWindowNextButtonClass {
	GtkButtonClass parent_class;
};

/**
* A PreviousButton is a Gtk.Button that initiates playback of the previous item
*/
struct _XnoiseMainWindowPreviousButton {
	GtkButton parent_instance;
	XnoiseMainWindowPreviousButtonPrivate * priv;
};

struct _XnoiseMainWindowPreviousButtonClass {
	GtkButtonClass parent_class;
};

/**
* A StopButton is a Gtk.Button that stops playback
*/
struct _XnoiseMainWindowStopButton {
	GtkButton parent_instance;
	XnoiseMainWindowStopButtonPrivate * priv;
};

struct _XnoiseMainWindowStopButtonClass {
	GtkButtonClass parent_class;
};

/**
* A PlayPauseButton is a Gtk.Button that accordingly pauses, unpauses or starts playback
*/
struct _XnoiseMainWindowPlayPauseButton {
	GtkButton parent_instance;
	XnoiseMainWindowPlayPauseButtonPrivate * priv;
};

struct _XnoiseMainWindowPlayPauseButtonClass {
	GtkButtonClass parent_class;
};

/**
* A SongProgressBar is  a Gtk.ProgressBar that shows the playback position in the 
* currently played item and changes it upon user input
*/
struct _XnoiseMainWindowSongProgressBar {
	GtkProgressBar parent_instance;
	XnoiseMainWindowSongProgressBarPrivate * priv;
};

struct _XnoiseMainWindowSongProgressBarClass {
	GtkProgressBarClass parent_class;
};

/**
* A VolumeSliderButton is a Gtk.VolumeButton used to change the volume
*/
struct _XnoiseMainWindowVolumeSliderButton {
	GtkVolumeButton parent_instance;
	XnoiseMainWindowVolumeSliderButtonPrivate * priv;
};

struct _XnoiseMainWindowVolumeSliderButtonClass {
	GtkVolumeButtonClass parent_class;
};

struct _XnoiseAboutDialog {
	GtkAboutDialog parent_instance;
	XnoiseAboutDialogPrivate * priv;
};

struct _XnoiseAboutDialogClass {
	GtkAboutDialogClass parent_class;
};

struct _XnoiseParams {
	GObject parent_instance;
	XnoiseParamsPrivate * priv;
};

struct _XnoiseParamsClass {
	GObjectClass parent_class;
};

struct _XnoiseDbBrowser {
	GObject parent_instance;
	XnoiseDbBrowserPrivate * priv;
};

struct _XnoiseDbBrowserClass {
	GObjectClass parent_class;
};

typedef enum  {
	XNOISE_MEDIA_TYPE_UNKNOWN = 0,
	XNOISE_MEDIA_TYPE_AUDIO,
	XNOISE_MEDIA_TYPE_VIDEO,
	XNOISE_MEDIA_TYPE_STREAM,
	XNOISE_MEDIA_TYPE_PLAYLISTFILE
} XnoiseMediaType;

struct _XnoiseTrackData {
	char* Artist;
	char* Album;
	char* Title;
	char* Genre;
	guint Tracknumber;
	XnoiseMediaType Mediatype;
	char* Uri;
};

struct _XnoiseTitle_MType_Id {
	char* name;
	gint id;
	XnoiseMediaType mediatype;
};

struct _XnoiseDbWriter {
	GObject parent_instance;
	XnoiseDbWriterPrivate * priv;
};

struct _XnoiseDbWriterClass {
	GObjectClass parent_class;
};

struct _XnoiseMediaBrowser {
	GtkTreeView parent_instance;
	XnoiseMediaBrowserPrivate * priv;
	GtkTreeStore* treemodel;
	gint fontsizeMB;
};

struct _XnoiseMediaBrowserClass {
	GtkTreeViewClass parent_class;
};

struct _XnoiseTrackList {
	GtkTreeView parent_instance;
	XnoiseTrackListPrivate * priv;
	GtkListStore* listmodel;
};

struct _XnoiseTrackListClass {
	GtkTreeViewClass parent_class;
};

typedef enum  {
	XNOISE_TRACK_STATE_STOPPED = 0,
	XNOISE_TRACK_STATE_PLAYING,
	XNOISE_TRACK_STATE_PAUSED,
	XNOISE_TRACK_STATE_POSITION_FLAG
} XnoiseTrackState;

/* PROJECT WIDE USED STRUCTS, INTERFACES AND ENUMS
Enums*/
typedef enum  {
	XNOISE_BROWSER_COLUMN_ICON = 0,
	XNOISE_BROWSER_COLUMN_VIS_TEXT,
	XNOISE_BROWSER_COLUMN_DB_ID,
	XNOISE_BROWSER_COLUMN_MEDIATYPE,
	XNOISE_BROWSER_COLUMN_COLL_TYPE,
	XNOISE_BROWSER_COLUMN_N_COLUMNS
} XnoiseBrowserColumn;

typedef enum  {
	XNOISE_BROWSER_COLLECTION_TYPE_UNKNOWN = 0,
	XNOISE_BROWSER_COLLECTION_TYPE_HIERARCHICAL = 1,
	XNOISE_BROWSER_COLLECTION_TYPE_LISTED = 2
} XnoiseBrowserCollectionType;

typedef enum  {
	XNOISE_REPEAT_NOT_AT_ALL = 0,
	XNOISE_REPEAT_SINGLE,
	XNOISE_REPEAT_ALL
} XnoiseRepeat;

typedef enum  {
	XNOISE_TRACK_LIST_COLUMN_STATE = 0,
	XNOISE_TRACK_LIST_COLUMN_ICON,
	XNOISE_TRACK_LIST_COLUMN_TRACKNUMBER,
	XNOISE_TRACK_LIST_COLUMN_TITLE,
	XNOISE_TRACK_LIST_COLUMN_ALBUM,
	XNOISE_TRACK_LIST_COLUMN_ARTIST,
	XNOISE_TRACK_LIST_COLUMN_URI,
	XNOISE_TRACK_LIST_COLUMN_N_COLUMNS
} XnoiseTrackListColumn;

typedef enum  {
	GST_STREAM_TYPE_UNKNOWN = 0,
	GST_STREAM_TYPE_AUDIO = 1,
	GST_STREAM_TYPE_VIDEO = 2
} GstStreamType;

struct _XnoiseVideoScreen {
	GtkDrawingArea parent_instance;
	XnoiseVideoScreenPrivate * priv;
	GdkPixbuf* logo_pixb;
};

struct _XnoiseVideoScreenClass {
	GtkDrawingAreaClass parent_class;
};

struct _XnoiseSettingsDialog {
	GtkBuilder parent_instance;
	XnoiseSettingsDialogPrivate * priv;
	GtkDialog* dialog;
};

struct _XnoiseSettingsDialogClass {
	GtkBuilderClass parent_class;
};

struct _XnoisePlugin {
	GObject parent_instance;
	XnoisePluginPrivate * priv;
};

struct _XnoisePluginClass {
	GObjectClass parent_class;
};

struct _XnoisePluginLoader {
	GObject parent_instance;
	XnoisePluginLoaderPrivate * priv;
	GHashTable* plugin_htable;
};

struct _XnoisePluginLoaderClass {
	GObjectClass parent_class;
};

struct _XnoisePluginInformation {
	GObject parent_instance;
	XnoisePluginInformationPrivate * priv;
};

struct _XnoisePluginInformationClass {
	GObjectClass parent_class;
};

struct _XnoiseIPluginIface {
	GTypeInterface parent_iface;
	gboolean (*init) (XnoiseIPlugin* self);
	gboolean (*has_settings_widget) (XnoiseIPlugin* self);
	GtkWidget* (*get_settings_widget) (XnoiseIPlugin* self);
	const char* (*get_name) (XnoiseIPlugin* self);
	XnoiseMain* (*get_xn) (XnoiseIPlugin* self);
	void (*set_xn) (XnoiseIPlugin* self, XnoiseMain* value);
};

struct _XnoisePluginManagerTree {
	GtkTreeView parent_instance;
	XnoisePluginManagerTreePrivate * priv;
};

struct _XnoisePluginManagerTreeClass {
	GtkTreeViewClass parent_class;
};

struct _XnoiseAlbumImage {
	GtkFixed parent_instance;
	XnoiseAlbumImagePrivate * priv;
	GtkImage* albumimage;
	GtkImage* albumimage_overlay;
};

struct _XnoiseAlbumImageClass {
	GtkFixedClass parent_class;
};


GType xnoise_app_starter_get_type (void);
GType xnoise_main_get_type (void);
extern XnoiseMain* xnoise_app_starter_xn;
UniqueResponse xnoise_app_starter_on_message_received (UniqueApp* sender, gint command, UniqueMessageData* message_data, guint time);
gint xnoise_app_starter_main (char** args, int args_length1);
XnoiseAppStarter* xnoise_app_starter_new (void);
XnoiseAppStarter* xnoise_app_starter_construct (GType object_type);
GType xnoise_main_window_get_type (void);
GType xnoise_plugin_loader_get_type (void);
GType xnoise_gst_player_get_type (void);
XnoiseMain* xnoise_main_new (void);
XnoiseMain* xnoise_main_construct (GType object_type);
void xnoise_main_add_track_to_gst_player (XnoiseMain* self, const char* uri);
XnoiseMain* xnoise_main_instance (void);
void xnoise_main_save_tracklist (XnoiseMain* self);
void xnoise_main_quit (XnoiseMain* self);
GType xnoise_video_screen_get_type (void);
XnoiseGstPlayer* xnoise_gst_player_new (void);
XnoiseGstPlayer* xnoise_gst_player_construct (GType object_type);
void xnoise_gst_player_play (XnoiseGstPlayer* self);
void xnoise_gst_player_pause (XnoiseGstPlayer* self);
void xnoise_gst_player_stop (XnoiseGstPlayer* self);
void xnoise_gst_player_playSong (XnoiseGstPlayer* self, gboolean force_play);
gint64 xnoise_gst_player_get_length_time (XnoiseGstPlayer* self);
void xnoise_gst_player_set_length_time (XnoiseGstPlayer* self, gint64 value);
gboolean xnoise_gst_player_get_seeking (XnoiseGstPlayer* self);
void xnoise_gst_player_set_seeking (XnoiseGstPlayer* self, gboolean value);
gboolean xnoise_gst_player_get_current_has_video (XnoiseGstPlayer* self);
void xnoise_gst_player_set_current_has_video (XnoiseGstPlayer* self, gboolean value);
double xnoise_gst_player_get_volume (XnoiseGstPlayer* self);
void xnoise_gst_player_set_volume (XnoiseGstPlayer* self, double value);
gboolean xnoise_gst_player_get_playing (XnoiseGstPlayer* self);
void xnoise_gst_player_set_playing (XnoiseGstPlayer* self, gboolean value);
gboolean xnoise_gst_player_get_paused (XnoiseGstPlayer* self);
void xnoise_gst_player_set_paused (XnoiseGstPlayer* self, gboolean value);
const char* xnoise_gst_player_get_currentartist (XnoiseGstPlayer* self);
const char* xnoise_gst_player_get_currentalbum (XnoiseGstPlayer* self);
const char* xnoise_gst_player_get_currenttitle (XnoiseGstPlayer* self);
GstTagList* xnoise_gst_player_get_taglist (XnoiseGstPlayer* self);
const char* xnoise_gst_player_get_Uri (XnoiseGstPlayer* self);
void xnoise_gst_player_set_Uri (XnoiseGstPlayer* self, const char* value);
void xnoise_gst_player_set_gst_position (XnoiseGstPlayer* self, double value);
GType xnoise_iparams_get_type (void);
GType xnoise_main_window_play_pause_button_get_type (void);
GType xnoise_main_window_previous_button_get_type (void);
GType xnoise_main_window_next_button_get_type (void);
GType xnoise_main_window_stop_button_get_type (void);
GType xnoise_album_image_get_type (void);
GType xnoise_main_window_song_progress_bar_get_type (void);
GType xnoise_media_browser_get_type (void);
GType xnoise_track_list_get_type (void);
GtkUIManager* xnoise_main_window_get_ui_manager (XnoiseMainWindow* self);
XnoiseMainWindow* xnoise_main_window_new (XnoiseMain** xn);
XnoiseMainWindow* xnoise_main_window_construct (GType object_type, XnoiseMain** xn);
GType xnoise_direction_get_type (void);
void xnoise_main_window_change_song (XnoiseMainWindow* self, XnoiseDirection direction, gboolean handle_repeat_state);
void xnoise_main_window_set_displayed_title (XnoiseMainWindow* self, const char* newuri);
gint xnoise_main_window_get_repeatState (XnoiseMainWindow* self);
void xnoise_main_window_set_repeatState (XnoiseMainWindow* self, gint value);
gboolean xnoise_main_window_get_fullscreenwindowvisible (XnoiseMainWindow* self);
void xnoise_main_window_set_fullscreenwindowvisible (XnoiseMainWindow* self, gboolean value);
XnoiseMainWindowNextButton* xnoise_main_window_next_button_new (void);
XnoiseMainWindowNextButton* xnoise_main_window_next_button_construct (GType object_type);
void xnoise_main_window_next_button_on_clicked (XnoiseMainWindowNextButton* self);
XnoiseMainWindowPreviousButton* xnoise_main_window_previous_button_new (void);
XnoiseMainWindowPreviousButton* xnoise_main_window_previous_button_construct (GType object_type);
void xnoise_main_window_previous_button_on_clicked (XnoiseMainWindowPreviousButton* self);
XnoiseMainWindowStopButton* xnoise_main_window_stop_button_new (void);
XnoiseMainWindowStopButton* xnoise_main_window_stop_button_construct (GType object_type);
XnoiseMainWindowPlayPauseButton* xnoise_main_window_play_pause_button_new (void);
XnoiseMainWindowPlayPauseButton* xnoise_main_window_play_pause_button_construct (GType object_type);
void xnoise_main_window_play_pause_button_on_clicked (XnoiseMainWindowPlayPauseButton* self);
void xnoise_main_window_play_pause_button_update_picture (XnoiseMainWindowPlayPauseButton* self);
void xnoise_main_window_play_pause_button_set_play_picture (XnoiseMainWindowPlayPauseButton* self);
void xnoise_main_window_play_pause_button_set_pause_picture (XnoiseMainWindowPlayPauseButton* self);
XnoiseMainWindowSongProgressBar* xnoise_main_window_song_progress_bar_new (void);
XnoiseMainWindowSongProgressBar* xnoise_main_window_song_progress_bar_construct (GType object_type);
void xnoise_main_window_song_progress_bar_set_value (XnoiseMainWindowSongProgressBar* self, guint pos, guint len);
GType xnoise_main_window_volume_slider_button_get_type (void);
XnoiseMainWindowVolumeSliderButton* xnoise_main_window_volume_slider_button_new (void);
XnoiseMainWindowVolumeSliderButton* xnoise_main_window_volume_slider_button_construct (GType object_type);
GType xnoise_about_dialog_get_type (void);
XnoiseAboutDialog* xnoise_about_dialog_new (void);
XnoiseAboutDialog* xnoise_about_dialog_construct (GType object_type);
GType xnoise_params_get_type (void);
XnoiseParams* xnoise_params_new (void);
XnoiseParams* xnoise_params_construct (GType object_type);
void xnoise_params_iparams_register (XnoiseParams* self, XnoiseIParams* iparam);
void xnoise_params_set_start_parameters_in_implementors (XnoiseParams* self);
void xnoise_params_write_all_parameters_to_file (XnoiseParams* self);
gint xnoise_params_get_int_value (XnoiseParams* self, const char* key);
double xnoise_params_get_double_value (XnoiseParams* self, const char* key);
char** xnoise_params_get_string_list_value (XnoiseParams* self, const char* key, int* result_length1);
char* xnoise_params_get_string_value (XnoiseParams* self, const char* key);
void xnoise_params_set_int_value (XnoiseParams* self, const char* key, gint value);
void xnoise_params_set_double_value (XnoiseParams* self, const char* key, double value);
void xnoise_params_set_string_list_value (XnoiseParams* self, const char* key, char** value, int value_length1);
void xnoise_params_set_string_value (XnoiseParams* self, const char* key, const char* value);
GType xnoise_db_browser_get_type (void);
XnoiseDbBrowser* xnoise_db_browser_new (void);
XnoiseDbBrowser* xnoise_db_browser_construct (GType object_type);
gboolean xnoise_db_browser_videos_available (XnoiseDbBrowser* self);
gboolean xnoise_db_browser_uri_is_in_db (XnoiseDbBrowser* self, const char* uri);
gboolean xnoise_db_browser_get_uri_for_id (XnoiseDbBrowser* self, gint id, char** val);
GType xnoise_track_data_get_type (void);
GType xnoise_media_type_get_type (void);
XnoiseTrackData* xnoise_track_data_dup (const XnoiseTrackData* self);
void xnoise_track_data_free (XnoiseTrackData* self);
void xnoise_track_data_copy (const XnoiseTrackData* self, XnoiseTrackData* dest);
void xnoise_track_data_destroy (XnoiseTrackData* self);
gboolean xnoise_db_browser_get_trackdata_for_id (XnoiseDbBrowser* self, gint id, XnoiseTrackData* val);
gboolean xnoise_db_browser_get_trackdata_for_uri (XnoiseDbBrowser* self, const char* uri, XnoiseTrackData* val);
gint xnoise_db_browser_get_track_id_for_path (XnoiseDbBrowser* self, const char* uri);
char* xnoise_db_browser_get_uri_for_title (XnoiseDbBrowser* self, const char* artist, const char* album, const char* title);
gint xnoise_db_browser_get_tracknumber_for_title (XnoiseDbBrowser* self, const char* artist, const char* album, const char* title);
char** xnoise_db_browser_get_lastused_uris (XnoiseDbBrowser* self, int* result_length1);
GType xnoise_title_mtype_id_get_type (void);
XnoiseTitle_MType_Id* xnoise_title_mtype_id_dup (const XnoiseTitle_MType_Id* self);
void xnoise_title_mtype_id_free (XnoiseTitle_MType_Id* self);
void xnoise_title_mtype_id_copy (const XnoiseTitle_MType_Id* self, XnoiseTitle_MType_Id* dest);
void xnoise_title_mtype_id_destroy (XnoiseTitle_MType_Id* self);
XnoiseTitle_MType_Id* xnoise_db_browser_get_video_data (XnoiseDbBrowser* self, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_videos (XnoiseDbBrowser* self, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_artists (XnoiseDbBrowser* self, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_albums (XnoiseDbBrowser* self, const char* artist, char** searchtext, int* result_length1);
XnoiseTitle_MType_Id* xnoise_db_browser_get_titles_with_mediatypes_and_ids (XnoiseDbBrowser* self, const char* artist, const char* album, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_titles (XnoiseDbBrowser* self, const char* artist, const char* album, char** searchtext, int* result_length1);
GType xnoise_db_writer_get_type (void);
XnoiseDbWriter* xnoise_db_writer_new (void);
XnoiseDbWriter* xnoise_db_writer_construct (GType object_type);
char** xnoise_db_writer_get_music_folders (XnoiseDbWriter* self, int* result_length1);
void xnoise_db_writer_write_music_folder_into_db (XnoiseDbWriter* self, char** mfolders, int mfolders_length1);
void xnoise_db_writer_begin_transaction (XnoiseDbWriter* self);
void xnoise_db_writer_commit_transaction (XnoiseDbWriter* self);
void xnoise_db_writer_write_final_tracks_to_db (XnoiseDbWriter* self, char** final_tracklist, int final_tracklist_length1);
XnoiseMediaBrowser* xnoise_media_browser_new (XnoiseMain** xn);
XnoiseMediaBrowser* xnoise_media_browser_construct (GType object_type, XnoiseMain** xn);
void xnoise_media_browser_on_searchtext_changed (XnoiseMediaBrowser* self, GtkEntry* sender);
gboolean xnoise_media_browser_on_button_press (XnoiseMediaBrowser* self, XnoiseMediaBrowser* sender, const GdkEventButton* e);
gboolean xnoise_media_browser_on_button_release (XnoiseMediaBrowser* self, XnoiseMediaBrowser* sender, const GdkEventButton* e);
void xnoise_media_browser_on_drag_data_get (XnoiseMediaBrowser* self, XnoiseMediaBrowser* sender, GdkDragContext* context, GtkSelectionData* selection, guint info, guint etime);
XnoiseTrackData* xnoise_media_browser_get_trackdata_for_treepath (XnoiseMediaBrowser* self, const GtkTreePath* path, int* result_length1);
void xnoise_media_browser_on_drag_end (XnoiseMediaBrowser* self, XnoiseMediaBrowser* sender, GdkDragContext* context);
gboolean xnoise_media_browser_change_model_data (XnoiseMediaBrowser* self);
XnoiseTrackList* xnoise_track_list_new (XnoiseMain** xn);
XnoiseTrackList* xnoise_track_list_construct (GType object_type, XnoiseMain** xn);
gboolean xnoise_track_list_on_button_press (XnoiseTrackList* self, XnoiseTrackList* sender, const GdkEventButton* e);
gboolean xnoise_track_list_on_button_release (XnoiseTrackList* self, XnoiseTrackList* sender, const GdkEventButton* e);
gboolean xnoise_track_list_on_drag_motion (XnoiseTrackList* self, XnoiseTrackList* sender, GdkDragContext* context, gint x, gint y, guint timestamp);
void xnoise_track_list_on_drag_end (XnoiseTrackList* self, XnoiseTrackList* sender, GdkDragContext* context);
void xnoise_track_list_on_drag_data_get (XnoiseTrackList* self, XnoiseTrackList* sender, GdkDragContext* context, GtkSelectionData* selection, guint target_type, guint etime);
char** xnoise_track_list_get_all_tracks (XnoiseTrackList* self, int* result_length1);
void xnoise_track_list_add_uris (XnoiseTrackList* self, char** uris, int uris_length1);
GType xnoise_track_state_get_type (void);
GtkTreeIter xnoise_track_list_insert_title (XnoiseTrackList* self, XnoiseTrackState status, GdkPixbuf* pixbuf, gint tracknumber, const char* title, const char* album, const char* artist, const char* uri);
void xnoise_track_list_set_state_picture_for_title (XnoiseTrackList* self, GtkTreeIter* iter, XnoiseTrackState state);
gboolean xnoise_track_list_set_play_state_for_first_song (XnoiseTrackList* self);
gboolean xnoise_track_list_set_play_state (XnoiseTrackList* self);
gboolean xnoise_track_list_set_pause_state (XnoiseTrackList* self);
void xnoise_track_list_set_focus_on_iter (XnoiseTrackList* self, GtkTreeIter* iter);
void xnoise_track_list_remove_selected_rows (XnoiseTrackList* self);
gboolean xnoise_track_list_not_empty (XnoiseTrackList* self);
void xnoise_track_list_reset_play_status_all_titles (XnoiseTrackList* self);
gboolean xnoise_track_list_get_active_path (XnoiseTrackList* self, GtkTreePath** path, XnoiseTrackState* currentstate, gboolean* is_first);
void xnoise_track_list_on_activated (XnoiseTrackList* self, const char* uri, const GtkTreePath* path);
char* xnoise_track_list_get_uri_for_path (XnoiseTrackList* self, const GtkTreePath* path);
extern XnoiseParams* xnoise_par;
void xnoise_initialize (void);
char* xnoise_remove_linebreaks (const char* value);
GType xnoise_browser_column_get_type (void);
GType xnoise_browser_collection_type_get_type (void);
GType xnoise_repeat_get_type (void);
GType xnoise_track_list_column_get_type (void);
GType gst_stream_type_get_type (void);
void xnoise_iparams_read_params_data (XnoiseIParams* self);
void xnoise_iparams_write_params_data (XnoiseIParams* self);
XnoiseVideoScreen* xnoise_video_screen_new (void);
XnoiseVideoScreen* xnoise_video_screen_construct (GType object_type);
GType xnoise_settings_dialog_get_type (void);
XnoiseSettingsDialog* xnoise_settings_dialog_new (XnoiseMain** xn);
XnoiseSettingsDialog* xnoise_settings_dialog_construct (GType object_type, XnoiseMain** xn);
GType xnoise_plugin_get_type (void);
GType xnoise_plugin_information_get_type (void);
XnoisePlugin* xnoise_plugin_new (XnoisePluginInformation* info);
XnoisePlugin* xnoise_plugin_construct (GType object_type, XnoisePluginInformation* info);
gboolean xnoise_plugin_load (XnoisePlugin* self, XnoiseMain** xn);
GtkWidget* xnoise_plugin_settingwidget (XnoisePlugin* self);
gboolean xnoise_plugin_get_loaded (XnoisePlugin* self);
gboolean xnoise_plugin_get_activated (XnoisePlugin* self);
void xnoise_plugin_set_activated (XnoisePlugin* self, gboolean value);
gboolean xnoise_plugin_get_configurable (XnoisePlugin* self);
XnoisePluginLoader* xnoise_plugin_loader_new (XnoiseMain** xn);
XnoisePluginLoader* xnoise_plugin_loader_construct (GType object_type, XnoiseMain** xn);
GList* xnoise_plugin_loader_get_info_files (XnoisePluginLoader* self);
gboolean xnoise_plugin_loader_load_all (XnoisePluginLoader* self);
gboolean xnoise_plugin_loader_activate_single_plugin (XnoisePluginLoader* self, const char* name);
void xnoise_plugin_loader_deactivate_single_plugin (XnoisePluginLoader* self, const char* name);
XnoisePluginInformation* xnoise_plugin_information_new (const char* xplug_file);
XnoisePluginInformation* xnoise_plugin_information_construct (GType object_type, const char* xplug_file);
gboolean xnoise_plugin_information_load_info (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_xplug_file (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_name (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_icon (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_module (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_description (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_website (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_license (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_copyright (XnoisePluginInformation* self);
const char* xnoise_plugin_information_get_author (XnoisePluginInformation* self);
GType xnoise_iplugin_get_type (void);
gboolean xnoise_iplugin_init (XnoiseIPlugin* self);
gboolean xnoise_iplugin_has_settings_widget (XnoiseIPlugin* self);
GtkWidget* xnoise_iplugin_get_settings_widget (XnoiseIPlugin* self);
const char* xnoise_iplugin_get_name (XnoiseIPlugin* self);
XnoiseMain* xnoise_iplugin_get_xn (XnoiseIPlugin* self);
void xnoise_iplugin_set_xn (XnoiseIPlugin* self, XnoiseMain* value);
GType xnoise_plugin_manager_tree_get_type (void);
XnoisePluginManagerTree* xnoise_plugin_manager_tree_new (XnoiseMain** xn);
XnoisePluginManagerTree* xnoise_plugin_manager_tree_construct (GType object_type, XnoiseMain** xn);
void xnoise_plugin_manager_tree_create_view (XnoisePluginManagerTree* self);
XnoiseAlbumImage* xnoise_album_image_new (void);
XnoiseAlbumImage* xnoise_album_image_construct (GType object_type);
void xnoise_album_image_find_album_image (XnoiseAlbumImage* self, const char* uri);
void xnoise_album_image_find_google_image (XnoiseAlbumImage* self, const char* search_term);
void* xnoise_album_image_set_albumimage_from_goo (XnoiseAlbumImage* self);


G_END_DECLS

#endif
