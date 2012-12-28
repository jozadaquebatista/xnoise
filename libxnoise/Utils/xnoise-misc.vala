/* xnoise-misc.vala
 *
 * Copyright (C) 2009-2011  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 *     Jörn Magens
 */

using Xnoise;
using Xnoise.Utilities;
using Xnoise.Resources;
using Xnoise.Database;
using Xnoise.PluginModule;
using Xnoise.ExtDev;



namespace Xnoise {
    public static Params par = null;
    public static GlobalAccess global = null;
    public static UserInfo userinfo = null;
    public static Worker db_worker = null;
    public static Worker io_worker = null;
    public static Worker cache_worker = null;
    public static Worker device_worker = null;
    
    public static MediaImporter media_importer = null;
    public static ItemHandlerManager itemhandler_manager = null;
    public static ItemConverter item_converter = null;
    public static Xnoise.DockableMediaManager dockable_media_sources;
    public static HashTable<int, Xnoise.DataSource>       data_source_registry;

    public static PatternSpec pattern_audio;
    public static PatternSpec pattern_video;

    private static HashTable<string,int> supported_types;

    public static Database.Reader db_reader;
    public static Database.Writer db_writer;
    
    private static Statistics statistics;
    
    internal static IconRepo icon_repo;
    internal static DbusThumbnailer thumbnailer = null;
    internal static DeviceManager device_manager;
    
    public static GstPlayer gst_player;
    
    public static PluginModule.Loader plugin_loader;
    
    public static MainWindow main_window;
    public static TrackList tl;
    public static TrackListModel tlm;
    
    public static TrayIcon tray_icon;
    
    private static RemoteSchemes        _remote_schemes;
    private static LocalSchemes         _local_schemes;
    private static MediaExtensions      _media_extensions;
    private static MediaStreamSchemes   _media_stream_schemes;
    private static DesktopNotifications _notifications;
    
    private static HashTable<int, uint32> _current_stamps;
    
    /*
     * This function is used to create static instances of Params
     * and GlobalInfo in the xnoise namespace.
     */
    private static void initialize(out bool is_first_start) {
        is_first_start = false;
        
        if(!verify_xnoise_directories()) {
            Main.instance.quit();
            return;
        }
        
        setup_pattern_specs();
        
        dockable_media_sources = new DockableMediaManager();
        data_source_registry   = new HashTable<int, Xnoise.DataSource>(direct_hash, direct_equal);
        
        _current_stamps   = new HashTable<int, uint32>(direct_hash, direct_equal);
        
        icon_repo = new IconRepo();
        
        // ITEM STUFF
        itemhandler_manager = new ItemHandlerManager();
        item_converter = new ItemConverter();
        
        // MEDIA IMPORTER
        media_importer = new MediaImporter();
        
        // WORKERS
        db_worker     = new Worker(MainContext.default());
        io_worker     = new Worker(MainContext.default());
        cache_worker  = new Worker(MainContext.default());
        device_worker = new Worker(MainContext.default());
        
        // THUMBNAILER DBUS PROXY
        thumbnailer = new DbusThumbnailer();
        
        _remote_schemes       = new RemoteSchemes();
        _local_schemes        = new LocalSchemes();
        _media_extensions     = new MediaExtensions();
        _media_stream_schemes = new MediaStreamSchemes();
        
        //GLOBAL ACCESS
        if(global == null)
            global = new GlobalAccess();
        
        File xnoise_data_home = File.new_for_path(data_folder());
        File xnoiseini = null;
        xnoiseini = xnoise_data_home.get_child(MAIN_DATABASE_NAME);
        if(!xnoiseini.query_exists(null))
            is_first_start = true;
        
        // PARAMS
        Params.init();
        int v = Params.get_int_value("fontsizeMB");
        // some early initializations
        global.fontsize_dockable = ((v >= 7 && v < 18) ? v : 10);
        global.collection_sort_mode = 
            (CollectionSortMode)Params.get_int_value("collection_sort_mode");
            //CollectionSortMode.GENRE_ARTIST_ALBUM;
        
        // DESKTOP NOTIFICATIONS
        _notifications = new DesktopNotifications();
        
        // DATABASE
        Database.DbCreator.check_tables(ref is_first_start);
        
        try {
            db_reader = new Database.Reader();
            db_writer  = new Database.Writer();
        }
        catch(DbError e) {
            print("%s", e.message);
            return;
        }
        register_data_source(db_reader);
        //print("source id: %d\n", dbid);
        
        statistics = new Statistics();
        
        // PLAYER
        gst_player = new GstPlayer();
        global.player = gst_player;
        
        // PLUGINS
        plugin_loader = new PluginModule.Loader();
        
        // DOCKABLE MEDIA
        DockableMedia d;
        d = new MusicBrowserDockable();         // LOCAL COLLECTION
        dockable_media_sources.insert(d.name(), d);
        d = new DockablePlaylistMostplayed();   // Dynamic Playlist Most played
        dockable_media_sources.insert(d.name(), d);
        d = new DockablePlaylistLastplayed();   // Dynamic Playlist Last played
        dockable_media_sources.insert(d.name(), d);
        d = new DockableVideos();               // VIDEOS
        dockable_media_sources.insert(d.name(), d);
        d = new DockableStreams();              // STREAMS
        dockable_media_sources.insert(d.name(), d);
        
        // STATIC WIDGETS
        tlm = new TrackListModel();
        tl = new TrackList();
        main_window = new MainWindow();
        if(!Params.get_bool_value("quit_if_closed"))
            tray_icon = new TrayIcon();
    }
    
