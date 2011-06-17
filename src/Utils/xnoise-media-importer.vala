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

public class Xnoise.MediaImporter : GLib.Object {

	private static int FILE_COUNT = 150;
	
	internal void reimport_media_groups() {
		Worker.Job job;
		job = new Worker.Job(Worker.ExecutionType.ONCE, reimport_media_groups_job);
		db_worker.push_job(job);
	}
	
	private bool reimport_media_groups_job(Worker.Job job) {
		Main.instance.main_window.mediaBr.mediabrowsermodel.cancel_fill_model();
		
		//add folders
		string[] mfolders = db_browser.get_media_folders();
		job.set_arg("mfolders", mfolders);
		
		//add files
		string[] mfiles = db_browser.get_media_files();
		job.set_arg("mfiles", mfiles);
		
		//add streams to list
		StreamData[] streams = db_browser.get_streams();
		
		string[] strms = {};
		
		foreach(StreamData sd in streams)
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
			Main.instance.main_window.mediaBr.mediabrowsermodel.clear();
			
			import_media_groups(strms, mfiles, mfolders, msg_id, true, false);
			
			return false;
		});
		return false;
	}

	internal void update_item_tag(ref TrackData td) {
		if(global.media_import_in_progress == true)
			return;
		
//		db_writer.begin_transaction();
		
		db_writer.update_title(ref td);	
			
//		db_writer.commit_transaction();
	}
	
	internal void update_artist_name(string old_name, string name) {
		if(global.media_import_in_progress == true)
			return;
		db_writer.begin_transaction();
		db_writer.update_artist_name(name, old_name);
		db_writer.commit_transaction();
	}

	internal void update_album_name(string artist, string old_name, string name) {
		if(global.media_import_in_progress == true)
			return;
		db_writer.begin_transaction();
		db_writer.update_album_name(artist, name, old_name);
		db_writer.commit_transaction();
	}
	
	internal string[] get_uris_for_artistalbum(string artist, string album) {
		return db_writer.get_uris_for_artistalbum(artist, album);
	}
	
	internal string[] get_uris_for_artist(string artist) {
		return db_writer.get_uris_for_artist(artist);
	}
	
	public string? get_uri_for_item_id(int32 id) {
		return db_writer.get_uri_for_item_id(id);
	}

	private uint current_import_msg_id = 0;
	
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
		
//		job = new Worker.Job(Worker.ExecutionType.ONCE, store_files_job);
//		job.set_arg("list_of_files", list_of_files);
//		job.set_arg("full_rescan", full_rescan);
//		db_worker.push_job(job);
		
		//Assuming that number of streams and number of files will be relatively small,
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
	private int job_count = 0;

	internal bool write_final_tracks_to_db_job(Worker.Job job) {
		string[] final_tracklist = (string[])job.get_arg("final_tracklist");
		try {
			db_writer.write_final_tracks_to_db(final_tracklist);
		}
		catch(Error err) {
			print("%s\n", err.message);
		}
		return false;
	}

	private PatternSpec psAudio = new PatternSpec("audio*");
	private PatternSpec psVideo = new PatternSpec("video*");
	
	// store a single file in the db, don't add it to the media path
	internal void add_single_file(string uri) {
		print("add single file %s\n", uri);
		
		db_writer.begin_transaction();
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
		
		if(psAudio.match_string(mime)) {
			string uri_lc = uri.down();
			if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
				int idbuffer = db_writer.uri_entry_exists(file.get_uri());
				if(idbuffer== -1) {
					var tr = new TagReader();
					TrackData td = tr.read_tag(file.get_path());
//					td.uri = file.get_uri();
//					td.db_id = db_writer.insert_title(ref td, file.get_uri());
//					if(db_writer.insert_title(ref td, file.get_uri())) {
////						TrackData[] tdy = { td };
//						Idle.add( () => {
////							Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdy); 
//							return false; 
//						});
//					}
				}
			}
		}
		else if(psVideo.match_string(mime)) {
			int idbuffer = db_writer.uri_entry_exists(file.get_uri());
			var td = new TrackData();
//			td.uri = file.get_uri();
			td.artist = "unknown artist";
			td.album = "unknown album";
			if(file!=null) 
				td.title = prepare_name_from_filename(file.get_basename());
			td.genre = "";
			td.tracknumber = 0;
//			td.mediatype = ItemType.LOCAL_VIDEO_TRACK;
			
//			if(idbuffer== -1 && db_writer.insert_title(ref td, file.get_uri())) {
////				db_writer.insert_title(td, file.get_uri());
////			}
////			td.db_id = db_writer.get_track_id_for_uri(file.get_uri());
////			if((int)td.db_id != -1) {
////				TrackData[] tdax = { td };
//				Idle.add( () => {
////					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax); 
//					return false; 
//				});
//			}
		}
		db_writer.commit_transaction();
	}

	// TODO: Can these be stored in a specific Worker.Job?
	private TrackData[] tda = {}; 
	private TrackData[] tdv = {};
