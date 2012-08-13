/* magnatune-db-reader.vala
 *
 * Copyright (C) 2012  Jörn Magens
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


using Sqlite;

using Xnoise;
using Xnoise.Services;

public class MagnatuneDatabaseConverter {
    private const string DATABASE_NAME = "/tmp/xnoise_magnatune_db";
    private const string TARGET_DB     = "/tmp/xnoise_magnatune.sqlite";
    private string DATABASE;

    private static const string STMT_CREATE_ARTISTS =
        "CREATE TABLE artists (id INTEGER PRIMARY KEY, name TEXT);";
    private static const string STMT_CREATE_ALBUMS =
        "CREATE TABLE albums (id INTEGER PRIMARY KEY, artist INTEGER, name TEXT, image TEXT);";
    private static const string STMT_CREATE_URIS =
        "CREATE TABLE uris (id INTEGER PRIMARY KEY, name TEXT, type INTEGER);";
    private static const string STMT_CREATE_GENRES =
        "CREATE TABLE genres (id integer primary key, name TEXT);";
    private static const string STMT_CREATE_ITEMS =
        "CREATE TABLE items (id INTEGER PRIMARY KEY, tracknumber INTEGER, artist INTEGER, album INTEGER, title TEXT, genre INTEGER, year INTEGER, uri INTEGER, mediatype INTEGER, length INTEGER, bitrate INTEGER, usertags TEXT, playcount INTEGER, rating INTEGER, lastplayTime DATETIME, addTimeUnix INTEGER, mimetype TEXT, CONSTRAINT link_uri FOREIGN KEY (uri) REFERENCES uris(id) ON DELETE CASCADE);";

    public MagnatuneDatabaseReader() {
        DATABASE = dbFileName();
        source = null;
        if(Sqlite.Database.open_v2(DATABASE, out source, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) {
            error("Can't open magnatune database: %s\n", (string)this.source.errmsg);
        }
        if(this.source == null) {
            error("magnatune db failed");
        }
        
        bool ret = create_taget_db();
        assert(ret == true);

        bool ret2 = move_data();
        assert(ret2 == true);

//        db.create_function_v2("utf8_lower", 1, Sqlite.ANY, null, utf8_lower, null, null, null);
//        db.create_collation("CUSTOM01", Sqlite.UTF8, compare_func);
        
//        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_SEARCH, -1, out get_artists_with_search_stmt);
//        this.db.prepare_v2(STMT_GET_ARTISTS, -1, out get_artists_from_source_stmt);
    }

    private bool move_data() {
        
    }
    
    private bool create_taget_db() {
        setup_target_handle();
        if(target == null)
            return false;
        
        if(!exec_stmnt_string(STMT_CREATE_ARTISTS)        ) { reset(); return false; }
        if(!exec_stmnt_string(STMT_CREATE_ALBUMS)         ) { reset(); return false; }
        if(!exec_stmnt_string(STMT_CREATE_URIS)           ) { reset(); return false; }
        if(!exec_stmnt_string(STMT_CREATE_ITEMS)          ) { reset(); return false; }
        if(!exec_stmnt_string(STMT_CREATE_GENRES)         ) { reset(); return false; }
        
        return true;
    }

    private bool exec_stmnt_string(string statement) {
        string errormsg;
        if(target.exec(statement, null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s", errormsg);
            return false;
        }
        return true;
    }
    
    private static void setup_target_handle() {
        File tf = File.new_for_path(TARGET_DB);
        if(!tf.query_exists(null)) {
            try {
                tf.delete();
                //xnoise_home.make_directory_with_parents(null);
            }
            catch(Error e) {
                print("%s\n", e.message);
            }
        }
        Sqlite.Database.open_v2(tf.get_path(),
                                out target,
                                Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE,
                                null
                                );
    }

    private static void utf8_lower(Sqlite.Context context, [CCode (array_length_pos = 1.1)] Sqlite.Value[] values) {
        context.result_text(values[0].to_text().down());
    }
    
    private static int compare_func(int alen, void* a, int blen, void* b) {
        return GLib.strcmp(((string)a).collate_key(alen), ((string)b).collate_key(blen));
    }
    
    private Sqlite.Database source;
    private Sqlite.Database target;

    private string dbFileName() {
        return DATABASE_NAME;//GLib.Path.build_filename("tmp", "xnoise_magnatune_db", null);
    }

    private void db_error(ref Database x) {
        print("Database error %d: %s \n\n", x.errcode(), x.errmsg());
    }

    private static const string STMT_GET_ARTISTS =
        "SELECT DISTINCT ar.artist FROM artists ar ORDER BY utf8_lower(ar.artist) COLLATE CUSTOM01 DESC";
    private static const string STMT_INSERT_ARTIST =
        "INSERT INTO artists (name) VALUES (?)";
        
//    private Statement get_artists_with_search_stmt;
//    private Statement get_artists_from_source_stmt;
    
    public void get_artists() {
        Statement stmt_s;
        Statement stmt_t;
        source.prepare_v2(STMT_GET_ARTISTS,   -1, out stmt_s);
        target.prepare_v2(STMT_INSERT_ARTIST, -1, out stmt_t);
        while(stmt_s.step() == Sqlite.ROW) {
            if(stmt_t.bind_text(1, stmt_s.column_text(0)) != Sqlite.OK) {
                this.db_error(ref stmt_t);
                return;
            }
            if(stmt_t.step() != Sqlite.DONE) {
                this.db_error(ref stmt_t);
                return;
            }
        }
    }

//    private static const string STMT_GET_TRACKS_WITH_SEARCH =
//        "SELECT DISTINCT s.desc, s.mp3, s.number FROM artists ar, albums al, genres g, songs s WHERE s.albumname = al.albumname AND al.artist = ar.artist AND g.albumname = al.albumname AND utf8_lower(ar.artist) = ? AND utf8_lower(al.albumname) = ? AND (utf8_lower(s.desc) LIKE ? OR utf8_lower(al.albumname) LIKE ? OR utf8_lower(ar.artist) LIKE ? OR utf8_lower(g.genre) LIKE ?) ORDER BY s.number DESC";
    private static const string STMT_GET_TRACKS =
        "SELECT DISTINCT s.desc, s.mp3, s.number FROM artists ar, albums al, songs s WHERE s.albumname = al.albumname AND al.artist = ar.artist AND utf8_lower(ar.artist) = ? AND utf8_lower(al.albumname) = ? ORDER BY s.number DESC";

    public TrackData[] get_tracks_for_album(string searchtext, string artist, string album) {
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != "") {
            string st = "%%%s%%".printf(searchtext);
            this.source.prepare_v2(STMT_GET_TRACKS_WITH_SEARCH, -1, out stmt);
            if(stmt.bind_text(1, artist.down()) != Sqlite.OK ||
               stmt.bind_text(2, album.down()) != Sqlite.OK ||
               stmt.bind_text(3, st)     != Sqlite.OK ||
               stmt.bind_text(4, st)     != Sqlite.OK ||
               stmt.bind_text(5, st)     != Sqlite.OK ||
               stmt.bind_text(6, st)     != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.source.prepare_v2(STMT_GET_TRACKS, -1, out stmt);
            if(stmt.bind_text(1, artist.down()) != Sqlite.OK ||
               stmt.bind_text(2, album.down()) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item();
            td.item = i;
            td.title = td.item.text = stmt.column_text(0);
            td.album = album;
            td.artist = artist;
            td.tracknumber = stmt.column_int(2);
            td.item.uri  = "http://he3.magnatune.com/all/" + Uri.escape_string(stmt.column_text(1), null, true);
            print("td.item.uri: %s\n", td.item.uri);
            val += td;
        }
        return (owned)val;
    }

    public override TrackData[]? get_trackdata_by_artistid(string searchtext, int32 id) {
        print("not implemented\n");
        return null;
    }

    public override Item? get_artistitem_by_artistid(string searchtext, int32 id) {
        print("not implemented\n");
        return null;
    }


    public override TrackData[]? get_trackdata_by_albumid(string searchtext, int32 id) {
        print("not implemented\n");
        return null;
    }


    private static const string STMT_GET_ALBUMS_WITH_SEARCH =
        "SELECT DISTINCT al.albumname FROM artists ar, albums al, genres g, songs s WHERE s.albumname = al.albumname AND al.artist = ar.artist AND g.albumname = al.albumname AND utf8_lower(ar.artist) = ? AND (utf8_lower(s.desc) LIKE ? OR utf8_lower(al.albumname) LIKE ? OR utf8_lower(ar.artist) LIKE ? OR utf8_lower(g.genre) LIKE ?) ORDER BY utf8_lower(al.albumname) COLLATE CUSTOM01 ASC";
    private static const string STMT_GET_ALBUMS =
        "SELECT DISTINCT al.albumname FROM artists ar, albums al WHERE al.artist = ar.artist AND utf8_lower(ar.artist) = ? ORDER BY utf8_lower(al.albumname) COLLATE CUSTOM01 ASC";

    public override Item[] get_albums_with_search(string searchtext, int32 id) { //(string)artist
        Item[] val = {};
        Statement stmt;
        if(searchtext != "") {
            string st = "%%%s%%".printf(searchtext);
            this.source.prepare_v2(STMT_GET_ALBUMS_WITH_SEARCH, -1, out stmt);
            if(stmt.bind_text(1, artist.down()) != Sqlite.OK ||
               stmt.bind_text(2, st)     != Sqlite.OK ||
               stmt.bind_text(3, st)     != Sqlite.OK ||
               stmt.bind_text(4, st)     != Sqlite.OK ||
               stmt.bind_text(5, st)     != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.source.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
            if(stmt.bind_text(1, artist.down()) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item();
            i.text = stmt.column_text(0);
            val += i;
        }
        return (owned)val;
    }
//    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH =
//        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01  ASC";
//    
//    private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
//        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
//    
//    public TrackData[]? get_trackdata_by_albumid(string searchtext, int32 id) {
//        TrackData[] val = {};
//        Statement stmt;
//        if(searchtext != EMPTYSTRING) {
//            string st = "%%%s%%".printf(searchtext);
//            this.source.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
//            if((stmt.bind_int (1, id) != Sqlite.OK) ||
//               (stmt.bind_text(2, st) != Sqlite.OK) ||
//               (stmt.bind_text(3, st) != Sqlite.OK) ||
//               (stmt.bind_text(4, st) != Sqlite.OK)) {
//                this.db_error();
//                return (owned)val;
//            }
//        }
//        else {
//            this.source.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
//            if((stmt.bind_int(1, id) != Sqlite.OK)) {
//                this.db_error();
//                return null;
//            }
//        }
//        while(stmt.step() == Sqlite.ROW) {
//            TrackData td = new TrackData();
//            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
//            
//            td.artist      = stmt.column_text(5);
//            td.album       = stmt.column_text(6);
//            td.title       = stmt.column_text(0);
//            td.item        = i;
//            td.tracknumber = stmt.column_int(3);
//            td.length      = stmt.column_int(7);
//            td.genre       = stmt.column_text(8);
//            td.year        = stmt.column_int(9);
//            val += td;
//        }
//        return (owned)val;
//    }
//    
//    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
//        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g  WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
//    
//    private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
//        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
//    
//    public TrackData[]? get_trackdata_by_artistid(string searchtext, int32 id) {
//        TrackData[] val = {};
//        Statement stmt;
//        if(searchtext != EMPTYSTRING) {
//            string st = "%%%s%%".printf(searchtext);
//            this.source.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
//            if((stmt.bind_int (1, id) != Sqlite.OK) ||
//               (stmt.bind_text(2, st) != Sqlite.OK) ||
//               (stmt.bind_text(3, st) != Sqlite.OK) ||
//               (stmt.bind_text(4, st) != Sqlite.OK)) {
//                this.db_error();
//                return (owned)val;
//            }
//        }
//        else {
//            this.source.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
//            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
//                this.db_error();
//                return null;
//            }
//        }        
//        while(stmt.step() == Sqlite.ROW) {
//            TrackData td = new TrackData();
//            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
//            
//            td.artist      = stmt.column_text(5);
//            td.album       = stmt.column_text(6);
//            td.title       = stmt.column_text(0);
//            td.item        = i;
//            td.tracknumber = stmt.column_int(3);
//            td.length      = stmt.column_int(7);
//            td.genre       = stmt.column_text(8);
//            td.year        = stmt.column_int(9);
//            val += td;
//        }
//        return (owned)val;
//    }

//    private static const string STMT_GET_VIDEOITEM_BY_ID =
//        "SELECT DISTINCT t.id, t.title, u.name, t.mediatype FROM items t, uris u WHERE t.uri = u.id AND t.id = ?";
//    
//    public Item? get_videoitem_by_id(int32 id) {
//        Statement stmt;
//        Item? i = Item(ItemType.UNKNOWN);
//        this.source.prepare_v2(STMT_GET_VIDEOITEM_BY_ID, -1, out stmt);
//        if((stmt.bind_int(1, id)!=Sqlite.OK)) {
//            this.db_error();
//            return (owned)i;
//        }
//        if(stmt.step() == Sqlite.ROW) {
//            i = Item((ItemType) stmt.column_int(3), stmt.column_text(2), stmt.column_int(0));
//            i.text = stmt.column_text(1);
//        }
//        return (owned)i;
//    }

//    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
//        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?)";
//    
//    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
//        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
//    
//    public Item? get_artistitem_by_artistid(string searchtext, int32 id) {
//        Statement stmt;
//        Item? i = Item(ItemType.UNKNOWN);
//        if(searchtext != EMPTYSTRING) {
//            string st = "%%%s%%".printf(searchtext);
//            this.source.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
//            if((stmt.bind_int (1, id) != Sqlite.OK) ||
//               (stmt.bind_text(2, st) != Sqlite.OK) ||
//               (stmt.bind_text(3, st) != Sqlite.OK) ||
//               (stmt.bind_text(4, st) != Sqlite.OK)) {
//                this.db_error();
//                return (owned)i;
//            }
//        }
//        else {
//            this.source.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID, -1, out stmt);
//            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
//                this.db_error();
//                return (owned)i;
//            }
//        }
//        if(stmt.step() == Sqlite.ROW) {
//            i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, id);
//            i.text = stmt.column_text(0);
//        }
//        return (owned)i;
//    }

//    private static const string STMT_GET_TRACKDATA_BY_TITLEID =
//        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
//        
//    public TrackData? get_trackdata_by_titleid(string searchtext, int32 id) {
//        Statement stmt;
//        
//        this.source.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
//        
//        if((stmt.bind_int(1, id)!=Sqlite.OK)) {
//            this.db_error();
//            return null;
//        }
//        TrackData td = null; 
//        if(stmt.step() == Sqlite.ROW) {
//            td = new TrackData();
//            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
//            
//            td.artist      = stmt.column_text(5);
//            td.album       = stmt.column_text(6);
//            td.title       = stmt.column_text(0);
//            td.item        = i;
//            td.tracknumber = stmt.column_int(3);
//            td.length      = stmt.column_int(7);
//            td.genre       = stmt.column_text(8);
//            td.year        = stmt.column_int(9);
//        }
//        return (owned)td;
//    }
}

