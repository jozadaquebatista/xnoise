/* xnoise-db-writer.vala
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
 * 	Jörn Magens
 */

using Sqlite;

public class Xnoise.DbWriter : GLib.Object {
	private const string DATABASE_NAME = "db.sqlite";
	private const string SETTINGS_FOLDER = ".xnoise";
	private Sqlite.Database db = null;
	private Statement update_album_image_statement;
	private Statement insert_lastused_entry_statement;
	private Statement add_radio_statement;
	private Statement check_track_exists_statement;
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
	private Statement delete_media_files_statement;
	private Statement add_mfile_statement;
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
	
	public delegate void ChangeNotificationCallback(ChangeType changetype, Item? item);
	
	public enum ChangeType {
		ADD_ARTIST,
		ADD_ALBUM,
		ADD_TITLE,
		REMOVE_ARTIST,
		REMOVE_ALBUM,
		REMOVE_TITLE,
		REMOVE_URI,
		CLEAR_DB
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
	private static const string STMT_UPDATE_ALBUM_IMAGE =
		"UPDATE albums SET image = ? WHERE id = (SELECT al.id FROM albums al, artists ar WHERE al.artist = ar.id AND LOWER(ar.name) = LOWER(?) AND LOWER(al.name) = LOWER(?))";
	private static const string STMT_CHECK_TRACK_EXISTS =
		"SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
	private static const string STMT_INSERT_LASTUSED =
		"INSERT INTO lastused (uri, mediatype) VALUES (?,?)";
	private static const string STMT_WRITE_MEDIA_FOLDERS =
		"INSERT INTO media_folders (name) VALUES (?)";
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
	private static const string STMT_GET_ARTIST_ID =
		"SELECT id FROM artists WHERE LOWER(name) = ?";
	private static const string STMT_INSERT_ARTIST =
		"INSERT INTO artists (name) VALUES (?)";
	private static const string STMT_GET_ALBUM_ID =
		"SELECT id FROM albums WHERE artist = ? AND LOWER(name) = ?";
	private static const string STMT_INSERT_ALBUM =
		"INSERT INTO albums (artist, name) VALUES (?, ?)";
	private static const string STMT_GET_URI_ID =
		"SELECT id FROM uris WHERE name = ?";
	private static const string STMT_INSERT_URI =
		"INSERT INTO uris (name) VALUES (?)";
	private static const string STMT_GET_GENRE_ID =
		"SELECT id FROM genres WHERE LOWER(name) = ?";
	private static const string STMT_INSERT_GENRE =
		"INSERT INTO genres (name) VALUES (?)";
	private static const string STMT_GET_TITLE_ID =
		"SELECT id FROM items WHERE artist = ? AND album = ? AND LOWER(title) = ?";
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
	private static const string STMT_TRACK_ID_FOR_URI =
		"SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
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
		
	/*private static const string STMT_GET_COL_FOR_URI_ID =
		"SELECT ? FROM items WHERE uri = ?";
	private static const string STMT_COUNT_COL_IN_ITEMS =
		"SELECT COUNT(id) FROM items WHERE ? = ?";
	private static const string STMT_DEL_ID_IN_TABLE = 
		"DELETE FROM ? WHERE id = ?";*/

		
		

	public DbWriter() throws DbError {
		this.db = null;
		this.db = get_db();
		
		if(this.db == null) 
			throw new DbError.FAILED("Cannot open database for writing.");

		this.begin_stmt_used = false; // initialize begin commit compare
		this.prepare_statements();
		
		setup_db();
	}
	
	private void setup_db() {
		setup_pragmas();
	}
	