//	// store a folder in the db, don't add it to the media path
//	// This is a recoursive function.
//	public async void add_local_tags(File dir, Worker.Job job) {
//		job.counter[0]++;
//		print( "add_local_tags thread %d", (int)Linux.gettid() );
//		FileEnumerator enumerator;
//		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
//		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
//		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
//		try {
//			enumerator = yield dir.enumerate_children_async(attr, FileQueryInfoFlags.NONE, Priority.DEFAULT, null);
//		} 
//		catch (Error error) {
//			critical("Error importing directory %s. %s\n", dir.get_path(), error.message);
//			job.counter[0]--;
//			if(tda.length > 0) {
////				TrackData[] tdax2 = tda;
//				tda = {};
//				Idle.add( () => {
////					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax2); 
//					return false; 
//				});
//			}
//			end_import(job);
//			return;
//		}
//		GLib.List<GLib.FileInfo> infos;
//		try {
//			while(true) {
//				infos = yield enumerator.next_files_async(FILE_COUNT, Priority.DEFAULT, null);
//				
//				if(infos == null) {
//					job.counter[0]--;
//					if(job.counter[0] == 0) {
//						db_writer.commit_transaction();
//						if(tda.length > 0) {
////							TrackData[] tdax1 = tda;
//							tda = {};
//							Idle.add( () => {
////								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax1); 
//								return false; 
//							});
//						}
//						if(tdv.length > 0) {
////							TrackData[] tdvx = tdv;
//							tdv = {};
//							Idle.add( () => {
////								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
//								return false; 
//							});
//						}
//						end_import(job);
//					}
//					return;
//				}
//				TrackData td;
//				foreach(FileInfo info in infos) {
//					int idbuffer;
//					string filename = info.get_name();
//					string filepath = Path.build_filename(dir.get_path(), filename);
//					File file = File.new_for_path(filepath);
//					FileType filetype = info.get_file_type();

//					string content = info.get_content_type();
//					string mime = GLib.ContentType.get_mime_type(content);
//					PatternSpec psAudio = new PatternSpec("audio*"); //TODO: handle *.m3u and *.pls seperately
//					PatternSpec psVideo = new PatternSpec("video*");

