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



namespace Xnoise {
    public static Params par = null;
    public static GlobalAccess global = null;
    public static UserInfo userinfo = null;
    public static Worker db_worker = null;
    public static Worker io_worker = null;
    public static MediaImporter media_importer = null;
    public static ItemHandlerManager itemhandler_manager = null;
    public static ItemConverter item_converter = null;
    public static HashTable<string,Xnoise.DockableMedia>  dockable_media_sources;
    public static HashTable<int, Xnoise.DataSource>       data_source_registry;

    public static Database.Reader db_reader;
    public static Database.Writer db_writer;
    
    private static Statistics statistics;
    
    internal static IconRepo icon_repo;
    internal static DbusThumbnailer thumbnailer = null;
    
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
        
        dockable_media_sources = new HashTable<string, DockableMedia> (str_hash, str_equal);
        data_source_registry   = new HashTable<int, Xnoise.DataSource>(direct_hash, direct_equal);
        
        _current_stamps   = new HashTable<int, uint32>(direct_hash, direct_equal);
        
        icon_repo = new IconRepo();
        
        // ITEM STUFF
        itemhandler_manager = new ItemHandlerManager();
        item_converter = new ItemConverter();
        
        // MEDIA IMPORTER
        media_importer = new MediaImporter();
        
        // WORKERS
        db_worker = new Worker(MainContext.default());
        io_worker = new Worker(MainContext.default());
        
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
        global.fontsize_dockable = ((v >= 7 && v < 18) ? v : 10);
        
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
        int dbid = register_data_source(db_reader);
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




// STRUCTS

public struct Xnoise.DndData { // drag data (mediabrowser -> tracklist)
    public int32 db_id;
    public ItemType mediatype;
    public int source_id; // use for registered data sources
    public uint32 stamp;
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