	private static Database? get_db () {
		// there was more luck on creating the db on first start, if using a static function
		Database database = null;
		File xnoise_home = File.new_for_path(global.settings_folder);
		File xnoisedb = xnoise_home.get_child(DATABASE_NAME);
		if (!xnoise_home.query_exists(null)) {
			print("Cannot find settings folder!\n");
			return null;
		}
		int ret = Database.open_v2(xnoisedb.get_path(),
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

	private void db_error() {
		print("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
	}

	private void prepare_statements() {
		this.db.prepare_v2(STMT_UPDATE_ALBUM_IMAGE, -1,
			out this.update_album_image_statement);
		this.db.prepare_v2(STMT_CHECK_TRACK_EXISTS, -1,
			out this.check_track_exists_statement);
		this.db.prepare_v2(STMT_INSERT_LASTUSED, -1,
			out this.insert_lastused_entry_statement);
		this.db.prepare_v2(STMT_BEGIN, -1,
			out this.begin_statement);
		this.db.prepare_v2(STMT_COMMIT, -1,
			out this.commit_statement);
		this.db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1,
			out this.get_media_folder_statement);
		this.db.prepare_v2(STMT_WRITE_MEDIA_FOLDERS, -1,
			out this.write_media_folder_statement);
		this.db.prepare_v2(STMT_DEL_MEDIA_FOLDERS, -1,
			out this.del_media_folder_statement);
		this.db.prepare_v2(STMT_ADD_RADIO, -1,
			out this.add_radio_statement);
		this.db.prepare_v2(STMT_DEL_RADIO_STREAM, -1,
			out this.del_streams_statement);
		this.db.prepare_v2(STMT_GET_ARTIST_ID, -1,
			out this.get_artist_id_statement);
		this.db.prepare_v2(STMT_INSERT_ARTIST, -1,
			out this.insert_artist_statement);
		this.db.prepare_v2(STMT_GET_ALBUM_ID, -1,
			out this.get_album_id_statement);
		this.db.prepare_v2(STMT_INSERT_ALBUM, -1,
			out this.insert_album_statement);
		this.db.prepare_v2(STMT_GET_URI_ID, -1,
			out this.get_uri_id_statement);
		this.db.prepare_v2(STMT_INSERT_URI, -1,
			out this.insert_uri_statement);
		this.db.prepare_v2(STMT_GET_GENRE_ID, -1,
			out this.get_genre_id_statement);
		this.db.prepare_v2(STMT_INSERT_GENRE, -1,
			out this.insert_genre_statement);
		this.db.prepare_v2(STMT_INSERT_TITLE, -1,
        	out this.insert_title_statement);
		this.db.prepare_v2(STMT_GET_TITLE_ID, -1,
			out this.get_title_id_statement);
		this.db.prepare_v2(STMT_DEL_ARTISTS, -1,
			out this.delete_artists_statement);
		this.db.prepare_v2(STMT_DEL_ALBUMS, -1,
			out this.delete_albums_statement);
		this.db.prepare_v2(STMT_DEL_ITEMS, -1,
			out this.delete_items_statement);
		this.db.prepare_v2(STMT_DEL_URIS, -1,
			out this.delete_uris_statement);
		this.db.prepare_v2(STMT_DEL_GENRES, -1,
			out this.delete_genres_statement);
		this.db.prepare_v2(STMT_DEL_MEDIAFILES, -1,
			out this.delete_media_files_statement);
		this.db.prepare_v2(STMT_ADD_MFILE, -1,
			out this.add_mfile_statement);
                        
		this.db.prepare_v2(STMT_GET_ARTIST_FOR_URI_ID , -1,
			out this.get_artist_for_uri_id_statement);
		this.db.prepare_v2(STMT_COUNT_ARTIST_IN_ITEMS , -1,
			out this.count_artist_in_items_statement);
		this.db.prepare_v2(STMT_DEL_ARTIST , -1,
			out this.delete_artist_statement);
		this.db.prepare_v2(STMT_DEL_URI , -1,
			out this.delete_uri_statement);
		this.db.prepare_v2(STMT_DEL_ITEM , -1,
			out this.delete_item_statement);
		        
		this.db.prepare_v2(STMT_GET_ALBUM_FOR_URI_ID , -1,
			out this.get_album_for_uri_id_statement);
		this.db.prepare_v2(STMT_COUNT_ALBUM_IN_ITEMS , -1,
			out this.count_album_in_items_statement);
		this.db.prepare_v2(STMT_DEL_ALBUM , -1,
			out this.delete_album_statement);

		this.db.prepare_v2(STMT_GET_GENRE_FOR_URI_ID , -1,
			out this.get_genre_for_uri_id_statement);
		this.db.prepare_v2(STMT_COUNT_GENRE_IN_ITEMS , -1,
			out this.count_genre_in_items_statement);
		this.db.prepare_v2(STMT_DEL_GENRE , -1,
			out this.delete_genre_statement);
		        
	}

	//private static const string STMT_UPDATE_TITLE_NAME  = "UPDATE items SET title=? WHERE id=?";

	//internal void update_title_name(int item_id, string? new_name) {
	//	Statement stmt;
	//	this.db.prepare_v2(STMT_UPDATE_TITLE_NAME, -1, out stmt);
	//	stmt.reset();
	//	if(new_name == null)
	//		return;
	//	if(stmt.bind_text(1, new_name) != Sqlite.OK ||
	//	   stmt.bind_int(2, item_id) != Sqlite.OK)
	//		this.db_error();
	//	
	//	if(stmt.step() != Sqlite.DONE) 
	//		this.db_error();
	//}
	
	private unowned ChangeNotificationCallback change_cb = null;
	public void register_change_callback(ChangeNotificationCallback cb) {
		change_cb = cb;
	}
	
	private static const string STMT_UPDATE_ALBUM  = "UPDATE albums SET name=? WHERE LOWER(name)=? AND artist=(SELECT artists.id from artists WHERE LOWER(artists.name)=?)";
	internal void update_album_name(string artist, string new_name, string old_name) {
		Statement stmt;
		this.db.prepare_v2(STMT_UPDATE_ALBUM, -1, out stmt);
		stmt.reset();
		if(new_name == "")
			return;
		if(stmt.bind_text(1, new_name)        != Sqlite.OK ||
		   stmt.bind_text(2, old_name.down()) != Sqlite.OK ||
		   stmt.bind_text(3, artist.down())   != Sqlite.OK)
			this.db_error();
		
		if(stmt.step() != Sqlite.DONE) 
			this.db_error();
	}
	
	private void setup_pragmas() {
		Statement stmt;
		int val = 0;
		int retv = 0;
		string errormsg;
		if(db.exec(STMT_PRAGMA_SET_FOREIGN_KEYS_ON, null, out errormsg)!= Sqlite.OK) {
			stderr.printf("exec_stmnt_string error: %s", errormsg);
			return;
		}
		//val = 0;
		//this.db.prepare_v2(STMT_PRAGMA_GET_FOREIGN_KEYS_ON, -1, out stmt);
		//retv = stmt.step();
		//val = stmt.column_int(0);
		//if(val != 1)
		//	print("ERROR Setting up pragmas\n");
	}

	private static const string STMT_UPDATE_ARTIST = "UPDATE artists SET name=? WHERE LOWER(artists.name)=?"; // AND id=(SELECT artists.id from artists WHERE LOWER(artists.name)=?)
	internal void update_artist_name(string new_name, string old_name) {
		Statement stmt;
		this.db.prepare_v2(STMT_UPDATE_ARTIST, -1, out stmt);
		stmt.reset();
		if(new_name == "")
			return;
		if(stmt.bind_text(1, new_name)        != Sqlite.OK ||
		   stmt.bind_text(2, old_name.down()) != Sqlite.OK)
			this.db_error();
		
		if(stmt.step() != Sqlite.DONE) 
			this.db_error();
	}

	private static const string STMT_URIS_FOR_ARTISTALBUM = "SELECT u.name FROM uris u, items it, albums al, artists ar WHERE it.uri = u.id AND al.id = it.album AND it.artist = ar.id AND LOWER(ar.name)=? AND LOWER(al.name)=?";
	internal string[] get_uris_for_artistalbum(string artist, string album) {
		Statement stmt;
		string[] val = {};
		this.db.prepare_v2(STMT_URIS_FOR_ARTISTALBUM, -1, out stmt);
		stmt.reset();
		if(stmt.bind_text(1, artist.down()) != Sqlite.OK ||
		   stmt.bind_text(2, album.down()) != Sqlite.OK)
			this.db_error();
		
		while(stmt.step() == Sqlite.ROW) 
			val += stmt.column_text(0);
		return val;
	}
	
	private static const string STMT_URIS_FOR_ARTIST = "SELECT u.name FROM uris u, items it, artists ar WHERE it.uri = u.id AND it.artist = ar.id AND LOWER(ar.name)=?";	
	internal string[] get_uris_for_artist(string artist) {
		Statement stmt;
		string[] val = {};
		this.db.prepare_v2(STMT_URIS_FOR_ARTIST, -1, out stmt);
		stmt.reset();
		if(stmt.bind_text(1, artist.down()) != Sqlite.OK)
			this.db_error();
		
		while(stmt.step() == Sqlite.ROW) 
			val += stmt.column_text(0);
		return val;
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
		return val;
	}
	
	public bool set_local_image_for_album(ref string artist,
	                                      ref string album,
	                                      string image_path) {
		// Existance has been checked before !

		begin_transaction();
		update_album_image_statement.reset();
		if(update_album_image_statement.bind_text(1, image_path) != Sqlite.OK ||
		   update_album_image_statement.bind_text(2, artist)     != Sqlite.OK ||
		   update_album_image_statement.bind_text(3, album)      != Sqlite.OK ) {
			this.db_error();
			return false;
		}
		if(update_album_image_statement.step() != Sqlite.DONE) {
			this.db_error();
			return false;
		}
		commit_transaction();
		return true;
	}

	private static const string STMT_UPDATE_ARTIST_NAME = "UPDATE artists SET name=? WHERE id=?";
	private int handle_artist(ref string artist, bool update_artist = false) {
		// find artist, if available or create entry_album
		// return id for artist
		int artist_id = -1;

		get_artist_id_statement.reset();
		if(get_artist_id_statement.bind_text(1, (artist != null ? artist.down().strip() : "")) != Sqlite.OK) {
			this.db_error();
			return -1;
		}
		if(get_artist_id_statement.step() == Sqlite.ROW)
			artist_id = get_artist_id_statement.column_int(0);

		if(artist_id == -1) { // artist not in table, yet
			// Insert artist
			insert_artist_statement.reset();
			if(insert_artist_statement.bind_text(1, artist.strip()) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(insert_artist_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique artist id key
			get_artist_id_statement.reset();
			if(get_artist_id_statement.bind_text(1, artist != null ? artist.down().strip() : "") != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(get_artist_id_statement.step() == Sqlite.ROW)
				artist_id = get_artist_id_statement.column_int(0);
			// change notification
			if(change_cb != null) {
				Item? item = Item(ItemType.COLLECTION_CONTAINER_ARTIST, null, artist_id);
				item.text = artist.strip();
				change_cb(ChangeType.ADD_ARTIST, item);
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

	private static const string STMT_UPDATE_ALBUM_NAME  = "UPDATE albums SET name=? WHERE id=?";
	private int handle_album(ref int artist_id, ref string album, bool update_album = false) {
		int album_id = -1;

		get_album_id_statement.reset();
		if(get_album_id_statement.bind_int (1, artist_id)    != Sqlite.OK ||
		   get_album_id_statement.bind_text(2, album != null ? album.down().strip() : "") != Sqlite.OK ) {
			this.db_error();
			return -1;
		   }
		if(get_album_id_statement.step() == Sqlite.ROW)
			album_id = get_album_id_statement.column_int(0);

		if(album_id == -1) { // album not in table, yet
			// Insert album
			insert_album_statement.reset();
			if(insert_album_statement.bind_int (1, artist_id) != Sqlite.OK ||
			   insert_album_statement.bind_text(2, album.strip())     != Sqlite.OK ) {
				this.db_error();
				return -1;
			}
			if(insert_album_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique album id key
			get_album_id_statement.reset();
			if(get_album_id_statement.bind_int (1, artist_id           )    != Sqlite.OK ||
			   get_album_id_statement.bind_text(2, album != null ? album.down().strip() : "") != Sqlite.OK ) {
				this.db_error();
				return -1;
			}
			if(get_album_id_statement.step() == Sqlite.ROW)
				album_id = get_album_id_statement.column_int(0);
		}
		if(update_album) {
			Statement stmt;
			this.db.prepare_v2(STMT_UPDATE_ALBUM_NAME, -1, out stmt);
			stmt.reset();
			if(stmt.bind_text(1, album)    != Sqlite.OK ||
			   stmt.bind_int (2, album_id) != Sqlite.OK ) {
				this.db_error();
				return -1;
			}
			if(stmt.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}

		}
		return album_id;
	}

	private int handle_uri(string uri) {
		int uri_id = -1;

		get_uri_id_statement.reset();
		if(get_uri_id_statement.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
			return -1;
		}
		if(get_uri_id_statement.step() == Sqlite.ROW)
			uri_id = get_uri_id_statement.column_int(0);

		if(uri_id == -1) { // uri not in table, yet
			// Insert uri
			insert_uri_statement.reset();
			if(insert_uri_statement.bind_text(1, uri) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(insert_uri_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique uri id key
			get_uri_id_statement.reset();
			if(get_uri_id_statement.bind_text(1, uri) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(get_uri_id_statement.step() == Sqlite.ROW)
				uri_id = get_uri_id_statement.column_int(0);
		}
		return uri_id;
	}

	public string[] get_media_folders() {
		string[] sa = {};
		get_media_folder_statement.reset();
		while(get_media_folder_statement.step() == Sqlite.ROW)
			sa += get_media_folder_statement.column_text(0);
		return sa;
	}

	private int handle_genre(ref string genre) {
		int genre_id = -1;
		if((genre.strip() == "")||(genre == null)) return -2; //NO GENRE

		get_genre_id_statement.reset();
		if(get_genre_id_statement.bind_text(1, genre != null ? genre.down().strip() : "") != Sqlite.OK) {
			this.db_error();
			return -1;
		}
		if(get_genre_id_statement.step() == Sqlite.ROW)
			genre_id = get_genre_id_statement.column_int(0);

		if(genre_id == -1) { // genre not in table, yet
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
			// Get unique genre id key
			get_genre_id_statement.reset();
			if(get_genre_id_statement.bind_text(1, genre != null ? genre.down().strip() : "") != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(get_genre_id_statement.step() == Sqlite.ROW)
				genre_id = get_genre_id_statement.column_int(0);
		}
		return genre_id;
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
			val.db_id = stmt.column_int(0);
			val.title = stmt.column_text(1);
			val.uri = uri;
			val.item = Item(ItemType.STREAM, uri, stmt.column_int(0));
			retval = true;
		}
		return retval;
	}

	public int get_track_id_for_uri(string uri) {
		int val = -1;
		Statement stmt;
		
		this.db.prepare_v2(STMT_TRACK_ID_FOR_URI, -1, out stmt);
		stmt.reset();
		stmt.bind_text(1, uri);
		if(stmt.step() == Sqlite.ROW) {
			val = stmt.column_int(0);
		}
		return val;
	}

	private static const string STMT_UPDATE_TITLE = "UPDATE items SET artist=?, album=?, title=? WHERE id=?";
	public bool update_title(int32 id, ref TrackData td) {
		int artist_id = handle_artist(ref td.artist, true);

		if(artist_id == -1) {
			print("Error importing artist for '%s' ! \n", td.artist);
			return false;
		}
		int album_id = handle_album(ref artist_id, ref td.album, true);
		if(album_id == -1) {
			print("Error importing album for '%s' ! \n", td.album);
			return false;
		}
		Statement stmt;
		this.db.prepare_v2(STMT_UPDATE_TITLE, -1, out stmt);
		
		stmt.reset();
		//print("%d %d %s %d\n", artist_id, album_id, td.title, id);
		if(stmt.bind_int (1, artist_id) != Sqlite.OK ||
		   stmt.bind_int (2, album_id)  != Sqlite.OK ||
		   stmt.bind_text(3, td.title)  != Sqlite.OK ||
		   stmt.bind_int (4, id)        != Sqlite.OK) {
			this.db_error();
			return false;
		}
		
		if(stmt.step() != Sqlite.DONE) {
			this.db_error();
			return false;
		}
		return true;
	}
	
	private static const string STMT_GET_GET_ITEM_ID = 
		"SELECT id FROM items WHERE artist = ? AND album = ? AND title = ?";
	
	private static const string STMT_INSERT_TITLE =
		"INSERT INTO items (tracknumber, artist, album, title, genre, year, uri, mediatype, length, bitrate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	
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
//			print("Error importing uri for %s : '%s' ! \n", uri, uri);
			return false;
		}
		int genre_id = handle_genre(ref td.genre);
		if(genre_id == -1) {
			print("Error importing genre for %s : '%s' ! \n", td.item.uri, td.genre);
			return false;
		}
		insert_title_statement.reset();
		if(insert_title_statement.bind_int (1,  (int)td.tracknumber) != Sqlite.OK ||
		   insert_title_statement.bind_int (2,  td.dat1)             != Sqlite.OK ||
		   insert_title_statement.bind_int (3,  td.dat2)             != Sqlite.OK ||
		   insert_title_statement.bind_text(4,  td.title)            != Sqlite.OK ||
		   insert_title_statement.bind_int (5,  genre_id)            != Sqlite.OK ||
		   insert_title_statement.bind_int (6,  (int)td.year)        != Sqlite.OK ||
		   insert_title_statement.bind_int (7,  uri_id)              != Sqlite.OK ||
		   insert_title_statement.bind_int (8,  td.mediatype)        != Sqlite.OK ||
		   insert_title_statement.bind_int (9,  td.length)           != Sqlite.OK ||
		   insert_title_statement.bind_int (10, td.bitrate)          != Sqlite.OK) {
			this.db_error();
			return false;
		}
		
		if(insert_title_statement.step()!=Sqlite.DONE) {
			this.db_error();
			return false;
		}
		
//		//get id back
//		Statement stmt;
//		this.db.prepare_v2(STMT_GET_GET_ITEM_ID, -1, out stmt);
//		if(stmt.bind_int (1, td.dat1)   != Sqlite.OK ||
//		   stmt.bind_int (2, td.dat2)   != Sqlite.OK ||
//		   stmt.bind_text(3, td.title)  != Sqlite.OK) {
//			this.db_error();
//			return false;
//		}
//		stmt.reset();
//		if(stmt.step() == Sqlite.ROW) {
//			td.db_id = (int32)stmt.column_int(0);
//			return true;
//		}
		return true;
	}

	/*
	* Delete a row from the uri table and delete every item that references it and
	* before that delete every album, artist or genre entry that would thus end up
	* with no item referencing it.	
	*/
	public void delete_uri(string uri) {
		// get uri id
		int uri_id = -1;
		

		get_uri_id_statement.reset();
		if(get_uri_id_statement.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
			return;
		}
		if(get_uri_id_statement.step() == Sqlite.ROW)
			uri_id = get_uri_id_statement.column_int(0);
		if (uri_id == -1) return;
		print("%s is %s\n", uri, uri_id.to_string()); 


		//delete the according album/artist/genre entries if not referenced by any other item
		//granted, there might be more intelligent ways to do this but I guess this is the fastest one
		//after all we can use foreign keys and cascading deletion when the distros ship sqlite >=3.6.19
		
		begin_transaction();
				
		//album
		get_album_for_uri_id_statement.reset();
		get_album_for_uri_id_statement.bind_int(1, uri_id);
		get_album_for_uri_id_statement.step();
		var album_id = get_album_for_uri_id_statement.column_int(0);

		count_album_in_items_statement.reset();
		count_album_in_items_statement.bind_int(1, album_id);
		count_album_in_items_statement.step();
		var album_count = count_album_in_items_statement.column_int(0);

		if(album_count < 2) {
			delete_album_statement.reset();
			delete_album_statement.bind_int(1, album_id);
			delete_album_statement.step();
		}
		
		//artist
		get_artist_for_uri_id_statement.reset();
		get_artist_for_uri_id_statement.bind_int(1, uri_id);
		get_artist_for_uri_id_statement.step();
		var artist_id = get_artist_for_uri_id_statement.column_int(0);
		
		count_artist_in_items_statement.reset();
		count_artist_in_items_statement.bind_int(1, artist_id);
		count_artist_in_items_statement.step();
		var artist_count = count_artist_in_items_statement.column_int(0);

		if(artist_count < 2) {
			delete_artist_statement.reset();
			delete_artist_statement.bind_int(1, artist_id);
			delete_artist_statement.step();
		}

		//genre
		get_genre_for_uri_id_statement.reset();
		get_genre_for_uri_id_statement.bind_int(1, uri_id);
		get_genre_for_uri_id_statement.step();
		var genre_id = get_genre_for_uri_id_statement.column_int(0);

		count_genre_in_items_statement.reset();
		count_genre_in_items_statement.bind_int(1, genre_id);
		count_genre_in_items_statement.step();
		var genre_count = count_genre_in_items_statement.column_int(0);

		if(genre_count < 2) {
			delete_genre_statement.reset();
			delete_genre_statement.bind_int(1, genre_id);
			delete_genre_statement.step();
		}

		//delete item
		delete_item_statement.reset();          
		delete_item_statement.bind_int(1, uri_id);
		delete_item_statement.step();
		print("deleted uri_id %s", uri_id.to_string());

		//delete uri
		delete_uri_statement.reset();
		delete_uri_statement.bind_int(1, uri_id);
		delete_uri_statement.step();
		
		commit_transaction();
	}

	public int uri_entry_exists(string uri) {
		int id = -1;
		check_track_exists_statement.reset();
		if(check_track_exists_statement.bind_text(1, uri)!=Sqlite.OK) {
			this.db_error();
		}
		while(check_track_exists_statement.step() == Sqlite.ROW) {
	        id = check_track_exists_statement.column_int(0);
		}
		return id;
	}
	

	// Single stream for collection
	public void add_single_stream_to_collection(string uri, string name = "") {
		if(db == null) return;
		print("add stream : %s \n", uri);
		if((uri == null) || (uri == "")) return;
		if(name == "") name = uri;
		add_radio_statement.reset();
		if(add_radio_statement.bind_text(1, name) != Sqlite.OK||
		   add_radio_statement.bind_text(2, uri)  != Sqlite.OK) {
			this.db_error();
		}
		if(add_radio_statement.step() != Sqlite.DONE) {
			this.db_error();
		}
	}

	// Single file for collection
	public void add_single_file_to_collection(string uri) {
		if(db == null) return;
		if((uri == null) || (uri == "")) return;
		add_mfile_statement.reset();
		if(add_mfile_statement.bind_text(1, uri) != Sqlite.OK) {
			this.db_error();
		}
		if(add_mfile_statement.step() != Sqlite.DONE) {
			this.db_error();
		}
	}

	public void add_single_folder_to_collection(string mfolder) {
		this.write_media_folder_statement.reset();
		this.write_media_folder_statement.bind_text(1, mfolder);
		if(write_media_folder_statement.step() != Sqlite.DONE) {
			this.db_error();
		}
	}

	public void write_final_tracks_to_db(string[] final_tracklist) throws Error {
		if(db == null) return;

		this.begin_transaction();
		if(db.exec("DELETE FROM lastused;", null, null)!= Sqlite.OK) {
			throw new DbError.FAILED("Error while removing old music folders");
		}
		foreach(string uri in final_tracklist) {
			this.insert_lastused_track(uri, 0);
		}
		this.commit_transaction();
	}
	
	public delegate void WriterCallback(Database database);
	
	public void do_callback_transaction(WriterCallback cb) {
		if(db == null) return;
		
		if(cb != null)
			cb(db);
	}
	
	private void insert_lastused_track(string uri, int mediatype) {
		this.insert_lastused_entry_statement.reset();
		this.insert_lastused_entry_statement.bind_text(1, uri);
		this.insert_lastused_entry_statement.bind_int (2, mediatype);
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

	public void del_all_folders() {
		if(!exec_prepared_stmt(del_media_folder_statement))
			print("error deleting folders from db\n");
	}

	public void del_all_files() {
		if(!exec_prepared_stmt(delete_media_files_statement))
			print("error deleting files from db\n");
	}

	public void del_all_streams() {
		if(!exec_prepared_stmt(del_streams_statement))
			print("error deleting streams from db\n");
	}

	public bool delete_local_media_data() {
		if(!exec_prepared_stmt(this.delete_artists_statement)) return false;
		if(!exec_prepared_stmt(this.delete_albums_statement )) return false;
		if(!exec_prepared_stmt(this.delete_items_statement  )) return false;
		if(!exec_prepared_stmt(this.delete_uris_statement   )) return false;
//		if(!exec_prepared_stmt(this.delete_genres_statement )) return false;
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

