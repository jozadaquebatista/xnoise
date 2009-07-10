
#ifndef ____XNOISE_H__
#define ____XNOISE_H__

#include <glib.h>
#include <glib-object.h>
#include <unique/unique.h>
#include <stdlib.h>
#include <string.h>
#include <gst/gst.h>
#include <gtk/gtk.h>
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

#define XNOISE_TYPE_PLUGIN (xnoise_plugin_get_type ())
#define XNOISE_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_PLUGIN, XnoisePlugin))
#define XNOISE_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_PLUGIN, XnoisePluginClass))
#define XNOISE_IS_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_PLUGIN))
#define XNOISE_IS_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_PLUGIN))
#define XNOISE_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_PLUGIN, XnoisePluginClass))

typedef struct _XnoisePlugin XnoisePlugin;
typedef struct _XnoisePluginClass XnoisePluginClass;
typedef struct _XnoiseGstPlayerPrivate XnoiseGstPlayerPrivate;

#define XNOISE_TYPE_IPARAMS (xnoise_iparams_get_type ())
#define XNOISE_IPARAMS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_IPARAMS, XnoiseIParams))
#define XNOISE_IS_IPARAMS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_IPARAMS))
#define XNOISE_IPARAMS_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), XNOISE_TYPE_IPARAMS, XnoiseIParamsIface))

typedef struct _XnoiseIParams XnoiseIParams;
typedef struct _XnoiseIParamsIface XnoiseIParamsIface;
typedef struct _XnoiseMainWindowPrivate XnoiseMainWindowPrivate;

#define XNOISE_TYPE_ALBUM_IMAGE (xnoise_album_image_get_type ())
#define XNOISE_ALBUM_IMAGE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImage))
#define XNOISE_ALBUM_IMAGE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImageClass))
#define XNOISE_IS_ALBUM_IMAGE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_ALBUM_IMAGE))
#define XNOISE_IS_ALBUM_IMAGE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_ALBUM_IMAGE))
#define XNOISE_ALBUM_IMAGE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_ALBUM_IMAGE, XnoiseAlbumImageClass))

typedef struct _XnoiseAlbumImage XnoiseAlbumImage;
typedef struct _XnoiseAlbumImageClass XnoiseAlbumImageClass;

#define XNOISE_TYPE_MUSIC_BROWSER (xnoise_music_browser_get_type ())
#define XNOISE_MUSIC_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_MUSIC_BROWSER, XnoiseMusicBrowser))
#define XNOISE_MUSIC_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_MUSIC_BROWSER, XnoiseMusicBrowserClass))
#define XNOISE_IS_MUSIC_BROWSER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_MUSIC_BROWSER))
#define XNOISE_IS_MUSIC_BROWSER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_MUSIC_BROWSER))
#define XNOISE_MUSIC_BROWSER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_MUSIC_BROWSER, XnoiseMusicBrowserClass))

typedef struct _XnoiseMusicBrowser XnoiseMusicBrowser;
typedef struct _XnoiseMusicBrowserClass XnoiseMusicBrowserClass;

#define XNOISE_TYPE_TRACK_LIST (xnoise_track_list_get_type ())
#define XNOISE_TRACK_LIST(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_TRACK_LIST, XnoiseTrackList))
#define XNOISE_TRACK_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_TRACK_LIST, XnoiseTrackListClass))
#define XNOISE_IS_TRACK_LIST(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_TRACK_LIST))
#define XNOISE_IS_TRACK_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_TRACK_LIST))
#define XNOISE_TRACK_LIST_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_TRACK_LIST, XnoiseTrackListClass))

typedef struct _XnoiseTrackList XnoiseTrackList;
typedef struct _XnoiseTrackListClass XnoiseTrackListClass;

#define XNOISE_TYPE_DIRECTION (xnoise_direction_get_type ())

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
typedef struct _XnoiseTrackData XnoiseTrackData;

