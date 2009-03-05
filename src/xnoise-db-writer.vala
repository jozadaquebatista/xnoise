/* xnoise-db-writer.vala
 *
 * Copyright (C) 2009  ert
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Jörn Magens
 */

using GLib;
using Sqlite;

public class Xnoise.DbWriter : GLib.Object {
	private string DATABASE;
	
	private Statement delete_mlib_entry_statement;
	private Statement update_mlib_entry_statement;
	private Statement insert_mlib_entry_statement;
	private Statement check_track_exists_statement;
	private Statement begin_statement;
	private Statement commit_statement;
	private Statement get_music_folders_statement;
	private Statement write_music_folder_statement;
	private Statement del_music_folder_statement;
	private Statement del_mlib_statement;
	
	private static const string STMT_DELETE_MLIB_ENTRY = 
		"DELETE FROM mlib WHERE id = ?";
	private static const string STMT_UPDATE_ENTRY = 
		"INSERT INTO mlib (id, artist, album, title, genre, path) VALUES (\"null\", ?, ?, ?, ?, ?)";
	private static const string STMT_INSERT_ENTRY = 
		"INSERT INTO mlib (artist, album, title, genre, path) VALUES (?, ?, ?, ?, ?)";
	private static const string STMT_CHECK_TRACK_EXISTS = 
		"SELECT id FROM mlib WHERE path = ?"; 
	private static const string STMT_BEGIN = 
		"BEGIN";
	private static const string STMT_COMMIT = 
		"COMMIT";
	private static const string STMT_GET_MUSIC_FOLDERS = 
		"SELECT * FROM music_folders";
	private static const string STMT_WRITE_MUSIC_FOLDERS = 
		"INSERT INTO music_folders (name) VALUES (?)";
	private static const string STMT_DEL_MUSIC_FOLDERS = 
		"DELETE FROM music_folders";
	private static const string STMT_DEL_MLIB = 
		"DELETE FROM mlib;";

	public DbWriter() {
		DATABASE = dbFileName();
//		make_pattern_spec();
		if(Database.open(DATABASE, out db)!=Sqlite.OK) { 
			stderr.printf("Can't open database: %s\n", (string)db.errmsg);
		}
		//TODO: check for db existance
		this.prepare_statements();
	}

//	~DbWriter() {
//		print("destruct dbWriter class\n");
//	}

	private Sqlite.Database db;

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

	private string dbFileName() {
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise", "db.sqlite", null);
	}
		
	private void db_update_entry(int id, string[4] tags, string pathname, string file) {
		string artist = tags[0];
		string title  = tags[1];
		string album  = tags[2];
		string genre  = tags[3];
		string path   = Path.build_filename(pathname, file);//= get_path(pathname, file); 
		
		if(id>0){
			delete_mlib_entry_statement.reset();
			delete_mlib_entry_statement.bind_int(1, id);
			delete_mlib_entry_statement.step();
			
			update_mlib_entry_statement.reset();
			update_mlib_entry_statement.bind_int(1, id);
			update_mlib_entry_statement.bind_text(2, artist);
			update_mlib_entry_statement.bind_text(3, album);
			update_mlib_entry_statement.bind_text(4, title);
			update_mlib_entry_statement.bind_text(5, genre);
			update_mlib_entry_statement.bind_text(6, path);
			update_mlib_entry_statement.step();
		}
	}

	private void db_insert_entry(string[4] tags, string pathname, string file) {
		if (tags[0]=="") return;
		if (tags[1]=="") return;
		if (tags[2]=="") return;
		if (tags[3]=="") return;
		string artist = tags[0]; 
		string title  = tags[1]; 
		string album  = tags[2]; 
		string genre  = tags[3]; 
		string path   = Path.build_filename(pathname, file);
		insert_mlib_entry_statement.reset();
		if( insert_mlib_entry_statement.bind_text(1, artist)!=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(2, album) !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(3, title) !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(4, genre) !=Sqlite.OK||
			insert_mlib_entry_statement.bind_text(5, path)  !=Sqlite.OK) {
			this.db_error();
		}
		if(insert_mlib_entry_statement.step()!=Sqlite.DONE) {
			this.db_error();
		}
	}

	private int db_entry_exists(string pathname, string file) {
		int val = -1;
		string pathOfFile = Path.build_filename(pathname, file);
		check_track_exists_statement.reset();
		if(check_track_exists_statement.bind_text(1, pathOfFile)!=Sqlite.OK) {
			this.db_error();
		}
		while(check_track_exists_statement.step() == Sqlite.ROW) {
	        val = check_track_exists_statement.column_int(0);
		}
		return val;
	}

	private uint current = 0; 
//	private uint amount = 0;
	public signal void sign_import_progress(uint current, uint amount);

//	private void count_songs_from_path(File dir) {
//	        FileEnumerator enumerator;
//        try {
//            string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
//                                FILE_ATTRIBUTE_STANDARD_TYPE + "," +
//                                FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
//            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
//        } catch (Error error) {
//            critical("Error accessing directory %s.\n%s\n", dir.get_path (), error.message);
//            return;
//        }
//        FileInfo info;
//        while((info = enumerator.next_file(null))!=null) {
//            string filename = info.get_name();
//            string filepath = Path.build_filename(dir.get_path(), filename);
//            File file = File.new_for_path (filepath);
//            FileType filetype = info.get_file_type ();

//			//get mime information
//			string content_type = info.get_content_type ();
//			weak string mime = g_content_type_get_mime_type(content_type);

//			if(filetype == FileType.DIRECTORY) {
//				this.import_tags_for_files(file);
//			} 
//			else if ((mime == "audio/x-vorbis+ogg")|
//			         (mime == "audio/mpeg")|
//			         (mime == "audio/x-wav")|
//			         (mime == "audio/x-flac")|
//			         (mime == "audio/x-speex")) {
//				amount+=1;
//			}
//        }
//	}

