/* xnoise-db-reader.vala
 *
 * Copyright (C) 2009-2012  Jörn Magens
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

public errordomain Xnoise.Database.DbError {
    FAILED;
}

public class Xnoise.Database.Reader : Xnoise.DataSource {
    private const string DATABASE_NAME = "db.sqlite";
    private const string SETTINGS_FOLDER = ".xnoise";
    private string DATABASE;
    private Sqlite.Database db;

    private static const string STMT_GET_LASTUSED =
        "SELECT uri FROM lastused";
    private static const string STMT_GET_RADIOS =
        "SELECT name, uri FROM streams";
    private static const string STMT_GET_MEDIA_FOLDERS =
        "SELECT * FROM media_folders";
    private static const string STMT_GET_MEDIA_FILES =
        "SELECT * FROM media_files";
    private static const string STMT_GET_RADIO_DATA    =
        "SELECT DISTINCT id, name, uri FROM streams WHERE utf8_lower(name) LIKE ? ORDER BY name COLLATE CUSTOM01 DESC";

    public Reader() throws DbError {
        DATABASE = dbFileName();
        db = null;
        if(Sqlite.Database.open_v2(DATABASE, out db, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) {
            print("Can't open database: %s\n", (string)this.db.errmsg);
            throw new DbError.FAILED("failed messge");
        }
        if(this.db == null) {
            throw new DbError.FAILED("failed messge");
        }
        //register my own db function
        db.create_function_v2("utf8_lower", 1, Sqlite.ANY, null, utf8_lower, null, null, null);
        //create custom utf8 collation
        db.create_collation("CUSTOM01", Sqlite.UTF8, compare_func);
        db.progress_handler(5, progress_handler);
        
        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_SEARCH, -1, out get_artists_with_search_stmt);
        this.db.prepare_v2(STMT_GET_ARTISTS, -1, out get_artists_with_search2_stmt);
        
        string errormsg;
        if(db.exec("PRAGMA synchronous=OFF", null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s", errormsg);
            return;
        }
    }

    private static void utf8_lower(Sqlite.Context context, [CCode (array_length_pos = 1.1)] Sqlite.Value[] values) {
        context.result_text(values[0].to_text().down());
    }
    
    private static int compare_func(int alen, void* a, int blen, void* b) {
        return GLib.strcmp(((string)a).collate_key(alen), ((string)b).collate_key(blen));
    }
    
    public void cancel() {
        abort = true;
    }
    
    private bool abort = false;
    private int progress_handler() {
        if(abort) {
            abort = false;
            return 1;
        }
        return 0;
    }

    public override string get_datasource_name() {
        return "XnoiseMainDatabase";
    }

    private string dbFileName() {
        return GLib.Path.build_filename(data_folder(), DATABASE_NAME, null);
    }

    private void db_error() {
        print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
    }

    public delegate void ReaderCallback(Sqlite.Database database);
    
    public void do_callback_transaction(ReaderCallback cb) {
        if(db == null) return;
        
        if(cb != null)
            cb(db);
    }

    private static const string STMT_GET_VIDEO_COUNT = "SELECT COUNT (t.id) FROM items t WHERE t.mediatype=? AND (utf8_lower(t.title) LIKE ?)";
    public int32 count_videos(string searchtext) {
        Statement stmt;
        int count = 0;
        
        this.db.prepare_v2(STMT_GET_VIDEO_COUNT, -1, out stmt);
        
        if(stmt.bind_int (1, ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK ||
           stmt.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK) {
            this.db_error();
            return 0;
        }
        
        if(stmt.step() == Sqlite.ROW) {
            count = stmt.column_int(0);
        }
        return count;
    }
    
    public bool get_lyrics(string artist, string title, out string txt, out string cred, out string ident) {
        Statement stmt;
        db.prepare_v2("SELECT txt, credits, identifier FROM lyrics WHERE LOWER(artist) = ? AND LOWER(title) = ?", -1, out stmt);
        
        stmt.reset();
        
        txt   = EMPTYSTRING;
        cred  = EMPTYSTRING;
        ident = EMPTYSTRING;
        
        if((stmt.bind_text(1, "%s".printf(prepare_for_comparison(artist))) != Sqlite.OK)|
           (stmt.bind_text(2, "%s".printf(prepare_for_comparison(title))) != Sqlite.OK)) {
            print("Error in database lyrics\n");
            return false;
        }
        if(stmt.step() == Sqlite.ROW) {
            txt   = stmt.column_text(0);
            cred  = stmt.column_text(1);
            ident = stmt.column_text(2);
            
            if(txt.strip() == "no lyrics found..." || txt.strip() == _("no lyrics found...")) {
                txt = cred = ident = EMPTYSTRING;
                return false;
            }
            return true;
        }
        else {
            return false;
        }
    }
    
    private static const string STMT_GET_LAST_PLAYED =
        "SELECT ar.name, t.title, t.mediatype, t.id, u.name, st.lastplayTime FROM artists ar, items t, albums al, uris u, statistics st WHERE st.lastplayTime > 0 AND t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND st.uri = u.name AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) ORDER BY st.lastplayTime DESC LIMIT 100";
    
    public Item[]? get_last_played(string searchtext) {
        Statement stmt;
        Item[] retv = {};
        string st = "%%%s%%".printf(searchtext);
        this.db.prepare_v2(STMT_GET_LAST_PLAYED , -1, out stmt);
        if((stmt.bind_text(1, st) != Sqlite.OK) ||
           (stmt.bind_text(2, st) != Sqlite.OK) ||
           (stmt.bind_text(3, st) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item((ItemType)stmt.column_int(2), stmt.column_text(4), stmt.column_int(3));
            i.source_id = get_source_id();
            if(i.type == ItemType.LOCAL_AUDIO_TRACK)
                i.text = stmt.column_text(0) + " - " + stmt.column_text(1);
            else
                i.text = stmt.column_text(1);
            retv += i;
        }
        if(retv.length == 0)
            return null;
        return (owned)retv;
    }
    
    
    private static const string STMT_GET_MOST_PLAYED =
        "SELECT ar.name, t.title, t.mediatype, t.id, u.name, st.playcount FROM artists ar, items t, albums al, uris u, statistics st WHERE st.playcount > 0 AND t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND st.uri = u.name AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) ORDER BY st.playcount DESC LIMIT 100";

    public Item[]? get_most_played(string searchtext) {
        Statement stmt;
        Item[] retv = {};
        string st = "%%%s%%".printf(searchtext);
        this.db.prepare_v2(STMT_GET_MOST_PLAYED , -1, out stmt);
        if((stmt.bind_text(1, st) != Sqlite.OK) ||
           (stmt.bind_text(2, st) != Sqlite.OK) ||
           (stmt.bind_text(3, st) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item((ItemType)stmt.column_int(2), stmt.column_text(4), stmt.column_int(3));
            i.source_id = get_source_id();
            if(i.type == ItemType.LOCAL_AUDIO_TRACK)
                i.text = stmt.column_text(0) + " - " + stmt.column_text(1);
            else
                i.text = stmt.column_text(1);
            retv += i;
        }
        if(retv.length == 0)
            return null;
        return (owned)retv;
    }
    
    private static const string STMT_ALL_TRACKDATA =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) and t.mediatype = ? ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 ASC, utf8_lower(al.name) COLLATE CUSTOM01 ASC, t.tracknumber ASC";
    
    public TrackData[]? get_all_tracks(string searchtext) {
        Statement stmt;
        TrackData[] retv = {};
        string st = "%%%s%%".printf(searchtext);
        this.db.prepare_v2(STMT_ALL_TRACKDATA , -1, out stmt);
        
        if((stmt.bind_text(1, st) != Sqlite.OK) ||
           (stmt.bind_text(2, st) != Sqlite.OK) ||
           (stmt.bind_text(3, st) != Sqlite.OK) ||
           (stmt.bind_int (4, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData val = new TrackData();
            val.artist      = stmt.column_text(0);
            val.album       = stmt.column_text(1);
            val.title       = stmt.column_text(2);
            val.tracknumber = stmt.column_int(3);
            val.length      = stmt.column_int(6);
            val.item        = Item((ItemType)stmt.column_int(4), stmt.column_text(5), stmt.column_int(7));
            val.item.source_id = get_source_id();
            val.genre       = stmt.column_text(8);
            val.year        = stmt.column_int(9);
            if((val.artist==EMPTYSTRING) || (val.artist==null)) {
                val.artist = UNKNOWN_ARTIST;
            }
            if((val.album== EMPTYSTRING) || (val.album== null)) {
                val.album = UNKNOWN_ALBUM;
            }
            if((val.genre== EMPTYSTRING) || (val.genre== null)) {
                val.genre = UNKNOWN_GENRE;
            }
            if((val.title== EMPTYSTRING) || (val.title== null)) {
                val.title = UNKNOWN_TITLE;
                File file = File.new_for_uri(val.item.uri);
                string fileBasename;
                if(file != null)
                    fileBasename = GLib.Filename.display_basename(file.get_path());
                else
                    fileBasename = val.item.uri;
                val.title = fileBasename;
            }
            retv += val;
        }
        return (owned)retv;
    }

    private static const string STMT_GET_STREAMITEM_BY_ID =
        "SELECT DISTINCT st.id, st.uri, st.name FROM streams st WHERE st.id = ? AND (utf8_lower(st.name) LIKE ? OR utf8_lower(st.uri) LIKE ?) ORDER BY utf8_lower(st.name) COLLATE CUSTOM01 DESC";
    
    public Item? get_streamitem_by_id(int32 id, string searchtext) {
        Statement stmt;
        string st = "%%%s%%".printf(searchtext);
        Item? i = Item(ItemType.UNKNOWN);
        this.db.prepare_v2(STMT_GET_STREAMITEM_BY_ID, -1, out stmt);
        if(stmt.bind_int (1, id)!=Sqlite.OK ||
           stmt.bind_text(2, st)!=Sqlite.OK ||
           stmt.bind_text(3, st)!=Sqlite.OK) {
            this.db_error();
            return (owned)i;
        }
        if(stmt.step() == Sqlite.ROW) {
            i = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
            i.text = stmt.column_text(2);
            i.source_id = get_source_id();
        }
        return (owned)i;
    }

    private static const string STMT_STREAM_TD_FOR_ID =
        "SELECT name, uri FROM streams WHERE id = ?";

    public override bool get_stream_td_for_id(int32 id, out TrackData val) {
        Statement stmt;
        val = new TrackData();
        this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
            
        stmt.reset();
        if(stmt.bind_int (1, id) != Sqlite.OK) {
            this.db_error();
            return false;
        }
        if(stmt.step() == Sqlite.ROW) {
            val.artist      = EMPTYSTRING;
            val.album       = EMPTYSTRING;
            val.title       = stmt.column_text(0);
            val.item        = Item(ItemType.STREAM, stmt.column_text(1), id);
            val.item.text   = stmt.column_text(0);
            val.item.source_id = get_source_id();
        }
        else {
            print("get_stream_td_for_id: track is not in db. ID: %d\n", id);
            return false;
        }
        return true;
    }

    private static const string STMT_TRACKDATA_FOR_URI =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.length, t.mediatype, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND u.name = ?";

    public override bool get_trackdata_for_uri(ref string? uri, out TrackData val) {
        bool retval = false;
        val = new TrackData();
        if(uri == null)
            return retval;
        
        Statement stmt;
        this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, out stmt);
            
        stmt.reset();
        stmt.bind_text(1, uri);
        if(stmt.step() == Sqlite.ROW) {
            val.artist      = stmt.column_text(0);
            val.album       = stmt.column_text(1);
            val.title       = stmt.column_text(2);
            val.tracknumber = (uint)stmt.column_int(3);
            val.length      = stmt.column_int(4);
            val.item        = Item((ItemType)stmt.column_int(5), uri, stmt.column_int(6));
            val.item.source_id = get_source_id();
            val.genre       = stmt.column_text(7);
            val.year        = stmt.column_int(8);
            retval = true;
        }
        if((val.artist==EMPTYSTRING) | (val.artist==null)) {
            val.artist = UNKNOWN_ARTIST;
        }
        if((val.album== EMPTYSTRING) | (val.album== null)) {
            val.album = UNKNOWN_ALBUM;
        }
        if((val.genre== EMPTYSTRING) | (val.genre== null)) {
            val.genre = UNKNOWN_GENRE;
        }
        if((val.title== EMPTYSTRING) | (val.title== null)) {
            val.title = UNKNOWN_TITLE;
            File file = File.new_for_uri(uri);
            string fpath = file.get_path();
            string fileBasename = EMPTYSTRING;
            if(fpath!=null) fileBasename = GLib.Filename.display_basename(fpath);
            val.title = fileBasename;
        }
        return retval;
    }

    public Item[] get_media_folders() {
        Statement stmt;
        Item[] mfolders = {};
        
        this.db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1, out stmt);
        
        while(stmt.step() == Sqlite.ROW) {
            File f = File.new_for_path(stmt.column_text(0));
            if(f == null)
                continue;
            Item? i = Item(ItemType.LOCAL_FOLDER, f.get_uri(), -1);
            i.source_id = get_source_id();
            i.text = stmt.column_text(0);
            mfolders += i;
        }
        return (owned)mfolders;
    }

    private static const string STMT_GET_STREAM_ITEMS_WITH_SEARCH =
        "SELECT DISTINCT s.id, s.uri, s.name FROM streams s WHERE utf8_lower(s.name) LIKE ? ORDER BY utf8_lower(s.name) COLLATE CUSTOM01 DESC";

    public Item[]? get_stream_items(string searchtext) {
        Item[] vals = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_STREAM_ITEMS_WITH_SEARCH, -1, out stmt);
        
        if(stmt.bind_text(1, "%%%s%%".printf(searchtext))     != Sqlite.OK) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item? item = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
            item.text = stmt.column_text(2);
            item.source_id = get_source_id();
            vals += item;
        }
        if(vals.length == 0)
            return null;
        return (owned)vals;
    }

    private static const string STMT_GET_SOME_LASTUSED_ITEMS =
        "SELECT mediatype, uri, id FROM lastused LIMIT ? OFFSET ?";
    public Item[] get_some_lastused_items(int limit, int offset) {
        Item[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_SOME_LASTUSED_ITEMS, -1, out stmt);
        
        if((stmt.bind_int(1, limit)  != Sqlite.OK) ||
           (stmt.bind_int(2, offset) != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        
        while(stmt.step() == Sqlite.ROW) {
            Item? item = Item((ItemType)stmt.column_int(0), stmt.column_text(1), stmt.column_int(2));
            item.source_id = get_source_id();
            val += item;
        }
        return (owned)val;
    }
    
    private static const string STMT_CNT_LASTUSED =
        "SELECT COUNT(mediatype) FROM lastused";
    
    public uint count_lastused_items() {
        uint val = 0;
        Statement stmt;
        
        this.db.prepare_v2(STMT_CNT_LASTUSED, -1, out stmt);
        
        if(stmt.step() == Sqlite.ROW) {
            return stmt.column_int(0);
        }
        return val;
    }

    private static const string STMT_GET_STREAM_DATA =
        "SELECT DISTINCT s.id, s.uri, s.name FROM streams s WHERE utf8_lower(s.name) LIKE ? ORDER BY utf8_lower(s.name) COLLATE CUSTOM01 DESC";

    public TrackData[] get_stream_data(string searchtext) {
        TrackData[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_STREAM_DATA, -1, out stmt);
        
        if(stmt.bind_text(1, "%%%s%%".printf(searchtext))     != Sqlite.OK) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            td.title       = stmt.column_text(2);
            td.name        = stmt.column_text(2);
            td.name        = stmt.column_text(1);
            td.item        = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
            td.item.source_id = get_source_id();
            td.item.text      = stmt.column_text(2);
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_VIDEO_ITEMS =
        "SELECT DISTINCT t.title, t.id, u.name FROM items t, uris u WHERE t.uri = u.id AND t.mediatype = ? AND (utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY utf8_lower(t.title) COLLATE CUSTOM01 DESC";

    public Item[]? get_video_items(string searchtext) {
        Item[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_VIDEO_ITEMS, -1, out stmt);
        
        if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
           (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(2), stmt.column_int(1));
            i.source_id = get_source_id();
            i.text = stmt.column_text(0);
            val += i;
        }
        if(val.length == 0)
            return null;
        return (owned)val;
    }

    private static const string STMT_GET_VIDEO_DATA =
        "SELECT DISTINCT t.title, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, t.genre FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.mediatype = ? AND (utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY utf8_lower(t.title) COLLATE CUSTOM01 DESC";

    public TrackData[] get_video_data(string searchtext) {
        TrackData[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_VIDEO_DATA, -1, out stmt);
        
        if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
           (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            td.artist      = stmt.column_text(4);
            td.album       = stmt.column_text(5);
            td.title       = stmt.column_text(0);
            td.tracknumber = stmt.column_int(2);
            td.length      = stmt.column_int(6);
            td.genre       = stmt.column_text(7);
            td.name        = stmt.column_text(0);
            td.item        = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(3), stmt.column_int(1));
            td.item.source_id = get_source_id();
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_TRACKDATA_FOR_VIDEO =
        "SELECT DISTINCT t.title, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.mediatype = ? AND (utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY utf8_lower(t.title) COLLATE CUSTOM01 ASC";

    public TrackData[] get_trackdata_for_video(string searchtext) {
        TrackData[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_VIDEO, -1, out stmt);
        
        if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
           (stmt.bind_text(2, "%%%s%%".printf(searchtext))     != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            td.artist      = stmt.column_text(4);
            td.album       = stmt.column_text(5);
            td.title       = stmt.column_text(0);
            td.tracknumber = stmt.column_int(2);
            td.length      = stmt.column_int(6);
            td.genre       = stmt.column_text(7);
            td.year        = stmt.column_int(8);
            td.name        = stmt.column_text(0);
            td.item        = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(3), stmt.column_int(1));
            td.item.source_id = get_source_id();
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_TRACKDATA_FOR_STREAMS =
        "SELECT DISTINCT s.id, s.uri, s.name FROM streams s WHERE utf8_lower(s.name) LIKE ? OR utf8_lower(s.uri) LIKE ? ORDER BY utf8_lower(s.name) COLLATE CUSTOM01 ASC";

    public TrackData[] get_trackdata_for_streams(string searchtext) {
        TrackData[] val = {};
        Statement stmt;
        string st = "%%%s%%".printf(searchtext);
        this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_STREAMS, -1, out stmt);
        
        if((stmt.bind_text(1, st)     != Sqlite.OK)||
           (stmt.bind_text(2, st)     != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            td.title       = stmt.column_text(2);
            td.name        = stmt.column_text(2);
            td.item        = Item(ItemType.STREAM, stmt.column_text(1), stmt.column_int(0));
            td.item.text   = stmt.column_text(2);
            td.item.source_id = get_source_id();
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_ARTISTS_WITH_SEARCH =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND (utf8_lower(t.title) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(ar.name) LIKE ?) AND t.mediatype = ? ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";

    private static const string STMT_GET_ARTISTS =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t WHERE t.artist = ar.id AND t.mediatype = ? ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";
    
    private Statement get_artists_with_search_stmt;
    private Statement get_artists_with_search2_stmt;
    
    public override Item[] get_artists_with_search(string searchtext) {
        Item[] val = {};
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            get_artists_with_search_stmt.reset();
            if(get_artists_with_search_stmt.bind_text(1, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(2, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(3, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_int (4, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_artists_with_search_stmt.step() == Sqlite.ROW) {
                Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, get_artists_with_search_stmt.column_int(0));
                i.text = get_artists_with_search_stmt.column_text(1);
                i.source_id = get_source_id();
                val += i;
            }
        }
        else {
            get_artists_with_search2_stmt.reset();
            if(get_artists_with_search2_stmt.bind_int(1, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_artists_with_search2_stmt.step() == Sqlite.ROW) {
                Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, get_artists_with_search2_stmt.column_int(0));
                i.text = get_artists_with_search2_stmt.column_text(1);
                i.source_id = get_source_id();
                val += i;
            }
        }
        return (owned)val;
    }

    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01  ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_by_albumid(string searchtext, int32 id) {
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
            if((stmt.bind_int(1, id) != Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            val += td;
        }
        return (owned)val;
    }
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g  WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_by_artistid(string searchtext, int32 id) {
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }        
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_VIDEOITEM_BY_ID =
        "SELECT DISTINCT t.id, t.title, u.name, t.mediatype FROM items t, uris u WHERE t.uri = u.id AND t.id = ?";
    
    public Item? get_videoitem_by_id(int32 id) {
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        this.db.prepare_v2(STMT_GET_VIDEOITEM_BY_ID, -1, out stmt);
        if((stmt.bind_int(1, id)!=Sqlite.OK)) {
            this.db_error();
            return (owned)i;
        }
        if(stmt.step() == Sqlite.ROW) {
            i = Item((ItemType) stmt.column_int(3), stmt.column_text(2), stmt.column_int(0));
            i.text = stmt.column_text(1);
            i.source_id = get_source_id();
        }
        return (owned)i;
    }

    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?)";
    
    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
    
    public override Item? get_artistitem_by_artistid(string searchtext, int32 id) {
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID, -1, out stmt);
            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        if(stmt.step() == Sqlite.ROW) {
            i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, id);
            i.text = stmt.column_text(0);
            i.source_id = get_source_id();
        }
        return (owned)i;
    }

    private static const string STMT_GET_TRACKDATA_BY_TITLEID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
        
    public override TrackData? get_trackdata_by_titleid(string searchtext, int32 id) {
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
        
        if((stmt.bind_int(1, id)!=Sqlite.OK)) {
            this.db_error();
            return null;
        }
        TrackData td = null; 
        if(stmt.step() == Sqlite.ROW) {
            td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
            i.source_id = get_source_id();
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
        }
        return (owned)td;
    }

    private static const string STMT_GET_ALBUMS_WITH_SEARCH =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t WHERE ar.id = t.artist AND al.id = t.album AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ALBUMS =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al WHERE ar.id = al.artist AND ar.id = ? ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    public override Item[] get_albums_with_search(string searchtext, int32 id) {
        Item[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_ALBUMS_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
            i.text = stmt.column_text(0);
            i.source_id = get_source_id();
            val += i;
        }
        return (owned)val;
    }
}

