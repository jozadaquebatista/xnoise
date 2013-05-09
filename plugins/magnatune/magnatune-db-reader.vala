/* magnatune-db-reader.vala
 *
 * Copyright (C) 2012 - 2013  Jörn Magens
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


public class MagnatuneDatabaseReader : Xnoise.DataSource {
//    private const string DATABASE_NAME = "/tmp/xnoise_magnatune.sqlite";
    private string DATABASE;
    private Statement get_genres_with_search_stmt;
    private Statement get_genres_with_search2_stmt;

    
    private string _username;
    internal string username { 
        get {
            return _username;
        }
        set {
            _username = value;
            if(_username != null &&
               _username != EMPTYSTRING &&
               _password != null &&
               _password != EMPTYSTRING)
                login_data_available = true;
            else
                login_data_available = false;
        }
    }
    
    private string _password;
    internal string password {
        get {
            return _password;
        }
        set {
            _password = value;
            if(_username != null &&
               _username != EMPTYSTRING &&
               _password != null &&
               _password != EMPTYSTRING) {
                login_data_available = true;
                http_replacement = "http://%s:%s@download.magnatune.com".printf(
                                                                           Uri.escape_string(_username, null, true),
                                                                           Uri.escape_string(_password, null, true)
                                                                           );
            }
            else {
                login_data_available = false;
            }
        }
    }
    private string http_replacement;
    internal bool login_data_available { get; set; }
    
    private string transform_mag_url(string original_url) {
        if(!_login_data_available)
            return original_url;
        if(original_url == null)
            return EMPTYSTRING;
        string url;
        url = original_url.replace("http://he3.magnatune.com", http_replacement);
        string suff;
        int inx;
        if((inx = url.last_index_of(".")) != -1) {
            suff = url.substring(inx + 1, url.length - inx -1);
            return url.substring(0, inx) + "_nospeech." + suff;
        }
        else {
            return url;
        }
    }
    
    private Cancellable cancel;
    
    public MagnatuneDatabaseReader(Cancellable cancel) {
        this.cancel = cancel;
        DATABASE = dbFileName();
        db = null;
        if(Sqlite.Database.open_v2(DATABASE, out db, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) {
            error("Can't open magnatune database: %s\n", (string)this.db.errmsg);
        }
        if(this.db == null) {
            error("magnatune db failed");
        }
        db.create_function_v2("utf8_lower", 1, Sqlite.ANY, null, utf8_lower, null, null, null);
        db.create_collation("CUSTOM01", Sqlite.UTF8, compare_func);
        
        this.db.prepare_v2(STMT_GET_ARTISTS_WITH_SEARCH, -1, out get_artists_with_search_stmt);
        this.db.prepare_v2(STMT_GET_ARTISTS, -1, out get_artists_with_search2_stmt);
        
        username = Xnoise.Params.get_string_value("magnatune_user");
        password = Xnoise.Params.get_string_value("magnatune_pass");
        
        this.notify["login-data-available"].connect( () => {
            if(login_data_available && !login_data_available_last) {
                renew_stamp(get_datasource_name());
                refreshed_stamp(get_current_stamp(get_source_id()));
            }
            login_data_available_last = _login_data_available;
        });
        
        this.db.prepare_v2(STMT_GET_GENRES_WITH_SEARCH, -1, out get_genres_with_search_stmt);
        this.db.prepare_v2(STMT_GET_GENRES, -1, out get_genres_with_search2_stmt);
    }

    private bool login_data_available_last;
    private static void utf8_lower(Sqlite.Context context,
                                   [CCode (array_length_pos = 1.1)] Sqlite.Value[] values) {
        context.result_text(values[0].to_text().down());
    }
    
    private static int compare_func(int alen, void* a, int blen, void* b) {
        return GLib.strcmp(((string)a).collate_key(alen), ((string)b).collate_key(blen));
    }
    
    private Sqlite.Database db;

    private string dbFileName() {
        return CONVERTED_DB;
    }

    private void db_error() {
        print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
    }

    private const string data_source_name = "MagnatuneDatabase";
    public override unowned string get_datasource_name() {
        return data_source_name;
    }

    private static const string STMT_TRACKDATA_FOR_URI =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.length, t.mediatype, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND u.name = ?";

    public override bool get_trackdata_for_uri(ref string? uri, out TrackData val) {
        bool retval = false;
        val = new TrackData();
        if(uri == null)
            return retval;
        
        uint32 stamp = get_current_stamp(get_source_id());
        Statement stmt;
        this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, out stmt);
        bool found = false;
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
            val.item.stamp = stamp;
            val.genre       = stmt.column_text(7);
            val.year        = stmt.column_int(8);
            retval = true;
            found = true;
        }
        if(found == false) {
            stmt.reset();
            string turi = transform_mag_url(uri);
            stmt.bind_text(1, turi);
            if(stmt.step() == Sqlite.ROW) {
                val.artist      = stmt.column_text(0);
                val.album       = stmt.column_text(1);
                val.title       = stmt.column_text(2);
                val.tracknumber = (uint)stmt.column_int(3);
                val.length      = stmt.column_int(4);
                val.item        = Item((ItemType)stmt.column_int(5), turi, stmt.column_int(6));
                val.item.source_id = get_source_id();
                val.item.stamp = stamp;
                val.genre       = stmt.column_text(7);
                val.year        = stmt.column_int(8);
                retval = true;
            }
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




    private static const string STMT_GET_ARTISTS_WITH_SEARCH =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND (utf8_lower(t.title) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(ar.name) LIKE ? OR utf8_lower(g.name) LIKE ?) ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";

    private static const string STMT_GET_ARTISTS =
        "SELECT DISTINCT ar.id, ar.name FROM artists ar, items t WHERE t.artist = ar.id ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 DESC";
    
    private Statement get_artists_with_search_stmt;
    private Statement get_artists_with_search2_stmt;
    
    public override Item[] get_artists(string searchtext = EMPTYSTRING,
                                       CollectionSortMode sort_mode,
                                       HashTable<ItemType,Item?>? items = null) {
        Item[] val = {};
        if(cancel.is_cancelled())
            return val;
        uint32 stamp = get_current_stamp(this.get_source_id());
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            get_artists_with_search_stmt.reset();
            if(get_artists_with_search_stmt.bind_text(1, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(2, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(3, st) != Sqlite.OK ||
               get_artists_with_search_stmt.bind_text(4, st) != Sqlite.OK) {
                this.db_error();
                return (owned)val;
            }
            while(get_artists_with_search_stmt.step() == Sqlite.ROW) {
                if(cancel.is_cancelled())
                    return val;
                Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, get_artists_with_search_stmt.column_int(0));
                i.text = get_artists_with_search_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stamp;
                val += i;
            }
        }
        else {
            get_artists_with_search2_stmt.reset();
            while(get_artists_with_search2_stmt.step() == Sqlite.ROW) {
                if(cancel.is_cancelled())
                    return val;
                Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, 
                              null, 
                              get_artists_with_search2_stmt.column_int(0)
                );
                i.text = get_artists_with_search2_stmt.column_text(1);
                i.source_id = get_source_id();
                i.stamp = stamp;
                val += i;
            }
        }
        return (owned)val;
    }




    private static const string STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g  WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ARTISTID =
        "SELECT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year  FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND ar.id = ? GROUP BY utf8_lower(t.title), al.id ORDER BY al.name COLLATE CUSTOM01 ASC, t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_for_albumartist(string searchtext,
                                                          CollectionSortMode sort_mode,
                                                          HashTable<ItemType,Item?>? items) {
        Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUMARTIST);
        return_val_if_fail(artist != null && get_current_stamp(get_source_id()) == artist.stamp, null);
        
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, artist.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ARTISTID, -1, out stmt);
            if((stmt.bind_int(1, artist.db_id)!=Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }        
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), transform_mag_url(stmt.column_text(4)), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = artist.stamp;
            
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

    public override TrackData[]? get_trackdata_for_artist(string searchtext,
                                                          CollectionSortMode sort_mode,
                                                          HashTable<ItemType,Item?>? items) {
        return get_trackdata_for_albumartist(searchtext, sort_mode, items);
    }


    public override Item? get_album_item_from_id(string searchtext, int32 id, uint32 stamp) {
        return null;
    }

    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID_WITH_SEARCH =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?)";
    
    private static const string STMT_GET_ARTISTITEM_BY_ARTISTID =
        "SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.id = ?";
    
    public override Item? get_albumartist_item_from_id(string searchtext, int32 id, uint32 stamp) {
        return_val_if_fail(get_current_stamp(get_source_id()) == stamp, null);
        Statement stmt;
        Item? i = Item(ItemType.UNKNOWN);
        i.source_id = get_source_id();
        i.stamp = stamp;
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
            i = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, id);
            i.text = stmt.column_text(0);
            i.source_id = get_source_id();
            i.stamp = stamp;
        }
        return (owned)i;
    }

    private static const string STMT_GET_SKU_BY_ALBUMID =
        "SELECT DISTINCT al.sku FROM albums al WHERE al.id = ?";
    
    internal string? get_sku_for_album(int32 id) {
        string? val = null;
        Statement stmt;
        this.db.prepare_v2(STMT_GET_SKU_BY_ALBUMID, -1, out stmt);
        if((stmt.bind_int(1, id) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        if(stmt.step() == Sqlite.ROW) {
            return stmt.column_text(0);
        }
        return val;
    }
    
    private static const string STMT_GET_SKU_BY_TITLEID =
        "SELECT DISTINCT al.sku FROM items t, albums al WHERE t.album = al.id AND t.id = ?";
    
    internal string? get_sku_for_title(int32 id) {
        string? val = null;
        Statement stmt;
        this.db.prepare_v2(STMT_GET_SKU_BY_TITLEID, -1, out stmt);
        if((stmt.bind_int(1, id) != Sqlite.OK)) {
            this.db_error();
            return null;
        }
        if(stmt.step() == Sqlite.ROW) {
            return stmt.column_text(0);
        }
        return val;
    }

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
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    private static const string STMT_GET_TRACKDATA_BY_ALBUMID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND al.id = ? GROUP BY utf8_lower(t.title) ORDER BY t.tracknumber ASC, t.title COLLATE CUSTOM01 ASC";
    
    public override TrackData[]? get_trackdata_for_album(string searchtext,
                                                         CollectionSortMode sort_mode,
                                                         HashTable<ItemType,Item?>? items) {
        Item? album = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUM);
        return_val_if_fail(get_current_stamp(get_source_id()) == album.stamp, null);
        TrackData[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, album.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_TRACKDATA_BY_ALBUMID, -1, out stmt);
            if((stmt.bind_int(1, album.db_id) != Sqlite.OK)) {
                this.db_error();
                return null;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            TrackData td = new TrackData();
            Item? i = Item((ItemType)stmt.column_int(1), transform_mag_url(stmt.column_text(4)), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = album.stamp;
            
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

    private static const string STMT_GET_ALBUMS_WITH_SEARCH =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al, items t, genres g WHERE ar.id = t.artist AND al.id = t.album AND t.genre = g.id AND ar.id = ? AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ? OR utf8_lower(g.name) LIKE ?) ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    private static const string STMT_GET_ALBUMS =
        "SELECT DISTINCT al.name, al.id FROM artists ar, albums al WHERE ar.id = al.artist AND ar.id = ? ORDER BY utf8_lower(al.name) COLLATE CUSTOM01 ASC";

    public override Item[] get_albums(string searchtext,
                                      CollectionSortMode sort_mode,
                                      HashTable<ItemType,Item?>? items) {
        Item? artist = items.lookup(ItemType.COLLECTION_CONTAINER_ALBUMARTIST);
        return_val_if_fail(artist != null &&
                             get_current_stamp(this.get_source_id()) == artist.stamp,
                           null);
        Item[] val = {};
        Statement stmt;
        if(searchtext != EMPTYSTRING) {
            string st = "%%%s%%".printf(searchtext);
            this.db.prepare_v2(STMT_GET_ALBUMS_WITH_SEARCH, -1, out stmt);
            if((stmt.bind_int (1, artist.db_id) != Sqlite.OK) ||
               (stmt.bind_text(2, st) != Sqlite.OK) ||
               (stmt.bind_text(3, st) != Sqlite.OK) ||
               (stmt.bind_text(4, st) != Sqlite.OK) ||
               (stmt.bind_text(5, st) != Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        else {
            this.db.prepare_v2(STMT_GET_ALBUMS, -1, out stmt);
            if((stmt.bind_int(1, artist.db_id)!=Sqlite.OK)) {
                this.db_error();
                return (owned)val;
            }
        }
        while(stmt.step() == Sqlite.ROW) {
            Item i = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, stmt.column_int(1));
            i.text        = stmt.column_text(0);
            i.source_id   = get_source_id();
            i.stamp       = artist.stamp;
            val += i;
        }
        return (owned)val;
    }



    private static const string STMT_GET_TRACKDATA_BY_TITLEID =
        "SELECT DISTINCT t.title, t.mediatype, t.id, t.tracknumber, u.name, ar.name, al.name, t.length, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND t.id = ?";
        
    public override TrackData[] get_trackdata_for_item(string searchterm, Item? item) {
        return_val_if_fail(item != null && get_current_stamp(get_source_id()) == item.stamp, null);
        Statement stmt;
        TrackData[] tda = {};
        this.db.prepare_v2(STMT_GET_TRACKDATA_BY_TITLEID, -1, out stmt);
        
        if((stmt.bind_int(1, item.db_id)!=Sqlite.OK)) {
            this.db_error();
            return (owned)tda;
        }
        TrackData td = null; 
        if(stmt.step() == Sqlite.ROW) {
            td = new TrackData();
            //print("transform_mag_url(stmt.column_text(4)) : %s\n", transform_mag_url(stmt.column_text(4)));
            Item? i = Item((ItemType)stmt.column_int(1), transform_mag_url(stmt.column_text(4)), stmt.column_int(2));
            i.source_id = get_source_id();
            i.stamp = item.stamp;
            
            td.artist      = stmt.column_text(5);
            td.album       = stmt.column_text(6);
            td.title       = stmt.column_text(0);
            td.item        = i;
            td.tracknumber = stmt.column_int(3);
            td.length      = stmt.column_int(7);
            td.genre       = stmt.column_text(8);
            td.year        = stmt.column_int(9);
            tda += td;
        }
        return (owned)tda;
    }

//    private static const string STMT_STREAM_TD_FOR_ID =
//        "SELECT name, uri FROM streams WHERE id = ?";

    public override bool get_stream_trackdata_for_item(Item? item, out TrackData val) {
        return_val_if_fail(item != null && get_current_stamp(get_source_id()) == item.stamp, false);
        val = null;
        TrackData[] tda = get_trackdata_for_item(global.searchtext, item);
        
        if(tda == null || tda.length == 0)
            return false;
        
        val = tda[0];
        
        return true;
    }
    
    private static const string STMT_ALL_TRACKDATA =
        "SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name, t.length, t.id, g.name, t.year FROM artists ar, items t, albums al, uris u, genres g WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.genre = g.id AND (utf8_lower(ar.name) LIKE ? OR utf8_lower(al.name) LIKE ? OR utf8_lower(t.title) LIKE ?) GROUP BY u.name ORDER BY utf8_lower(ar.name) COLLATE CUSTOM01 ASC, utf8_lower(al.name) COLLATE CUSTOM01 ASC, t.tracknumber ASC";
    
    public override TrackData[]? get_all_tracks(string searchtext) {
        Statement stmt;
        TrackData[] retv = {};
        string st = "%%%s%%".printf(searchtext);
        
        uint stamp = get_current_stamp(get_source_id());
        
        this.db.prepare_v2(STMT_ALL_TRACKDATA , -1, out stmt);
        if(stmt.bind_text(1, st) != Sqlite.OK ||
           stmt.bind_text(2, st) != Sqlite.OK ||
           stmt.bind_text(3, st) != Sqlite.OK) {
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
            val.item        = Item((ItemType)stmt.column_int(4), transform_mag_url(stmt.column_text(5)), stmt.column_int(7));
            val.item.stamp = stamp;
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
}