    private void import_tags_for_files(File dir) {
        FileEnumerator enumerator;
        try {
            string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                                FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                                FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
            enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
        } catch (Error error) {
            critical("Error accessing directory %s.\n%s\n", dir.get_path (), error.message);
            return;
        }
        FileInfo info;
        while((info = enumerator.next_file(null))!=null) {
            string filename = info.get_name();
            string filepath = Path.build_filename(dir.get_path(), filename);
            File file = File.new_for_path (filepath);
            FileType filetype = info.get_file_type ();

			//get mime information
			string content_type = info.get_content_type ();
			weak string mime = g_content_type_get_mime_type(content_type);

			if(filetype == FileType.DIRECTORY) {
				this.import_tags_for_files(file);
			} 
			else if ((mime == "audio/x-vorbis+ogg")|
			         (mime == "audio/mpeg")|
			         (mime == "audio/x-wav")|
			         (mime == "audio/x-flac")|
			         (mime == "audio/x-speex")) {
				
				int idbuffer = db_entry_exists(dir.get_path(), info.get_name());
				if(idbuffer== -1) {
					var tr = new TagReader();
					db_insert_entry(tr.read_tag_from_file(filepath), dir.get_path(), info.get_name());
					current+=1;
				}
				else {
					var tr = new TagReader();
					db_update_entry(idbuffer, tr.read_tag_from_file(filepath), dir.get_path(), info.get_name());
					current+=1;
				}
//				sign_import_progress(current, amount);   //TODO: Maybe use this to track import progress        
			}
        }
    }
    
	public void check_db_and_tables_exist() {
		bool db_table_exists = false;
		string current_query = "";
		int nrow,ncolumn;
		int rc1 = 0;
		int rc2 = 0;
		int rc3 = 0;
		weak string[] resultArray;
		string errmsg;

		//Check for Table existance
		current_query = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
		rc1 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
		if (rc1 != Sqlite.OK) { 
			stderr.printf("SQL error: %s\n", errmsg);
			return;
		}

		//search main table
		for (int offset = 1; offset < nrow + 1 && db_table_exists == false;offset++) {
			for (int j = offset*ncolumn; j< (offset+1)*ncolumn;j++) {
				if (resultArray[j]=="mlib") {
					db_table_exists = true;
				}
			}
		}

		//create Tables if not existant
		if(db_table_exists == false) {
			current_query = "CREATE TABLE mlib(id integer primary key, artist text, album text, title text, genre text, path text);";
			rc1 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
			current_query = "CREATE TABLE lastused(id integer);";
			rc2 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
			current_query = "CREATE TABLE music_folders(name text primary key);";
			rc3 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
		}
		if ((rc1 != Sqlite.OK)|(rc2 != Sqlite.OK)|(rc3 != Sqlite.OK)) { 
			stderr.printf("SQL error (table exist): %s\n", errmsg);
			return;
		}
	}

	public string[] get_music_folders() { //ref GLib.List<string> mfolders
		string[] mfolders = new string[0];
		get_music_folders_statement.reset();
		while(get_music_folders_statement.step() == Sqlite.ROW) {
			mfolders += get_music_folders_statement.column_text(0);
//			mfolders.append(get_music_folders_statement.column_text(0));
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
		
//		uint count = 0;
//		foreach(string folder in mfolders) { //TODO check this
//			foreach(string temp_folder in mfolders) {
//				if (folder == temp_folder) { 
//					count++;
//					if (count > 1) mfolders.remove(temp_folder);
//				}
//			}
//		}
	
//		foreach(string folder in mfolders) {
//			File dir = File.new_for_path(folder);
////			assert(dir!=null && is_dir(dir));
//			count_songs_from_path(dir);
//		}
		
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
	
	public void write_final_track_ids_to_db(ref GLib.List<string> final_tracklist) {
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
//		print("lala null item: %s\n", final_tracklist[1]);
//		for(int i=0;i<=(int)(final_tracklist.length)-1;i++) {
		foreach(string id in final_tracklist) {
//			this.insert_lastused_id(id);
		}
		this.commit_transaction();
	}
	
//	private void insert_lastused_id(string id) { //TODO: This table is shit
//		string current_query = "";
//		int rc1,nrow,ncolumn;
//		weak string[] resultArray;
//		string errmsg;
//		current_query = "INSERT INTO lastused (id) VALUES (\""+ id + "\");";
//		rc1 = db.get_table(current_query, out resultArray, out nrow, out ncolumn, out errmsg);
//		if (rc1 != Sqlite.OK) { 
//			print("not ok\n");
//			stderr.printf("SQL error, while adding new music folder content: %s\n", errmsg);
//			return;
//		}	
//	}

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

