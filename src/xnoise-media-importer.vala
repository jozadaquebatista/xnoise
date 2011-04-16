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

using Gtk;

public class Xnoise.MediaImporter : GLib.Object {
	private DbWriter? _dbw;
	private DbWriter? dbw {
		get {
			lock(_dbw) {
				if(_dbw == null) {
					try {
						_dbw = new DbWriter();
					}
					catch(Error e) {
						print("%s\n", e.message);
						return null;
					}
				}
			}
			return _dbw;
		}
	}

	// store a single file in the db, don't add it to the media path
	public void add_single_file(string uri) {
		print("add single file %s\n", uri);
		
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
		string mime = GLib.ContentType.get_mime_type(content);
		PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
		PatternSpec psVideo = new PatternSpec("video*");
		
		if(psAudio.match_string(mime)) {
			string uri_lc = uri.down();
			if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
				int idbuffer = dbw.uri_entry_exists(file.get_uri());
				if(idbuffer== -1) {
					var tr = new TagReader();
					TrackData td = tr.read_tag(file.get_path());
					td.db_id = dbw.insert_title(td, file.get_uri());
					if((int)td.db_id != -1) {
						TrackData[] tdy = { td };
						Idle.add( () => {
							Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdy); 
							return false; 
						});
					}
				}
			}
		}
		else if(psVideo.match_string(mime)) {
			int idbuffer = dbw.uri_entry_exists(file.get_uri());
			var td = new TrackData();
			td.artist = "unknown artist";
			td.album = "unknown album";
			if(file!=null) td.title = prepare_name_from_filename(file.get_basename());
			td.genre = "";
			td.tracknumber = 0;
			td.mediatype = MediaType.VIDEO;
			
			if(idbuffer== -1) {
				dbw.insert_title(td, file.get_uri());
			}
			td.db_id = dbw.get_track_id_for_uri(file.get_uri());
			if((int)td.db_id != -1) {
				TrackData[] tdax = { td };
				Idle.add( () => {
					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax); 
					return false; 
				});
			}
		}
		dbw.commit_transaction();
	}

	// TODO: Can these be stored in a specific Worker.Job?
	private TrackData[] tda = {}; 
	private TrackData[] tdv = {};
	// store a folder in the db, don't add it to the media path
	// This is a recoursive function.
	public async void add_local_tags(File dir, Worker.Job job) { //DbWriter dbw,
		job.counter[0]++;
		
		FileEnumerator enumerator;
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		try {
			enumerator = yield dir.enumerate_children_async(attr, FileQueryInfoFlags.NONE, GLib.Priority.DEFAULT, null);
		} 
		catch (Error error) {
			critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
			job.counter[0]--;
			if(tda.length > 0) {
				TrackData[] tdax2 = tda;
				tda = {};
				Idle.add( () => {
					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax2); 
					return false; 
				});
			}
			end_import(job);
			return;
		}
		GLib.List<GLib.FileInfo> infos;
		try {
			while(true) {
				infos = yield enumerator.next_files_async(15, GLib.Priority.DEFAULT, null);
				
				if(infos == null) {
					job.counter[0]--;
					if(job.counter[0] == 0) {
						dbw.commit_transaction();
						if(tda.length > 0) {
							TrackData[] tdax1 = tda;
							tda = {};
							Idle.add( () => {
								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax1); 
								return false; 
							});
						}
						if(tdv.length > 0) {
							TrackData[] tdvx = tdv;
							tdv = {};
							Idle.add( () => {
								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
								return false; 
							});
						}
						end_import(job);
					}
					return;
				}
				TrackData td;
				foreach(FileInfo info in infos) {
					int idbuffer;
					string filename = info.get_name();
					string filepath = Path.build_filename(dir.get_path(), filename);
					File file = File.new_for_path(filepath);
					FileType filetype = info.get_file_type();

					string content = info.get_content_type();
					string mime = GLib.ContentType.get_mime_type(content);
					PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
					PatternSpec psVideo = new PatternSpec("video*");

					if(filetype == FileType.DIRECTORY) {
						yield this.add_local_tags(file, job);
					}
					else if(psAudio.match_string(mime)) {
						string uri_lc = filename.down();
						if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
							idbuffer = dbw.uri_entry_exists(file.get_uri()); //TODO wird das verwendet?
							if(idbuffer== -1) {
								td = new TrackData();
								var tr = new TagReader();
								td = tr.read_tag(filepath);
								//print("++%s\n", td.title);
								int32 id = dbw.insert_title(td, file.get_uri());
								td.db_id = id;
								td.mediatype = MediaType.AUDIO;
								if((int)id != -1)
									tda += td;
								if(tda.length > 15) {
									TrackData[] tdax = tda;
									tda = {};
									dbw.commit_transaction(); // intermediate commit make tracks fully available for user
									Idle.add( () => {
										Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax); 
										return false; 
									});
									dbw.begin_transaction();
								}
							}
						}
					}
					else if(psVideo.match_string(mime)) {
						idbuffer = dbw.uri_entry_exists(file.get_uri());
						td = new TrackData();
						td.artist = "unknown artist";
						td.album = "unknown album";
						td.title = prepare_name_from_filename(file.get_basename());
						td.genre = "";
						td.tracknumber = 0;
						td.mediatype = MediaType.VIDEO;
						if(idbuffer== -1) {
							dbw.insert_title(td, file.get_uri());
						}
						td.db_id = dbw.get_track_id_for_uri(file.get_uri());
						if((int)td.db_id != -1)
							tdv += td;
						if(tdv.length > 15) {
							TrackData[] tdvx = tdv;
							tdv = {};
							dbw.commit_transaction(); // intermediate commit make tracks fully available for user
							Idle.add( () => {
								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
								return false; 
							});
							dbw.begin_transaction();
						}
					}
				}
			}
		}
		catch(Error e) {
			print("%s\n", e.message);
		}
		job.counter[0]--;
		if(job.counter[0] == 0) {
			dbw.commit_transaction();
			if(tda.length > 0) {
				TrackData[] tdax1 = tda;
				tda = {};
				Idle.add( () => {
					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax1); 
					return false; 
				});
			}
			if(tdv.length > 0) {
				TrackData[] tdvx = tdv;
				tdv = {};
				Idle.add( () => {
					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
					return false; 
				});
			}
			end_import(job);
		}
		return;
	}

	private void end_import(Worker.Job job) {
		print("end import\n");
		Idle.add( () => {
			// update user info in idle in main thread
			userinfo.update_text_by_id((uint)job.get_arg("msg_id"), "Finished import.", false);
			userinfo.update_symbol_widget_by_id((uint)job.get_arg("msg_id"), UserInfo.ContentClass.INFO);
			return false;
		});
		Timeout.add_seconds(4, () => {
			// remove user info after some seconds
			userinfo.popdown((uint)job.get_arg("msg_id"));
			Idle.add( () => {
				global.sig_media_path_changed();
				return false;
			});
			return false;
		});
		_dbw = null;
		global.media_import_in_progress = false;
	}

	public void reset_local_data_library_job(Worker.Job job) {
		dbw.begin_transaction();
		if(!dbw.delete_local_media_data())
			return;
		dbw.commit_transaction();
	}

	// add folders to the media path and store them in the db
	// only for Worker.Job usage
	public void store_folders_job(Worker.Job job){
		print("store_folders_job \n");
		var mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
		dbw.begin_transaction();
		dbw.del_all_folders();

		foreach(string folder in (string[])job.get_arg("mfolders")) {
			mfolders_ht.insert(folder, 1); // this removes double entries
		}

		foreach(unowned string folder in mfolders_ht.get_keys()) {
			dbw.add_single_folder_to_collection(folder);
		}

		if(mfolders_ht.get_keys().length() == 0) {
			dbw.commit_transaction();
			end_import(job);
			return;
		}
		
		foreach(string folder in mfolders_ht.get_keys()) {
			File dir = File.new_for_path(folder);
			assert(dir != null);
			// import all the files
			add_local_tags.begin(dir, job);
		}
		mfolders_ht.remove_all();
	}

	// add streams to the media path and store them in the db
	public void store_streams_job(Worker.Job job) {
		var streams_ht = new HashTable<string,int>(str_hash, str_equal);
		dbw.begin_transaction();

		dbw.del_all_streams();

		foreach(string strm in (string[])job.get_arg("list_of_streams")) {
			streams_ht.insert(strm, 1); // remove duplicates
		}

		foreach(string strm in streams_ht.get_keys()) {
			dbw.add_single_stream_to_collection(strm, strm); //TODO: Use name different from uri
		}
		
		dbw.commit_transaction();
		
		TrackData val;
		TrackData[] tdax = {};
		foreach(string strm in streams_ht.get_keys()) {
			dbw.get_trackdata_for_stream(strm, out val);
			tdax += val;
		}
		job.track_dat = tdax;
		Idle.add( () => {
			Main.instance.main_window.mediaBr.mediabrowsermodel.insert_stream_sorted(job.track_dat); 
			return false; 
		});
		
		streams_ht.remove_all();
//		global.sig_media_path_changed();
	}
	
	// add files to the media path and store them in the db
	public void store_files_job(Worker.Job job) {
		if(dbw == null) 
			return;
		
		var files_ht = new HashTable<string,int>(str_hash, str_equal);

		dbw.del_all_files();

		foreach(string strm in (string[])job.get_arg("list_of_files")) {
			files_ht.insert(strm, 1);
		}

		foreach(string uri in files_ht.get_keys()) {
			dbw.add_single_file_to_collection(uri);
		}

		foreach(string uri in files_ht.get_keys()) {
			this.add_single_file(uri);
		}

		files_ht.remove_all();
//		global.sig_media_path_changed();
	}

}