#define XNOISE_TYPE_DB_WRITER (xnoise_db_writer_get_type ())
#define XNOISE_DB_WRITER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_DB_WRITER, XnoiseDbWriter))
#define XNOISE_DB_WRITER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_DB_WRITER, XnoiseDbWriterClass))
#define XNOISE_IS_DB_WRITER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_DB_WRITER))
#define XNOISE_IS_DB_WRITER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_DB_WRITER))
#define XNOISE_DB_WRITER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_DB_WRITER, XnoiseDbWriterClass))

typedef struct _XnoiseDbWriter XnoiseDbWriter;
typedef struct _XnoiseDbWriterClass XnoiseDbWriterClass;
typedef struct _XnoiseDbWriterPrivate XnoiseDbWriterPrivate;
typedef struct _XnoiseMusicBrowserPrivate XnoiseMusicBrowserPrivate;
typedef struct _XnoiseTrackListPrivate XnoiseTrackListPrivate;

#define XNOISE_TYPE_TRACK_STATE (xnoise_track_state_get_type ())

#define XNOISE_TYPE_BROWSER_COLUMN (xnoise_browser_column_get_type ())

#define XNOISE_TYPE_REPEAT (xnoise_repeat_get_type ())

#define XNOISE_TYPE_TRACK_LIST_COLUMN (xnoise_track_list_column_get_type ())

#define GST_TYPE_STREAM_TYPE (gst_stream_type_get_type ())

#define XNOISE_TYPE_SETTINGS_DIALOG (xnoise_settings_dialog_get_type ())
#define XNOISE_SETTINGS_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialog))
#define XNOISE_SETTINGS_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialogClass))
#define XNOISE_IS_SETTINGS_DIALOG(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XNOISE_TYPE_SETTINGS_DIALOG))
#define XNOISE_IS_SETTINGS_DIALOG_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XNOISE_TYPE_SETTINGS_DIALOG))
#define XNOISE_SETTINGS_DIALOG_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XNOISE_TYPE_SETTINGS_DIALOG, XnoiseSettingsDialogClass))

typedef struct _XnoiseSettingsDialog XnoiseSettingsDialog;
typedef struct _XnoiseSettingsDialogClass XnoiseSettingsDialogClass;
typedef struct _XnoiseSettingsDialogPrivate XnoiseSettingsDialogPrivate;
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
	XnoisePlugin* plugin;
};

struct _XnoiseMainClass {
	GObjectClass parent_class;
};

struct _XnoiseGstPlayer {
	GObject parent_instance;
	XnoiseGstPlayerPrivate * priv;
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
	GObject parent_instance;
	XnoiseMainWindowPrivate * priv;
	GtkDrawingArea* videodrawingarea;
	GtkLabel* showvideolabel;
	GtkEntry* searchEntryMB;
	GtkButton* playPauseButton;
	GtkButton* repeatButton;
	GtkNotebook* browsernotebook;
	GtkNotebook* tracklistnotebook;
	GtkImage* repeatImage;
	XnoiseAlbumImage* albumimage;
	GtkLabel* repeatLabel;
	GtkProgressBar* songProgressBar;
	double current_volume;
	XnoiseMusicBrowser* musicBr;
	XnoiseTrackList* trackList;
	GtkWindow* window;
	GtkImage* playpause_popup_image;
};

struct _XnoiseMainWindowClass {
	GObjectClass parent_class;
};

typedef enum  {
	XNOISE_DIRECTION_NEXT = 0,
	XNOISE_DIRECTION_PREVIOUS
} XnoiseDirection;

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

struct _XnoiseTrackData {
	char* Artist;
	char* Album;
	char* Title;
	char* Genre;
	guint Tracknumber;
};

struct _XnoiseDbWriter {
	GObject parent_instance;
	XnoiseDbWriterPrivate * priv;
};

struct _XnoiseDbWriterClass {
	GObjectClass parent_class;
};

