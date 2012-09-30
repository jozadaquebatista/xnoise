/* xnoise-db-writer.vala
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
using Xnoise.Resources;
using Xnoise.Utilities;

public class Xnoise.Database.Writer : GLib.Object {
    private Sqlite.Database db = null;
    private Statement insert_lastused_entry_statement;
    private Statement add_radio_statement;
    private Statement begin_statement;
    private Statement commit_statement;
    private Statement write_media_folder_statement;
    private Statement get_media_folder_statement;
    private Statement del_media_folder_statement;
    private Statement del_streams_statement;
    private Statement get_artist_id_statement;
    private Statement insert_artist_statement;
    private Statement get_album_id_statement;
    private Statement insert_album_statement;
    private Statement get_uri_id_statement;
    private Statement insert_uri_statement;
    private Statement get_genre_id_statement;
    private Statement insert_genre_statement;
    private Statement insert_title_statement;
    private Statement get_title_id_statement;
    private Statement delete_artists_statement;
    private Statement delete_albums_statement;
    private Statement delete_items_statement;
    private Statement delete_uris_statement;
    private Statement delete_genres_statement;
    private static Statement delete_uri_statement;
    private static Statement delete_item_statement;

    private Statement get_artist_for_uri_id_statement;
    private Statement count_artist_in_items_statement;
    private Statement delete_artist_statement;

    private Statement get_album_for_uri_id_statement;
    private Statement count_album_in_items_statement;
    private Statement delete_album_statement;

    private Statement get_genre_for_uri_id_statement;
    private Statement count_genre_in_items_statement;
    private Statement delete_genre_statement;

    private Statement get_statistics_id_statement;
    private Statement add_statistic_statement;
    private Statement update_playtime_statement;

    private Statement get_artist_max_id_statement;
    private Statement get_uri_max_id_statement;
    private Statement get_genre_max_id_statement;
    private Statement get_albums_max_id_statement;
    
    public delegate void ChangeNotificationCallback(ChangeType changetype, Item? item);
    
    public enum ChangeType {
        ADD_ARTIST,
        ADD_ALBUM,
        ADD_TITLE,
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
    private static const string STMT_PRAGMA_SET_FOREIGN_KEYS_ON =
        "PRAGMA foreign_keys = ON;";
    private static const string STMT_PRAGMA_GET_FOREIGN_KEYS_ON =
        "PRAGMA foreign_keys;";

    // DBWRITER STATEMENTS
    private static const string STMT_BEGIN =
        "BEGIN";
    private static const string STMT_COMMIT =
        "COMMIT";
    private static const string STMT_CHECK_TRACK_EXISTS =
        "SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
    private static const string STMT_DEL_MEDIA_FOLDERS =
        "DELETE FROM media_folders";
    private static const string STMT_DEL_RADIO_STREAM =
        "DELETE FROM streams;";
    private static const string STMT_DEL_MEDIAFILES =
        "DELETE FROM media_files;";
    private static const string STMT_ADD_RADIO =
        "INSERT INTO streams (name, uri) VALUES (?, ?)";
    private static const string STMT_ADD_MFILE =
        "INSERT INTO media_files (name) VALUES (?)";
    private static const string STMT_GET_MEDIA_FOLDERS =
        "SELECT * FROM media_folders";
    private static const string STMT_INSERT_ARTIST =
        "INSERT INTO artists (name) VALUES (?)";
    private static const string STMT_INSERT_ALBUM =
        "INSERT INTO albums (artist, name) VALUES (?, ?)";
    private static const string STMT_GET_URI_ID =
        "SELECT id FROM uris WHERE name = ?";
    private static const string STMT_INSERT_URI =
        "INSERT INTO uris (name) VALUES (?)";
    private static const string STMT_GET_GENRE_ID =
        "SELECT id FROM genres WHERE utf8_lower(name) = ?";
    private static const string STMT_INSERT_GENRE =
        "INSERT INTO genres (name) VALUES (?)";
    private static const string STMT_GET_TITLE_ID =
        "SELECT id FROM items WHERE artist = ? AND album = ? AND utf8_lower(title) = ?";
    private static const string STMT_DEL_ARTISTS =
        "DELETE FROM artists";
    private static const string STMT_DEL_ALBUMS =
        "DELETE FROM albums";
    private static const string STMT_DEL_ITEMS =
        "DELETE FROM items";
    private static const string STMT_DEL_URIS =
        "DELETE FROM uris";
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
    private static const string STMT_DEL_ARTIST = 
        "DELETE FROM ARTISTS WHERE id = ?";
    private static const string STMT_GET_ALBUM_FOR_URI_ID =
        "SELECT album FROM items WHERE uri = ?";
    private static const string STMT_COUNT_ALBUM_IN_ITEMS =
        "SELECT COUNT(id) FROM items WHERE album = ?";
    private static const string STMT_DEL_ALBUM = 
        "DELETE FROM albums WHERE id = ?";
        
    private static const string STMT_GET_GENRE_FOR_URI_ID =
        "SELECT genre FROM items WHERE uri = ?";
    private static const string STMT_COUNT_GENRE_IN_ITEMS =
        "SELECT COUNT(id) FROM genre WHERE album = ?";
    private static const string STMT_DEL_GENRE = 
        "DELETE FROM genre WHERE id = ?";

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
        
        setup_db();
    }
    
    private void setup_db() {
        setup_pragmas();
    }
    
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
        this.db.prepare_v2(STMT_INSERT_LASTUSED, -1, out this.insert_lastused_entry_statement);
        this.db.prepare_v2(STMT_BEGIN, -1, out this.begin_statement);
        this.db.prepare_v2(STMT_COMMIT, -1, out this.commit_statement);
        this.db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1, out this.get_media_folder_statement);
        this.db.prepare_v2(STMT_WRITE_MEDIA_FOLDERS, -1, out this.write_media_folder_statement);
        this.db.prepare_v2(STMT_DEL_MEDIA_FOLDERS, -1, out this.del_media_folder_statement);
        this.db.prepare_v2(STMT_ADD_RADIO, -1, out this.add_radio_statement);
        this.db.prepare_v2(STMT_DEL_RADIO_STREAM, -1, out this.del_streams_statement);
        this.db.prepare_v2(STMT_GET_ARTIST_ID, -1, out this.get_artist_id_statement);
        this.db.prepare_v2(STMT_INSERT_ARTIST, -1, out this.insert_artist_statement);
        this.db.prepare_v2(STMT_GET_ALBUM_ID, -1, out this.get_album_id_statement);
        this.db.prepare_v2(STMT_INSERT_ALBUM, -1, out this.insert_album_statement);
        this.db.prepare_v2(STMT_GET_URI_ID, -1, out this.get_uri_id_statement);
        this.db.prepare_v2(STMT_INSERT_URI, -1, out this.insert_uri_statement);
        this.db.prepare_v2(STMT_GET_GENRE_ID, -1, out this.get_genre_id_statement);
        this.db.prepare_v2(STMT_INSERT_GENRE, -1, out this.insert_genre_statement);
        this.db.prepare_v2(STMT_INSERT_TITLE, -1, out this.insert_title_statement);
        this.db.prepare_v2(STMT_GET_TITLE_ID, -1, out this.get_title_id_statement);
        this.db.prepare_v2(STMT_DEL_ARTISTS, -1, out this.delete_artists_statement);
        this.db.prepare_v2(STMT_DEL_ALBUMS, -1, out this.delete_albums_statement);
        this.db.prepare_v2(STMT_DEL_ITEMS, -1, out this.delete_items_statement);
        this.db.prepare_v2(STMT_DEL_URIS, -1, out this.delete_uris_statement);
        this.db.prepare_v2(STMT_DEL_GENRES, -1, out this.delete_genres_statement);
        this.db.prepare_v2(STMT_GET_ARTIST_FOR_URI_ID , -1, out this.get_artist_for_uri_id_statement);
        this.db.prepare_v2(STMT_COUNT_ARTIST_IN_ITEMS , -1, out this.count_artist_in_items_statement);
        this.db.prepare_v2(STMT_DEL_ARTIST , -1, out this.delete_artist_statement);
        this.db.prepare_v2(STMT_DEL_URI , -1, out this.delete_uri_statement);
        this.db.prepare_v2(STMT_DEL_ITEM , -1, out this.delete_item_statement);
        this.db.prepare_v2(STMT_GET_ALBUM_FOR_URI_ID , -1, out this.get_album_for_uri_id_statement);
        this.db.prepare_v2(STMT_COUNT_ALBUM_IN_ITEMS , -1, out this.count_album_in_items_statement);
        this.db.prepare_v2(STMT_DEL_ALBUM , -1, out this.delete_album_statement);
        this.db.prepare_v2(STMT_GET_GENRE_FOR_URI_ID , -1, out this.get_genre_for_uri_id_statement);
        this.db.prepare_v2(STMT_COUNT_GENRE_IN_ITEMS , -1, out this.count_genre_in_items_statement);
        this.db.prepare_v2(STMT_DEL_GENRE , -1, out this.delete_genre_statement);
        this.db.prepare_v2(STMT_GET_STATISTICS_ID , -1, out this.get_statistics_id_statement);
        this.db.prepare_v2(STMT_ADD_STATISTIC , -1, out this.add_statistic_statement);
        this.db.prepare_v2(STMT_UPDATE_PLAYTIME , -1, out this.update_playtime_statement);
        this.db.prepare_v2(STMT_GET_ARTIST_MAX_ID, -1, out get_artist_max_id_statement);
        this.db.prepare_v2(STMT_GET_URI_MAX_ID, -1, out get_uri_max_id_statement);
        this.db.prepare_v2(STMT_GET_GENRE_MAX_ID, -1, out get_genre_max_id_statement);
        this.db.prepare_v2(STMT_GET_ALBUMS_MAX_ID, -1, out get_albums_max_id_statement);
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
    
    private void setup_pragmas() {
        string errormsg;
        if(db.exec(STMT_PRAGMA_SET_FOREIGN_KEYS_ON, null, out errormsg)!= Sqlite.OK) {
            stderr.printf("exec_stmnt_string error: %s", errormsg);
            return;
        }
    }
    
    private static const string STMT_GET_URI_FOR_ITEM_ID =
        "SELECT u.name FROM uris u, items it WHERE it.uri = u.id AND it.id = ?";
    public string? get_uri_for_item_id(int32 id) {
        string? val = null;
        Statement stmt;
        this.db.prepare_v2(STMT_GET_URI_FOR_ITEM_ID, -1, out stmt);
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
        "SELECT id FROM artists WHERE utf8_lower(name) = ?";
    private static const string STMT_UPDATE_ARTIST_NAME = 
        "UPDATE artists SET name=? WHERE id=?";
    private int handle_artist(ref string artist, bool update_artist = false) {
        // find artist, if available or create entry_album
        // return id for artist
        int artist_id = -1;
        get_artist_id_statement.reset();
        if(get_artist_id_statement.bind_text(1, (artist != null ? artist.down().strip() : EMPTYSTRING)) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_artist_id_statement.step() == Sqlite.ROW)
            artist_id = get_artist_id_statement.column_int(0);
        
        if(artist_id == -1) { // artist not in table, yet
            insert_artist_statement.reset();
            if(insert_artist_statement.bind_text(1, artist.strip()) != Sqlite.OK) {
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
            foreach(NotificationData cxd in change_callbacks) {
                Item? item = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, artist_id);
//                item.source_id = db_browser.get_source_id();
                item.text = artist.strip();
                if(cxd.cb != null)
                    cxd.cb(ChangeType.ADD_ARTIST, item);
            }
        }
        if(update_artist) {
            Statement stmt;
            this.db.prepare_v2(STMT_UPDATE_ARTIST_NAME, -1, out stmt);
            stmt.reset();
            if(stmt.bind_text(1, artist)    != Sqlite.OK ||
               stmt.bind_int (2, artist_id) != Sqlite.OK ) {
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
        
        this.db.prepare_v2(STMT_INC_PLAYCOUNT, -1, out stmt);
        
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
        "SELECT id FROM albums WHERE artist = ? AND utf8_lower(name) = ?";
    private static const string STMT_UPDATE_ALBUM_NAME = 
        "UPDATE albums SET name=? WHERE id=?";
    private int handle_album(ref int artist_id, ref string album, bool update_album = false) {
        get_album_id_statement.reset();
        if(get_album_id_statement.bind_int (1, artist_id) != Sqlite.OK ||
           get_album_id_statement.bind_text(2, album != null ? album.down().strip() : EMPTYSTRING) != Sqlite.OK ) {
            this.db_error();
            return -1;
           }
        if(get_album_id_statement.step() == Sqlite.ROW)
            return get_album_id_statement.column_int(0);
        
        // Insert album
        insert_album_statement.reset();
        if(insert_album_statement.bind_int (1, artist_id)     != Sqlite.OK ||
           insert_album_statement.bind_text(2, album.strip()) != Sqlite.OK ) {
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

    private static const string STMT_GET_URI_MAX_ID =
        "SELECT MAX(id) FROM uris";

    private int handle_uri(string uri) {
        insert_uri_statement.reset();
        if(insert_uri_statement.bind_text(1, uri) != Sqlite.OK) {
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

    private int handle_genre(ref string genre) {
        if((genre == null)||(genre.strip() == EMPTYSTRING)) return -2; //NO GENRE

        get_genre_id_statement.reset();
        if(get_genre_id_statement.bind_text(1, genre != null ? genre.down().strip() : EMPTYSTRING) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(get_genre_id_statement.step() == Sqlite.ROW)
            return get_genre_id_statement.column_int(0);
//        if(genre_id == -1) { // genre not in table, yet
        // Insert genre
        insert_genre_statement.reset();
        if(insert_genre_statement.bind_text(1, genre.strip()) != Sqlite.OK) {
            this.db_error();
            return -1;
        }
        if(insert_genre_statement.step() != Sqlite.DONE) {
            this.db_error();
            return -1;
        }
        // Return id key
        get_genre_max_id_statement.reset();
        if(get_genre_max_id_statement.step() == Sqlite.ROW)
            return get_genre_max_id_statement.column_int(0);
        else
            return -1;
    }

    public bool get_trackdata_for_stream(string uri, out TrackData val) {
        Statement stmt;
        bool retval = false;
        val = new TrackData();
        this.db.prepare_v2(STMT_TRACKDATA_FOR_STREAM, -1, out stmt);
            
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

    private static const string STMT_UPDATE_TITLE = "UPDATE items SET artist=?, album=?, title=?, genre=?, year=?, tracknumber=? WHERE id=?";
    private static const string STMT_UPDATE_ARTISTALBUM = "UPDATE items SET artist=?, album=? WHERE id=?";
    public bool update_title(ref Item? item, ref TrackData td) {
        if(item.type != ItemType.LOCAL_AUDIO_TRACK &&
           item.type != ItemType.LOCAL_VIDEO_TRACK) {
            
            int artist_id = handle_artist(ref td.artist, true);
            
            if(artist_id == -1) {
                print("Error updating artist for '%s' ! \n", td.artist);
                return false;
            }
            int album_id = handle_album(ref artist_id, ref td.album, true);
            if(album_id == -1) {
                print("Error updating album for '%s' ! \n", td.album);
                return false;
            }
            Statement stmt;
            this.db.prepare_v2(STMT_UPDATE_ARTISTALBUM, -1, out stmt);
        
            if(stmt.bind_int (1, artist_id)     != Sqlite.OK ||
               stmt.bind_int (2, album_id)      != Sqlite.OK ||
               stmt.bind_int (3, td.item.db_id) != Sqlite.OK) {
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
            else if(item.type == ItemType.COLLECTION_CONTAINER_ARTIST) {
                count_artist_in_items_statement.reset();
                if(count_artist_in_items_statement.bind_int (1, item.db_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                int cnt = 0;
                if(count_artist_in_items_statement.step() == Sqlite.ROW) {
                    cnt = count_artist_in_items_statement.column_int(0);
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
        }
        else {
            // Buffer old ids
            int32 old_artist_id, old_album_id;
            
            get_ids_for_item(item, out old_artist_id, out old_album_id);
            int artist_id = handle_artist(ref td.artist, false);
            
            if(artist_id == -1) {
                print("Error updating artist for '%s' ! \n", td.artist);
                return false;
            }
            int album_id = handle_album(ref artist_id, ref td.album, false);
            if(album_id == -1) {
                print("Error updating album for '%s' ! \n", td.album);
                return false;
            }
            int genre_id = handle_genre(ref td.genre);
            if(genre_id == -1) {
                print("Error updating genre for '%s' ! \n", td.genre);
                return false;
            }
            Statement stmt;
            this.db.prepare_v2(STMT_UPDATE_TITLE, -1, out stmt);
            
            if(stmt.bind_int (1, artist_id)     != Sqlite.OK ||
               stmt.bind_int (2, album_id)      != Sqlite.OK ||
               stmt.bind_text(3, td.title)      != Sqlite.OK ||
               stmt.bind_int (4, genre_id)      != Sqlite.OK ||
               stmt.bind_int (5, (int)td.year)       != Sqlite.OK ||
               stmt.bind_int (6, (int)td.tracknumber)!= Sqlite.OK ||
               stmt.bind_int (7, td.item.db_id) != Sqlite.OK) {
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
            if(cnt == 0) {
                delete_artist_statement.reset();
                if(delete_artist_statement.bind_int (1, old_artist_id) != Sqlite.OK) {
                    this.db_error();
                    return false;
                }
                delete_artist_statement.step();
            }
        }
        return true;
    }
    
    
    private static const string STMT_GET_ARTIST_AND_ALBUM_IDS = 
        "SELECT artist, album FROM items WHERE id = ?";
    private void get_ids_for_item(Item? item, out int32 old_artist_id, out int32 old_album_id) {
        old_artist_id = old_album_id = -1;
        Statement stmt;
        this.db.prepare_v2(STMT_GET_ARTIST_AND_ALBUM_IDS, -1, out stmt);
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
    
    private static const string STMT_GET_TRACK_CNT_FOR_ARTIST = 
       "SELECT COUNT(id) FROM items WHERE artist=(SELECT artist FROM items WHERE items.id=?)";

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
        
        db.prepare_v2(STMT_GET_TRACK_CNT_FOR_ARTIST, -1, out stmt);
        if(stmt.bind_int(1, uri_id)!= Sqlite.OK ) {
            return;
        }
        bool more_tracks_from_same_artist = true;
        if(stmt.step() == Sqlite.ROW) {
            more_tracks_from_same_artist = stmt.column_int(0) > 1;
        }
        else {
            return;
        }
        
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
        
        if(!more_tracks_from_same_artist) {
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

    private static const string STMT_GET_GET_ITEM_ID = 
        "SELECT id FROM items WHERE artist = ? AND album = ? AND title = ?";
    
    private static const string STMT_INSERT_TITLE =
        "INSERT INTO items (tracknumber, artist, album, title, genre, year, uri, mediatype, length, bitrate, mimetype) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    private static const string STMT_GET_ITEM_ID =
        "SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.id = ?";
    
    public bool insert_title(ref TrackData td) { // , string uri
        // make entries in other tables and get references from there
        td.dat1 = handle_artist(ref td.artist);
        if(td.dat1 == -1) {
            print("Error importing artist for %s : '%s' ! \n", td.item.uri, td.artist);
            return false;
        }
        td.dat2 = handle_album(ref td.dat1, ref td.album);
        if(td.dat2 == -1) {
            print("Error importing album for %s : '%s' ! \n", td.item.uri, td.album);
            return false;
        }
        int uri_id = handle_uri(td.item.uri);
        if(uri_id == -1) {
            //print("Error importing uri for %s : '%s' ! \n", uri, uri);
            return false;
        }
        int genre_id = handle_genre(ref td.genre);
        if(genre_id == -1) {
            print("Error importing genre for %s : '%s' ! \n", td.item.uri, td.genre);
            return false;
        }
        //print("insert_title td.item.type %s\n", td.item.type.to_string());
        insert_title_statement.reset();
        if(insert_title_statement.bind_int (1,  (int)td.tracknumber) != Sqlite.OK ||
           insert_title_statement.bind_int (2,  td.dat1)             != Sqlite.OK ||
           insert_title_statement.bind_int (3,  td.dat2)             != Sqlite.OK ||
           insert_title_statement.bind_text(4,  td.title)            != Sqlite.OK ||
           insert_title_statement.bind_int (5,  genre_id)            != Sqlite.OK ||
           insert_title_statement.bind_int (6,  (int)td.year)        != Sqlite.OK ||
           insert_title_statement.bind_int (7,  uri_id)              != Sqlite.OK ||
           insert_title_statement.bind_int (8,  td.item.type)        != Sqlite.OK ||
           insert_title_statement.bind_int (9,  td.length)           != Sqlite.OK ||
           insert_title_statement.bind_int (10, td.bitrate)          != Sqlite.OK ||
           insert_title_statement.bind_text(11, td.mimetype)         != Sqlite.OK) {
            this.db_error();
            return false;
        }
        
        if(insert_title_statement.step()!=Sqlite.DONE) {
            this.db_error();
            return false;
        }
        if(td.item.type == ItemType.LOCAL_VIDEO_TRACK) {
            Statement stmt;
            this.db.prepare_v2(STMT_GET_ITEM_ID , -1, out stmt);
            if(stmt.bind_int (1,uri_id) != Sqlite.OK) {
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
        
        add_radio_statement.reset();
        if(add_radio_statement.bind_text(1, i.text) != Sqlite.OK||
           add_radio_statement.bind_text(2, i.uri)  != Sqlite.OK) {
            this.db_error();
            return false;
        }
        if(add_radio_statement.step() != Sqlite.DONE) {
            this.db_error();
            return false;
        }
        Statement stmt;
        this.db.prepare_v2(STMT_GET_STREAM_ID_BY_URI, -1, out stmt);
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
        this.db.prepare_v2(STMT_UPDATE_STREAM_NAME, -1, out stmt);
        if(stmt.bind_text(1, item.text) != Sqlite.OK ||
           stmt.bind_text(2, item.uri ) != Sqlite.OK) {
            this.db_error();
            return;
        }
        if(stmt.step() != Sqlite.DONE)
            this.db_error();
    }
    
    private static const string STMT_WRITE_MEDIA_FOLDERS =
        "INSERT INTO media_folders (name) VALUES (?)";

    public bool add_single_folder_to_collection(Item? mfolder) {
        if(mfolder == null)
            return false;
        // TODO add check for existance
        this.write_media_folder_statement.reset();
        File f = File.new_for_uri(mfolder.uri);
        this.write_media_folder_statement.bind_text(1, f.get_path());
        if(write_media_folder_statement.step() != Sqlite.DONE) {
            this.db_error();
            return false;
        }
        return true;
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
        this.begin_transaction();
        foreach(TrackData? td in tda)
            this.insert_lastused_track(ref td);
        this.commit_transaction();
    }
    
    private static const string STMT_INSERT_LASTUSED =
        "INSERT INTO lastused (uri, mediatype, tracknumber, title, album, artist, length, genre, year, id, source) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
    
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
        
        if(insert_lastused_entry_statement.step() != Sqlite.DONE) {
            this.db_error();
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

    internal bool delete_local_media_data() {
        if(!exec_prepared_stmt(this.delete_artists_statement)) return false;
        if(!exec_prepared_stmt(this.delete_albums_statement )) return false;
        if(!exec_prepared_stmt(this.delete_items_statement  )) return false;
        if(!exec_prepared_stmt(this.delete_uris_statement   )) return false;
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