    // A data source is an implementor of DataSoure abstr.class
    // (e.g the Database.Reader)
    public static DataSource? get_data_source(int source_number) {
        assert(data_source_registry != null);
        DataSource? ret = data_source_registry.lookup(source_number);
        return ret;
    }

    // A data source is an implementor of DataSoure abstr.class
    // (e.g the Database.Reader)
    // try not to use this function too often, because it is slow
    public static DataSource? get_data_source_by_name(string? name) {
        if(name == null || name == EMPTYSTRING)
            return null;
        assert(data_source_registry != null);
        foreach(int i in data_source_registry.get_keys()) {
            DataSource? ret = data_source_registry.lookup(i);
            if(ret != null && ret.get_datasource_name() == name)
                return ret;
        }
        return null;
    }

    public static int get_data_source_id_by_name(string? name) {
        if(name == null || name == EMPTYSTRING)
            return -1;
        assert(data_source_registry != null);
        foreach(int i in data_source_registry.get_keys()) {
            DataSource? ret = data_source_registry.lookup(i);
            if(ret != null && ret.get_datasource_name() == name)
                return i;
        }
        return -1;
    }

    // A data source is an implementor of DataSoure abstr.class
    // (e.g the Database.Reader)
    public static string? get_data_source_name(int source_number) {
        assert(data_source_registry != null);
        DataSource? ret = data_source_registry.lookup(source_number);
        if(ret != null)
            return ret.get_datasource_name();
        else
            return EMPTYSTRING;
    }

    public static int register_data_source(DataSource? source) {
        if(source == null)
            return -1;
        if(source.get_datasource_name() == null || source.get_datasource_name() == EMPTYSTRING)
            return -1;
        int idx = -1;
        for(int i = 0; i < int.MAX; i++) {
            DataSource? ret = data_source_registry.lookup(i);
            if(ret == null) {
                idx = i;
                break;
            }
        }
        source.set_source_id(idx);
        data_source_registry.insert(idx, source);
        _current_stamps.insert(source.get_source_id(), Random.next_int());
        return idx;
    }
    
    public static void remove_data_source(DataSource source) {
        assert(data_source_registry != null);
        if(source == null)
            return;
        for(int i = 0; i < int.MAX; i++) {
            DataSource? ret = data_source_registry.lookup(i);
            if(ret == source) {
                data_source_registry.remove(i);
                break;
            }
        }
    }

    public static void remove_data_source_by_id(int id) {
        assert(data_source_registry != null);
        if(id < 0)
            return;
        data_source_registry.remove(id);
    }
    
