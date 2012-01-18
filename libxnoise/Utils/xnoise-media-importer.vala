/* xnoise-media-importer.vala
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

using Gtk;

using Xnoise;
using Xnoise.TagAccess;

public class Xnoise.MediaImporter : GLib.Object {

	private static int FILE_COUNT = 150;
	
	internal void reimport_media_groups() {
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, reimport_media_groups_job);
		db_worker.push_job(job);
	}
	
	private bool reimport_media_groups_job(Worker.Job job) {
		main_window.mediaBr.mediabrowsermodel.cancel_fill_model();
		
		//add folders
		string[] mfolders = db_browser.get_media_folders();
		job.set_arg("mfolders", mfolders);
		
		//add files
		string[] mfiles = db_browser.get_media_files();
		job.set_arg("mfiles", mfiles);
		
		//add streams to list
		StreamData[] streams = db_browser.get_streams();
		
		string[] strms = {};
		
		foreach(unowned StreamData sd in streams)
			strms += sd.uri;
		
		Timeout.add(200, () => {
			var prg_bar = new Gtk.ProgressBar();
			prg_bar.set_fraction(0.0);
			prg_bar.set_text("0 / 0");
			uint msg_id = userinfo.popup(UserInfo.RemovalType.EXTERNAL,
			                             UserInfo.ContentClass.WAIT,
			                             _("Importing media data. This may take some time..."),
			                             true,
			                             5,
			                             prg_bar);
			global.media_import_in_progress = true;
			main_window.mediaBr.mediabrowsermodel.remove_all();
			
			import_media_groups(strms, mfiles, mfolders, msg_id, true, false);
			
			return false;
		});
		return false;
	}

	internal void update_item_tag(ref Item? item, ref TrackData td) {
		if(global.media_import_in_progress == true)
			return;
		db_writer.update_title(ref item, ref td);
	}
	
//	internal void update_artist_name(string old_name, string name) {
//		if(global.media_import_in_progress == true)
//			return;
//		db_writer.begin_transaction();
//		db_writer.update_artist_name(name, old_name);
//		db_writer.commit_transaction();
//	}

//	internal void update_album_name(string artist, string old_name, string name) {
//		if(global.media_import_in_progress == true)
//			return;
//		db_writer.begin_transaction();
//		db_writer.update_album_name(artist, name, old_name);
//		db_writer.commit_transaction();
//	}
	
//	internal string[] get_uris_for_artistalbum(string artist, string album) {
//		return db_writer.get_uris_for_artistalbum(artist, album);
//	}
//	
//	internal string[] get_uris_for_artist(string artist) {
//		return db_writer.get_uris_for_artist(artist);
//	}
	
	public string? get_uri_for_item_id(int32 id) {
		return db_writer.get_uri_for_item_id(id);
	}

	private uint current_import_msg_id = 0;
	private uint current_import_track_count = 0;
	
	internal void import_media_groups(string[] list_of_streams, string[] list_of_files, string[] list_of_folders, uint msg_id, bool full_rescan = true, bool interrupted_populate_model = false) {
		// global.media_import_in_progress has to be reset in the last job !
		io_import_job_running = true;
		
		Worker.Job job;
		if(full_rescan) {
			job = new Worker.Job(Worker.ExecutionType.ONCE, reset_local_data_library_job);
			db_worker.push_job(job);
		}
		
		if(list_of_streams.length > 0) {
			job = new Worker.Job(Worker.ExecutionType.ONCE, store_streams_job);
			job.set_arg("list_of_streams", list_of_streams);
			job.set_arg("full_rescan", full_rescan);
			db_worker.push_job(job);
		}
		
		//Assuming that number of streams will be relatively small,
		//the progress of import will only be done for folder imports
		job = new Worker.Job(Worker.ExecutionType.ONCE, store_folders_job);
		job.set_arg("mfolders", list_of_folders);
		job.set_arg("msg_id", msg_id);
		current_import_msg_id = msg_id;
		job.set_arg("interrupted_populate_model", interrupted_populate_model);
		job.set_arg("full_rescan", full_rescan);
		db_worker.push_job(job);
	}
	private bool io_import_job_running = false;
//	private int job_count = 0;

	internal bool write_final_tracks_to_db_job(Worker.Job job) {
		try {
			db_writer.write_final_tracks_to_db(job);
		}
		catch(Error err) {
			print("%s\n", err.message);
		}
		return false;
	}

//	private PatternSpec psAudio = new PatternSpec("audio*");
//	private PatternSpec psVideo = new PatternSpec("video*");
	
	// store a single file in the db, don't add it to the media path
//	internal void add_single_file(string uri) {
//		print("add single file %s\n", uri);
//		
//		db_writer.begin_transaction();
//		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
//		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
//		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
//		FileInfo info = null;
//		File file = File.new_for_uri(uri);
//		try {
//			info = file.query_info(attr, FileQueryInfoFlags.NONE, null);
//		}
//		catch(Error e) {
//			print("single file import: %s\n", e.message);
//			return;
//		}
//		string content = info.get_content_type();
//		string mime = GLib.ContentType.get_mime_type(content);
//		
//		if(psAudio.match_string(mime)) {
//			string uri_lc = uri.down();
//			if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
//				int idbuffer = db_writer.uri_entry_exists(file.get_uri());
//				if(idbuffer== -1) {
//					var tr = new TagReader();
//					TrackData td = tr.read_tag(file.get_path());
//				}
//			}
//		}
//		else if(psVideo.match_string(mime)) {
//			int idbuffer = db_writer.uri_entry_exists(file.get_uri());
//			var td = new TrackData();
//			td.artist = "unknown artist";
//			td.album = "unknown album";
//			if(file!=null) 
//				td.title = prepare_name_from_filename(file.get_basename());
//			td.genre = "";
//			td.tracknumber = 0;
//		}
//		db_writer.commit_transaction();
//	}

	private TrackData[] tda = {}; 
//	private TrackData[] tdv = {};

	// running in io thread
	private void end_import(Worker.Job job) {
		//print("end import 1 %d %d\n", job.counter[1], job.counter[2]);
		if(job.counter[1] != job.counter[2])
			return;
		
		Idle.add( () => {
			// update user info in idle in main thread
			uint xcnt = 0;
			lock(current_import_track_count) {
				xcnt = current_import_track_count;
			}
			userinfo.update_text_by_id((uint)job.get_arg("msg_id"),
			                           _("Found %u tracks. Updating library ...".printf(xcnt)),
			                           false);
			if(userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")) != null)
				userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")).hide();
			return false;
		});
		var finisher_job = new Worker.Job(Worker.ExecutionType.ONCE, finish_import_job);
		db_worker.push_job(finisher_job);
	}
	
	// running in db thread
	private bool finish_import_job(Worker.Job job) {
		Idle.add( () => {
			print("finish import\n");
			global.media_import_in_progress = false;
			if(current_import_msg_id != 0) {
				userinfo.popdown(current_import_msg_id);
				current_import_msg_id = 0;
				lock(current_import_track_count) {
					current_import_track_count = 0;
				}
			}
			return false;
		});
		return false;
	}

	// running in db thread
	private bool reset_local_data_library_job(Worker.Job job) {
		db_writer.begin_transaction();
		if(!db_writer.delete_local_media_data())
			return false;
		db_writer.commit_transaction();
		
		// remove streams
		db_writer.del_all_streams();
		return false;
	}

	// add folders to the media path and store them in the db
	// only for Worker.Job usage
	private bool store_folders_job(Worker.Job job){
		//print("store_folders_job \n");
		var mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
		if(((bool)job.get_arg("full_rescan"))) {
			db_writer.del_all_folders();
		
			foreach(unowned string folder in (string[])job.get_arg("mfolders"))
				mfolders_ht.insert(folder, 1); // this removes double entries
		
			foreach(unowned string folder in mfolders_ht.get_keys())
				db_writer.add_single_folder_to_collection(folder);
		
			if(mfolders_ht.get_keys().length() == 0) {
				db_writer.commit_transaction();
				end_import(job);
				return false;
			}
			// COUNT HERE
//			foreach(string folder in mfolders_ht.get_keys()) {
//				File file = File.new_for_commandline_arg(folder);
//				count_media_files(file, job);
//			}
			//print("count: %d\n", (int)(job.big_counter[0]));			
			int cnt = 1;
			foreach(unowned string folder in mfolders_ht.get_keys()) {
				File dir = File.new_for_path(folder);
				assert(dir != null);
				// import all the files
				var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
				reader_job.set_arg("dir", dir);
				reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
				reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
				reader_job.counter[1] = cnt;
				reader_job.counter[2] = (int)mfolders_ht.get_keys().length();
				io_worker.push_job(reader_job);
				cnt ++;
			}
			mfolders_ht.remove_all();
		}
		else { // import new folders only
			// after import at least the media folder have to be updated
			
			string[] dbfolders = db_writer.get_media_folders();
			
			foreach(unowned string folder in (string[])job.get_arg("mfolders"))
				mfolders_ht.insert(folder, 1); // this removes double entries
			
			db_writer.del_all_folders();
			foreach(unowned string folder in mfolders_ht.get_keys()) {
//				if(!(folder in dbfolders))
					db_writer.add_single_folder_to_collection(folder);
			}
			var new_mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
			foreach(unowned string folder in mfolders_ht.get_keys()) {
				if(!(folder in dbfolders))
					new_mfolders_ht.insert(folder, 1);
			}
				// COUNT HERE
//			foreach(string folder in new_mfolders_ht.get_keys()) {
//				File file = File.new_for_commandline_arg(folder);
//				count_media_files(file, job);
//			}
	
			if(new_mfolders_ht.get_keys().length() == 0) {
				db_writer.commit_transaction();
				end_import(job);
				return false;
			}
			int cnt = 1;
			foreach(unowned string folder in new_mfolders_ht.get_keys()) {
				File dir = File.new_for_path(folder);
				assert(dir != null);
				var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
				reader_job.set_arg("dir", dir);
				reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
				reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
				reader_job.counter[1] = cnt;
				reader_job.counter[2] = (int)new_mfolders_ht.get_keys().length();
				io_worker.push_job(reader_job);
				cnt++;
			}
			mfolders_ht.remove_all();
		}
		return false;
	}
	
	// running in io thread
	private bool read_media_folder_job(Worker.Job job) {
//		count_media_files((File)job.get_arg("dir"), job);
		read_recoursive((File)job.get_arg("dir"), job);
		return false;
	}
	
	// running in io thread
	private void read_recoursive(File dir, Worker.Job job) {
		job.counter[0]++;
		FileEnumerator enumerator;
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE;
		try {
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
		} 
		catch(Error e) {
			print("Error importing directory %s. %s\n", dir.get_path(), e.message);
			job.counter[0]--;
			if(job.counter[0] == 0)
				end_import(job);
			return;
		}
		GLib.FileInfo info;
		try {
			while((info = enumerator.next_file()) != null) {
				TrackData td = null;
//				int idbuffer;
				string filename = info.get_name();
				string filepath = Path.build_filename(dir.get_path(), filename);
				File file = File.new_for_path(filepath);
				FileType filetype = info.get_file_type();
				if(filetype == FileType.DIRECTORY) {
					read_recoursive(file, job);
				}
				else {
					string uri_lc = filename.down();
					if(!(uri_lc.has_suffix(".m3u")||
					     uri_lc.has_suffix(".pls")||
					     uri_lc.has_suffix(".asx")||
					     uri_lc.has_suffix(".xspf")||
					     uri_lc.has_suffix(".wpl"))) {
						var tr = new TagReader();
						td = tr.read_tag(filepath);
						if(td != null) {
							tda += td;
							job.big_counter[1]++;
							lock(current_import_track_count) {
								current_import_track_count++;
							}
						}
						if(job.big_counter[1] % 50 == 0) {
							Idle.add( () => {  // Update progress bar
								uint xcnt = 0;
								lock(current_import_track_count) {
									xcnt = current_import_track_count;
								}
								unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
								if(pb != null) {
									pb.pulse();
									pb.set_text(_("%u tracks found").printf(xcnt));
								}
								return false;
							});
						}
						if(tda.length > FILE_COUNT) {
							var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
							db_job.track_dat = tda;
							db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
							tda = {};
							db_worker.push_job(db_job);
						}
					}
					else {
						//TODO use Item converter
						print("found playlist file\n");
						Item item = ItemHandlerManager.create_item(file.get_uri());
						string? searcht = null;
						TrackData[]? playlist_content = item_converter.to_trackdata(item, ref searcht);
						if(playlist_content != null) {
							foreach(unowned TrackData tdat in playlist_content) {
								//print("fnd playlist_content : %s - %s\n", tdat.item.uri, tdat.title);
								tda += tdat;
								job.big_counter[1]++;
								lock(current_import_track_count) {
									current_import_track_count++;
								}
							}
							if(job.big_counter[1] % 50 == 0) {
								Idle.add( () => {  // Update progress bar
									uint xcnt = 0;
									lock(current_import_track_count) {
										xcnt = current_import_track_count;
									}
									unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
									if(pb != null) {
										pb.pulse();
										pb.set_text(_("%u tracks found").printf(xcnt));
									}
									return false;
								});
							}
							if(tda.length > FILE_COUNT) {
								var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
								db_job.track_dat = tda;
								db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
								tda = {};
								db_worker.push_job(db_job);
							}
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
			if(tda.length > 0) {
				var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
				db_job.track_dat = tda;
				tda = {};
				db_worker.push_job(db_job);
			}
			end_import(job);
		}
		return;
	}
	
	private bool insert_trackdata_job(Worker.Job job) {
		db_writer.begin_transaction();
		foreach(TrackData td in job.track_dat) {
			db_writer.insert_title(ref td);
		}
		db_writer.commit_transaction();
		return false;
	}
	
//	private void count_media_files(File dir, Worker.Job job) {
//		FileInfo info;
//		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
//		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
//		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
//		try {
//			var enumerator = dir.enumerate_children(attr, 0);
//			
//			while((info = enumerator.next_file()) != null) {
//				FileType filetype = info.get_file_type();
//				string filename = info.get_name();
//				string filepath = Path.build_filename(dir.get_path(), filename);
//				File file = File.new_for_path(filepath);
//				if(filetype == FileType.DIRECTORY) {
//					count_media_files(file, job);
//				}
//				else {
//					string content = info.get_content_type();
//					string mime    = ContentType.get_mime_type(content);
//					if(psAudio.match_string(mime) || psVideo.match_string(mime))
//						job.big_counter[0]++;
//				}
//			}
//		} 
//		catch(Error e) {
//			print("%s\n", e.message);
//		}
//	}
	
	// add streams to the media path and store them in the db
	private bool store_streams_job(Worker.Job job) {
		var streams_ht = new HashTable<string,int>(str_hash, str_equal);
		db_writer.begin_transaction();

		db_writer.del_all_streams();

		foreach(unowned string strm in (string[])job.get_arg("list_of_streams")) {
			streams_ht.insert(strm, 1); // remove duplicates
		}

		foreach(unowned string strm in streams_ht.get_keys()) {
			db_writer.add_single_stream_to_collection(strm, strm); //TODO: Use name different from uri
			lock(current_import_track_count) {
				current_import_track_count++;
			}
		}
		
		db_writer.commit_transaction();
		
		TrackData val;
		TrackData[] tdax = {};
		foreach(unowned string strm in streams_ht.get_keys()) {
			db_writer.get_trackdata_for_stream(strm, out val);
			print("stream: %s\n", strm);
			tdax += val;
		}
		job.track_dat = tdax;
		Idle.add( () => {
//			main_window.mediaBr.mediabrowsermodel.insert_stream_sorted(job.track_dat); 
			return false; 
		});
		
		streams_ht.remove_all();
//		global.sig_media_path_changed();
		return false;
	}
}

