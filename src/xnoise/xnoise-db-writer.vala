/* xnoise-db-writer.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
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
	private bool begin_stmt_used;

	// DBWRITER STATEMENTS
	private static const string STMT_BEGIN =
		"BEGIN";
	private static const string STMT_COMMIT =
		"COMMIT";
	private static const string STMT_UPDATE_ALBUM_IMAGE =
		"UPDATE albums SET image = ? WHERE id = (SELECT al.id FROM albums al, artists ar WHERE al.artist = ar.id AND ar.name = ? AND al.name = ?)";
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
	private static const string STMT_INSERT_TITLE =
		"INSERT INTO items (tracknumber, artist, album, title, genre, year, uri, mediatype, length, bitrate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
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

	public DbWriter() {
		this.db = get_db();
		if(this.db == null)
			return;
		
		this.begin_stmt_used = false;
		this.prepare_statements();
	}

	private static Database? get_db () {
		// there was more luck on creating the db on first start, if using a static function
		Database database;
		File home_dir = File.new_for_path(Environment.get_home_dir());
		File xnoise_home = home_dir.get_child(SETTINGS_FOLDER);
		File xnoisedb = xnoise_home.get_child(DATABASE_NAME);
		if (!xnoise_home.query_exists(null)) {
			print("Cannot find settings folder!\n");
			return null;
		}
		Database.open_v2(xnoisedb.get_path(),
		                 out database,
		                 Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE,
		                 null) ;
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

	private int handle_artist(ref string artist) {
		int artist_id = -1;

		get_artist_id_statement.reset();
		if(get_artist_id_statement.bind_text(1, artist.down()) != Sqlite.OK) {
			this.db_error();
			return -1;
		}
		if(get_artist_id_statement.step() == Sqlite.ROW)
			artist_id = get_artist_id_statement.column_int(0);

		if(artist_id == -1) { // Artist not in table, yet
			// Insert artist
			insert_artist_statement.reset();
			if(insert_artist_statement.bind_text(1, artist) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(insert_artist_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique artist id key
			get_artist_id_statement.reset();
			if(get_artist_id_statement.bind_text(1, artist.down()) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(get_artist_id_statement.step() == Sqlite.ROW)
				artist_id = get_artist_id_statement.column_int(0);
		}
		return artist_id;
	}

	private int handle_album(ref int artist_id, ref string album) {
		int album_id = -1;

		get_album_id_statement.reset();
		if(get_album_id_statement.bind_int (1, artist_id)    != Sqlite.OK ||
		   get_album_id_statement.bind_text(2, album.down()) != Sqlite.OK ) {
			this.db_error();
			return -1;
		   }
		if(get_album_id_statement.step() == Sqlite.ROW)
			album_id = get_album_id_statement.column_int(0);

		if(album_id == -1) { // album not in table, yet
			// Insert album
			insert_album_statement.reset();
			if(insert_album_statement.bind_int (1, artist_id) != Sqlite.OK ||
			   insert_album_statement.bind_text(2, album)     != Sqlite.OK ) {
				this.db_error();
				return -1;
			}
			if(insert_album_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique album id key
			get_album_id_statement.reset();
			if(get_album_id_statement.bind_int (1, artist_id)    != Sqlite.OK ||
			   get_album_id_statement.bind_text(2, album.down()) != Sqlite.OK ) {
				this.db_error();
				return -1;
			}
			if(get_album_id_statement.step() == Sqlite.ROW)
				album_id = get_album_id_statement.column_int(0);
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

	private int handle_genre(ref string genre) {
		int genre_id = -1;
		if((genre.strip() == "")||(genre == null)) return -2; //NO GENRE

		get_genre_id_statement.reset();
		if(get_genre_id_statement.bind_text(1, genre.down()) != Sqlite.OK) {
			this.db_error();
			return -1;
		}
		if(get_genre_id_statement.step() == Sqlite.ROW)
			genre_id = get_genre_id_statement.column_int(0);

		if(genre_id == -1) { // genre not in table, yet
			// Insert genre
			insert_genre_statement.reset();
			if(insert_genre_statement.bind_text(1, genre) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(insert_genre_statement.step() != Sqlite.DONE) {
				this.db_error();
				return -1;
			}
			// Get unique genre id key
			get_genre_id_statement.reset();
			if(get_genre_id_statement.bind_text(1, genre.down()) != Sqlite.OK) {
				this.db_error();
				return -1;
			}
			if(get_genre_id_statement.step() == Sqlite.ROW)
				genre_id = get_genre_id_statement.column_int(0);
		}
		return genre_id;
	}

	public void insert_title(TrackData td, string uri) {
		// make entries in other tables and get references from there
		int artist_id = handle_artist(ref td.Artist);
		if(artist_id == -1) {
			print("Error importing artist!\n");
			return;
		}
		int album_id = handle_album(ref artist_id, ref td.Album);
		if(album_id == -1) {
			print("Error importing album!\n");
			return;
		}
		int uri_id = handle_uri(uri);
		if(uri_id == -1) {
			print("Error importing uri!\n");
			return;
		}
		int genre_id = handle_genre(ref td.Genre);
		if(genre_id == -1) {
			print("Error importing genre!\n");
			return;
		}
		insert_title_statement.reset();
		if( insert_title_statement.bind_int (1,  (int)td.Tracknumber) != Sqlite.OK ||
			insert_title_statement.bind_int (2,  artist_id)           != Sqlite.OK ||
			insert_title_statement.bind_int (3,  album_id)            != Sqlite.OK ||
			insert_title_statement.bind_text(4,  td.Title)            != Sqlite.OK ||
			insert_title_statement.bind_int (5,  genre_id)            != Sqlite.OK ||
			insert_title_statement.bind_int (6,  (int)td.Year)        != Sqlite.OK ||
			insert_title_statement.bind_int (7,  uri_id)              != Sqlite.OK ||
			insert_title_statement.bind_int (8,  td.Mediatype)        != Sqlite.OK ||
			insert_title_statement.bind_int (9,  td.Length)           != Sqlite.OK ||
			insert_title_statement.bind_int (10, td.Bitrate)          != Sqlite.OK) {
			this.db_error();
		}
		if(insert_title_statement.step()!=Sqlite.DONE)
			this.db_error();
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

	// Single file for media items
	public void add_single_file(string uri) {
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		FileInfo info = null;
		File file = File.new_for_uri(uri);
		try {
			info = file.query_info(attr, FileQueryInfoFlags.NONE, null);
		}
		catch(Error e) {
			print("single file import: %s\n", e.message);
			return;
		}

		string content = info.get_content_type();
		unowned string mime = g_content_type_get_mime_type(content);
		PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
		PatternSpec psVideo = new PatternSpec("video*");

		if(psAudio.match_string(mime)) {
			int idbuffer = uri_entry_exists(file.get_uri());
			if(idbuffer== -1) {
				var tr = new TagReader();
				this.insert_title(tr.read_tag(file.get_path()), file.get_uri());
			}
		}
		else if(psVideo.match_string(mime)) {
			int idbuffer = uri_entry_exists(file.get_uri());
			var td = new TrackData();
			td.Artist = "unknown artist";
			td.Album = "unknown album";
			if(file!=null) td.Title = file.get_basename();
			td.Genre = "";
			td.Tracknumber = 0;
			td.Mediatype = MediaType.VIDEO;

			if(idbuffer== -1) {
				this.insert_title(td, file.get_uri());
			}
		}
	}

	public void add_single_mediafolder_to_collection(string mfolder) {
		this.write_media_folder_statement.reset();
		this.write_media_folder_statement.bind_text(1, mfolder);
		if(write_media_folder_statement.step() != Sqlite.DONE) {
			this.db_error();
		}
	}

	public void write_final_tracks_to_db(string[] final_tracklist) {
		string current_query = "";
		int rc1, nrow, ncolumn;
		unowned string[] resultArray;
		string errmsg;
		if(db == null) return;

		this.begin_transaction();
		current_query = "DELETE FROM lastused;";
		rc1 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
		if (rc1 != Sqlite.OK) {
			stderr.printf("SQL error, while removing old music folders: %s\n", errmsg);
			return;
		}
		foreach(string uri in final_tracklist) {
			this.insert_lastused_track(uri, 0);
		}
		this.commit_transaction();
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

	public void del_media_folders() {
		exec_prepared_stmt(del_media_folder_statement);
	}

	public void del_media_files() {
		exec_prepared_stmt(delete_media_files_statement);
	}

	public void del_streams() {
		exec_prepared_stmt(del_streams_statement);
	}

	public bool delete_local_media_data() {
		if(!exec_prepared_stmt(this.delete_artists_statement)) return false;
		if(!exec_prepared_stmt(this.delete_albums_statement )) return false;
		if(!exec_prepared_stmt(this.delete_items_statement  )) return false;
		if(!exec_prepared_stmt(this.delete_uris_statement   )) return false;
		if(!exec_prepared_stmt(this.delete_genres_statement )) return false;
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