struct _XnoiseMusicBrowser {
	GtkTreeView parent_instance;
	XnoiseMusicBrowserPrivate * priv;
	GtkTreeStore* model;
	gint fontsizeMB;
};

struct _XnoiseMusicBrowserClass {
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
	XNOISE_BROWSER_COLUMN_N_COLUMNS
} XnoiseBrowserColumn;

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
GType xnoise_plugin_get_type (void);
XnoiseMain* xnoise_main_new (void);
XnoiseMain* xnoise_main_construct (GType object_type);
void xnoise_main_add_track_to_gst_player (XnoiseMain* self, const char* uri);
XnoiseMain* xnoise_main_instance (void);
void xnoise_main_save_tracklist (XnoiseMain* self);
void xnoise_main_quit (XnoiseMain* self);
XnoiseGstPlayer* xnoise_gst_player_new (GtkDrawingArea** da);
XnoiseGstPlayer* xnoise_gst_player_construct (GType object_type, GtkDrawingArea** da);
void xnoise_gst_player_play (XnoiseGstPlayer* self);
void xnoise_gst_player_pause (XnoiseGstPlayer* self);
void xnoise_gst_player_stop (XnoiseGstPlayer* self);
void xnoise_gst_player_playSong (XnoiseGstPlayer* self);
gboolean xnoise_gst_player_get_seeking (XnoiseGstPlayer* self);
void xnoise_gst_player_set_seeking (XnoiseGstPlayer* self, gboolean value);
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
GType xnoise_album_image_get_type (void);
GType xnoise_music_browser_get_type (void);
GType xnoise_track_list_get_type (void);
GtkUIManager* xnoise_main_window_get_ui_manager (XnoiseMainWindow* self);
XnoiseMainWindow* xnoise_main_window_new (XnoiseMain** xn);
XnoiseMainWindow* xnoise_main_window_construct (GType object_type, XnoiseMain** xn);
void xnoise_main_window_playpause_button_set_play_picture (XnoiseMainWindow* self);
void xnoise_main_window_playpause_button_set_pause_picture (XnoiseMainWindow* self);
GType xnoise_direction_get_type (void);
void xnoise_main_window_change_song (XnoiseMainWindow* self, XnoiseDirection direction, gboolean handle_repeat_state);
void xnoise_main_window_progressbar_set_value (XnoiseMainWindow* self, guint pos, guint len);
void xnoise_main_window_set_displayed_title (XnoiseMainWindow* self, const char* newuri);
gint xnoise_main_window_get_repeatState (XnoiseMainWindow* self);
void xnoise_main_window_set_repeatState (XnoiseMainWindow* self, gint value);
GType xnoise_about_dialog_get_type (void);
XnoiseAboutDialog* xnoise_about_dialog_new (void);
XnoiseAboutDialog* xnoise_about_dialog_construct (GType object_type);
GType xnoise_params_get_type (void);
XnoiseParams* xnoise_params_new (void);
XnoiseParams* xnoise_params_construct (GType object_type);
void xnoise_params_data_register (XnoiseParams* self, XnoiseIParams* iparam);
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
gboolean xnoise_db_browser_uri_is_in_db (XnoiseDbBrowser* self, const char* uri);
GType xnoise_track_data_get_type (void);
XnoiseTrackData* xnoise_track_data_dup (const XnoiseTrackData* self);
void xnoise_track_data_free (XnoiseTrackData* self);
void xnoise_track_data_copy (const XnoiseTrackData* self, XnoiseTrackData* dest);
void xnoise_track_data_destroy (XnoiseTrackData* self);
gboolean xnoise_db_browser_get_trackdata_for_uri (XnoiseDbBrowser* self, const char* uri, XnoiseTrackData* val);
gint xnoise_db_browser_get_track_id_for_path (XnoiseDbBrowser* self, const char* uri);
char* xnoise_db_browser_get_uri_for_title (XnoiseDbBrowser* self, const char* artist, const char* album, const char* title);
gint xnoise_db_browser_get_tracknumber_for_title (XnoiseDbBrowser* self, const char* artist, const char* album, const char* title);
char** xnoise_db_browser_get_lastused_uris (XnoiseDbBrowser* self, int* result_length1);
char** xnoise_db_browser_get_artists (XnoiseDbBrowser* self, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_albums (XnoiseDbBrowser* self, const char* artist, char** searchtext, int* result_length1);
char** xnoise_db_browser_get_titles (XnoiseDbBrowser* self, const char* artist, const char* album, char** searchtext, int* result_length1);
GType xnoise_db_writer_get_type (void);
XnoiseDbWriter* xnoise_db_writer_new (void);
XnoiseDbWriter* xnoise_db_writer_construct (GType object_type);
char** xnoise_db_writer_get_music_folders (XnoiseDbWriter* self, int* result_length1);
void xnoise_db_writer_write_music_folder_into_db (XnoiseDbWriter* self, char** mfolders, int mfolders_length1);
void xnoise_db_writer_begin_transaction (XnoiseDbWriter* self);
void xnoise_db_writer_commit_transaction (XnoiseDbWriter* self);
void xnoise_db_writer_write_final_tracks_to_db (XnoiseDbWriter* self, char** final_tracklist, int final_tracklist_length1);
XnoiseMusicBrowser* xnoise_music_browser_new (void);
XnoiseMusicBrowser* xnoise_music_browser_construct (GType object_type);
void xnoise_music_browser_on_searchtext_changed (XnoiseMusicBrowser* self, GtkEntry* sender);
gboolean xnoise_music_browser_on_button_press (XnoiseMusicBrowser* self, XnoiseMusicBrowser* sender, const GdkEventButton* e);
gboolean xnoise_music_browser_on_button_release (XnoiseMusicBrowser* self, XnoiseMusicBrowser* sender, const GdkEventButton* e);
void xnoise_music_browser_on_drag_data_get (XnoiseMusicBrowser* self, XnoiseMusicBrowser* sender, GdkDragContext* context, GtkSelectionData* selection, guint info, guint etime);
void xnoise_music_browser_on_drag_end (XnoiseMusicBrowser* self, XnoiseMusicBrowser* sender, GdkDragContext* context);
gboolean xnoise_music_browser_change_model_data (XnoiseMusicBrowser* self);
XnoiseTrackList* xnoise_track_list_new (void);
XnoiseTrackList* xnoise_track_list_construct (GType object_type);
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
void xnoise_track_list_set_play_picture (XnoiseTrackList* self);
void xnoise_track_list_set_pause_picture (XnoiseTrackList* self);
void xnoise_track_list_set_focus_on_iter (XnoiseTrackList* self, GtkTreeIter* iter);
void xnoise_track_list_remove_selected_row (XnoiseTrackList* self);
gboolean xnoise_track_list_not_empty (XnoiseTrackList* self);
void xnoise_track_list_reset_play_status_for_title (XnoiseTrackList* self);
gboolean xnoise_track_list_get_active_path (XnoiseTrackList* self, GtkTreePath** path);
void xnoise_track_list_on_activated (XnoiseTrackList* self, const char* uri, const GtkTreePath* path);
char* xnoise_track_list_get_uri_for_path (XnoiseTrackList* self, const GtkTreePath* path);
extern XnoiseParams* xnoise_par;
void xnoise_initialize (void);
GType xnoise_browser_column_get_type (void);
GType xnoise_repeat_get_type (void);
GType xnoise_track_list_column_get_type (void);
GType gst_stream_type_get_type (void);
void xnoise_iparams_read_params_data (XnoiseIParams* self);
void xnoise_iparams_write_params_data (XnoiseIParams* self);
GType xnoise_settings_dialog_get_type (void);
XnoiseSettingsDialog* xnoise_settings_dialog_new (XnoiseMain** xn);
XnoiseSettingsDialog* xnoise_settings_dialog_construct (GType object_type, XnoiseMain** xn);
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
