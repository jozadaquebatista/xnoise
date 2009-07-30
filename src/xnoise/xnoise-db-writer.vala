/* xnoise-db-writer.vala
 *
 * Copyright (C) 2009  Jörn Magens
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
	private const string INIFOLDER = ".xnoise";
	private Sqlite.Database db;
	
	private Statement delete_mlib_entry_statement;
	private Statement update_mlib_entry_statement;
	private Statement insert_mlib_entry_statement;
	private Statement insert_lastused_entry_statement;
	private Statement check_track_exists_statement;
	private Statement begin_statement;
	private Statement commit_statement;
	private Statement get_music_folders_statement;
	private Statement write_music_folder_statement;
	private Statement del_music_folder_statement;
	private Statement del_mlib_statement;


	//CREATE TABLE STATEMENTS
	private static const string STMT_CREATE_MLIB = 
		"CREATE TABLE mlib(id integer primary key, tracknumber integer, artist text, album text, title text, genre text, uri text, mediatype integer);";
	private static const string STMT_CREATE_LASTUSED = 
		"CREATE TABLE lastused(uri text, mediatype integer);"; //for now 0=audio,1=video
	private static const string STMT_CREATE_MUSICFOLDERS = 
		"CREATE TABLE music_folders(name text primary key);";

	//FIND TABLE	
	private static const string STMT_FIND_TABLE = 
		"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
	
	//ALL OTHER DBWRITER STATEMENTS
	private static const string STMT_BEGIN = 
		"BEGIN";
	private static const string STMT_COMMIT = 
		"COMMIT";
	private static const string STMT_CHECK_TRACK_EXISTS = 
		"SELECT id FROM mlib WHERE uri = ?"; 
	private static const string STMT_GET_MUSIC_FOLDERS = 
		"SELECT * FROM music_folders";
	private static const string STMT_UPDATE_ENTRY = 
		"INSERT INTO mlib (id, tracknumber, artist, album, title, genre, uri, mediatype) VALUES (\"null\", ?, ?, ?, ?, ?, ?, ?)";
	private static const string STMT_INSERT_ENTRY = 
		"INSERT INTO mlib (tracknumber, artist, album, title, genre, uri, mediatype) VALUES (?, ?, ?, ?, ?, ?, ?)";
	private static const string STMT_INSERT_LASTUSED = 
		"INSERT INTO lastused (uri, mediatype) VALUES (?,?)";
	private static const string STMT_WRITE_MUSIC_FOLDERS = 
		"INSERT INTO music_folders (name) VALUES (?)";
	private static const string STMT_DEL_MUSIC_FOLDERS = 
		"DELETE FROM music_folders";
	private static const string STMT_DEL_MLIB = 
		"DELETE FROM mlib;";
	private static const string STMT_DELETE_MLIB_ENTRY = 
		"DELETE FROM mlib WHERE id = ?";

	public DbWriter() {
        this.db = get_db();
		this.prepare_statements();
	}

//	~DbWriter() {
//		print("destruct dbWriter class\n");
//	}

	private static Database? get_db () {
		// there was more luck on creating the db on first start, if using a static function
		Database database;
		File home_dir = File.new_for_path(Environment.get_home_dir());
		File xnoise_home = home_dir.get_child(INIFOLDER);
		File xnoisedb = xnoise_home.get_child(DATABASE_NAME);
		if (!xnoise_home.query_exists(null)) {
			try {
				File current_dir = xnoise_home;
				File[] directory_list = {};
				while(current_dir != null) {
				    if (current_dir.query_exists (null)) break;
					directory_list += current_dir;
				    current_dir = current_dir.get_parent();
				}
				foreach(File dir in directory_list) {
				    print("Creating config path %s\n", dir.get_path());
				    dir.make_directory(null);
				}
			} 
			catch (Error e) {
				stderr.printf("Error with create directory: %s", e.message);
				return null;
			}
		}
		Database.open_v2(xnoisedb.get_path(), 
		                 out database, 
		                 Sqlite.OPEN_CREATE|Sqlite.OPEN_READWRITE, 
		                 null) ;
		if(xnoisedb.query_exists(null) && database!=null) {
			bool db_table_exists = false;
			int nrow,ncolumn;
			weak string[] resultArray;
			string errmsg;

			//Check for Table existance
			if(database.get_table(STMT_FIND_TABLE, out resultArray, out nrow, out ncolumn, out errmsg) != Sqlite.OK) { 
				stderr.printf("SQL error: %s\n", errmsg);
				return null;
			}

			//search main table
			for (int offset = 1; offset < nrow + 1 && db_table_exists == false;offset++) {
				for (int j = offset*ncolumn; j< (offset+1)*ncolumn;j++) {
					if (resultArray[j]=="mlib") {
						db_table_exists = true; //assume that if mlib is existing all other tables also exist
					}
				}
			}

			//create Tables if not existant
			if(db_table_exists == false) {
				string errormsg;

				if(database.exec(STMT_CREATE_MLIB, null, out errormsg)!= Sqlite.OK) {
					stderr.printf("Create DB: %s", errormsg);
					return null;
				}

				if(database.exec(STMT_CREATE_LASTUSED, null, out errormsg)!= Sqlite.OK) {
					stderr.printf("Create DB: %s", errormsg);
					return null;
				}

				if(database.exec(STMT_CREATE_MUSICFOLDERS, null, out errormsg)!= Sqlite.OK) {
					stderr.printf("Create DB: %s", errormsg);
					return null;
				}
			}
		}
		return database;
	}

	private void db_error() {
		stderr.printf("Database error %d: %s \n\n", this.db.errcode(), this.db.errmsg());
	}

	private void prepare_statements() { 
	    this.db.prepare_v2(STMT_DELETE_MLIB_ENTRY, -1, 
	    	out this.delete_mlib_entry_statement);
	    this.db.prepare_v2(STMT_UPDATE_ENTRY, -1, 
	    	out this.update_mlib_entry_statement); 
	    this.db.prepare_v2(STMT_CHECK_TRACK_EXISTS, -1, 
	    	out this.check_track_exists_statement); 
	    this.db.prepare_v2(STMT_INSERT_ENTRY, -1, 
	    	out this.insert_mlib_entry_statement); 
	    this.db.prepare_v2(STMT_INSERT_LASTUSED, -1, 
	    	out this.insert_lastused_entry_statement); 
	    this.db.prepare_v2(STMT_BEGIN, -1, 
	    	out this.begin_statement); 
	    this.db.prepare_v2(STMT_COMMIT, -1, 
	    	out this.commit_statement); 
	    this.db.prepare_v2(STMT_GET_MUSIC_FOLDERS, -1, 
	    	out this.get_music_folders_statement); 
	    this.db.prepare_v2(STMT_WRITE_MUSIC_FOLDERS, -1, 
	    	out this.write_music_folder_statement); 
	    this.db.prepare_v2(STMT_DEL_MUSIC_FOLDERS, -1, 
	    	out this.del_music_folder_statement); 
	    this.db.prepare_v2(STMT_DEL_MLIB, -1, 
	    	out this.del_mlib_statement); 
	}

	private void db_update_entry(int id, TrackData td, string uri) {
		string artist    = td.Artist;
		string title     = td.Title;
		string album     = td.Album;
		string genre     = td.Genre;
		uint tracknumber = td.Tracknumber;
		int mediatype    = (int)td.Mediatype;

		if(id>0){
			delete_mlib_entry_statement.reset();
			delete_mlib_entry_statement.bind_int(1, id);
			delete_mlib_entry_statement.step();
			
			update_mlib_entry_statement.reset();
			update_mlib_entry_statement.bind_int( 1, id);
			update_mlib_entry_statement.bind_int( 2, (int)tracknumber);
			update_mlib_entry_statement.bind_text(3, artist);
			update_mlib_entry_statement.bind_text(4, album);
			update_mlib_entry_statement.bind_text(5, title);
			update_mlib_entry_statement.bind_text(6, genre);
			update_mlib_entry_statement.bind_text(7, uri);
			update_mlib_entry_statement.bind_int (8, mediatype);
			update_mlib_entry_statement.step();
		}
	}

	private void db_insert_entry(TrackData td, string uri) {
		string artist    = td.Artist;
		string title     = td.Title;
		string album     = td.Album;
		string genre     = td.Genre;
		uint tracknumber = td.Tracknumber; 
		int mediatype    = (int)td.Mediatype;
		
		insert_mlib_entry_statement.reset();
		if( insert_mlib_entry_statement.bind_int( 1, (int)tracknumber) !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(2, artist)   !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(3, album)    !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(4, title)    !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(5, genre)    !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(6, uri)      !=Sqlite.OK||
			insert_mlib_entry_statement.bind_int (7, mediatype)!=Sqlite.OK) {
			this.db_error();
		}
		if(insert_mlib_entry_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}

	private int db_entry_exists(string uri) {
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

	private uint current = 0; 
//	private uint amount = 0;
	public signal void sign_import_progress(uint current, uint amount);

	private void import_tags_for_files(File dir) {
		FileEnumerator enumerator;
		try {
			string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
			              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
			              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
		} catch (Error error) {
			critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
			return;
		}
		FileInfo info;
		while((info = enumerator.next_file(null))!=null) {
			string filename = info.get_name();
			string filepath = Path.build_filename(dir.get_path(), filename);
			File file = File.new_for_path(filepath);
			FileType filetype = info.get_file_type();

			string content = info.get_content_type();
			weak string mime = g_content_type_get_mime_type(content);
			PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u seperately
			PatternSpec psVideo = new PatternSpec("video*");

			if(filetype == FileType.DIRECTORY) {
				this.import_tags_for_files(file);
			} 
			else if(psAudio.match_string(mime)) {
//				if(mime=="audio/x-mpegurl") print("file %s\n",file.get_path()); 
				int idbuffer = db_entry_exists(file.get_uri());
				if(idbuffer== -1) {
					var tr = new TagReader();
					this.db_insert_entry(tr.read_tag_from_file(filepath), file.get_uri());
					current+=1;
				}
				else {
					var tr = new TagReader();
					this.db_update_entry(idbuffer, tr.read_tag_from_file(filepath), file.get_uri());
					current+=1;
				}
//				sign_import_progress(current, amount);   //TODO: Maybe use this to track import progress        
			}
			else if(psVideo.match_string(mime)) {
				int idbuffer = db_entry_exists(file.get_uri());
				TrackData td = TrackData();
				td.Artist = "unknown artist";
				td.Album = "unknown album";
				td.Title = file.get_basename();
				td.Genre = "";
				td.Tracknumber = 0;
				td.Mediatype = MediaType.VIDEO;
				
				if(idbuffer== -1) {
					this.db_insert_entry(td, file.get_uri());
					current+=1;
				}
				else {
					this.db_update_entry(idbuffer, td, file.get_uri());
					current+=1;
				}				
			}
		}
	}

	public string[] get_music_folders() { 
		string[] mfolders = {};
		get_music_folders_statement.reset();
		while(get_music_folders_statement.step() == Sqlite.ROW) {
			mfolders += get_music_folders_statement.column_text(0);
		}
		return mfolders;
	}

	private void del_music_folders() {
		this.del_music_folder_statement.reset();
		if(del_music_folder_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}
	

	public void write_music_folder_into_db(string[] mfolders){
		this.del_music_folders();
		foreach(string folder in mfolders) {
			this.write_single_mfolder_to_db(folder);
		}
		if(delete_mlib_data()==0) return;
		
		//TODO: Remove duplicates
		
		this.begin_transaction();	
			
		foreach(string folder in mfolders) {
			File dir = File.new_for_path(folder);
			assert(dir!=null);
			this.import_tags_for_files(dir);
		}
		
		this.commit_transaction();
	}

	public void begin_transaction() {
		this.begin_statement.reset();
		if(begin_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}
	
	public void commit_transaction() {
		this.commit_statement.reset();
		if(commit_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}
	
	public void write_final_tracks_to_db(string[] final_tracklist) {
		string current_query = "";
		int rc1, nrow, ncolumn;
		weak string[] resultArray;
		string errmsg;

		this.begin_transaction();
		current_query = "DELETE FROM lastused;";
		rc1 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
		if (rc1 != Sqlite.OK) { 
			stderr.printf("SQL error, while removing old music folders: %s\n", errmsg);//TODO
			return;
		}	
		foreach(string uri in final_tracklist) {
			this.insert_lastused_track(uri, 0); //TODO: handle media type !=0 (video)
		}
		this.commit_transaction();
	}
	
	private void insert_lastused_track(string uri, int mediatype) { 
		this.insert_lastused_entry_statement.reset();
		this.insert_lastused_entry_statement.bind_text(1, uri);
		this.insert_lastused_entry_statement.bind_int (2, mediatype);
		if(insert_lastused_entry_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}

	private int delete_mlib_data() {
		this.del_mlib_statement.reset();
		if(del_mlib_statement.step()!=Sqlite.DONE) {
			this.db_error();
			return 0;
		}
		return 1;
	}

	private void write_single_mfolder_to_db(string mfolder) {
		this.write_music_folder_statement.reset();
		this.write_music_folder_statement.bind_text(1, mfolder);
		if(write_music_folder_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}
}

