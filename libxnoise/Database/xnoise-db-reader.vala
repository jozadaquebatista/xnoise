/* xnoise-db-reader.vala
 *
 * Copyright (C) 2009-2013  Jörn Magens
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
using Xnoise.Resources;
using Xnoise.Utilities;

public errordomain Xnoise.Database.DbError {
    FAILED;
}

public class Xnoise.Database.Reader : Xnoise.DataSource {
    private string DATABASE;
    private Sqlite.Database db;
    private Statement get_artists_with_search_stmt;
    private Statement get_artists_with_search2_stmt;
    private Statement get_genres_with_search_stmt;
    private Statement get_genres_with_search2_stmt;
    private Statement get_artists_with_genre_and_search_stmt;
    private Statement get_artists_with_genre_and_search2_stmt;
    
    
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
        this.db.prepare_v2(STMT_GET_GENRES_WITH_SEARCH, -1, out get_genres_with_search_stmt);
        this.db.prepare_v2(STMT_GET_GENRES, -1, out get_genres_with_search2_stmt);
        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_GENRE_AND_SEARCH,
                           -1,
                           out get_artists_with_genre_and_search_stmt
        );
        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_GENRE,
                           -1,
                           out get_artists_with_genre_and_search2_stmt
        );
        
        string errormsg;
        if(db.exec("PRAGMA synchronous=NORMAL", null, out errormsg)!= Sqlite.OK) {
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

    private const string data_source_name = "XnoiseMainDatabase";
    public override unowned string get_datasource_name() {
        return data_source_name;
    }

    private string dbFileName() {
        return GLib.Path.build_filename(data_folder(), MAIN_DATABASE_NAME, null);
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
        "SELECT ar.name, t.title, t.mediatype, t.id, u.name, st.lastplayTime FROM artists ar, items t, albums al, uris u, statistics st, genres g WHERE st.lastplayTime > 0 AND t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND st.uri = u.name AND t.genre = g.id AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) ORDER BY st.lastplayTime DESC LIMIT 100";
    
    public Item[]? get_last_played(string searchtext) {
        Statement stmt;
        Item[] retv = {};
        string stcl = "%%%s%%".printf(searchtext.casefold());
        this.db.prepare_v2(STMT_GET_LAST_PLAYED , -1, out stmt);
        if((stmt.bind_text(1, stcl) != Sqlite.OK) ||
           (stmt.bind_text(2, stcl) != Sqlite.OK) ||
           (stmt.bind_text(3, stcl) != Sqlite.OK) ||
           (stmt.bind_text(4, stcl) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item((ItemType)stmt.column_int(2), stmt.column_text(4), stmt.column_int(3));
            i.source_id = get_source_id();
            i.stamp = get_current_stamp(get_source_id());
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
        "SELECT ar.name, t.title, t.mediatype, t.id, u.name, st.playcount FROM artists ar, items t, albums al, uris u, statistics st, genres g WHERE st.playcount > 0 AND t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND st.uri = u.name AND t.genre = g.id AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) ORDER BY st.playcount DESC LIMIT 100";

    public Item[]? get_most_played(string searchtext) {
        Statement stmt;
        Item[] retv = {};
        string stcl = "%%%s%%".printf(searchtext.casefold());
        this.db.prepare_v2(STMT_GET_MOST_PLAYED , -1, out stmt);
        if((stmt.bind_text(1, stcl) != Sqlite.OK) ||
           (stmt.bind_text(2, stcl) != Sqlite.OK) ||
           (stmt.bind_text(3, stcl) != Sqlite.OK) ||
           (stmt.bind_text(4, stcl) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item((ItemType)stmt.column_int(2), stmt.column_text(4), stmt.column_int(3));
            i.source_id = get_source_id();
            i.stamp = get_current_stamp(get_source_id());
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
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ORDER BY ar.caseless_name ASC, al.caseless_name ASC, t.tracknumber ASC";
    
    public override TrackData[]? get_all_tracks(string searchtext) {
        Statement stmt;
        TrackData[] retv = {};
        string stcl = "%%%s%%".printf(searchtext.casefold());
        this.db.prepare_v2(STMT_ALL_TRACKDATA , -1, out stmt);
        
        if((stmt.bind_text(1, stcl) != Sqlite.OK) ||
           (stmt.bind_text(2, stcl) != Sqlite.OK) ||
           (stmt.bind_text(3, stcl) != Sqlite.OK) ||
           (stmt.bind_text(4, stcl) != Sqlite.OK) ||
           (stmt.bind_int (5, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK)) {
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
            val.item.stamp = get_current_stamp(get_source_id());
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
            i.stamp = get_current_stamp(get_source_id());
        }
        return (owned)i;
    }

    private static const string STMT_STREAM_TD_FOR_ID =
        "SELECT name, uri FROM streams WHERE id = ?";

    public override bool get_stream_trackdata_for_item(Item? item, out TrackData val) {
        return_val_if_fail(item.stamp == get_current_stamp(get_source_id()), false);
        Statement stmt;
        val = new TrackData();
        this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, out stmt);
            
        stmt.reset();
        if(stmt.bind_int (1, item.db_id) != Sqlite.OK) {
            this.db_error();
            return false;
        }
        if(stmt.step() == Sqlite.ROW) {
            val.artist      = EMPTYSTRING;
            val.album       = EMPTYSTRING;
            val.title       = stmt.column_text(0);
            val.item        = Item(ItemType.STREAM, stmt.column_text(1), item.db_id);
            val.item.text   = stmt.column_text(0);
            val.item.source_id = get_source_id();
            val.item.stamp = item.stamp;
        }
        else {
            print("get_stream_td_for_id: track is not in db. ID: %d\n", item.db_id);
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
            val.item.stamp = get_current_stamp(get_source_id());
            val.genre       = stmt.column_text(7);
            val.year        = stmt.column_int(8);
            retval = true;
        }
        if((val.artist ==EMPTYSTRING) || (val.artist==null)) {
            val.artist = UNKNOWN_ARTIST;
        }
        if((val.album == EMPTYSTRING) || (val.album== null)) {
            val.album = UNKNOWN_ALBUM;
        }
        if((val.genre == EMPTYSTRING) || (val.genre== null)) {
            val.genre = UNKNOWN_GENRE;
        }
        if((val.title == EMPTYSTRING) || (val.title== null)) {
            val.title = UNKNOWN_TITLE;
            File file = File.new_for_uri(uri);
            string fpath = file.get_path();
            string fileBasename = EMPTYSTRING;
            if(fpath!=null) fileBasename = GLib.Filename.display_basename(fpath);
            val.title = fileBasename;
        }
        return retval;
    }

    private static const string STMT_GET_MEDIA_FOLDERS =
        "SELECT name FROM media_folders GROUP BY utf8_lower(name)";

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
            i.stamp = get_current_stamp(get_source_id());
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
            item.stamp = get_current_stamp(get_source_id());
            item.source_id = get_source_id();
            vals += item;
        }
        if(vals.length == 0)
            return null;
        return (owned)vals;
    }

    private static const string STMT_GET_SOME_LASTUSED_ITEMS =
        "SELECT mediatype, uri, id, source, artist, album, title, length, genre, year, tracknumber FROM lastused LIMIT ? OFFSET ?";
//        "SELECT mediatype, uri, id FROM lastused LIMIT ? OFFSET ?";
    public TrackData[] get_some_lastused_items(int limit, int offset) {
        TrackData[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_SOME_LASTUSED_ITEMS, -1, out stmt);
        
        if((stmt.bind_int(1, limit)  != Sqlite.OK) ||
           (stmt.bind_int(2, offset) != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        
        while(stmt.step() == Sqlite.ROW) {
            var td = new TrackData();
            td.item = Item((ItemType)stmt.column_int(0), stmt.column_text(1), stmt.column_int(2));
            td.item.text   = stmt.column_text(3);
            td.item.stamp  = get_current_stamp(get_source_id());
            td.artist      = stmt.column_text(4);
            td.album       = stmt.column_text(5);
            td.title       = stmt.column_text(6);
            td.length      = length_string_to_int(stmt.column_text(7));
            td.genre       = stmt.column_text(8);
            if(stmt.column_text(9) != null && stmt.column_text(9) != EMPTYSTRING)
                td.year        = int.parse(stmt.column_text(9));
            if(stmt.column_text(10) != null && stmt.column_text(10) != EMPTYSTRING)
                td.tracknumber = int.parse(stmt.column_text(10));
            val += td;
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
            td.item.stamp = get_current_stamp(get_source_id());
            td.item.text      = stmt.column_text(2);
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_VIDEO_ITEMS =
        "SELECT DISTINCT t.title, t.id, u.name FROM items t, uris u WHERE t.uri = u.id AND t.mediatype = ? AND (t.caseless_name LIKE ?) GROUP BY t.caseless_name ORDER BY t.caseless_name DESC";

    public Item[]? get_video_items(string searchtext) {
        Item[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_VIDEO_ITEMS, -1, out stmt);
        
        if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK) != Sqlite.OK)||
           (stmt.bind_text(2, "%%%s%%".printf(searchtext.casefold()))     != Sqlite.OK)) {
            this.db_error();
            return (owned)val;
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item(ItemType.LOCAL_VIDEO_TRACK, stmt.column_text(2), stmt.column_int(1));
            i.source_id = get_source_id();
            i.text = stmt.column_text(0);
            i.stamp = get_current_stamp(get_source_id());
            val += i;
        }
        if(val.length == 0)
            return null;
        return (owned)val;
    }

    private static const string STMT_GET_TRACKDATA_FOR_VIDEO =
        "SELECT DISTINCT t.title, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.mediatype = ? AND (t.caseless_name LIKE ?) GROUP BY t.caseless_name ORDER BY t.caseless_name ASC";

    public TrackData[] get_trackdata_for_video(string searchtext) {
        TrackData[] val = {};
        Statement stmt;
        
        this.db.prepare_v2(STMT_GET_TRACKDATA_FOR_VIDEO, -1, out stmt);
        
        if((stmt.bind_int (1, (int)ItemType.LOCAL_VIDEO_TRACK)        != Sqlite.OK)||
           (stmt.bind_text(2, "%%%s%%".printf(searchtext.casefold())) != Sqlite.OK)) {
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
            td.item.stamp = get_current_stamp(get_source_id());
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
            td.item.stamp = get_current_stamp(get_source_id());
            val += td;
        }
        return (owned)val;
    }

    private static const string STMT_GET_ARTISTS_WITH_GENRE_AND_SEARCH =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al, genres g, artists art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.genre = g.id AND (t.caseless_name LIKE ? OR al.caseless_name LIKE ? OR ar.caseless_name LIKE ? OR art.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND g.id = ? AND t.mediatype = ? ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ARTISTS_WITH_GENRE =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, genres g WHERE t.artist = ar.id AND t.genre = g.id AND g.id = ? AND t.mediatype = ? ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_ARTISTS_WITH_SEARCH =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al, genres g, artists art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.genre = g.id AND (t.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR ar.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ORDER BY ar.caseless_name COLLATE CUSTOM01 DESC";

    private static const string STMT_GET_ARTISTS =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t WHERE t.artist = ar.id AND t.mediatype = ? ORDER BY ar.caseless_name COLLATE CUSTOM01 DESC";
    
    public override Item[] get_artists(string searchtext,
                                       CollectionSortMode sort_mode,
                                       HashTable<ItemType,Item?>? items = null
                                       ) {
        uint32 stmp = get_current_stamp(get_source_id());
        Item[] val = {};
        
        switch(sort_mode) {
            case CollectionSortMode.GENRE_ARTIST_ALBUM:
                Item? genre = items.lookup(ItemType.COLLECTION_CONTAINER_GENRE);
                assert(genre != null);
                assert(genre.stamp == stmp);
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    get_artists_with_genre_and_search_stmt.reset();
                    if(get_artists_with_genre_and_search_stmt.bind_text(1, stcl) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_text(2, stcl) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_text(3, stcl) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_text(4, stcl) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_text(5, stcl) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_int (6, genre.db_id) != Sqlite.OK ||
                       get_artists_with_genre_and_search_stmt.bind_int (7, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                    while(get_artists_with_genre_and_search_stmt.step() == Sqlite.ROW) {
                        Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, 
                                      get_artists_with_genre_and_search_stmt.column_int(0));
                        i.text = get_artists_with_genre_and_search_stmt.column_text(1);
                        i.source_id = get_source_id();
                        i.stamp = genre.stamp;
                        val += i;
                    }
                }
                else {
                    get_artists_with_genre_and_search2_stmt.reset();
                    if(get_artists_with_genre_and_search2_stmt.bind_int(1, genre.db_id) != Sqlite.OK ||
                       get_artists_with_genre_and_search2_stmt.bind_int(2, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                    while(get_artists_with_genre_and_search2_stmt.step() == Sqlite.ROW) {
                        Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, get_artists_with_genre_and_search2_stmt.column_int(0));
                        i.text = get_artists_with_genre_and_search2_stmt.column_text(1);
                        i.source_id = get_source_id();
                        i.stamp = genre.stamp;
                        val += i;
                    }
                }
                return (owned)val;
            case CollectionSortMode.ARTIST_ALBUM_TITLE:
            default:
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    get_artists_with_search_stmt.reset();
                    if(get_artists_with_search_stmt.bind_text(1, stcl) != Sqlite.OK ||
                       get_artists_with_search_stmt.bind_text(2, stcl) != Sqlite.OK ||
                       get_artists_with_search_stmt.bind_text(3, stcl) != Sqlite.OK ||
                       get_artists_with_search_stmt.bind_text(4, stcl) != Sqlite.OK ||
                       get_artists_with_search_stmt.bind_text(5, stcl) != Sqlite.OK ||
                       get_artists_with_search_stmt.bind_int (6, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                    while(get_artists_with_search_stmt.step() == Sqlite.ROW) {
                        Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, get_artists_with_search_stmt.column_int(0));
                        i.text = get_artists_with_search_stmt.column_text(1);
                        i.source_id = get_source_id();
                        i.stamp = stmp;
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
                        i.stamp = stmp;
                        val += i;
                    }
                }
                return (owned)val;
        }
    }
    
//    public Item[] get_artists(string searchtext = EMPTYSTRING,
//                              HashTable<ItemType,Item?>? items = null,
//                              SortDirection sortdir = SortDirection.DESCENDING
//                              ) {
//        uint32 stmp = get_current_stamp(get_source_id());
//        Item[] val = {};
//        const string STMT_GET_ARTISTS =
//            "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al, genres g 
//                WHERE t.artist = ar.id 
//                    AND t.album = al.id 
//                    AND t.genre = g.id 
//                    AND t.mediatype = ?
//            ";
//        string sql = STMT_GET_ARTISTS;
//        bool search = false;
//        Statement stmt;
//        if(searchtext != EMPTYSTRING) {
//            sql = sql + " AND (utf8_lower(t.title) LIKE ? OR 
//                               utf8_lower(al.name) LIKE ? OR 
//                               utf8_lower(ar.name) LIKE ? OR 
//                               utf8_lower(g.name) LIKE ?)
//                        ";
//            search = true;
//        }
//        int genre = -1;
//        if(items != null) {
//            foreach(unowned ItemType it in items.get_keys() ) {
//                switch(it) {
//                    case ItemType.COLLECTION_CONTAINER_GENRE:
//                        sql = sql + " AND g.id = ?";
//                        genre = (search ? 6 : 2);
//                        break;
//                    case ItemType.UNKNOWN:
//                    default:
//                        print("this should not happen #100\n");
//                        assert_not_reached();
//                        break;
//                }
//            }
//        }
//        if(sortdir == SortDirection.DESCENDING)
//            sql = sql + " ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";
//        else
//            sql = sql + " ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 ASC";
//        
//        this.db.prepare_v2(sql, -1, out stmt);
//        if(search) {
//            string st = "%%%s%%".printf(searchtext);
//            if(stmt.bind_int (1, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK ||
//               stmt.bind_text(2, st) != Sqlite.OK ||
//               stmt.bind_text(3, st) != Sqlite.OK ||
//               stmt.bind_text(4, st) != Sqlite.OK ||
//               stmt.bind_text(5, st) != Sqlite.OK) {
//                this.db_error();
//                return (owned)val;
//            }
//        }
//        else {
//            if(stmt.bind_int (1, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
//                this.db_error();
//                return (owned)val;
//            }
//        }
//        if(genre > -1) {
//            if(stmt.bind_int(genre,
//                             items.lookup(ItemType.COLLECTION_CONTAINER_GENRE).db_id) != Sqlite.OK) {
//                this.db_error();
//                return (owned)val;
//            }
//        }
//        //print("sql: \"%s\"\n", stmt.sql());
//        while(stmt.step() == Sqlite.ROW) {
//            Item i = Item(ItemType.COLLECTION_CONTAINER_ARTIST,
//                          null,
//                          stmt.column_int(0)
//            );
//            i.text = stmt.column_text(1);
//            i.source_id = get_source_id();
//            i.stamp = stmp;
//            val += i;
//        }
//        return (owned)val;
//    }

    private static const string STMT_GET_GENRES_WITH_SEARCH =
        "SELECT DISTINCT g.id, g.name FROM artists ar, items t, albums al, genres g, artists art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.genre = g.id AND (al.caseless_name LIKE ? OR ar.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ORDER BY g.caseless_name DESC";

    private static const string STMT_GET_GENRES =
        "SELECT DISTINCT g.id, g.name FROM genres g, items t WHERE t.genre = g.id AND t.mediatype = ? ORDER BY g.caseless_name DESC";
    
    public Item[] get_genres_with_search(string searchtext) {
        Item[] val = {};
        uint32 stmp = get_current_stamp(get_source_id());
        if(searchtext != EMPTYSTRING) {
            string stcl = "%%%s%%".printf(searchtext.casefold());
            get_genres_with_search_stmt.reset();
            if(get_genres_with_search_stmt.bind_text(1, stcl) != Sqlite.OK ||
               get_genres_with_search_stmt.bind_text(2, stcl) != Sqlite.OK ||
               get_genres_with_search_stmt.bind_text(3, stcl) != Sqlite.OK ||
               get_genres_with_search_stmt.bind_text(4, stcl) != Sqlite.OK ||
               get_genres_with_search_stmt.bind_text(5, stcl) != Sqlite.OK ||
               get_genres_with_search_stmt.bind_int (6, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_genres_with_search_stmt.step() == Sqlite.ROW) {
                Item i = Item(ItemType.COLLECTION_CONTAINER_GENRE,
                              null,
                              get_genres_with_search_stmt.column_int(0)
                );
                i.text = get_genres_with_search_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stmp;
                val += i;
            }
        }
        else {
            get_genres_with_search2_stmt.reset();
            if(get_genres_with_search2_stmt.bind_int(1, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_genres_with_search2_stmt.step() == Sqlite.ROW) {
                Item i = Item(ItemType.COLLECTION_CONTAINER_GENRE, null, get_genres_with_search2_stmt.column_int(0));
                i.text = get_genres_with_search2_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stmp;
                val += i;
            }
        }
        return (owned)val;
    }

    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? GROUP BY t.caseless_name ORDER BY t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND t.mediatype = ? GROUP BY t.caseless_name ORDER BY t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_GENRE_AND_SEARCH =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND g.id = ? AND t.mediatype = ? GROUP BY t.caseless_name ORDER BY t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID_WITH_GENRE =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND g.id = ? AND t.mediatype = ? GROUP BY t.caseless_name ORDER BY t.tracknumber ASC, t.caseless_name ASC";
    
    public override TrackData[]? get_trackdata_for_album(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items) {
        TrackData[] val = {};
        Statement stmt;
        Item? album = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUM);
        if(album == null || 
           album.stamp != get_current_stamp(get_source_id()))
            return null;
        Item? genre = items.lookup(ItemType.COLLECTION_CONTAINER_GENRE);
//        switch(sort_mode) {
        if(genre != null) {
//            case CollectionSortMode.GENRE_ARTIST_ALBUM:
                if(genre.stamp != get_current_stamp(get_source_id()))
                    return null;
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_GENRE_AND_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, album.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, genre.db_id) != Sqlite.OK ||
                       stmt.bind_int (8, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_GENRE, -1, out stmt);
                    if(stmt.bind_int(1, album.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, genre.db_id)  != Sqlite.OK ||
                       stmt.bind_int(3, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return null;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    TrackData td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = album.stamp;
                    //print("td.albumartist: %s    art: %s\n", td.albumartist, td.artist);
                    td.albumartist = stmt.column_text(11);
                    td.artist      = //(stmt.column_text(5).down() == "various artists" && 
                                       //                              td.albumartist != "*" ? 
                                         //                               td.albumartist :
                                                                        stmt.column_text(5);//);
                    td.album       = stmt.column_text(6);
                    td.title       = stmt.column_text(0);
                    td.item        = i;
                    td.tracknumber = stmt.column_int(3);
                    td.length      = stmt.column_int(7);
                    td.genre       = stmt.column_text(8);
                    td.year        = stmt.column_int(9);
                    td.is_compilation = (stmt.column_int(10) != 0 ? true : false);
                    val += td;
                }
                return (owned)val;
            }
            else {
//           case CollectionSortMode.ARTIST_ALBUM_TITLE:
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, album.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
                    if(stmt.bind_int(1, album.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return null;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    TrackData td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = album.stamp;
                    
                    td.albumartist = stmt.column_text(11);
                    td.artist      = //(stmt.column_text(5).down() == "various artists" && 
                                       //                              td.albumartist != "*" ? 
                                         //                               td.albumartist :
                                                                        stmt.column_text(5);//);
                    td.album       = stmt.column_text(6);
                    td.title       = stmt.column_text(0);
                    td.item        = i;
                    td.tracknumber = stmt.column_int(3);
                    td.length      = stmt.column_int(7);
                    td.genre       = stmt.column_text(8);
                    td.year        = stmt.column_int(9);
                    td.is_compilation = (stmt.column_int(10) != 0 ? true : false);
                    val += td;
                }
                return (owned)val;
//            default:
//                break;
        }
    }
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_GENRE_AND_SEARCH =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name FROM artists ar, items t, albums al, uris u, genres g, artists art  WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND g.id = ? AND t.mediatype = ? GROUP BY t.caseless_name, al.id ORDER BY al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_GENRE =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists art  WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND g.id = ? AND t.mediatype = ? GROUP BY t.caseless_name, al.id ORDER BY al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name  FROM artists ar, items t, albums al, uris u, genres g, artists art  WHERE t.artist = ar.id AND t.album = al.id AND t.album_artist = art.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? GROUP BY t.caseless_name, al.id ORDER BY al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, al.is_compilation, art.name FROM artists ar, items t, albums al, uris u, genres g, artists art  WHERE t.artist = ar.id AND t.album = al.id AND t.album_artist = art.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND t.mediatype = ? GROUP BY t.caseless_name, al.id ORDER BY al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    public override TrackData[]? get_trackdata_for_artist(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items) {
        TrackData[] val = {};
        Statement stmt;
        Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ARTIST);
        if(artist == null || 
           artist.stamp != get_current_stamp(get_source_id()))
            return null;
        Item? genre = items.lookup(ItemType.COLLECTION_CONTAINER_GENRE);
//        if(genre == null) 
//            return null;
        if(genre != null) {
            if(genre.stamp != get_current_stamp(get_source_id()))
                return null;
//            case CollectionSortMode.GENRE_ARTIST_ALBUM:
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext);
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_GENRE_AND_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, genre.db_id) != Sqlite.OK ||
                       stmt.bind_int (8, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_GENRE, -1, out stmt);
                    if(stmt.bind_int(1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, genre.db_id)  != Sqlite.OK ||
                       stmt.bind_int(3, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return null;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    TrackData td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = genre.stamp;
                    
                    td.albumartist = stmt.column_text(11);
                    td.artist      = 
//                    (stmt.column_text(5).down() == stmt.column_text(5);
//                                                                       "various artists" && 
//                                                                     td.albumartist != "*" ? 
//                                                                        td.albumartist :
                                                                        stmt.column_text(5);//);
//                    td.artist      = stmt.column_text(5);
                    td.is_compilation = (stmt.column_int(10) == 1 ? true : false);
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
            else {
//            case CollectionSortMode.ARTIST_ALBUM_TITLE:
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext);
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
                    if(stmt.bind_int(1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return null;
                    }
                }        
                while(stmt.step() == Sqlite.ROW) {
                    TrackData td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = artist.stamp;
                    
                    td.albumartist = stmt.column_text(11);
                    td.artist      = stmt.column_text(5);
//                    (stmt.column_text(5).down() == "various artists" && 
//                                                                     td.albumartist != "*" ? 
//                                                                        td.albumartist :
//                                                                        stmt.column_text(5));
//                    td.is_compilation = (stmt.column_int(10) == 1 ? true : false);
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
//            default:
//                break;
        }
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
            i.stamp = get_current_stamp(get_source_id());
        }
        return (owned)i;
    }

    private static const string STMT_GET_GENREITEM_BY_GENREID_WITH_SEARCH =
        "SELECT DISTINCT g.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND g.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_GENREITEM_BY_GENREID =
        "SELECT DISTINCT g.name FROM artists ar, items t, genres g WHERE t.artist = ar.id AND t.genre = g.id AND g.id = ? ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC";
    
    // function used only to verify if an item matches the searchtext
    public Item? get_genreitem_by_genreid(string searchtext, int32 id, uint32 stmp) {
        return_val_if_fail(stmp == get_current_stamp(get_source_id()), null);
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        if(searchtext != EMPTYSTRING) {
            string stcl = "%%%s%%".printf(searchtext.casefold());
            this.db.prepare_v2(STMT_GET_GENREITEM_BY_GENREID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, stcl) != Sqlite.OK) ||
               (stmt.bind_text(3, stcl) != Sqlite.OK) ||
               (stmt.bind_text(4, stcl) != Sqlite.OK) ||
               (stmt.bind_text(5, stcl) != Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_GENREITEM_BY_GENREID, -1, out stmt);
            if((stmt.bind_int(1, id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)i;
            }
        }
        if(stmt.step() == Sqlite.ROW) {
            i = Item(ItemType.COLLECTION_CONTAINER_GENRE, null, id);
            i.text = stmt.column_text(0);
            i.source_id = get_source_id();
            i.stamp = stmp;
        }
        return (owned)i;
    }

    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?)";
    
    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
    
    // function used only to verify if an item matches the searchtext
    public override Item? get_artistitem_by_artistid(string searchtext, int32 id, uint32 stmp) {
        return_val_if_fail(stmp == get_current_stamp(get_source_id()), null);
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        if(searchtext != EMPTYSTRING) {
            string stcl = "%%%s%%".printf(searchtext.casefold());
            this.db.prepare_v2(STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, id) != Sqlite.OK) ||
               (stmt.bind_text(2, stcl) != Sqlite.OK) ||
               (stmt.bind_text(3, stcl) != Sqlite.OK) ||
               (stmt.bind_text(4, stcl) != Sqlite.OK) ||
               (stmt.bind_text(5, stcl) != Sqlite.OK)) {
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
            i.stamp = stmp;
        }
        return (owned)i;
    }

    private static const string STMT_GET_TRACKDATA_BY_TITLEID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, art.name, al.is_compilation FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
    
    private static const string STMT_GET_TRACKDATA_BY_GENRE_WITH_SEARCH =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, art.name, al.is_compilation  FROM artists ar, items t, albums al, uris u, genres g, artists art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND g.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? GROUP BY utf8_lower(t.title) ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC, al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_GENRE =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year, art.name, al.is_compilation  FROM artists ar, items t, albums al, uris u, genres g, artists AS art WHERE t.artist = ar.id AND t.album_artist = art.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND g.id = ? AND t.mediatype = ? GROUP BY t.caseless_name ORDER BY ar.caseless_name COLLATE CUSTOM01 ASC, al.caseless_name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.caseless_name ASC";
    
    public override TrackData[] get_trackdata_for_item(string searchtext, Item? item) {
        return_val_if_fail(item != null && item.stamp == get_current_stamp(get_source_id()), null);
        
        Statement stmt;
        TrackData[] val = {};
        switch(item.type) {
            case ItemType.LOCAL_AUDIO_TRACK:
            case ItemType.LOCAL_VIDEO_TRACK:
                this.db.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
                
                if((stmt.bind_int(1, item.db_id)!=Sqlite.OK)) {
                    this.db_error();
                    return (owned)val;
                }
                TrackData td = null; 
                if(stmt.step() == Sqlite.ROW) {
                    td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = item.stamp;
                    
                    td.albumartist = stmt.column_text(10);
                    td.artist      = stmt.column_text(5);
//                                        (stmt.column_text(5).down() == "various artists" && 
//                                                                     td.albumartist != "*" ? 
//                                                                        td.albumartist :
//                                                                        stmt.column_text(5));
                    td.album       = stmt.column_text(6);
                    td.title       = stmt.column_text(0);
                    td.item        = i;
                    td.tracknumber = stmt.column_int(3);
                    td.length      = stmt.column_int(7);
                    td.genre       = stmt.column_text(8);
                    td.year        = stmt.column_int(9);
                    td.is_compilation = (stmt.column_int(11) != 0 ? true : false);
                    val += td;
                }
                return (owned)val;
            case ItemType.COLLECTION_CONTAINER_GENRE:
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext);
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_GENRE_WITH_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, item.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_TRACKDATA_BY_GENRE, -1, out stmt);
                    if(stmt.bind_int(1, item.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    TrackData td = new TrackData();
                    Item? i = Item((ItemType)stmt.column_int(1), stmt.column_text(4), stmt.column_int(2));
                    i.source_id = get_source_id();
                    i.stamp = item.stamp;
                    
//                    td.albumartist = stmt.column_text(10);
//                    td.artist      = stmt.column_text(5);
                    td.albumartist = stmt.column_text(10);
                    td.artist      = stmt.column_text(5); 
//                                                        (stmt.column_text(5).down() == "various artists" && 
//                                                                     td.albumartist != "*" ? 
//                                                                        td.albumartist :
//                                                                        stmt.column_text(5));

                    td.album       = stmt.column_text(6);
                    td.title       = stmt.column_text(0);
                    td.item        = i;
                    td.tracknumber = stmt.column_int(3);
                    td.length      = stmt.column_int(7);
                    td.genre       = stmt.column_text(8);
                    td.year        = stmt.column_int(9);
                    td.is_compilation = (stmt.column_int(11) != 0 ? true : false);
                    val += td;
                }
                return (owned)val;
            default:
                break;
        }
        return (owned)val;
    }

    private static const string STMT_GET_ALBUMS_WITH_SEARCH =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g, artists art WHERE ar.id = t.artist AND art.id = t.album_artist AND al.id = t.album AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR art.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ORDER BY al.year ASC, al.caseless_name COLLATE CUSTOM01 ASC";
    private static const string STMT_GET_ALBUMS_WITH_SEARCH_2 =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g, artists art WHERE ar.id = t.artist AND art.id = t.album_artist AND al.id = t.album AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR art.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ORDER BY al.caseless_name COLLATE CUSTOM01 ASC";


    private static const string STMT_GET_ALBUMS =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t WHERE ar.id = al.artist AND al.id = t.album AND ar.id = ? AND t.mediatype = ? ORDER BY al.year ASC, al.caseless_name COLLATE CUSTOM01 ASC";
    private static const string STMT_GET_ALBUMS_2 =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t WHERE ar.id = al.artist AND al.id = t.album AND ar.id = ? AND t.mediatype = ? ORDER BY al.caseless_name COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ALBUMS_WITH_GENRE_AND_SEARCH =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g, artists art WHERE ar.id = t.artist AND art.id = t.album_artist AND al.id = t.album AND t.genre = g.id AND ar.id = ? AND (ar.caseless_name LIKE ? OR al.caseless_name LIKE ? OR art.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND g.id = ? AND t.mediatype = ? ORDER BY al.year ASC, al.caseless_name COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ALBUMS_WITH_GENRE =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g WHERE ar.id = al.artist AND t.genre = g.id AND al.id = t.album AND ar.id = ? AND g.id = ? AND t.mediatype = ? ORDER BY al.year ASC, al.caseless_name COLLATE CUSTOM01 ASC";

    public override Item[] get_albums(string searchtext,
                                       CollectionSortMode sort_mode,
                                       HashTable<ItemType,Item?>? items = null) {
//        return_val_if_fail(stmp == get_current_stamp(get_source_id()), null);
        Item[] val = {};
        Statement stmt;
        switch(sort_mode) {
            case CollectionSortMode.GENRE_ARTIST_ALBUM:
                Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ARTIST);
                Item? genre  = items.lookup(ItemType.COLLECTION_CONTAINER_GENRE);
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    this.db.prepare_v2(STMT_GET_ALBUMS_WITH_GENRE_AND_SEARCH, -1, out stmt);
                    if(stmt.bind_int (1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, genre.db_id) != Sqlite.OK||
                       stmt.bind_int (8, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    this.db.prepare_v2(STMT_GET_ALBUMS_WITH_GENRE, -1, out stmt);
                    if(stmt.bind_int(1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_int(2, genre.db_id) != Sqlite.OK||
                       stmt.bind_int(3, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    Item i      = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
                    i.text      = stmt.column_text(0);
                    i.stamp     = get_current_stamp(get_source_id());
                    i.source_id = get_source_id();
                    val += i;
                }
                return (owned)val;
            case CollectionSortMode.ARTIST_ALBUM_TITLE:
            default:
                Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ARTIST);
                if(searchtext != EMPTYSTRING) {
                    string stcl = "%%%s%%".printf(searchtext.casefold());
                    string stmt_str;
                    if(artist.db_id != 1) { 
                        stmt_str = STMT_GET_ALBUMS_WITH_SEARCH;
                    }
                    else { // VA
                        stmt_str = STMT_GET_ALBUMS_WITH_SEARCH_2;
                    }
                    this.db.prepare_v2(stmt_str, -1, out stmt);
                    if(stmt.bind_int (1, artist.db_id) != Sqlite.OK ||
                       stmt.bind_text(2, stcl) != Sqlite.OK ||
                       stmt.bind_text(3, stcl) != Sqlite.OK ||
                       stmt.bind_text(4, stcl) != Sqlite.OK ||
                       stmt.bind_text(5, stcl) != Sqlite.OK ||
                       stmt.bind_text(6, stcl) != Sqlite.OK ||
                       stmt.bind_int (7, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                else {
                    string stmt_str;
                    if(artist.db_id != 1) { 
                        stmt_str = STMT_GET_ALBUMS;
                    }
                    else { // VA
                        stmt_str = STMT_GET_ALBUMS_2;
                    }
                    this.db.prepare_v2(stmt_str, -1, out stmt);
                    if((stmt.bind_int(1, artist.db_id)!=Sqlite.OK) ||
                       stmt.bind_int (2, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                        this.db_error();
                        return (owned)val;
                    }
                }
                while(stmt.step() == Sqlite.ROW) {
                    Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
                    i.text = stmt.column_text(0);
                    i.stamp = get_current_stamp(get_source_id());
                    i.source_id = get_source_id();
                    val += i;
                }
                return (owned)val;
        }
    }

    private static const string STMT_GET_ALL_ALBUMS =
        "SELECT al.name, al.id, ar.name, al.is_compilation, g.name, al.year FROM artists ar, albums al, items t, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND t.mediatype = ?";

    private static const string STMT_GET_ALL_ALBUMS_WITH_SEARCH =
        "SELECT al.name, al.id, ar.name, al.is_compilation, g.name, al.year FROM artists ar, albums al, items t, genres g, artists art WHERE ar.id = t.artist AND art.id = t.album_artist AND al.id = t.album AND t.genre = g.id AND (ar.caseless_name LIKE ? OR art.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ?";

    private static const string STMT_GET_ALL_ALBUMS_MOST_PLAYED =
        "SELECT al.name, al.id, ar.name, al.is_compilation, g.name, al.year FROM artists ar, items t, albums al, uris u, statistics st, genres g WHERE st.playcount > 0 AND t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND st.uri = u.name AND t.genre = g.id AND t.mediatype = ? ";//" ORDER BY st.playcount DESC LIMIT 100";

    private static const string STMT_GET_ALL_ALBUMS_MOST_PLAYED_WITH_SEARCH =
        "SELECT al.name, al.id, ar.name, al.is_compilation, g.name, al.year FROM artists ar, items t, albums al, uris u, statistics st, genres g, artists art WHERE st.playcount > 0 AND t.artist = ar.id AND t.album = al.id AND art.id = t.album_artist AND t.uri = u.id AND st.uri = u.name AND t.genre = g.id AND (ar.caseless_name LIKE ? OR art.caseless_name LIKE ? OR al.caseless_name LIKE ? OR t.caseless_name LIKE ? OR g.caseless_name LIKE ?) AND t.mediatype = ? ";//" ORDER BY st.playcount DESC LIMIT 100";

    public AlbumData[] get_all_albums_with_search(string searchtext, 
                                                  string? sorting = "ARTIST",
                                                  string? direction = "ASC") {
        AlbumData[] list = {};
        Statement stmt;
        string? dir = direction;
        if(dir == null || dir == EMPTYSTRING)
            dir = "ASC";
        if(searchtext != EMPTYSTRING) {
            string stcl = "%%%s%%".printf(searchtext.casefold());
            string sql = STMT_GET_ALL_ALBUMS_WITH_SEARCH;
            switch(sorting) {
                case "PLAYCOUNT":
                    sql = STMT_GET_ALL_ALBUMS_MOST_PLAYED_WITH_SEARCH + 
                        " GROUP BY al.id ORDER BY st.playcount %s LIMIT 300".printf(dir);
                    break;
                case "YEAR":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY al.year %s".printf(dir);
                    break;
                case "GENRE":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY g.caseless_name COLLATE CUSTOM01 %s, ar.caseless_name COLLATE CUSTOM01 %s".printf(dir, dir);
                    break;
                case "ALBUM":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY al.caseless_name COLLATE CUSTOM01 %s".printf(dir);
                    break;
                case "ARTIST":
                default:
                    sql = sql +
                        " GROUP BY al.id ORDER BY ar.caseless_name COLLATE CUSTOM01 %s, al.caseless_name COLLATE CUSTOM01 %s".printf(dir, dir);
                    break;
            }
            this.db.prepare_v2(sql, -1, out stmt);
            if(stmt.bind_text(1, stcl) != Sqlite.OK ||
               stmt.bind_text(2, stcl) != Sqlite.OK ||
               stmt.bind_text(3, stcl) != Sqlite.OK ||
               stmt.bind_text(4, stcl) != Sqlite.OK ||
               stmt.bind_text(5, stcl) != Sqlite.OK ||
               stmt.bind_int (6, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)list;
            }
        }
        else {
            string sql = STMT_GET_ALL_ALBUMS;
            switch(sorting) {
                case "PLAYCOUNT":
                    sql = STMT_GET_ALL_ALBUMS_MOST_PLAYED + 
                        " GROUP BY al.id ORDER BY st.playcount %s LIMIT 300".printf(dir);
                    break;
                case "YEAR":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY al.year %s, ar.caseless_name COLLATE CUSTOM01 %s".printf(dir, dir);
                    break;
                case "GENRE":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY g.caseless_name COLLATE CUSTOM01 %s, ar.caseless_name COLLATE CUSTOM01 %s".printf(dir, dir);
                    break;
                case "ALBUM":
                    sql = sql + 
                        " GROUP BY al.id ORDER BY al.caseless_name COLLATE CUSTOM01 %s".printf(dir);
                    break;
                case "ARTIST":
                default:
                    sql = sql +
                        " GROUP BY al.id ORDER BY ar.caseless_name COLLATE CUSTOM01 %s, al.caseless_name COLLATE CUSTOM01 %s".printf(dir, dir);
                    break;
            }
            this.db.prepare_v2(sql, -1, out stmt);
            if(stmt.bind_int(1, ItemType.LOCAL_AUDIO_TRACK) != Sqlite.OK) {
                this.db_error();
                return (owned)list;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            AlbumData ad = new AlbumData();
            Item? it = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
            it.stamp = get_current_stamp(get_source_id());
            ad.item  = it;
            ad.artist = stmt.column_text(2);
            ad.album  = stmt.column_text(0);
            ad.is_compilation = (stmt.column_int(3) != 0 ? true : false);
            ad.genre = stmt.column_text(4);
            ad.year = (uint)stmt.column_int(5);
            list += ad;
        }
        return (owned)list;
    }
}

