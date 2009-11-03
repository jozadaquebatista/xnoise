/* xnoise-db-browser.vala
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

public class Xnoise.DbBrowser : GLib.Object {
	private const string DATABASE_NAME = "db.sqlite";
	private const string INIFOLDER = ".xnoise";
	private string DATABASE;
	private Statement count_for_uri_statement;
	private Statement get_lastused_statement;
	private Statement get_videos_statement;
	private Statement get_video_data_statement;
	private Statement get_artist_statement;
	private Statement get_albums_statement;
	private Statement get_items_statement;
	private Statement get_items_with_mediatypes_and_ids_statement;
	private Statement track_id_for_uri_statement;
	private Statement trackdata_for_uri_statement;
	private Statement trackdata_for_id_statement;
	private Statement uri_for_id_statement;
	private Statement count_for_mediatype_statement;
	private Statement get_radios_statement;
	private Statement get_single_radio_uri_statement;
	private Statement get_media_folders_statement;
	private Statement get_radio_data_statement;
	private Statement stream_td_for_id_statement;
	
	private static const string STMT_COUNT_FOR_MEDIATYPE = 
		"SELECT COUNT (title) FROM items WHERE mediatype = ?";
	private static const string STMT_COUNT_FOR_URI = 
		"SELECT COUNT (title) FROM items i, uris u WHERE i.uri = u.id AND u.name = ?"; 
	private static const string STMT_TRACKDATA_FOR_URI = 
		"SELECT ar.name, al.name, t.title, t.tracknumber FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND u.name = ?";
	private static const string STMT_TRACKDATA_FOR_ID = 
		"SELECT ar.name, al.name, t.title, t.tracknumber, t.mediatype, u.name FROM artists ar, items t, albums al, uris u WHERE t.artist = ar.id AND t.album = al.id AND t.uri = u.id AND t.id = ?";
	private static const string STMT_STREAM_TD_FOR_ID = 
		"SELECT name, uri FROM streams WHERE id = ?";
	private static const string STMT_URI_FOR_ID = 
		"SELECT u.name FROM items t, uris u WHERE t.uri = u.id AND t.id = ?";
	private static const string STMT_TRACK_ID_FOR_URI = 
		"SELECT t.id FROM items t, uris u WHERE t.uri = u.id AND u.name = ?";
	private static const string STMT_GET_LASTUSED = 
		"SELECT uri FROM lastused";
	private static const string STMT_GET_VIDEO_DATA = 
		"SELECT DISTINCT title, mediatype, id FROM items WHERE LOWER(title) LIKE ? AND mediatype = ? ORDER BY title DESC";
	private static const string STMT_GET_VIDEOS = 
		"SELECT DISTINCT title FROM items WHERE LOWER(title) LIKE ? AND mediatype = ? ORDER BY title DESC";
	private static const string STMT_GET_ARTISTS = 
		"SELECT DISTINCT ar.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND (LOWER(ar.name) LIKE ? OR LOWER(al.name) LIKE ? OR LOWER(t.title) LIKE ?) ORDER BY ar.name DESC";
	private static const string STMT_GET_ALBUMS = 
		"SELECT DISTINCT al.name FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND (LOWER(al.name) LIKE ? OR LOWER(t.title) LIKE ?) ORDER BY al.name DESC";
	private static const string STMT_GET_ITEMS = 
		"SELECT DISTINCT t.title FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND LOWER(t.title) LIKE ? ORDER BY t.tracknumber DESC";
	private static const string STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS = 
		"SELECT DISTINCT t.title, t.mediatype, t.id FROM artists ar, items t, albums al WHERE t.artist = ar.id AND t.album = al.id AND ar.name = ? AND al.name = ? AND LOWER(t.title) LIKE ? ORDER BY t.tracknumber DESC";
	private static const string STMT_GET_RADIOS = 
		"SELECT name, uri FROM streams";
	private static const string STMT_GET_SINGLE_RADIO_URI = 
		"SELECT uri FROM streams WHERE name = ?";
	private static const string STMT_GET_MEDIA_FOLDERS = 
		"SELECT * FROM media_folders";
	private static const string STMT_GET_RADIO_DATA	=
		"SELECT DISTINCT id, name, uri FROM streams WHERE LOWER(name) LIKE ? ORDER BY name DESC";
		
	public DbBrowser() {
		DATABASE = dbFileName();
		if(Database.open_v2(DATABASE, out db, Sqlite.OPEN_READONLY, null)!=Sqlite.OK) { 
			stderr.printf("Can't open database: %s\n", (string)this.db.errmsg);
		}
		this.prepare_statements();
	}

	//	~DbBrowser() {
	//		print("destruct dbbrowser\n");
	//	}

	private Database db;

	private string dbFileName() {
		return GLib.Path.build_filename(GLib.Environment.get_home_dir(), INIFOLDER, DATABASE_NAME, null);
	}

	private void db_error() {
		critical("Database error: %s", this.db.errmsg ());
	}

	private void prepare_statements() { 
		this.db.prepare_v2(STMT_COUNT_FOR_MEDIATYPE, -1, 
			out this.count_for_mediatype_statement); 	
		this.db.prepare_v2(STMT_COUNT_FOR_URI, -1, 
			out this.count_for_uri_statement); 
		this.db.prepare_v2(STMT_GET_ARTISTS, -1, 
			out this.get_artist_statement); 
		this.db.prepare_v2(STMT_GET_LASTUSED, -1, 
			out this.get_lastused_statement); 		
		this.db.prepare_v2(STMT_GET_VIDEOS, -1, 
			out this.get_videos_statement);
		this.db.prepare_v2(STMT_GET_VIDEO_DATA, -1, 
			out this.get_video_data_statement);
		this.db.prepare_v2(STMT_GET_RADIO_DATA, -1, 
			out this.get_radio_data_statement);
		this.db.prepare_v2(STMT_GET_ALBUMS, -1, 
			out this.get_albums_statement); 
		this.db.prepare_v2(STMT_GET_ITEMS, -1, 
			out this.get_items_statement); 
		this.db.prepare_v2(STMT_GET_ITEMS_WITH_MEDIATYPES_AND_IDS, -1, 
			out this.get_items_with_mediatypes_and_ids_statement); 
		this.db.prepare_v2(STMT_TRACKDATA_FOR_URI, -1, 
			out this.trackdata_for_uri_statement); 
		this.db.prepare_v2(STMT_URI_FOR_ID, -1, 
			out this.uri_for_id_statement);
		this.db.prepare_v2(STMT_TRACK_ID_FOR_URI, -1, 
			out this.track_id_for_uri_statement); 
		this.db.prepare_v2(STMT_TRACKDATA_FOR_ID , -1, 
			out this.trackdata_for_id_statement); 
		this.db.prepare_v2(STMT_GET_RADIOS, -1, 
			out this.get_radios_statement);
		this.db.prepare_v2(STMT_GET_SINGLE_RADIO_URI, -1, 
			out this.get_single_radio_uri_statement);
		this.db.prepare_v2(STMT_GET_MEDIA_FOLDERS, -1, 
			out this.get_media_folders_statement);
		this.db.prepare_v2(STMT_STREAM_TD_FOR_ID , -1, 
			out this.stream_td_for_id_statement); 
	}

	public bool videos_available() {
		int count = 0;
		count_for_mediatype_statement.reset();
		
		if(count_for_mediatype_statement.bind_int(1, MediaType.VIDEO)!=Sqlite.OK) {
			this.db_error();
		}
		if(count_for_mediatype_statement.step() == Sqlite.ROW) {
			count = count_for_mediatype_statement.column_int(0);
		}
		if(count>0) return true;
		return false;
	}
		
	public bool uri_is_in_db(string uri) {
		int count = 0;
		count_for_uri_statement.reset();
		
		if(count_for_uri_statement.bind_text(1, uri)!=Sqlite.OK) {
			this.db_error();
		}
		if(count_for_uri_statement.step() == Sqlite.ROW) {
			count = count_for_uri_statement.column_int(0);
		}
		if(count>0) return true;
		return false;
	}

	public bool get_uri_for_id(int id, out string val) {
		val = "";
		uri_for_id_statement.reset();
		uri_for_id_statement.bind_int(1, id);
		if(uri_for_id_statement.step() == Sqlite.ROW) {
			val = uri_for_id_statement.column_text(0);
			return true;
		}
		return false;
	}

	public bool get_trackdata_for_id(int id, out TrackData val) { 
		val = TrackData();
		trackdata_for_id_statement.reset();
		trackdata_for_id_statement.bind_int(1, id);
		if(trackdata_for_id_statement.step() == Sqlite.ROW) {
			val.Artist      = trackdata_for_id_statement.column_text(0);
			val.Album       = trackdata_for_id_statement.column_text(1);
			val.Title       = trackdata_for_id_statement.column_text(2);
			val.Tracknumber = trackdata_for_id_statement.column_int(3); 
			val.Mediatype   = (MediaType)trackdata_for_id_statement.column_int(4);
			val.Uri         = trackdata_for_id_statement.column_text(5);
		}
		else {
			print("get_trackdata_for_id: track is not in db. ID: %d\n", id);
			return false;
		}
		if((val.Artist=="") | (val.Artist==null)) {
			val.Artist = "unknown artist";
		}
		if((val.Album== "") | (val.Album== null)) {
			val.Album = "unknown album";
		}
		if((val.Title== "") | (val.Title== null)) {
			val.Title = "unknown title";
			File file = File.new_for_uri(val.Uri);
			string fileBasename = GLib.Filename.display_basename(file.get_path());
			val.Title = fileBasename;
		}
		return true;
	}

	public bool get_stream_td_for_id(int id, out TrackData val) { 
		val = TrackData();
		stream_td_for_id_statement.reset();
		stream_td_for_id_statement.bind_int(1, id);
		if(stream_td_for_id_statement.step() == Sqlite.ROW) {
			val.Artist      = "";
			val.Album       = "";
			val.Title       = stream_td_for_id_statement.column_text(0);
			val.Mediatype   = MediaType.STREAM;
			val.Uri         = stream_td_for_id_statement.column_text(1);
		}
		else {
			print("get_stream_td_for_id: track is not in db. ID: %d\n", id);
			return false;
		}
		return true;
	}

	public bool get_stream_for_id(int id, out string uri) { 
		stream_td_for_id_statement.reset();
		stream_td_for_id_statement.bind_int(1, id);
		if(stream_td_for_id_statement.step() == Sqlite.ROW) {
			uri = stream_td_for_id_statement.column_text(1);
			return true;
		}
		return false;
	}
			
	public bool get_trackdata_for_uri(string uri, out TrackData val) { 
		val = TrackData();
		trackdata_for_uri_statement.reset();
		trackdata_for_uri_statement.bind_text(1, uri);
		if(trackdata_for_uri_statement.step() == Sqlite.ROW) {
			val.Artist      = trackdata_for_uri_statement.column_text(0);
			val.Album       = trackdata_for_uri_statement.column_text(1);
			val.Title       = trackdata_for_uri_statement.column_text(2);
			val.Tracknumber = (uint)trackdata_for_uri_statement.column_int(3); 
		}
		if((val.Artist=="") | (val.Artist==null)) {
			val.Artist = "unknown artist";
		}
		if((val.Album== "") | (val.Album== null)) {
			val.Album = "unknown album";
		}
		if((val.Title== "") | (val.Title== null)) {
			val.Title = "unknown title";
			File file = File.new_for_uri(uri);
			string fileBasename = GLib.Filename.display_basename(file.get_path());
			val.Title = fileBasename;
		}
		return true;
	}

	public string[] get_music_folders() { 
		string[] mfolders = {};
		get_media_folders_statement.reset();
		while(get_media_folders_statement.step() == Sqlite.ROW) {
			mfolders += get_media_folders_statement.column_text(0);
		}
		return mfolders;
	}

	public StreamData[] get_streams() { 
		StreamData[] sData = {};
		get_radios_statement.reset();
		while(get_radios_statement.step() == Sqlite.ROW) {
			StreamData sd = StreamData();
			sd.Name = get_radios_statement.column_text(0);
			sd.Uri  = get_radios_statement.column_text(1);
			sData += sd;
		}
		return sData;
	}
	
	public string? get_single_stream_uri(string name) { 
		get_single_radio_uri_statement.reset();
		get_single_radio_uri_statement.bind_text(1, name);
		if(get_single_radio_uri_statement.step() == Sqlite.ROW) {
			return get_single_radio_uri_statement.column_text(0);
		}
		return null;
	}
		
	public int get_track_id_for_path(string uri) {
		int val = -1;
		track_id_for_uri_statement.reset();
		track_id_for_uri_statement.bind_text(1, uri);
		if(track_id_for_uri_statement.step() == Sqlite.ROW) {
			val = track_id_for_uri_statement.column_int(0);
		}
		return val;
	}

	public string[] get_lastused_uris() { 
		string[] val = {};
		get_lastused_statement.reset();
		while(this.get_lastused_statement.step() == Sqlite.ROW) {
			val += get_lastused_statement.column_text(0);
		}
		return val;
	}

	public TitleMtypeId[] get_video_data(ref string searchtext) { 
		TitleMtypeId[] val = {};
		get_video_data_statement.reset();
		if((this.get_video_data_statement.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (this.get_video_data_statement.bind_int (2, (int)MediaType.VIDEO)        != Sqlite.OK)) {
			this.db_error();
		}
		while(get_video_data_statement.step() == Sqlite.ROW) {
			TitleMtypeId vd = TitleMtypeId();
			vd.name = get_video_data_statement.column_text(0);
			vd.mediatype = (MediaType)get_video_data_statement.column_int(1);
			vd.id = get_video_data_statement.column_int(2);
			val += vd;
		}
		return val;
	}

	public TitleMtypeId[] get_stream_data(ref string searchtext) {
	print("in get_stream_data\n");
		TitleMtypeId[] val = {};
		get_radio_data_statement.reset();
		if((this.get_radio_data_statement.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
		while(get_radio_data_statement.step() == Sqlite.ROW) {
			TitleMtypeId vd = TitleMtypeId();
			vd.id = get_radio_data_statement.column_int(0);
			vd.name = get_radio_data_statement.column_text(1);
			vd.mediatype = MediaType.STREAM;
			val += vd;
		}
		return val;
	}

	public string[] get_videos(ref string searchtext) { 
		string[] val = {};
		get_videos_statement.reset();
		if((this.get_videos_statement.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (this.get_videos_statement.bind_int (2, (int)MediaType.VIDEO)        != Sqlite.OK)) {
			this.db_error();
		}
		while(get_videos_statement.step() == Sqlite.ROW) {
			val += get_videos_statement.column_text(0);
		}
		return val;
	}

	public string[] get_artists(ref string searchtext) { 
		string[] val = {};
		get_artist_statement.reset();
		if((this.get_artist_statement.bind_text(1, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (this.get_artist_statement.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (this.get_artist_statement.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
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
		   (this.get_albums_statement.bind_text(2, "%%%s%%".printf(searchtext)) != Sqlite.OK)|
		   (this.get_albums_statement.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
		while(get_albums_statement.step() == Sqlite.ROW) {
			val += get_albums_statement.column_text(0);
		}
		return val;
	}

	public TitleMtypeId[] get_titles_with_mediatypes_and_ids(string artist, string album, ref string searchtext) { 
		TitleMtypeId[] val = {};
		get_items_with_mediatypes_and_ids_statement.reset();
		if((this.get_items_with_mediatypes_and_ids_statement.bind_text(1, artist)!=Sqlite.OK)|
		   (this.get_items_with_mediatypes_and_ids_statement.bind_text(2, album )!=Sqlite.OK)|
		   (this.get_items_with_mediatypes_and_ids_statement.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
		
		while(get_items_with_mediatypes_and_ids_statement.step() == Sqlite.ROW) {
			TitleMtypeId twt = TitleMtypeId();
			twt.name = get_items_with_mediatypes_and_ids_statement.column_text(0);
			twt.mediatype = (MediaType) get_items_with_mediatypes_and_ids_statement.column_int(1);
			twt.id = get_items_with_mediatypes_and_ids_statement.column_int(2);
			val += twt;
		}
		return val;
	}

	public string[] get_titles(string artist, string album, ref string searchtext) { 
		string[] val = {};
		get_items_statement.reset();
		if((this.get_items_statement.bind_text(1, artist)!=Sqlite.OK)|
		   (this.get_items_statement.bind_text(2, album)!=Sqlite.OK)|
		   (this.get_items_statement.bind_text(3, "%%%s%%".printf(searchtext)) != Sqlite.OK)) {
			this.db_error();
		}
		
		while(get_items_statement.step() == Sqlite.ROW) {
			val += get_items_statement.column_text(0);
		}
		return val;
	}
}