    public uint32 get_current_stamp(int source) {
        return _current_stamps.lookup(source);
    }

    public void renew_stamp(string source_name) {
        int source_id = get_data_source_id_by_name(source_name);
        assert(source_id > -1);
        _current_stamps.insert(source_id, Random.next_int());
    }
    
    private static void setup_pattern_specs() {
        if(supported_types == null) {
            // some extra mime types
            supported_types = new HashTable<string,int>(str_hash, str_equal);
            supported_types.insert("application/vnd.rn-realmedia", 1);
            supported_types.insert("application/ogg", 1);
            supported_types.insert("application/x-extension-m4a", 1);
            supported_types.insert("application/x-extension-mp4", 1);
            supported_types.insert("application/x-flac", 1);
            supported_types.insert("application/x-flash-video", 1);
            supported_types.insert("application/x-matroska", 1);
            supported_types.insert("application/x-ogg", 1);
            supported_types.insert("application/x-troff-msvideo", 1);
            supported_types.insert("application/xspf+xml", 1);
            
            pattern_video = new PatternSpec("video*");
            pattern_audio = new PatternSpec("audio*");
        }
    }
}



// PROJECT WIDE USED STRUCTS, INTERFACES AND ENUMS

//internal enum Xnoise.TrackListNoteBookTab { // used in various places
//    TRACKLIST = 0,
//    VIDEO,
//    LYRICS
//}

//public enum Gst.StreamType {
//    UNKNOWN = 0,
//    AUDIO   = 1,
//    VIDEO   = 2
//}

public enum Xnoise.PlayerState {
    STOPPED = 0,
    PLAYING,
    PAUSED
}

public enum Xnoise.CollectionSortMode {
    ARTIST_ALBUM_TITLE = 0,
    GENRE_ARTIST_ALBUM
}

//public enum Xnoise.SortDirection {
//    ASCENDING,
//    DESCENDING
//}




// STRUCTS
[CCode (destroy_function = "xnoise_dnd_data_destroy")]
public struct Xnoise.DndData { // drag data (mediabrowser -> tracklist)
    public int32    db_id;
    public ItemType mediatype;
    public int      source_id; // use for registered data sources
    public uint32   stamp;
    
    public int32    extra_db_id[4];
    public ItemType extra_mediatype[4];
    public uint32   extra_stamps[4];
    
    //public static DndData copy(DndData dat) {
    //    DndData ret   = DndData();
    //    ret.db_id     = dat.db_id;
    //    ret.mediatype = dat.mediatype;
    //    ret.source_id = dat.source_id;
    //    ret.stamp     = dat.stamp;
    //    ret.extra_db_id[0] = dat.extra_db_id[0];
    //    ret.extra_db_id[1] = dat.extra_db_id[1];
    //    ret.extra_db_id[2] = dat.extra_db_id[2];
    //    ret.extra_db_id[3] = dat.extra_db_id[3];
    //    ret.extra_mediatype[0] = dat.extra_mediatype[0];
    //    ret.extra_mediatype[1] = dat.extra_mediatype[1];
    //    ret.extra_mediatype[2] = dat.extra_mediatype[2];
    //    ret.extra_mediatype[3] = dat.extra_mediatype[3];
    //    ret.extra_stamps[0] = dat.extra_stamps[0];
    //    ret.extra_stamps[1] = dat.extra_stamps[1];
    //    ret.extra_stamps[2] = dat.extra_stamps[2];
    //    ret.extra_stamps[3] = dat.extra_stamps[3];
    //    return ret;
    //}
}



// INTERFACES


public interface Xnoise.IMainView : Gtk.Widget {
    public abstract string get_view_name();
}


// this is used by mediakeys plugin. Only works if the interface  is in xnoise itself 
[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface Xnoise.GnomeMediaKeys : GLib.Object {
    public abstract void GrabMediaPlayerKeys(string application, uint32 time) throws IOError;
    public abstract void ReleaseMediaPlayerKeys(string application) throws IOError;
    public signal void MediaPlayerKeyPressed(string application, string key);
}


