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
	private Statement count_for_uri_statement;
	private Statement get_artist_statement;
	private Statement get_albums_statement;
	private Statement get_titles_statement;
	private Statement uri_for_track_statement;
	private Statement track_id_for_uri_statement;
	private Statement trackdata_for_uri_statement;
	private Statement tracknumber_for_track_statement;
	
	private static const string STMT_COUNT_FOR_URI = 
		"SELECT COUNT (*) FROM mlib WHERE uri = ?";
	private static const string STMT_TABLES_EXIST = 
		"SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'mlib';";
	private static const string STMT_TRACKDATA_FOR_URI = 
		"SELECT artist, album, title, tracknumber FROM mlib WHERE uri = ?";
	private static const string STMT_TRACK_ID_FOR_URI = 
		"SELECT id FROM mlib WHERE uri = ?";
	private static const string STMT_URI_FOR_TRACK = 
		"SELECT uri FROM mlib WHERE artist = ? AND album = ? AND title = ?";
	private static const string STMT_TRACKNUMBER_FOR_TRACK = 
		"SELECT tracknumber FROM mlib WHERE artist = ? AND album = ? AND title = ?";
	private static const string STMT_GET_ARTISTS = 
		"SELECT DISTINCT artist FROM mlib WHERE LOWER(artist) LIKE ? OR LOWER(album) LIKE ? OR LOWER(title) LIKE ? ORDER BY LOWER(artist) DESC";
	private static const string STMT_GET_ALBUMS = 
		"SELECT DISTINCT album FROM mlib WHERE artist = ? AND (LOWER(artist) LIKE ? OR LOWER(album) LIKE ? OR LOWER(title) LIKE ?) ORDER BY LOWER(album) DESC";
	private static const string STMT_GET_TITLES = 
		"SELECT DISTINCT title FROM mlib WHERE artist = ? AND album = ? AND (LOWER(artist) LIKE ? OR LOWER(album) LIKE ? OR LOWER(title) LIKE ?) ORDER BY tracknumber DESC"; 

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
		this.db.prepare_v2(STMT_COUNT_FOR_URI, -1, 
			out this.count_for_uri_statement); 
		this.db.prepare_v2(STMT_GET_ARTISTS, -1, 
			out this.get_artist_statement); 
		this.db.prepare_v2(STMT_GET_ALBUMS, -1, 
			out this.get_albums_statement); 
		this.db.prepare_v2(STMT_GET_TITLES, -1, 
			out this.get_titles_statement); 
		this.db.prepare_v2(STMT_TRACKDATA_FOR_URI , -1, 
			out this.trackdata_for_uri_statement); 
		this.db.prepare_v2(STMT_TRACK_ID_FOR_URI, -1, 
			out this.track_id_for_uri_statement); 
		this.db.prepare_v2(STMT_URI_FOR_TRACK, -1, 
			out this.uri_for_track_statement);
		this.db.prepare_v2(STMT_TRACKNUMBER_FOR_TRACK, -1, 
			out this.tracknumber_for_track_statement);
	}
	
	public bool uri_is_in_db(string uri) {
		int count = 0;
		count_for_uri_statement.reset();
		
		if(count_for_uri_statement.bind_text(1, uri)!=Sqlite.OK) {
			this.db_error();
		}
		while(count_for_uri_statement.step() == Sqlite.ROW) {
			count = count_for_uri_statement.column_int(0);
		}
		if(count>0) return true;
		return false;
	}
	
	public TrackData get_trackdata_for_uri(string uri) { 
		var val = TrackData();
		trackdata_for_uri_statement.reset();
		trackdata_for_uri_statement.bind_text(1, uri);
		while(trackdata_for_uri_statement.step() == Sqlite.ROW) {
			val.Artist      = Markup.printf_escaped("%s", trackdata_for_uri_statement.column_text(0));
			val.Album       = Markup.printf_escaped("%s", trackdata_for_uri_statement.column_text(1));
			val.Title       = Markup.printf_escaped("%s", trackdata_for_uri_statement.column_text(2));
			val.Tracknumber = trackdata_for_uri_statement.column_int(3); 
		}
		if(val.Artist=="") val.Artist = "unknown artist";
		if(val.Album=="")  val.Album  = "unknown album";
		if(val.Title=="")  val.Title  = "unknown title";
		return val;
	}
	
	public int get_track_id_for_path(string uri) {
		int val = -1;
		track_id_for_uri_statement.reset();
		track_id_for_uri_statement.bind_text(1, uri);
		while(track_id_for_uri_statement.step() == Sqlite.ROW) {
			val = track_id_for_uri_statement.column_int(0);
		}
		return val;
	}
		
	public string get_uri_for_title(string artist,string album, string title) {
		string val = "";
		uri_for_track_statement.reset();
		if((this.uri_for_track_statement.bind_text(1, artist)!=Sqlite.OK)|
			(uri_for_track_statement.bind_text(2, album)!=Sqlite.OK)|
			(uri_for_track_statement.bind_text(3, title)!=Sqlite.OK)) {
			this.db_error();
		}
		while(uri_for_track_statement.step() == Sqlite.ROW) {
			val = uri_for_track_statement.column_text(0);
		}
		return val;
	}
	
	public int get_tracknumber_for_title(string artist,string album, string title) {
		int val = 0;
		tracknumber_for_track_statement.reset();
		if((this.tracknumber_for_track_statement.bind_text(1, artist)!=Sqlite.OK)|
			(tracknumber_for_track_statement.bind_text(2, album)!=Sqlite.OK)|
			(tracknumber_for_track_statement.bind_text(3, title)!=Sqlite.OK)) {
			this.db_error();
		}
		while(tracknumber_for_track_statement.step() == Sqlite.ROW) {
			val = tracknumber_for_track_statement.column_int(0);
		}
		return val;
	}

	public string[] get_artists(ref string searchtext) { 
		string[] val = {};
		get_artist_statement.reset();
		if((this.get_artist_statement.bind_text(1, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_artist_statement.bind_text(2, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_artist_statement.bind_text(3, "%%%s%%".printf(searchtext))!=Sqlite.OK)) {
			this.db_error();
		}
		while(get_artist_statement.step() == Sqlite.ROW) {
			val += get_artist_statement.column_text(0);
		}
		return val;
	}

	public string[] get_albums(string artist, ref string searchtext) { 
		string[] val = {};
		get_albums_statement.reset();
		if((this.get_albums_statement.bind_text(1, artist)!=Sqlite.OK)|
		   (this.get_albums_statement.bind_text(2, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_albums_statement.bind_text(3, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_albums_statement.bind_text(4, "%%%s%%".printf(searchtext))!=Sqlite.OK)) {
			this.db_error();
		}
		while(get_albums_statement.step() == Sqlite.ROW) {
			val += get_albums_statement.column_text(0);
		}
		return val;
	}

	public string[] get_titles(string artist, string album, ref string searchtext) { 
		string[] val = {};
		get_titles_statement.reset();
		if((this.get_titles_statement.bind_text(1, artist)!=Sqlite.OK)|
		   (this.get_titles_statement.bind_text(2, album)!=Sqlite.OK)|
		   (this.get_titles_statement.bind_text(3, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_titles_statement.bind_text(4, "%%%s%%".printf(searchtext))!=Sqlite.OK)|
		   (this.get_titles_statement.bind_text(5, "%%%s%%".printf(searchtext))!=Sqlite.OK)) {
			this.db_error();
		}
		
		while(get_titles_statement.step() == Sqlite.ROW) {
			val += get_titles_statement.column_text(0);
		}
		return val;
	}
}

