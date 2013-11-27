/* xnoise-db-writer.vala
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

public class Xnoise.Database.Writer : GLib.Object {
    private Sqlite.Database db = null;
    private Statement insert_lastused_entry_statement;
    private Statement ins_va_statement;
    private Statement add_stream_statement;
    private Statement begin_statement;
    private Statement commit_statement;
//    private Statement write_media_folder_statement;
    private Statement get_media_folder_statement;
    private Statement del_media_folder_statement;
    private Statement del_streams_statement;
    private Statement get_artist_id_statement;
    private Statement insert_artist_statement;
    private Statement get_album_id_statement;
    private Statement insert_album_statement;
    private Statement get_uri_id_statement;
    private Statement get_path_id_statement;
    private Statement insert_uri_statement;
    private Statement insert_path_statement;
    private Statement get_genre_id_statement;
    private Statement insert_genre_statement;
    private Statement insert_title_statement;
    private Statement get_title_id_statement;
    private Statement delete_artists_statement;
    private Statement delete_albums_statement;
//    private Statement delete_album_names_statement;
    private Statement delete_items_statement;
    private Statement delete_uris_statement;
    private Statement delete_paths_statement;
    private Statement delete_genres_statement;
    private Statement update_album_statement;
    private Statement get_album_name_ids_statement;

    private Statement count_artist_in_items_statement;
    private Statement count_albumartist_in_items_statement;
    private Statement delete_artist_statement;

    private Statement count_genres_in_items_statement;
    private Statement delete_genre_statement;

    private Statement count_album_in_items_statement;
    private Statement delete_album_statement;

    private Statement get_statistics_id_statement;
    private Statement add_statistic_statement;
    private Statement update_playtime_statement;

    private Statement get_artist_max_id_statement;
    private Statement get_uri_max_id_statement;
    private Statement get_paths_max_id_statement;
    private Statement get_genre_max_id_statement;
    private Statement get_albums_max_id_statement;
    
    public delegate void ChangeNotificationCallback(ChangeType changetype, Item? item);
    
    public enum ChangeType {
        ADD_ARTIST,
        ADD_ALBUM,
        ADD_TITLE,
        ADD_GENRE,
        ADD_VIDEO,
        ADD_STREAM,
        REMOVE_ARTIST,
        REMOVE_ALBUM,
        REMOVE_TITLE,
        REMOVE_URI,
        CLEAR_DB,
        UPDATE_PLAYCOUNT,
        UPDATE_LASTPLAYED,
        UPDATE_RATING
    }
    
    private bool begin_stmt_used;
    
    public bool in_transaction {
        get {
            return begin_stmt_used;
        }
    }
    //SQLITE CONFIG STATEMENTS
//    private static const string STMT_PRAGMA_SET_FOREIGN_KEYS_ON =
//        "PRAGMA foreign_keys = ON;";
//    private static const string STMT_PRAGMA_GET_FOREIGN_KEYS_ON =
//        "PRAGMA foreign_keys;";

    // DBWRITER STATEMENTS
    private static const string STMT_BEGIN =
        "BEGIN";
    private static const string STMT_COMMIT =
        "COMMIT";
    private static const string STMT_DEL_MEDIA_FOLDERS =
        "DELETE FROM paths";
    private static const string STMT_DEL_RADIO_STREAM =
        "DELETE FROM streams;";
    private static const string STMT_ADD_STREAM =
        "INSERT INTO streams (name, uri) VALUES (?, ?)";
    private static const string STMT_GET_MEDIA_FOLDERS =
        "SELECT name FROM paths";
    private static const string STMT_GET_TITLE_ID =
        "SELECT id FROM items WHERE artist = ? AND album = ? AND utf8_lower(title) = ?";
    private static const string STMT_DEL_ARTISTS =
        "DELETE FROM artists";
    private static const string STMT_DEL_ALBUMS =
        "DELETE FROM albums";
//    private static const string STMT_DEL_ALBUM_NAMES =
//        "DELETE FROM album_names";
    private static const string STMT_DEL_ITEMS =
        "DELETE FROM items";
    private static const string STMT_DEL_URIS =
        "DELETE FROM uris";
    private static const string STMT_DEL_PATHS =
        "DELETE FROM paths";
    private static const string STMT_DEL_GENRES =
        "DELETE FROM genres";
    private static const string STMT_DEL_URI = 
        "DELETE FROM uris WHERE id = ?";
    private static const string STMT_DEL_ITEM = 
        "DELETE FROM items WHERE uri = ?";
    private static const string STMT_TRACKDATA_FOR_STREAM =
        "SELECT st.id, st.name FROM streams st WHERE st.name = ?";
    private static const string STMT_GET_ARTIST_FOR_URI_ID =
        "SELECT artist FROM items WHERE uri = ?";
    private static const string STMT_COUNT_ARTIST_IN_ITEMS =
        "SELECT COUNT(id) FROM items WHERE artist = ?";
    private static const string STMT_COUNT_ALBUMARTIST_IN_ITEMS =
        "SELECT COUNT(id) FROM items WHERE album_artist = ?";
    private static const string STMT_COUNT_GENRE_IN_ITEMS =
        "SELECT COUNT(id) FROM items WHERE genre = ?";
    private static const string STMT_DEL_GENRE = 
        "DELETE FROM genres WHERE id = ?";
    private static const string STMT_DEL_ARTIST = 
        "DELETE FROM artists WHERE id = ?";
    private static const string STMT_GET_ALBUM_FOR_URI_ID =
        "SELECT album FROM items WHERE uri = ?";
    private static const string STMT_COUNT_ALBUM_IN_ITEMS =
        "SELECT COUNT(id) FROM items WHERE album = ?";
    private static const string STMT_DEL_ALBUM = 
        "DELETE FROM albums WHERE id = ?";
    private static const string STMT_GET_GENRE_FOR_URI_ID =
        "SELECT genre FROM items WHERE uri = ?";
    private static const string STMT_GET_STATISTICS_ID =
        "SELECT id FROM statistics WHERE uri = ?";
    private static const string STMT_ADD_STATISTIC =
        "INSERT INTO statistics (uri, playcount) VALUES (?,0)";
    
    public Writer() throws DbError {
        this.db = null;
        this.db = get_db();
        
        if(this.db == null) 
            throw new DbError.FAILED("Cannot open database for writing.");
        
        //register my own db function
        db.create_function_v2("utf8_lower", 1, Sqlite.ANY, null, utf8_lower, null, null, null);
        
        this.begin_stmt_used = false; // initialize begin commit compare
        
        this.prepare_statements();
        
//        setup_db();
    }
    
//    private void setup_db() {
//        setup_pragmas();
//    }
    
    private static Sqlite.Database? get_db () {
        // there was more luck on creating the db on first start, if using a static function
        Sqlite.Database database = null;
        File xnoise_home = File.new_for_path(data_folder());
        File xnoisedb = xnoise_home.get_child(MAIN_DATABASE_NAME);
        if (!xnoise_home.query_exists(null)) {
            print("Cannot find settings folder!\n");
            return null;
        }
        int ret = Sqlite.Database.open_v2(xnoisedb.get_path(),
                                          out database,
                                          Sqlite.OPEN_READWRITE,
                                          null);

        if(ret != Sqlite.OK) {
            print("Cannot open database.\n");
            return null;
        }
        
        //workaround
        //check if write permissions were given (readwrite
        //succeeded instead of readonly fallback)
        if(database.exec("UPDATE items SET id=0 WHERE 0;", null, null)!= Sqlite.OK) {
            return null;
        }
        return database;
    }

    private static void utf8_lower(Sqlite.Context context, [CCode (array_length_pos = 1.1)] Sqlite.Value[] values) {
        context.result_text(values[0].to_text().down());
    }
    
    private void db_error() {
        print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
    }

    private void prepare_statements() {
        db.prepare_v2(STMT_INSERT_LASTUSED, -1, out insert_lastused_entry_statement);
        db.prepare_v2(STMT_BEGIN, -1, out begin_statement);
        db.prepare_v2(STMT_COMMIT, -1, out commit_statement);
        db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1, out get_media_folder_statement);
//        db.prepare_v2(STMT_WRITE_MEDIA_FOLDERS, -1, out write_media_folder_statement);
        db.prepare_v2(STMT_DEL_MEDIA_FOLDERS, -1, out del_media_folder_statement);
        db.prepare_v2(STMT_ADD_STREAM, -1, out add_stream_statement);
        db.prepare_v2(STMT_DEL_RADIO_STREAM, -1, out del_streams_statement);
        db.prepare_v2(STMT_GET_ARTIST_ID, -1, out get_artist_id_statement);
        db.prepare_v2(STMT_INSERT_ARTIST, -1, out insert_artist_statement);
        db.prepare_v2(STMT_GET_ALBUM_ID, -1, out get_album_id_statement);
        db.prepare_v2(STMT_INSERT_ALBUM, -1, out insert_album_statement);
        db.prepare_v2(STMT_UPDATE_ALBUM, -1, out update_album_statement);
        db.prepare_v2(STMT_GET_URI_ID, -1, out get_uri_id_statement);
        db.prepare_v2(STMT_GET_PATH_ID, -1, out get_path_id_statement);
        db.prepare_v2(STMT_INSERT_URI, -1, out insert_uri_statement);
        db.prepare_v2(STMT_INSERT_PATH, -1, out insert_path_statement);
        db.prepare_v2(STMT_GET_GENRE_ID, -1, out get_genre_id_statement);
        db.prepare_v2(STMT_INSERT_GENRE, -1, out insert_genre_statement);
        db.prepare_v2(STMT_INSERT_TITLE, -1, out insert_title_statement);
        db.prepare_v2(STMT_GET_TITLE_ID, -1, out get_title_id_statement);
        db.prepare_v2(STMT_DEL_ARTISTS, -1, out delete_artists_statement);
        db.prepare_v2(STMT_DEL_ALBUMS, -1, out delete_albums_statement);
//        db.prepare_v2(STMT_DEL_ALBUM_NAMES, -1, out delete_album_names_statement);
        db.prepare_v2(STMT_DEL_ITEMS, -1, out delete_items_statement);
        db.prepare_v2(STMT_DEL_URIS, -1, out delete_uris_statement);
        db.prepare_v2(STMT_DEL_PATHS, -1, out delete_paths_statement);
        db.prepare_v2(STMT_DEL_GENRES, -1, out delete_genres_statement);
        db.prepare_v2(STMT_COUNT_ARTIST_IN_ITEMS , -1, out count_artist_in_items_statement);
        db.prepare_v2(STMT_COUNT_ALBUMARTIST_IN_ITEMS , -1, out count_albumartist_in_items_statement);
        db.prepare_v2(STMT_COUNT_GENRE_IN_ITEMS , -1, out count_genres_in_items_statement);
        db.prepare_v2(STMT_DEL_ARTIST , -1, out delete_artist_statement);
        db.prepare_v2(STMT_DEL_GENRE , -1, out delete_genre_statement);
        db.prepare_v2(STMT_COUNT_ALBUM_IN_ITEMS , -1, out count_album_in_items_statement);
        db.prepare_v2(STMT_DEL_ALBUM , -1, out delete_album_statement);
        db.prepare_v2(STMT_GET_STATISTICS_ID , -1, out get_statistics_id_statement);
        db.prepare_v2(STMT_ADD_STATISTIC , -1, out add_statistic_statement);
        db.prepare_v2(STMT_UPDATE_PLAYTIME , -1, out update_playtime_statement);
        db.prepare_v2(STMT_GET_ARTIST_MAX_ID, -1, out get_artist_max_id_statement);
        db.prepare_v2(STMT_GET_URI_MAX_ID, -1, out get_uri_max_id_statement);
        db.prepare_v2(STMT_GET_PATHS_MAX_ID, -1, out get_paths_max_id_statement);
        db.prepare_v2(STMT_GET_GENRE_MAX_ID, -1, out get_genre_max_id_statement);
        db.prepare_v2(STMT_GET_ALBUMS_MAX_ID, -1, out get_albums_max_id_statement);
        db.prepare_v2(STMT_INS_VARIOUS_ARTISTS, -1, out ins_va_statement);
        db.prepare_v2(STMT_GET_ALBUM_NAME_IDS, -1, out get_album_name_ids_statement);
    }

    public struct NotificationData {
        public unowned ChangeNotificationCallback cb;
    }
    
    private List<NotificationData?> change_callbacks = new List<NotificationData?>();
    
    public void register_change_callback(NotificationData? cbd) {
        if(cbd == null)
            return;
        change_callbacks.prepend(cbd);
    }
    
//    private void setup_pragmas() {
//        string errormsg;
//        if(db.exec(STMT_PRAGMA_SET_FOREIGN_KEYS_ON, null, out errormsg)!= Sqlite.OK) {
//            stderr.printf("exec_stmnt_string error: %s", errormsg);
//            return;
//        }
//    }
    
    private static const string STMT_GET_URI_FOR_ITEM_ID =
        "SELECT u.name FROM uris u, items it WHERE it.uri = u.id AND it.id = ?";
    public string? get_uri_for_item_id(int32 id) {
        string? val = null;
        Statement stmt;
        db.prepare_v2(STMT_GET_URI_FOR_ITEM_ID, -1, out stmt);
        stmt.reset();
        if(stmt.bind_int(1, id)!= Sqlite.OK ) {
            this.db_error();
            return null;
        }
        if(stmt.step() == Sqlite.ROW) {
            val = stmt.column_text(0);
        }
        return (owned)val;
    }
    
    private static const string STMT_GET_ARTIST_MAX_ID =
        "SELECT MAX(id) FROM artists";
    private static const string STMT_GET_ARTIST_ID =
        "SELECT id FROM artists WHERE caseless_name = ?";
    private static const string STMT_UPDATE_ARTIST_NAME = 
        "UPDATE artists SET name=?, caseless_name=? WHERE id=?";
    private static const string STMT_INSERT_ARTIST =
        "INSERT INTO artists (name,caseless_name) VALUES (?,?)";

    private int handle_artist(ref string artist, bool update_artist = false) {
        // find artist, if available or create entry_album
        // return id for artist
        int artist_id = -1;
        string stripped_art;
        string caseless_artist;
        if(artist != null)
            stripped_art = artist.strip();
        else
            stripped_art = UNKNOWN_ARTIST;
        caseless_artist = stripped_art.casefold();
        
        get_artist_id_statement.reset();
        if(get_artist_id_statement.bind_text(1, caseless_artist) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_artist_id_statement.step() == Sqlite.ROW)
            artist_id = get_artist_id_statement.column_int(0);
        
        if(artist_id == -1) { // artist not in table, yet
            insert_artist_statement.reset();
            if(insert_artist_statement.bind_text(1, stripped_art)    != Sqlite.OK ||
               insert_artist_statement.bind_text(2, caseless_artist) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(insert_artist_statement.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
            get_artist_max_id_statement.reset();
            if(get_artist_max_id_statement.step() == Sqlite.ROW)
                artist_id = get_artist_max_id_statement.column_int(0);
            // change notification
//            Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, artist_id);
//            item.source_id = db_reader.get_source_id();
//            item.stamp = get_current_stamp(db_reader.get_source_id());
//            item.text = stripped_art;
//            foreach(NotificationData cxd in change_callbacks) {
//                if(cxd.cb != null)
//                    cxd.cb(ChangeType.ADD_ARTIST, item);
//            }
        }
//        else if(artist_id == 1) {
//            Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, artist_id);
//            item.source_id = db_reader.get_source_id();
//            item.stamp = get_current_stamp(db_reader.get_source_id());
//            item.text = stripped_art;
//            foreach(NotificationData cxd in change_callbacks) {
//                if(cxd.cb != null)
//                    cxd.cb(ChangeType.ADD_ARTIST, item);
//            }
//        }
        if(update_artist) {
            Statement stmt;
            db.prepare_v2(STMT_UPDATE_ARTIST_NAME, -1, out stmt);
            stmt.reset();
            if(stmt.bind_text(1, stripped_art)    != Sqlite.OK ||
               stmt.bind_text(2, caseless_artist) != Sqlite.OK ||
               stmt.bind_int (3, artist_id)       != Sqlite.OK ) {
                this.db_error();
                return -1;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
        }
        return artist_id;
    }
    
    private const string WILDCARD = "*";
    private int handle_albumartist(ref TrackData td, bool update_artist = false) {
        // find artist, if available or create entry
        // return id for artist
        string artist;
        string caseless_artist;
        if(td.albumartist == null || td.albumartist == EMPTYSTRING) {
            if(td.artist != null && td.artist.strip() != EMPTYSTRING)
                artist = td.artist.strip();
            else
                artist = (td.is_compilation ? VARIOUS_ARTISTS : UNKNOWN_ARTIST);//WILDCARD;
        }
        else {
            artist = td.albumartist.strip();
        }
        caseless_artist = artist.casefold();
        
        int artist_id = -1;
        get_artist_id_statement.reset();
        if(get_artist_id_statement.bind_text(1, caseless_artist) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_artist_id_statement.step() == Sqlite.ROW)
            artist_id = get_artist_id_statement.column_int(0);
        
        if(artist_id == -1) { // artist not in table, yet
            insert_artist_statement.reset();
            if(insert_artist_statement.bind_text(1, artist) != Sqlite.OK ||
               insert_artist_statement.bind_text(2, caseless_artist) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(insert_artist_statement.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
            get_artist_max_id_statement.reset();
            if(get_artist_max_id_statement.step() == Sqlite.ROW)
                artist_id = get_artist_max_id_statement.column_int(0);
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, artist_id);
                item.source_id = db_reader.get_source_id();
                item.stamp = get_current_stamp(db_reader.get_source_id());
                item.text = artist;
                foreach(NotificationData cxd in change_callbacks) {
                    if(cxd.cb != null)
                        cxd.cb(ChangeType.ADD_ARTIST, item);
                }
            }
        }
        else if(artist_id == 1) {
            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, artist_id);
                item.source_id = db_reader.get_source_id();
                item.stamp = get_current_stamp(db_reader.get_source_id());
                item.text = artist;
                foreach(NotificationData cxd in change_callbacks) {
                    if(cxd.cb != null)
                        cxd.cb(ChangeType.ADD_ARTIST, item);
                }
            }
        }
        if(update_artist) { // ??? TODO
            Statement stmt;
            db.prepare_v2(STMT_UPDATE_ARTIST_NAME, -1, out stmt);
            stmt.reset();
            if(stmt.bind_text(1, artist)          != Sqlite.OK ||
               stmt.bind_text(2, caseless_artist) != Sqlite.OK ||
               stmt.bind_int (3, artist_id)       != Sqlite.OK ) {
                this.db_error();
                return -1;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
        }
        return artist_id;
    }
    
    private static const string STMT_INC_PLAYCOUNT = 
        "UPDATE statistics SET playcount = playcount + 1 WHERE id=?";
    public void inc_playcount(string uri) {
        
        int32 id = this.get_statistics_id_for_uri(uri);
        
        Statement stmt;
        
        db.prepare_v2(STMT_INC_PLAYCOUNT, -1, out stmt);
        
        stmt.reset();
        if(stmt.bind_int(1, id) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return;
        }
        foreach(NotificationData? cxd in change_callbacks) {
            if(cxd.cb != null)
                cxd.cb(ChangeType.UPDATE_PLAYCOUNT, null);
        }
    }
    
    private static const string STMT_UPDATE_PLAYTIME = 
        "UPDATE statistics SET lastplayTime=? WHERE id=?";
    public void update_lastplay_time(string uri, int64 playtime) {
        int32 id = this.get_statistics_id_for_uri(uri);
        update_playtime_statement.reset();
        if(update_playtime_statement.bind_int64(1, playtime) != Sqlite.OK ||
           update_playtime_statement.bind_int(2, id) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(update_playtime_statement.step() != Sqlite.DONE) {
            this.db_error();
            return;
        }
        foreach(NotificationData? cxd in change_callbacks) {
            if(cxd.cb != null)
                cxd.cb(ChangeType.UPDATE_LASTPLAYED, null);
        }
    }
    
    private int32 get_statistics_id_for_uri(string uri) {
        int uri_id = -1;
        get_statistics_id_statement.reset();
        if(get_statistics_id_statement.bind_text(1, uri) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_statistics_id_statement.step() == Sqlite.ROW)
            uri_id = get_statistics_id_statement.column_int(0);
        
        if(uri_id == -1) { // uri not in table, yet
            // Insert uri
            add_statistic_statement.reset();
            if(add_statistic_statement.bind_text(1, uri) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(add_statistic_statement.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
            // Get unique uri id key
            get_statistics_id_statement.reset();
            if(get_statistics_id_statement.bind_text(1, uri) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(get_statistics_id_statement.step() == Sqlite.ROW)
                uri_id = get_statistics_id_statement.column_int(0);
        }
        return uri_id;
    }
    
    private static const string STMT_GET_ALBUMS_MAX_ID =
        "SELECT MAX(id) FROM albums";
    private static const string STMT_GET_ALBUM_ID =
        "SELECT id FROM albums WHERE artist = ? AND caseless_name = ?";
    private static const string STMT_UPDATE_ALBUM = 
        "UPDATE albums SET name=?, year=?, is_compilation=?, caseless_name = ? WHERE id=?";
    private static const string STMT_INSERT_ALBUM =
        "INSERT INTO albums (artist, name, year, is_compilation, caseless_name) VALUES (?,?,?,?,?)";
    private static const string STMT_GET_ALBUM_NAME_IDS =
        "SELECT id, year FROM albums WHERE caseless_name = ? AND artist != ?";
    
    private static const int VA_ID = 1;
    
    private int[] get_ids_for_album_name_different_artist(ref string casefolded_album_name,
                                                          int artist_id,
                                                          int year) {
        int[] ids = {};
        get_album_name_ids_statement.reset();
        if(get_album_name_ids_statement.bind_text(1, casefolded_album_name) != Sqlite.OK ||
           get_album_name_ids_statement.bind_int (2, artist_id            ) != Sqlite.OK) {
            this.db_error();
            return ids;
        }
        while(get_album_name_ids_statement.step() == Sqlite.ROW) {
            if(year == get_album_name_ids_statement.column_int(1))
                ids += get_album_name_ids_statement.column_int(0);
        }
        // TODO If there is something in ids, then compare the year. 
        //      If year is same, then we might have a real VA album
        return ids;
    }
    
    
    private int handle_album(ref int artist_id, ref TrackData td, bool update_album) {
        string stripped_album;
        string stripped_art;
        string caseless_album;
        stripped_art = td.albumartist != null ? td.albumartist.strip() : EMPTYSTRING;
        stripped_album = td.album != null ? td.album.strip() : EMPTYSTRING;
        caseless_album = stripped_album.casefold();
        
        if(update_album == false) {
            int al_id = -1;
            get_album_id_statement.reset();
            if(get_album_id_statement.bind_int (1, VA_ID) != Sqlite.OK ||
               get_album_id_statement.bind_text(2, caseless_album) != Sqlite.OK ) {
                this.db_error();
                return -1;
            }
            if(get_album_id_statement.step() == Sqlite.ROW) {
                al_id = get_album_id_statement.column_int(0);
                artist_id = VA_ID;
            }
            
            if(al_id == -1) {
                get_album_id_statement.reset();
                if(get_album_id_statement.bind_int (1, artist_id) != Sqlite.OK ||
                   get_album_id_statement.bind_text(2, caseless_album) != Sqlite.OK ) {
                    this.db_error();
                    return -1;
                }
                if(get_album_id_statement.step() == Sqlite.ROW)
                    al_id = get_album_id_statement.column_int(0);
            }
            
            if(al_id == -1) {
                
                if(stripped_album != UNKNOWN_ALBUM && caseless_album != "self titled" &&
                   caseless_album != "unknown" && caseless_album != "greatest hits" &&
                   caseless_album != "no title" && caseless_album != "%s".printf(_("unknown").down()) &&
                   !caseless_album.has_prefix("http") && caseless_album != "live") {
                    int[] xids = get_ids_for_album_name_different_artist(ref caseless_album,
                                                                         artist_id, 
                                                                         (int)td.year);
                    if(xids.length > 0) {
                        if(xids.length > 1)
                            print("this should never happen!\n");
                        insert_album_statement.reset();
                        artist_id = VA_ID; //insrt al and later title as VA
                        td.is_compilation = true;
                        if(insert_album_statement.bind_int (1, artist_id)       != Sqlite.OK ||
                           insert_album_statement.bind_text(2, stripped_album)  != Sqlite.OK ||
                           insert_album_statement.bind_int (3, (int)td.year)    != Sqlite.OK ||
                           insert_album_statement.bind_int (4, 1)               != Sqlite.OK || // compilation
                           insert_album_statement.bind_text(5, caseless_album)  != Sqlite.OK) {
                            this.db_error();
                            return -1;
                        }
                        if(insert_album_statement.step() != Sqlite.DONE) {
                            this.db_error();
                            return -1;
                        }
                        //Return id
                        get_albums_max_id_statement.reset();
                        if(get_albums_max_id_statement.step() == Sqlite.ROW) {
                            al_id = get_albums_max_id_statement.column_int(0);
                            if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
                                Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, al_id);
                                item.source_id = db_reader.get_source_id();
                                item.stamp = get_current_stamp(db_reader.get_source_id());
                                item.text = stripped_album;
                                foreach(NotificationData cxd in change_callbacks) {
                                    if(cxd.cb != null)
                                        cxd.cb(ChangeType.ADD_ALBUM, item);
                                }
                            }
                        }
                        else {
                            warning("should not happen !!\n");
                            return -1;
                        }
                        
                        //Method: remove xids-albums, update items for xid-album
                        set_albumname_is_va_album(ref stripped_album, ref xids, al_id);
                        
                        if(artist_id == VA_ID) {
                            if(global.collection_sort_mode == CollectionSortMode.ARTIST_ALBUM_TITLE) {
                                foreach(NotificationData cxd in change_callbacks) {
                                    Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUMARTIST, null, VA_ID);
                                    item.source_id = db_reader.get_source_id();
                                    item.stamp = get_current_stamp(db_reader.get_source_id());
                                    item.text = VARIOUS_ARTISTS;
                                    if(cxd.cb != null)
                                        cxd.cb(ChangeType.ADD_ARTIST, item);
                                }
                            }
                        }
                        return al_id;
                    }
                }
                // Insert album
                insert_album_statement.reset();
                if(insert_album_statement.bind_int (1, artist_id)                         != Sqlite.OK ||
                   insert_album_statement.bind_text(2, stripped_album)                    != Sqlite.OK ||
                   insert_album_statement.bind_int (3, (int)td.year)                      != Sqlite.OK ||
                   insert_album_statement.bind_int (4, td.is_compilation == true ? 1 : 0) != Sqlite.OK ||
                   insert_album_statement.bind_text(5, caseless_album)                    != Sqlite.OK) {
                    this.db_error();
                    return -1;
                }
                if(insert_album_statement.step() != Sqlite.DONE) {
                    this.db_error();
                    return -1;
                }
                
                //Return id
                get_albums_max_id_statement.reset();
                if(get_albums_max_id_statement.step() == Sqlite.ROW) {
                    al_id = get_albums_max_id_statement.column_int(0);
                    if(global.collection_sort_mode == CollectionSortMode.ALBUM_ARTIST_TITLE) {
                        Item? item = Item(ItemType.COLLECTION_CONTAINER_ALBUM, null, al_id);
                        item.source_id = db_reader.get_source_id();
                        item.stamp = get_current_stamp(db_reader.get_source_id());
                        item.text = stripped_album;
                        foreach(NotificationData cxd in change_callbacks) {
                            if(cxd.cb != null)
                                cxd.cb(ChangeType.ADD_ALBUM, item);
                        }
                    }
                    return al_id;
                }
                else {
                    return -1;
                }
            }
            else {
                return al_id;
            }
        }
        else {
            get_album_id_statement.reset();
            if(get_album_id_statement.bind_int (1, artist_id) != Sqlite.OK ||
               get_album_id_statement.bind_text(2, caseless_album) != Sqlite.OK ) {
                this.db_error();
                return -1;
            }
            int alb_id = -1;
            if(get_album_id_statement.step() == Sqlite.ROW)
                alb_id = get_album_id_statement.column_int(0);
            
            if(alb_id == -1) {
                // Insert album
                insert_album_statement.reset();
                if(insert_album_statement.bind_int (1, artist_id)        != Sqlite.OK ||
                   insert_album_statement.bind_text(2, td.album.strip()) != Sqlite.OK ||
                   insert_album_statement.bind_int (3, (int)td.year)     != Sqlite.OK ||
                   insert_album_statement.bind_int (4, td.is_compilation == true ? 1 : 0) != Sqlite.OK ||
                   insert_album_statement.bind_text(5, caseless_album)                    != Sqlite.OK) {
                    this.db_error();
                    return -1;
                }
                if(insert_album_statement.step() != Sqlite.DONE) {
                    this.db_error();
                    return -1;
                }
                
                //Return id
                get_albums_max_id_statement.reset();
                if(get_albums_max_id_statement.step() == Sqlite.ROW)
                    return get_albums_max_id_statement.column_int(0);
                else
                    return -1;
            }
            else {
                update_album_statement.reset();
                if(update_album_statement.bind_text(1, td.album.strip()) != Sqlite.OK ||
                   update_album_statement.bind_int (2, (int)td.year)     != Sqlite.OK ||
                   update_album_statement.bind_int (3, td.is_compilation == true ? 1 : 0) != Sqlite.OK ||
                   update_album_statement.bind_int (4, alb_id)           != Sqlite.OK ||
                   update_album_statement.bind_text(5, caseless_album)   != Sqlite.OK) {
                    this.db_error();
                    return -1;
                }
                if(update_album_statement.step() != Sqlite.DONE) {
                    this.db_error();
                    return -1;
                }
                return alb_id;
            }
        }
    }

    private static const string STMT_GET_PATHS_MAX_ID =
        "SELECT MAX(id) FROM paths";
    private static const string STMT_GET_PATH_ID =
        "SELECT id FROM paths WHERE caseless_name = ?";
    private static const string STMT_INSERT_PATH =
        "INSERT INTO paths (name, caseless_name) VALUES (?,?)";

    private int handle_path(string path) {
        int path_id = -1;
        string stripped_path;
        string caseless_path;
        if(path != null)
            stripped_path = path.strip();
        else
            return -1;
        caseless_path = stripped_path.casefold();
        
        get_path_id_statement.reset();
        if(get_path_id_statement.bind_text(1, caseless_path) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_path_id_statement.step() == Sqlite.ROW) {
            path_id = get_path_id_statement.column_int(0);
        }
        if(path_id == -1) { // not in table, yet 
            insert_path_statement.reset();
            if(insert_path_statement.bind_text(1, stripped_path) != Sqlite.OK ||
               insert_path_statement.bind_text(2, caseless_path) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(insert_path_statement.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
        }
        else {
            return path_id;
        }
        get_paths_max_id_statement.reset();
        if(get_paths_max_id_statement.step() == Sqlite.ROW)
            return get_paths_max_id_statement.column_int(0);
        else
            return -1;
    }

    private static const string STMT_GET_URI_MAX_ID =
        "SELECT MAX(id) FROM uris";
    private static const string STMT_GET_URI_ID =
        "SELECT id FROM uris WHERE name = ?";
    private static const string STMT_INSERT_URI =
        "INSERT INTO uris (name, path) VALUES (?,?)";

    private int handle_uri(string uri, int path_id = -1) {
        this.get_uri_id_statement.reset();
        if(this.get_uri_id_statement.bind_text(1, uri)!= Sqlite.OK )
            return -1;
        if(this.get_uri_id_statement.step() == Sqlite.ROW)
            return -2;

        insert_uri_statement.reset();
        if(insert_uri_statement.bind_text(1, uri)     != Sqlite.OK ||
           insert_uri_statement.bind_int (2, path_id) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_uri_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        get_uri_max_id_statement.reset();
        if(get_uri_max_id_statement.step() == Sqlite.ROW)
            return get_uri_max_id_statement.column_int(0);
        else
            return -1;
    }

    public string[] get_media_folders() {
        string[] sa = {};
        get_media_folder_statement.reset();
        while(get_media_folder_statement.step() == Sqlite.ROW)
            sa += get_media_folder_statement.column_text(0);
        return (owned)sa;
    }

    private static const string STMT_GET_GENRE_MAX_ID =
        "SELECT MAX(id) FROM genres";
    private static const string STMT_UPDATE_GENRE_NAME = 
        "UPDATE genres SET name=?, caseless_name=? WHERE id=?";
    private static const string STMT_INSERT_GENRE =
        "INSERT INTO genres (name,caseless_name) VALUES (?,?)";
    private static const string STMT_GET_GENRE_ID =
        "SELECT id FROM genres WHERE caseless_name = ?";

    private int handle_genre(ref TrackData td, bool update_genre = false) {
//        if((td.genre == null)||(td.genre.strip() == EMPTYSTRING)) 
//            td.genre = UNKNOWN_GENRE;
        int genre_id = -1;
        string stripped_genre;
        string caseless_genre;
        if(td.genre != null)
            stripped_genre = td.genre.strip();
        else
            stripped_genre = UNKNOWN_GENRE;
        caseless_genre = stripped_genre.casefold();
        
        get_genre_id_statement.reset();
        if(get_genre_id_statement.bind_text(1, caseless_genre) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_genre_id_statement.step() == Sqlite.ROW) {
            genre_id = get_genre_id_statement.column_int(0);
        }
        if(genre_id == -1) { // genre not in table, yet 
            // Insert genre
            insert_genre_statement.reset();
            if(insert_genre_statement.bind_text(1, stripped_genre) != Sqlite.OK ||
               insert_genre_statement.bind_text(2, caseless_genre) != Sqlite.OK) {
                this.db_error();
                return -1;
            }
            if(insert_genre_statement.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
            // Return id key
            get_genre_max_id_statement.reset();
            if(get_genre_max_id_statement.step() == Sqlite.ROW) {
                genre_id = get_genre_max_id_statement.column_int(0);
                Item? item = Item(ItemType.COLLECTION_CONTAINER_GENRE, null, genre_id);
                item.source_id = db_reader.get_source_id();
                item.stamp = get_current_stamp(db_reader.get_source_id());
                item.text = stripped_genre;
                if(global.collection_sort_mode == CollectionSortMode.GENRE_ARTIST_ALBUM) {
                    foreach(NotificationData cxd in change_callbacks) {
                        if(cxd.cb != null)
                            cxd.cb(ChangeType.ADD_GENRE, item);
                    }
                }
            }
            else {
                return -1;
            }
        }
        if(update_genre) {
            Statement stmt;
            db.prepare_v2(STMT_UPDATE_GENRE_NAME, -1, out stmt);
            stmt.reset();
            if(stmt.bind_text(1, stripped_genre)    != Sqlite.OK ||
               stmt.bind_text(1, caseless_genre)    != Sqlite.OK ||
               stmt.bind_int (2, genre_id)          != Sqlite.OK ) {
                this.db_error();
                return -1;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return -1;
            }
        }
        return genre_id;
    }

    public bool get_trackdata_for_stream(string uri, out TrackData val) {
        Statement stmt;
        bool retval = false;
        val = new TrackData();
        db.prepare_v2(STMT_TRACKDATA_FOR_STREAM, -1, out stmt);
            
        stmt.reset();
        if(stmt.bind_text(1, uri) != Sqlite.OK) {
            this.db_error();
        }
        if(stmt.step() == Sqlite.ROW) {
            val.title = stmt.column_text(1);
            val.item = Item(ItemType.STREAM, uri, stmt.column_int(0));
            retval = true;
        }
        return retval;
    }

    private static const string STMT_UPDATE_TITLE =
        "UPDATE items SET artist=?, album=?, title=?, genre=?, year=?, tracknumber=?, album_artist=? WHERE id=?";
    private static const string STMT_UPDATE_ARTISTALBUM =
        "UPDATE items SET artist=?, album=?, genre=?, album_artist=? WHERE id=?";
    
    public bool update_title(ref Item? item, ref TrackData td) {
        if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
           item.type != ItemType.LOCAL_VIDEO_TRACK) {
            
            int artist_id = handle_artist(ref td.artist, true);
            
            if(artist_id == -1) {
                print("Error updating artist for '%s' ! \n", td.artist);
                return false;
            }
            int albumartist_id = handle_albumartist(ref td, true);
            if(albumartist_id == -1) {
                print("Error updating albumartist for '%s' ! \n", td.albumartist);
                return false;
            }
            int album_id = handle_album(ref artist_id, ref td, true);
            if(album_id == -1) {
                print("Error updating album for '%s' ! \n", td.album);
                return false;
            }
            int genre_id = handle_genre(ref td, true);
            if(genre_id == -1) {
                print("Error updating genre for '%s' ! \n", td.genre);
                return false;
            }
            Statement stmt;
            db.prepare_v2(STMT_UPDATE_ARTISTALBUM, -1, out stmt);
        
            if(stmt.bind_int (1, artist_id)     != Sqlite.OK ||
               stmt.bind_int (2, album_id)      != Sqlite.OK ||
               stmt.bind_int (3, genre_id)      != Sqlite.OK ||
               stmt.bind_int (4, albumartist_id) != Sqlite.OK ||
               stmt.bind_int (5, td.item.db_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return false;
            }
            if(item.type == ItemType.COLLECTION_CONTAINER_ALBUM) {
                count_album_in_items_statement.reset();
                if(count_album_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                int cnt = 0;
                if(count_album_in_items_statement.step() == Sqlite.ROW) {
                    cnt = count_album_in_items_statement.column_int(0);
                }
                if(cnt == 0) {
                    delete_album_statement.reset();
                    if(delete_album_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                        this.db_error();
                        return false;
                    }
                    delete_album_statement.step();
                }
            }
            else if(item.type == ItemType.COLLECTION_CONTAINER_ALBUMARTIST) {
                count_artist_in_items_statement.reset();
                if(count_artist_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                int cnt = 0;
                if(count_artist_in_items_statement.step() == Sqlite.ROW) {
                    cnt = count_artist_in_items_statement.column_int(0);
                }
                
                count_albumartist_in_items_statement.reset();
                if(count_albumartist_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                if(count_albumartist_in_items_statement.step() == Sqlite.ROW) {
                    cnt += count_albumartist_in_items_statement.column_int(0);
                }
                
                if(cnt == 0) {
                    delete_artist_statement.reset();
                    if(delete_artist_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                        this.db_error();
                        return false;
                    }
                    delete_artist_statement.step();
                }
            }
            else if(item.type == ItemType.COLLECTION_CONTAINER_GENRE) {
                count_genres_in_items_statement.reset();
                if(count_genres_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                int cnt = 0;
                if(count_genres_in_items_statement.step() == Sqlite.ROW) {
                    cnt = count_genres_in_items_statement.column_int(0);
                }
                if(cnt == 0) {
                    delete_genre_statement.reset();
                    if(delete_genre_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                        this.db_error();
                        return false;
                    }
                    delete_genre_statement.step();
                }
            }
        }
        else {
            // Buffer old ids
            int32 old_artist_id, old_album_id;
            
            if(td.artist != null && (td.artist.strip().down() == "various artists" ||
                                     td.artist.strip().down() == "various")) {
                td.is_compilation = true;
            }
            else {
                if(td.albumartist == null || td.albumartist.strip() == EMPTYSTRING)
                    td.albumartist = td.artist;
//                td.is_compilation = false; //???
            }
            
            if(td.is_compilation)
                td.artist = VARIOUS_ARTISTS; // We are save here, it's only database
            
            get_ids_for_item(item, out old_artist_id, out old_album_id);
            int artist_id = handle_artist(ref td.artist, false);
            
            if(artist_id == -1) {
                print("Error updating artist for '%s' ! \n", td.artist);
                return false;
            }
            int albumartist_id = handle_albumartist(ref td, false);
            if(albumartist_id == -1) {
                print("Error updating albumartist for '%s' ! \n", td.albumartist);
                return false;
            }
            int album_id = handle_album(ref artist_id, ref td, false);
            if(album_id == -1) {
                print("Error updating album for '%s' ! \n", td.album);
                return false;
            }
            int genre_id = handle_genre(ref td, false);
            if(genre_id == -1) {
                print("Error updating genre for '%s' ! \n", td.genre);
                return false;
            }
            Statement stmt;
            db.prepare_v2(STMT_UPDATE_TITLE, -1, out stmt);
            
            if(stmt.bind_int (1, artist_id)     != Sqlite.OK ||
               stmt.bind_int (2, album_id)      != Sqlite.OK ||
               stmt.bind_text(3, td.title)      != Sqlite.OK ||
               stmt.bind_int (4, genre_id)      != Sqlite.OK ||
               stmt.bind_int (5, (int)td.year)       != Sqlite.OK ||
               stmt.bind_int (6, (int)td.tracknumber)!= Sqlite.OK ||
               stmt.bind_int (7, albumartist_id) != Sqlite.OK ||
               stmt.bind_int (8, td.item.db_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return false;
            }
            count_album_in_items_statement.reset();
            if(count_album_in_items_statement.bind_int (1, old_album_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            int cnt = 0;
            if(count_album_in_items_statement.step() == Sqlite.ROW) {
                cnt = count_album_in_items_statement.column_int(0);
            }
            if(cnt == 0) {
                delete_album_statement.reset();
                if(delete_album_statement.bind_int (1, old_album_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                delete_album_statement.step();
            }
            count_artist_in_items_statement.reset();
            if(count_artist_in_items_statement.bind_int (1, old_artist_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            cnt = 0;
            if(count_artist_in_items_statement.step() == Sqlite.ROW) {
                cnt = count_artist_in_items_statement.column_int(0);
            }
            count_albumartist_in_items_statement.reset();
            if(count_albumartist_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            if(count_albumartist_in_items_statement.step() == Sqlite.ROW) {
                cnt += count_albumartist_in_items_statement.column_int(0);
            }
            
            if(cnt == 0) {
                delete_artist_statement.reset();
                if(delete_artist_statement.bind_int (1, old_artist_id) != Sqlite.OK) { //TODO
                    this.db_error();
                    return false;
                }
                delete_artist_statement.step();//TODO
            }
        }
        return true;
    }
    
    
    private static const string STMT_GET_ARTIST_AND_ALBUM_IDS = 
        "SELECT artist, album FROM items WHERE id = ?";
    private void get_ids_for_item(Item? item, out int32 old_artist_id, out int32 old_album_id) {
        old_artist_id = old_album_id = -1;
        Statement stmt;
        db.prepare_v2(STMT_GET_ARTIST_AND_ALBUM_IDS, -1, out stmt);
        if(stmt.bind_int (1, item.db_id) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(stmt.step() == Sqlite.ROW) {
            old_artist_id      = stmt.column_int(0);
            old_album_id       = stmt.column_int(1);
        }
    }

    private static const string STMT_GET_ITEM_DAT = 
       "SELECT id,artist,album FROM items WHERE uri=?";
    
    private static const string STMT_GET_TRACK_CNT_FOR_ALBUMARTIST =
        "SELECT COUNT(*) FROM items WHERE album_artist =(SELECT album_artist FROM items WHERE items.id=?)";
    private static const string STMT_GET_TRACK_CNT_FOR_ARTIST = 
       "SELECT COUNT(*) FROM items WHERE artist=(SELECT artist FROM items WHERE items.id=?)";

    private static const string STMT_GET_TRACK_CNT_FOR_ALBUM = 
       "SELECT COUNT(id) FROM items WHERE album=(SELECT album FROM items WHERE items.id=?)";
    
    public void remove_uri(string uri) {
        
        Statement stmt;
        string errormsg;
        
        this.get_uri_id_statement.reset();
        if(this.get_uri_id_statement.bind_text(1, uri)!= Sqlite.OK ) {
            return;
        }
        int32 uri_id = -1;
        if(this.get_uri_id_statement.step() == Sqlite.ROW) {
            uri_id = this.get_uri_id_statement.column_int(0);
        }
        else {
            return;
        }
        
        db.prepare_v2(STMT_GET_ITEM_DAT, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        
        int32 item_id   = -1;
        int32 artist_id = -1;
        int32 album_id  = -1;
        
        if(stmt.step() == Sqlite.ROW) {
            item_id     = stmt.column_int(0);
            artist_id   = stmt.column_int(1);
            album_id    = stmt.column_int(2);
        }
        else {
            return;
        }
        
        bool more_tracks_from_same_artist = false;
        int art_cnt = 0;
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ALBUMARTIST, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        if(stmt.step() == Sqlite.ROW) {
            art_cnt = stmt.column_int(0);
        }
//        else {
//            return;
//        }
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ARTIST, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
//        bool more_tracks_from_same_artist = true;
        if(stmt.step() == Sqlite.ROW) {
            art_cnt += stmt.column_int(0);
        }
//        else {
//            return;
//        }
        more_tracks_from_same_artist = (art_cnt > 1);
        
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ALBUM, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        bool more_tracks_from_same_album = true;
        if(stmt.step() == Sqlite.ROW) {
            more_tracks_from_same_album = stmt.column_int(0) > 1;
        }
        else {
            return;
        }
        
        if(!more_tracks_from_same_artist && artist_id != 1) {
            if(db.exec("DELETE FROM artists WHERE id=%d;".printf(artist_id), null, out errormsg)!= Sqlite.OK) {
                stderr.printf("exec_stmnt_string error: %s\n", errormsg);
            }
        }
        if(!more_tracks_from_same_album) {
            if(db.exec("DELETE FROM albums WHERE id=%d;".printf(album_id), null, out errormsg)!= Sqlite.OK) {
                stderr.printf("exec_stmnt_string error: %s\n", errormsg);
            }
        }
        if(db.exec("DELETE FROM items WHERE id=%d;".printf(item_id), null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s\n", errormsg);
        }
        if(db.exec("DELETE FROM uris WHERE id=%d;".printf(uri_id), null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s\n", errormsg);
        }
    }

     private static const string STMT_DEL_ITEMS_FOR_FOLDER =
        "DELETE FROM items WHERE uri IN (SELECT id FROM uris WHERE name LIKE ?)";
        
     private static const string STMT_DEL_URIS_FOR_FOLDER =
        "DELETE FROM uris WHERE name LIKE ?";
   
    public void remove_folder(string uri, bool check_media_folders = false) {
        Statement stmt;
        
        string uri_text = "%s%%".printf(uri);
        
        db.prepare_v2(STMT_DEL_ITEMS_FOR_FOLDER, -1, out stmt);
        if(stmt.bind_text(1, uri_text)!= Sqlite.OK ) {
            db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE) {
            db_error();
            return;
        }
        
        db.prepare_v2(STMT_DEL_URIS_FOR_FOLDER, -1, out stmt);
        if(stmt.bind_text(1, uri_text)!= Sqlite.OK ) {
            db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE) {
            db_error();
            return;
        }
    }

    private static const string STMT_GET_GET_ITEM_ID = 
        "SELECT id FROM items WHERE artist = ? AND album = ? AND title = ?";
    
    private static const string STMT_INSERT_TITLE =
        "INSERT INTO items (tracknumber, artist, album, title, genre, year, path, uri, mediatype, length, bitrate, mimetype, album_artist, cd_number, caseless_name, has_embedded_image) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    
    private static const string STMT_GET_ITEM_ID =
        "SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.id = ?";
//    private Timer t = new Timer();

//    ulong str1_usec = 0;
//    ulong artist_usec = 0;
//    ulong albumartist_usec = 0;
//    ulong album_usec = 0;
//    ulong path_usec = 0;
//    ulong uri_usec = 0;
//    ulong genre_usec = 0;
//    ulong title_usec = 0;

//    ulong FACTOR = 20;

    private string get_fitting_parent_path(string pth) {
        Statement stmt;
        
        this.db.prepare_v2("SELECT name FROM paths GROUP BY utf8_lower(name)", -1, out stmt);
        string result = "";
        string nme = "";
        while(stmt.step() == Sqlite.ROW) {
            nme = stmt.column_text(0);
            if(pth.has_prefix(nme)) {
                if(result.length < nme.length) {
                    result = nme;
                }
            }
        }
        //print("result : %s\n", result);
        return result;
    }
    
    public bool insert_title(ref TrackData td) { // , string uri
        // make entries in other tables and get references from there
//        t.reset();
//        t.start();
        File f = File.new_for_uri(td.item.uri);
        if(td.media_folder == null)
            td.media_folder = get_fitting_parent_path(f.get_parent().get_path());
        int path_id = handle_path(td.media_folder);// f.get_parent().get_path());
        if(path_id == -1) {
            return false;
        }
//        if(path_id == -2) {
//            print("path exists\n");
//            return false;
//        }
//        t.stop();
//        t.elapsed(out usec);
//        path_usec = (FACTOR * path_usec + usec) / (FACTOR + 1 );

//        t.reset();
//        t.start();
        int uri_id = handle_uri(f.get_uri(), path_id);
        if(uri_id == -1) {
            //print("Error importing uri for %s : '%s' ! \n", uri, uri);
            return false;
        }
        if(uri_id == -2) {
            print("uri exists\n");
            //print("Error importing uri for %s : '%s' ! \n", uri, uri);
            return false;
        }
//        t.stop();
//        t.elapsed(out usec);
//        uri_usec = (FACTOR * uri_usec + usec) / (FACTOR + 1 );

        if(td.albumartist != null && (td.albumartist.strip().down() == "various artists" ||
                                      td.albumartist.strip().down() == "various")) {
            td.is_compilation = true;
        }
        
        if(td.albumartist != null && td.albumartist.strip().down() == "various") {
            td.albumartist = VARIOUS_ARTISTS;
        }
//        else {
//            if(td.albumartist == null || td.albumartist.strip() == EMPTYSTRING)
//                td.albumartist = td.artist;
//            td.is_compilation = false; //???
//        }
        if(td.albumartist == null || td.albumartist.strip() == EMPTYSTRING)
            td.albumartist = td.artist;
//        t.stop();
//        ulong usec;
//        t.elapsed(out usec);
//        str1_usec = (FACTOR * str1_usec + usec) / (FACTOR + 1 );
        
//        if(td.is_compilation)
//            td.albumartist = VARIOUS_ARTISTS; // We are save here, it's only database
        
//        t.reset();
//        t.start();
        td.dat3 = handle_albumartist(ref td, false);
        if(td.dat3 == -1) {
            print("Error importing artist for %s : '%s' ! \n", td.item.uri, td.albumartist);
            return false;
        }
        td.dat1 = handle_artist(ref td.artist, false);
        if(td.dat1 == -1) {
            print("Error importing artist for %s : '%s' ! \n", td.item.uri, td.artist);
            return false;
        }
//        t.stop();
//        t.elapsed(out usec);
//        artist_usec = (FACTOR * artist_usec + usec) / (FACTOR + 1 );
        
//        t.reset();
//        t.start();
//        t.stop();
//        t.elapsed(out usec);
//        albumartist_usec = (FACTOR * albumartist_usec + usec) / (FACTOR + 1 );

//        t.reset();
//        t.start();
        td.dat2 = handle_album(ref td.dat3, ref td, false);
        if(td.dat2 == -1) {
            print("Error importing album for %s : '%s' ! \n", td.item.uri, td.album);
            return false;
        }
//        if(td.dat2 == VA_ID) {
//            td.is_compilation = true;
//            td.albumartist = VARIOUS_ARTISTS; // We are save here, it's only database
//        }
//        t.stop();
//        t.elapsed(out usec);
//        album_usec = (FACTOR * album_usec + usec) / (FACTOR + 1 );

//        t.reset();
//        t.start();

//        t.reset();
//        t.start();
        int genre_id = handle_genre(ref td);
        if(genre_id == -1) {
            print("Error importing genre for %s : '%s' ! \n", td.item.uri, td.genre);
            return false;
        }
//        t.stop();
//        t.elapsed(out usec);
//        genre_usec = (FACTOR * genre_usec + usec) / (FACTOR + 1 );

//        t.reset();
//        t.start();
        int disk_number = td.disk_number < 1 ? 1 : td.disk_number;
        //print("insert_title td.item.type %s\n", td.item.type.to_string());
        string stripped_title = td.title.strip();
        string caseless_title = stripped_title.casefold();
        insert_title_statement.reset();
        int embedded_image = (td.has_embedded_image ? 1 : 0);
        if(insert_title_statement.bind_int (1,  (int)td.tracknumber) != Sqlite.OK ||
           insert_title_statement.bind_int (2,  td.dat1)             != Sqlite.OK ||
           insert_title_statement.bind_int (3,  td.dat2)             != Sqlite.OK ||
           insert_title_statement.bind_text(4,  td.title)            != Sqlite.OK ||
           insert_title_statement.bind_int (5,  genre_id)            != Sqlite.OK ||
           insert_title_statement.bind_int (6,  (int)td.year)        != Sqlite.OK ||
           insert_title_statement.bind_int (7,  path_id)             != Sqlite.OK ||
           insert_title_statement.bind_int (8,  uri_id)              != Sqlite.OK ||
           insert_title_statement.bind_int (9,  td.item.type)        != Sqlite.OK ||
           insert_title_statement.bind_int (10, td.length )          != Sqlite.OK ||
           insert_title_statement.bind_int (11, td.bitrate)          != Sqlite.OK ||
           insert_title_statement.bind_text(12, td.mimetype)         != Sqlite.OK ||
           insert_title_statement.bind_int (13, td.dat3)             != Sqlite.OK ||
           insert_title_statement.bind_int (14, disk_number)         != Sqlite.OK ||
           insert_title_statement.bind_text(15, caseless_title)      != Sqlite.OK ||
           insert_title_statement.bind_int (16, embedded_image)      != Sqlite.OK) {
            this.db_error();
            return false;
        }
        
        if(insert_title_statement.step()!=Sqlite.DONE) {
            this.db_error();
            return false;
        }
//        t.stop();
//        t.elapsed(out usec);
//        title_usec = (FACTOR * title_usec + usec) / (FACTOR + 1 );
        
//print("## str:%lu  art:%lu  aa:%lu  alb:%lu  u:%lu  p:%lu  g:%lu  ti:%lu\n", str1_usec, artist_usec, albumartist_usec, album_usec, uri_usec, path_usec, genre_usec, title_usec);
        if(td.item.type == ItemType.LOCAL_VIDEO_TRACK) {
            Statement stmt;
            db.prepare_v2(STMT_GET_ITEM_ID , -1, out stmt);
            if(stmt.bind_int (1, uri_id) != Sqlite.OK) {
                this.db_error();
                return false;
            }
            int32 idv = -1;
            if(stmt.step() == Sqlite.ROW) {
                idv = (int32)stmt.column_int(0);
            }
            else {
                this.db_error();
                return false;
            }
            Item? item = Item(ItemType.LOCAL_VIDEO_TRACK, td.item.uri, idv);
            item.source_id = db_reader.get_source_id();
            item.stamp = get_current_stamp(db_reader.get_source_id());
            foreach(NotificationData cxd in change_callbacks) {
                if(cxd.cb != null)
                    cxd.cb(ChangeType.ADD_VIDEO, item);
            }
        }
        return true;
    }

    private static const string STMT_GET_STREAM_ID_BY_URI =
        "SELECT id FROM streams WHERE uri=?";
        
    // Single stream for collection
    public bool add_single_stream_to_collection(Item? i) {
        if(db == null)
            return false;
        if(i == null)
            return false;
        //print("add stream : %s \n", i.uri);
        if(i.uri == null || i.uri == EMPTYSTRING)
            return false;
        if(i.text == null || i.text == EMPTYSTRING)
            i.text = i.uri;
        
        add_stream_statement.reset();
        if(add_stream_statement.bind_text(1, i.text) != Sqlite.OK||
           add_stream_statement.bind_text(2, i.uri)  != Sqlite.OK) {
            this.db_error();
            return false;
        }
        if(add_stream_statement.step() != Sqlite.DONE) {
            this.db_error();
            return false;
        }
        Statement stmt;
        db.prepare_v2(STMT_GET_STREAM_ID_BY_URI, -1, out stmt);
        if(stmt.bind_text(1, i.uri) != Sqlite.OK) {
            this.db_error();
            return false;
        }
        int stream_id = -1;
        if(stmt.step() == Sqlite.ROW)
            stream_id = stmt.column_int(0);
        // change notification
        foreach(NotificationData cxd in change_callbacks) {
            if(stream_id > -1) {
                Item? item = Item(ItemType.STREAM, i.uri, stream_id);
                item.text = i.text;
                item.source_id = db_reader.get_source_id();
                item.stamp = get_current_stamp(db_reader.get_source_id());
                if(cxd.cb != null)
                    cxd.cb(ChangeType.ADD_STREAM, item);
            }
        }
        return true;
    }
    
    private static const string STMT_UPDATE_STREAM_NAME = 
        "UPDATE streams SET name=? WHERE uri=?";
    public void update_stream_name(Item? item) {
        if(item == null)
            return;
        Statement stmt;
        db.prepare_v2(STMT_UPDATE_STREAM_NAME, -1, out stmt);
        if(stmt.bind_text(1, item.text) != Sqlite.OK ||
           stmt.bind_text(2, item.uri ) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE)
            this.db_error();
    }
    
//    private static const string STMT_WRITE_MEDIA_FOLDERS =
//        "INSERT INTO paths (name) VALUES (?)";

    //add media folder
    public bool add_single_folder_to_collection(Item? mfolder) {
        if(mfolder == null)
            return false;
        File f = File.new_for_uri(mfolder.uri);
        return_val_if_fail(f.get_path() != null, false);
        int id = handle_path(f.get_path());
        if(id == -1)
            return false;
        return true;
    }
    
    private static const string STMT_GET_MEDIA_FOLDER_ID =
        "SELECT id FROM paths WHERE name = ?";
    
    public static const string STMT_REMOVE_MEDIA_FOLDER_ITEMS =
        "DELETE FROM items WHERE path=?";
    
    private static const string STMT_REMOVE_MEDIA_FOLDER_ID =
        "DELETE FROM paths WHERE id=?";
    
    private static const string STMT_REMOVE_URI_ITEMS =
        "DELETE FROM uris WHERE path=?";
    
    private static const string STMT_GET_URI_IDS_FOR_PATH =
        "SELECT uri FROM items WHERE path=?";
    //remove media folder and all items referencing to this media folder
    public bool remove_single_media_folder(Item? mfolder) {
        if(mfolder == null)
            return false;
        File f = File.new_for_uri(mfolder.uri);
        return_val_if_fail(f.get_path() != null && f.get_path() != "", false);
        Statement stmt;
        this.db.prepare_v2(STMT_GET_MEDIA_FOLDER_ID, -1, out stmt);
        stmt.bind_text(1, f.get_path());
        //print("ää path: %s\n", f.get_path());
        if(stmt.step() == Sqlite.ROW) {
            int id = stmt.column_int(0);
            this.db.prepare_v2(STMT_REMOVE_URI_ITEMS, -1, out stmt);
            stmt.bind_int(1, id);
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return false;
            }
            this.db.prepare_v2(STMT_REMOVE_MEDIA_FOLDER_ITEMS, -1, out stmt);
            stmt.bind_int(1, id);
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return false;
            }
            this.db.prepare_v2(STMT_REMOVE_MEDIA_FOLDER_ID, -1, out stmt);
            stmt.bind_int(1, id);
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                return false;
            }
            return true;
        }
        else {
            print("FOLDER was not in DB!\n");
            return true;
        }
    }

    private static const string STMT_REMOVE_OLD_ARTISTS =
        "DELETE FROM artists WHERE id != ? AND id NOT IN (SELECT i.artist FROM items i GROUP BY i.artist) AND id NOT IN (SELECT i.album_artist FROM items i GROUP BY i.artist)";
    
    private static const string STMT_REMOVE_OLD_GENRES =
        "DELETE FROM genres WHERE id NOT IN (SELECT i.genre FROM items i GROUP BY i.genre)";
    
    private static const string STMT_REMOVE_OLD_ALBUMS =
        "DELETE FROM albums WHERE id NOT IN (SELECT DISTINCT i.album FROM items i GROUP BY i.album)";

    public void cleanup_database() {
        Statement stmt;
        // cleanup artists
        this.db.prepare_v2(STMT_REMOVE_OLD_ARTISTS, -1, out stmt);
        if(stmt.bind_int (1, VA_ID) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return;
        }
        
        // cleanup genres
        this.db.prepare_v2(STMT_REMOVE_OLD_GENRES, -1, out stmt);
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return;
        }
        
        // cleanup albums
        this.db.prepare_v2(STMT_REMOVE_OLD_ALBUMS, -1, out stmt);
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return;
        }
    }

    public delegate void WriterCallback(Sqlite.Database database);
    
    public void do_callback_transaction(WriterCallback cb) {
        if(db == null) return;
        
        if(cb != null)
            cb(db);
    }
    
    internal void write_lastused(ref TrackData[] tda) throws DbError {
        if(db == null)
            return;
        
        if(db.exec("DELETE FROM lastused;", null, null)!= Sqlite.OK) {
            throw new DbError.FAILED("Error while removing old music folders");
        }
        foreach(TrackData? td in tda)
            this.insert_lastused_track(ref td);
    }
    
    private static const string STMT_INSERT_LASTUSED =
        "INSERT INTO lastused (uri, mediatype, tracknumber, title, album, artist, length, genre, year, id, source, cd_number) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    
    private void insert_lastused_track(ref TrackData td) {
        this.insert_lastused_entry_statement.reset();
        this.insert_lastused_entry_statement.bind_text(1, td.item.uri);
        this.insert_lastused_entry_statement.bind_int (2, td.item.type);
        if(td.tracknumber > 0)
            this.insert_lastused_entry_statement.bind_text(3, td.tracknumber.to_string());
        else
            this.insert_lastused_entry_statement.bind_text(3, "0");
        
        if(td.title != null)
            this.insert_lastused_entry_statement.bind_text(4, td.title);
        if(td.album != null)
            this.insert_lastused_entry_statement.bind_text(5, td.album);
        if(td.artist != null)
            this.insert_lastused_entry_statement.bind_text(6, td.artist);
        if(td.length > 0)
            this.insert_lastused_entry_statement.bind_text(7, make_time_display_from_seconds(td.length));
        else
            this.insert_lastused_entry_statement.bind_text(7, "0");
        if(td.genre != null)
            this.insert_lastused_entry_statement.bind_text(8, td.genre);
        if(td.year > 0)
            this.insert_lastused_entry_statement.bind_text(9, td.year.to_string());
        else
            this.insert_lastused_entry_statement.bind_text(9, "0");
        this.insert_lastused_entry_statement.bind_int (10, td.item.db_id);
        this.insert_lastused_entry_statement.bind_text(11, td.item.text);
        this.insert_lastused_entry_statement.bind_text(12, td.disk_number.to_string());
        
        if(insert_lastused_entry_statement.step() != Sqlite.DONE) {
            this.db_error();
        }
    }
    
//    private static const string STMT_GET_ALBUM_IDS_BY_NAME =
//        "SELECT id FROM albums WHERE artist != 1 AND caseless_name = ?"; // TODO try index
    private static const string STMT_REMOVE_ALBUM =
        "DELETE FROM albums WHERE id=?";
    private static const string STMT_REPLACE_ARTIST_A_ALBUM_IN_ITEMS =
        "UPDATE items SET album_artist=?, album=? WHERE album=?";
    
    private void set_albumname_is_va_album(ref string stripped_album, ref int[] ids, int va_al_id) {
        string caseless_album;
        caseless_album = stripped_album.casefold();
        
        Statement stmt;
        this.db.prepare_v2(STMT_REMOVE_ALBUM, -1, out stmt);
        
        foreach(int xi in ids) {

            stmt.reset();
            if(stmt.bind_int (1, xi) != Sqlite.OK) {
                this.db_error();
                continue;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                continue;
            }
        }
        
        this.db.prepare_v2(STMT_REPLACE_ARTIST_A_ALBUM_IN_ITEMS, -1, out stmt);
        
        foreach(int xi in ids) {
            stmt.reset();
            if(stmt.bind_int (1, VA_ID)    != Sqlite.OK ||
               stmt.bind_int (2, va_al_id) != Sqlite.OK ||
               stmt.bind_int (3, xi)       != Sqlite.OK) {
                this.db_error();
                continue;
            }
            if(stmt.step() != Sqlite.DONE) {
                this.db_error();
                continue;
            }
        }
    }

    // Execution of prepared statements of that the return values are not
    // used (delete, drop, ...) and that do not need to bind data.
    // Function returns true if ok
    private bool exec_prepared_stmt(Statement stmt) {
        stmt.reset();
        if(stmt.step() != Sqlite.DONE) {
            this.db_error();
            return false;
        }
        return true;
    }

    internal void del_all_folders() {
        if(!exec_prepared_stmt(del_media_folder_statement))
            print("error deleting folders from db\n");
    }

    internal void del_all_streams() {
        if(!exec_prepared_stmt(del_streams_statement))
            print("error deleting streams from db\n");
    }

    private static const string STMT_INS_VARIOUS_ARTISTS =
        "INSERT INTO artists (name, caseless_name) VALUES ('Various artists','various artists');";

    internal bool reset_database() {
        if(!exec_prepared_stmt(this.delete_artists_statement     )) return false;
        if(!exec_prepared_stmt(this.ins_va_statement             )) return false; // VA id = 1 !
        if(!exec_prepared_stmt(this.delete_albums_statement      )) return false;
//        if(!exec_prepared_stmt(this.delete_album_names_statement )) return false;
        if(!exec_prepared_stmt(this.delete_items_statement       )) return false;
        if(!exec_prepared_stmt(this.delete_genres_statement      )) return false;
        if(!exec_prepared_stmt(this.delete_paths_statement       )) return false;
        if(!exec_prepared_stmt(this.delete_uris_statement        )) return false;
        return true;
    }

    public void begin_transaction() {
        exec_prepared_stmt(begin_statement);
        begin_stmt_used = true;
    }

    public void commit_transaction() {
        if(begin_stmt_used != true)
            return;
            
        exec_prepared_stmt(commit_statement);
        begin_stmt_used = false;
    }
}

