/* xnoise-db-browser.vala
 *
 * Copyright (C) 2009  Jörn Magens
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

public class Xnoise.DbBrowser : GLib.Object {
	private string DATABASE;
	private Statement count_for_path_statement;
	private Statement get_artist_statement;
	private Statement get_albums_statement;
	private Statement get_titles_statement;
	private Statement uri_for_track_statement;
	private Statement track_id_for_path_statement;
	private Statement trackdata_for_path_statement;
	
	private static const string STMT_COUNT_FOR_PATH = 
		"SELECT COUNT (*) FROM mlib WHERE path = ?";
    private static const string STMT_TABLES_EXIST = 
		"SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'mlib';";
    private static const string STMT_TRACKDATA_FOR_PATH = 
    	"SELECT artist, album, title FROM mlib WHERE path = ?";
    private static const string STMT_TRACK_ID_FOR_PATH = 
    	"SELECT id FROM mlib WHERE path = ?";
    private static const string STMT_URI_FOR_TRACK = 
    	"SELECT path FROM mlib WHERE artist = ? AND album = ? AND title = ?";
    private static const string STMT_GET_ARTISTS = 
    	"SELECT DISTINCT artist FROM mlib ORDER BY artist DESC";
    private static const string STMT_GET_ALBUMS = 
    	"SELECT DISTINCT album FROM mlib WHERE artist = ? ORDER BY album DESC";
    private static const string STMT_GET_TITLES = 
    	"SELECT DISTINCT title FROM mlib WHERE artist = ? AND album = ?"; 

	public DbBrowser() {
		DATABASE = dbFileName();
		if(Database.open(DATABASE, out db)!=Sqlite.OK) { 
			stderr.printf("Can't open database: %s\n", (string)this.db.errmsg);
		}
		this.prepare_statements();
	}

//	~DbBrowser() {
//		print("destruct dbbrowser\n");
//	}

	private Database db;

	private string dbFileName() {
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".xnoise", "db.sqlite", null);
	}

	private void db_error() {
		critical("Database error: %s", this.db.errmsg ());
	}

	private void prepare_statements() { 
	    this.db.prepare_v2(STMT_COUNT_FOR_PATH, -1, 
	    	out this.count_for_path_statement); 
	    this.db.prepare_v2(STMT_GET_ARTISTS, -1, 
	    	out this.get_artist_statement); 
	    this.db.prepare_v2(STMT_GET_ALBUMS, -1, 
	    	out this.get_albums_statement); 
	    this.db.prepare_v2(STMT_GET_TITLES, -1, 
	    	out this.get_titles_statement); 
	    this.db.prepare_v2(STMT_TRACKDATA_FOR_PATH , -1, 
	    	out this.trackdata_for_path_statement); 
	    this.db.prepare_v2(STMT_TRACK_ID_FOR_PATH, -1, 
	    	out this.track_id_for_path_statement); 
	    this.db.prepare_v2(STMT_URI_FOR_TRACK, -1, 
			out this.uri_for_track_statement);
	}
	
	public bool path_is_in_db(string path) {
		int count = 0;
		count_for_path_statement.reset();
		
		if(count_for_path_statement.bind_text(1, path)!=Sqlite.OK) {
			this.db_error();
		}
		while(count_for_path_statement.step() == Sqlite.ROW) {
	        count = count_for_path_statement.column_int(0);
		}
		if(count>0) return true;
		return false;
	}
	
	public string[3] get_trackdata_for_path(string path) {
		string[] val = new string[3];
		trackdata_for_path_statement.reset();
		trackdata_for_path_statement.bind_text(1, path);
		while(trackdata_for_path_statement.step() == Sqlite.ROW) {
	        val[0] = Markup.printf_escaped("%s", trackdata_for_path_statement.column_text(0));
	        val[1] = Markup.printf_escaped("%s", trackdata_for_path_statement.column_text(1));
	        val[2] = Markup.printf_escaped("%s", trackdata_for_path_statement.column_text(2));
		}
		if(val[0]=="") val[0] = "unknown artist";
		if(val[1]=="") val[1] = "unknown album";
		if(val[2]=="") val[2] = "unknown title";
		return val;
	}
	
	public int get_track_id_for_path(string path) {
		int val = -1;
		track_id_for_path_statement.reset();
		track_id_for_path_statement.bind_text(1, path);
		while(track_id_for_path_statement.step() == Sqlite.ROW) {
	        val = track_id_for_path_statement.column_int(0);
		}
		return val;
	}
		
	public string get_uri_for_title(string artist,string album, string title) {
		string val = "";
		uri_for_track_statement.reset();
		if((this.uri_for_track_statement.bind_text(1, artist)!=Sqlite.OK)|
			(uri_for_track_statement.bind_text(2, album)!=Sqlite.OK)|
			(uri_for_track_statement.bind_text(3, title))) {
			this.db_error();
		}
		while(uri_for_track_statement.step() == Sqlite.ROW) {
	        val = uri_for_track_statement.column_text(0);
		}
		string buffer = "";
		if(val!="") buffer = GLib.Filename.to_uri(val);
		return buffer;
	}

	public string[] get_artists() { 
		string[] val = new string[0];
		get_artist_statement.reset();
		while(get_artist_statement.step() == Sqlite.ROW) {
	        val += get_artist_statement.column_text(0);
		}
		return val;
	}

	public string[] get_albums(string artist) { 
		string[] val = new string[0];
		get_albums_statement.reset();
		if(this.get_albums_statement.bind_text(1, artist)!=Sqlite.OK) {
			this.db_error();
		}
		while(get_albums_statement.step() == Sqlite.ROW) {
	        val += get_albums_statement.column_text(0);
		}
		return val;
	}

	public string[] get_titles(string artist, string album) { 
		string[] val = new string[0];
		get_titles_statement.reset();
		if((this.get_titles_statement.bind_text(1, artist)!=Sqlite.OK)|
			(get_titles_statement.bind_text(2, album)!=Sqlite.OK)) {
			this.db_error();
		}
		
		while(get_titles_statement.step() == Sqlite.ROW) {
	        val += get_titles_statement.column_text(0);
		}
		return val;
	}
}

