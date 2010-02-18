/* xnoise-media-importer.vala
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


public class Xnoise.MediaImporter : Object {
//	private static MediaImporter _instance = null;
	public signal void sig_media_path_changed();

//	public static MediaImporter instance {
//		get {
//			if(_instance == null)
//				_instance = new MediaImporter();
//			return _instance;
//		}
//	}

//	public MediaImporter() { 
		//if(_media_importer == null) _media_importer = this;
		//else this=_media_importer;
//	}

	// add files to the media path and store them in the db
	public void store_files(string[] list_of_files, ref DbWriter dbw) {
		if(dbw == null) 
			return;
		
		var files_ht = new HashTable<string,int>(str_hash, str_equal);
		dbw.begin_transaction();

		dbw.del_all_files();

		foreach(string strm in list_of_files) {
			files_ht.insert(strm, 1);
		}

		foreach(string uri in files_ht.get_keys()) {
			dbw.add_single_file_to_collection(uri);
		}

		dbw.commit_transaction();

		foreach(string uri in files_ht.get_keys()) {
			this.add_single_file(uri, ref dbw);
		}

		files_ht.remove_all();
		global.sig_media_path_changed();
	}

	// store a single file in the db, don't add it to the media path
	public void add_single_file(string uri, ref DbWriter dbw) {
		if(dbw == null) 
			return;
		dbw.begin_transaction();
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
			int idbuffer = dbw.uri_entry_exists(file.get_uri());
			if(idbuffer== -1) {
				var tr = new TagReader();
				dbw.insert_title(tr.read_tag(file.get_path()), file.get_uri());
			}
		}
		else if(psVideo.match_string(mime)) {
			int idbuffer = dbw.uri_entry_exists(file.get_uri());
			var td = new TrackData();
			td.Artist = "unknown artist";
			td.Album = "unknown album";
			if(file!=null) td.Title = file.get_basename();
			td.Genre = "";
			td.Tracknumber = 0;
			td.Mediatype = MediaType.VIDEO;

			if(idbuffer== -1) {
				dbw.insert_title(td, file.get_uri());
			}
		}
		dbw.commit_transaction();
	}


	// store a folder in the db, don't add it to the media path
	public void add_local_tags(File dir, ref DbWriter dbw) {
		if(dbw == null) 
			return;
		FileEnumerator enumerator;
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		try {
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE, null);
		} catch (Error error) {
			critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
			return;
		}
		FileInfo info;
		try {
			while((info = enumerator.next_file(null))!=null) {
				string filename = info.get_name();
				string filepath = Path.build_filename(dir.get_path(), filename);
				File file = File.new_for_path(filepath);
				FileType filetype = info.get_file_type();

				string content = info.get_content_type();
				unowned string mime = g_content_type_get_mime_type(content);
				PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
				PatternSpec psVideo = new PatternSpec("video*");

				if(filetype == FileType.DIRECTORY) {
					this.add_local_tags(file, ref dbw);
				}
				else if(psAudio.match_string(mime)) {
					int idbuffer = dbw.uri_entry_exists(file.get_uri());
					if(idbuffer== -1) {
						var tr = new TagReader();
						dbw.insert_title(tr.read_tag(filepath), file.get_uri());
					}
				}
				else if(psVideo.match_string(mime)) {
					int idbuffer = dbw.uri_entry_exists(file.get_uri());
					var td = new TrackData();
					td.Artist = "unknown artist";
					td.Album = "unknown album";
					td.Title = file.get_basename();
					td.Genre = "";
					td.Tracknumber = 0;
					td.Mediatype = MediaType.VIDEO;

					if(idbuffer== -1) {
						dbw.insert_title(td, file.get_uri());
					}
				}
			}
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
	}

	// add folders to the media path and store them in the db
	public void store_folders(string[] mfolders, ref DbWriter dbw){
		if(dbw == null) 
			return;
		
		var mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
		dbw.begin_transaction();
		dbw.del_all_folders();

		foreach(string folder in mfolders) {
			mfolders_ht.insert(folder, 1);
		}

		foreach(string folder in mfolders_ht.get_keys()) {
			dbw.add_single_folder_to_collection(folder);
		}

		if(!dbw.delete_local_media_data()) return;

		foreach(string folder in mfolders_ht.get_keys()) {
			File dir = File.new_for_path(folder);
			assert(dir != null);
			add_local_tags(dir, ref dbw);
		}
		dbw.commit_transaction();

		mfolders_ht.remove_all();
		global.sig_media_path_changed();
	}

	// add streams to the media path and store them in the db
	public void store_streams(string[] list_of_streams, ref DbWriter dbw) {
		if(dbw == null) 
			return;

		var streams_ht = new HashTable<string,int>(str_hash, str_equal);
		dbw.begin_transaction();

		dbw.del_all_streams();

		foreach(string strm in list_of_streams) {
			streams_ht.insert(strm, 1);
		}

		foreach(string strm in streams_ht.get_keys()) {
			dbw.add_single_stream_to_collection(strm, strm); //TODO: Use name different from uri
		}

		dbw.commit_transaction();

		streams_ht.remove_all();
		global.sig_media_path_changed();
	}
}