//					if(filetype == FileType.DIRECTORY) {
//						yield this.add_local_tags(file, job);
//					}
//					else if(psAudio.match_string(mime)) {
//						string uri_lc = filename.down();
//						if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
//							idbuffer = db_writer.uri_entry_exists(file.get_uri()); //TODO wird das verwendet?
//							if(idbuffer== -1) {
//								td = new TrackData();
//								var tr = new TagReader();
//								td = tr.read_tag(filepath);
//								td.uri = file.get_uri();
//								//print("++%s\n", td.title);
////								int32 id = db_writer.insert_title(td, file.get_uri());
////								td.db_id = id;
//								td.item = Item(ItemType.LOCAL_AUDIO_TRACK, file.get_uri(), td.db_id);
//								td.mediatype = ItemType.LOCAL_AUDIO_TRACK;
//								if(db_writer.insert_title(ref td, file.get_uri())) {
//									tda += td;
//									job.big_counter[1]++;
//									Idle.add( () => {
//										unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
//										if(pb != null) {
//											pb.set_fraction(((double)((double)job.big_counter[1] / (double)job.big_counter[0])));
//											pb.set_text("%d / %d".printf((int)job.big_counter[1], (int)job.big_counter[0]));
//										}
//										return false;
//									});
//								}
//								if(tda.length > FILE_COUNT) {
////									TrackData[] tdax = tda;
//									tda = {};
//									db_writer.commit_transaction(); // intermediate commit make tracks fully available for user
//									Idle.add( () => {
////										Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax); 
//										return false; 
//									});
//									db_writer.begin_transaction();
//								}
//							}
//						}
//					}
//					else if(psVideo.match_string(mime)) {
//						idbuffer = db_writer.uri_entry_exists(file.get_uri());
//						td = new TrackData();
//						td.artist = "unknown artist";
//						td.album = "unknown album";
//						td.title = prepare_name_from_filename(file.get_basename());
//						td.genre = "";
//						td.tracknumber = 0;
//						td.mediatype = ItemType.LOCAL_VIDEO_TRACK;
//						if(idbuffer== -1 && db_writer.insert_title(ref td, file.get_uri())) {
////							db_writer.insert_title(td, file.get_uri());
////						}
////						td.db_id = db_writer.get_track_id_for_uri(file.get_uri());
////						if((int)td.db_id != -1) {
//							td.item = Item(ItemType.LOCAL_VIDEO_TRACK, file.get_uri(), td.db_id);
//							tdv += td;
//							job.big_counter[1]++;
//						}
//						if(tdv.length > FILE_COUNT) {
////							TrackData[] tdvx = tdv;
//							tdv = {};
//							db_writer.commit_transaction(); // intermediate commit make tracks fully available for user
//							Idle.add( () => {
////								Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
//								return false; 
//							});
//							db_writer.begin_transaction();
//						}
//					}
//				}
//			}
//		}
//		catch(Error e) {
//			print("%s\n", e.message);
//		}
//		job.counter[0]--;
//		if(job.counter[0] == 0) {
//			db_writer.commit_transaction();
//			if(tda.length > 0) {
////				TrackData[] tdax1 = tda;
//				tda = {};
//				Idle.add( () => {
////					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_trackdata_sorted(tdax1); 
//					return false; 
//				});
//			}
//			if(tdv.length > 0) {
////				TrackData[] tdvx = tdv;
//				tdv = {};
//				Idle.add( () => {
////					Main.instance.main_window.mediaBr.mediabrowsermodel.insert_video_sorted(tdvx); 
//					return false; 
//				});
//			}
//			end_import(job);
//		}
//		return;
//	}

	private void end_import(Worker.Job job) {
		print("end import\n");
//		Idle.add( () => {
//			// update user info in idle in main thread
//			userinfo.update_text_by_id((uint)job.get_arg("msg_id"), 
//			                           ( ((bool)job.get_arg("full_rescan")) == true ?
//			                               _("Finished import. ") +  " " + _("Found %d media files").printf((int)job.big_counter[0]) : 
//			                               ( (int)job.big_counter[1] > 0 ? 
//			                                   _("Updated library for new media folders. ") + " " + _("Found %d new media files").printf((int)job.big_counter[1]) : 
//			                                   _("Updated library for new media folders. ") ) ), 
//			                           false);
//			if(userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")) != null)
//				userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id")).hide();
//			userinfo.update_symbol_widget_by_id((uint)job.get_arg("msg_id"), UserInfo.ContentClass.INFO);
//			return false;
//		});
//		Timeout.add_seconds(4, () => {
//			// remove user info after some seconds
////			userinfo.popdown((uint)job.get_arg("msg_id"));
//			Idle.add( () => {
//				global.sig_media_path_changed();
//				return false;
//			});
//			io_import_job_running = false;
//			return false;
//		});
//		print("set import to false\n");
//		global.media_import_in_progress = false;
	}

	private bool reset_local_data_library_job(Worker.Job job) {
		db_writer.begin_transaction();
		if(!db_writer.delete_local_media_data())
			return false;
		db_writer.commit_transaction();
		return false;
	}

	// add folders to the media path and store them in the db
	// only for Worker.Job usage
	private bool store_folders_job(Worker.Job job){
		//print("store_folders_job \n");
		var mfolders_ht = new HashTable<string,int>(str_hash, str_equal);
//		db_writer.begin_transaction();
		if(((bool)job.get_arg("full_rescan"))) {
			db_writer.del_all_folders();
		
			foreach(string folder in (string[])job.get_arg("mfolders"))
				mfolders_ht.insert(folder, 1); // this removes double entries
		
			foreach(unowned string folder in mfolders_ht.get_keys())
				db_writer.add_single_folder_to_collection(folder);
		
			if(mfolders_ht.get_keys().length() == 0) {
				db_writer.commit_transaction();
				end_import(job);
				return false;
			}
			// COUNT HERE
			foreach(string folder in mfolders_ht.get_keys()) {
				File file = File.new_for_commandline_arg(folder);
				count_media_files(file, job);
			}
			//print("count: %d\n", (int)(job.big_counter[0]));			
			int cnt = 0;
			foreach(string folder in mfolders_ht.get_keys()) {
				File dir = File.new_for_path(folder);
				assert(dir != null);
				// import all the files
//				add_local_tags.begin(dir, job);
				var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
				reader_job.set_arg("dir", dir);
				reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
				reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
				if(cnt==(mfolders_ht.get_keys().length() - 1))
					reader_job.finished.connect( (s) => {
			//			print("end import\n");
						Idle.add( () => {
							// update user info in idle in main thread
							userinfo.update_text_by_id((uint)s.get_arg("msg_id"), 
										               _("Finished reading. Updating Library"),
										               false);
							if(userinfo.get_extra_widget_by_id((uint)s.get_arg("msg_id")) != null)
								userinfo.get_extra_widget_by_id((uint)s.get_arg("msg_id")).hide();
							return false;
						});
						Timeout.add_seconds(4, () => {
							//print("reset io_import_job_running flag\n");
							io_import_job_running = false;
							if(AtomicInt.get(ref job_count) <= 0) {
								global.media_import_in_progress = false;
								if(current_import_msg_id != 0) {
									userinfo.popdown(current_import_msg_id);
									current_import_msg_id = 0;
								}
							}
							return false;
						});
					});
				io_worker.push_job(reader_job);
				cnt ++;
			}
			mfolders_ht.remove_all();
		}
		else { // import new folders only
			// after import at least the media folder have to be updated
//			if((bool)job.get_arg("interrupted_populate_model"))
//				trigger_mediabrowser_update_id = global.notify["media-import-in-progress"].connect(trigger_mediabrowser_update);
			
			string[] dbfolders = db_writer.get_media_folders();
			
			foreach(string folder in (string[])job.get_arg("mfolders"))
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
			foreach(string folder in new_mfolders_ht.get_keys()) {
				File file = File.new_for_commandline_arg(folder);
				count_media_files(file, job);
			}
	
			if(new_mfolders_ht.get_keys().length() == 0) {
				db_writer.commit_transaction();
				end_import(job);
				return false;
			}
			foreach(string folder in new_mfolders_ht.get_keys()) {
				File dir = File.new_for_path(folder);
				assert(dir != null);
				var reader_job = new Worker.Job(Worker.ExecutionType.ONCE, read_media_folder_job);
				reader_job.set_arg("dir", dir);
				reader_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
				reader_job.set_arg("full_rescan", (bool)job.get_arg("full_rescan"));
				
				io_worker.push_job(reader_job);
//				add_local_tags.begin(dir, job); 
			}
			mfolders_ht.remove_all();
		}
		return false;
	}
	
	private bool read_media_folder_job(Worker.Job job) {
//		count_media_files((File)job.get_arg("dir"), job);
		read_recoursive((File)job.get_arg("dir"), job);
		return false;
	}
	
	private void read_recoursive(File dir, Worker.Job job) {
		job.counter[0]++;
		FileEnumerator enumerator;
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		try {
			enumerator = dir.enumerate_children(attr, FileQueryInfoFlags.NONE);
		} 
		catch(Error e) {
			print("Error importing directory %s. %s\n", dir.get_path(), e.message);
			job.counter[0]--;
			return;
		}
		GLib.FileInfo info;
		try {
			while((info = enumerator.next_file()) != null) {
				TrackData td = null;
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
					read_recoursive(file, job);
				}
				else if(psAudio.match_string(mime)) {
					string uri_lc = filename.down();
					if(!(uri_lc.has_suffix(".m3u")||uri_lc.has_suffix(".pls")||uri_lc.has_suffix(".asx")||uri_lc.has_suffix(".xspf")||uri_lc.has_suffix(".wpl"))) {
						var tr = new TagReader();
						td = tr.read_tag(filepath);
//						td.uri = file.get_uri();
//						td.item = Item(ItemType.LOCAL_AUDIO_TRACK, file.get_uri(), td.db_id);
//						td.mediatype = ItemType.LOCAL_AUDIO_TRACK;
						tda += td;
						job.big_counter[1]++;
						if(job.big_counter[1] % 50 == 0) {
							Idle.add( () => {  // Update progress bar
								unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
								if(pb != null) {
									pb.pulse();
									pb.set_text("%d tracks found".printf((int)job.big_counter[1]));//, (int)job.big_counter[0]));
								}
								return false;
							});
						}
						if(tda.length > FILE_COUNT) {
							var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
							db_job.track_dat = tda;
							db_job.set_arg("msg_id", (uint)job.get_arg("msg_id"));
							tda = {};
							AtomicInt.inc(ref job_count);
							db_job.finished.connect(dec_and_test_job_cnt);
							db_worker.push_job(db_job);
						}
					}
				}
				else if(psVideo.match_string(mime)) {
					td = new TrackData();
					td.artist = "unknown artist";
					td.album = "unknown album";
					td.title = prepare_name_from_filename(file.get_basename());
					td.genre = "";
					td.tracknumber = 0;
//					td.uri = file.get_uri();
//					td.mediatype = ItemType.LOCAL_VIDEO_TRACK;
					td.item = Item(ItemType.LOCAL_VIDEO_TRACK, file.get_uri());
					tdv += td;
					job.big_counter[1]++;
					if(job.big_counter[1] % 50 == 0) {
						Idle.add( () => {  // Update progress bar
							unowned Gtk.ProgressBar pb = (Gtk.ProgressBar) userinfo.get_extra_widget_by_id((uint)job.get_arg("msg_id"));
							if(pb != null) {
								pb.pulse();
								pb.set_text("%d tracks found".printf((int)job.big_counter[1]));//, (int)job.big_counter[0]));
							}
							return false;
						});
					}
					if(tdv.length > FILE_COUNT) {
						var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
						db_job.track_dat = tda;
						tdv = {};
						AtomicInt.inc(ref job_count);
						db_job.finished.connect(dec_and_test_job_cnt);
						db_worker.push_job(db_job);
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
				AtomicInt.inc(ref job_count);
				db_job.finished.connect(dec_and_test_job_cnt);
				db_worker.push_job(db_job);
			}
			if(tdv.length > 0) {
				TrackData[] tdvx = tdv;
				var db_job = new Worker.Job(Worker.ExecutionType.ONCE, insert_trackdata_job);
				db_job.track_dat = tdv;
				tdv = {};
				AtomicInt.inc(ref job_count);
				db_job.finished.connect(dec_and_test_job_cnt);
				db_worker.push_job(db_job);
			}
			end_import(job);
		}
		return;
	}
	
	private void dec_and_test_job_cnt() {
		AtomicInt.dec_and_test(ref job_count);
		//print("AtomicInt.get(ref job_count): %d\n", AtomicInt.get(ref job_count));
		if(AtomicInt.get(ref job_count) <= 0 && io_import_job_running == false) {
			//print("NOW !\n");
			//print("set import to false\n");
			global.media_import_in_progress = false;
			if(current_import_msg_id != 0) {
				userinfo.popdown(current_import_msg_id);
				current_import_msg_id = 0;
			}
		}
	}
	
	private bool insert_trackdata_job(Worker.Job job) {
		db_writer.begin_transaction();
		foreach(TrackData td in job.track_dat) {
			db_writer.insert_title(ref td);
		}
		db_writer.commit_transaction();
		return false;
	}
	
	private void count_media_files(File dir, Worker.Job job) {
		FileInfo info;
		string attr = FILE_ATTRIBUTE_STANDARD_NAME + "," +
		              FILE_ATTRIBUTE_STANDARD_TYPE + "," +
		              FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
		try {
			var enumerator = dir.enumerate_children(attr, 0);
			
			while((info = enumerator.next_file()) != null) {
				FileType filetype = info.get_file_type();
				string filename = info.get_name();
				string filepath = Path.build_filename(dir.get_path(), filename);
				File file = File.new_for_path(filepath);
				if(filetype == FileType.DIRECTORY) {
					count_media_files(file, job);
				}
				else {
					string content = info.get_content_type();
					string mime    = ContentType.get_mime_type(content);
					if(psAudio.match_string(mime) || psVideo.match_string(mime))
						job.big_counter[0]++;
				}
			}
		} 
		catch(Error e) {
			print("%s\n", e.message);
		}
	}
	
	// add streams to the media path and store them in the db
	private bool store_streams_job(Worker.Job job) {
		var streams_ht = new HashTable<string,int>(str_hash, str_equal);
		db_writer.begin_transaction();

		db_writer.del_all_streams();

		foreach(string strm in (string[])job.get_arg("list_of_streams")) {
			streams_ht.insert(strm, 1); // remove duplicates
		}

		foreach(string strm in streams_ht.get_keys()) {
			db_writer.add_single_stream_to_collection(strm, strm); //TODO: Use name different from uri
		}
		
		db_writer.commit_transaction();
		
		TrackData val;
		TrackData[] tdax = {};
		foreach(string strm in streams_ht.get_keys()) {
			db_writer.get_trackdata_for_stream(strm, out val);
			tdax += val;
		}
		job.track_dat = tdax;
		Idle.add( () => {
//			Main.instance.main_window.mediaBr.mediabrowsermodel.insert_stream_sorted(job.track_dat); 
			return false; 
		});
		
		streams_ht.remove_all();
//		global.sig_media_path_changed();
		return false;
	}
	
	// add files to the media path and store them in the db
	private bool store_files_job(Worker.Job job) {
		if(db_writer == null) 
			return false;
		
		var files_ht = new HashTable<string,int>(str_hash, str_equal);

		db_writer.del_all_files();

		foreach(string strm in (string[])job.get_arg("list_of_files")) {
			files_ht.insert(strm, 1);
		}
		
		//put in db
		foreach(string uri in files_ht.get_keys()) {
			db_writer.add_single_file_to_collection(uri);
		}

		//put in mediabrowser
		foreach(string uri in files_ht.get_keys()) {
			this.add_single_file(uri);
		}

		files_ht.remove_all();
//		global.sig_media_path_changed();
		return false;
	}

}

